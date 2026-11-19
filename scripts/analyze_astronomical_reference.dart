import 'dart:convert';
import 'dart:io';

import 'package:islamic_utility/islamic_utility.dart';

const _defaultInput = 'test/data/reference/astronomy/noaa-2026.json';
const _defaultJsonOutput =
    'test/data/reference/astronomy/current-engine-baseline.json';
const _defaultMarkdownOutput =
    'test/data/reference/astronomy/current-engine-baseline.md';

void main(List<String> arguments) {
  if (arguments.length > 3) {
    throw ArgumentError('Use: [reference.json [output.json [output.md]]].');
  }
  final input = arguments.isEmpty ? _defaultInput : arguments[0];
  final jsonOutput = arguments.length < 2 ? _defaultJsonOutput : arguments[1];
  final markdownOutput = arguments.length < 3
      ? _defaultMarkdownOutput
      : arguments[2];
  final source =
      jsonDecode(File(input).readAsStringSync()) as Map<String, dynamic>;
  final rows = <Map<String, dynamic>>[];
  final differences = <String, List<double>>{};
  final availabilityMismatch = <String, int>{};

  for (final raw in source['records'] as List<dynamic>) {
    final record = raw as Map<String, dynamic>;
    final date = DateTime.parse(record['date'] as String);
    final coords = Coordinates(
      (record['latitude'] as num).toDouble(),
      (record['longitude'] as num).toDouble(),
    );
    final parameters = CalculationMethod.other.parameters.copyWith(
      fajrAngle: 18,
      ishaAngle: 17,
      madhab: Madhab.shafi,
    );
    final times = PrayerTimes(
      date: date,
      coordinates: coords,
      calculationParameters: parameters,
      precision: true,
    );
    final actual = <String, PrayerEventResult>{
      'transit': times.eventForPrayer(Prayer.dhuhr),
      'sunrise': times.eventForPrayer(Prayer.sunrise),
      'sunset': times.eventForPrayer(Prayer.maghrib),
      'asr_shafii': times.eventForPrayer(Prayer.asr),
      'fajr_18': times.eventForPrayer(Prayer.fajr),
      'isha_17': times.eventForPrayer(Prayer.isha),
    };
    final expected = record['events_utc'] as Map<String, dynamic>;
    final eventRows = <String, dynamic>{};
    for (final entry in actual.entries) {
      final referenceString = expected[entry.key] as String?;
      final engineResult = entry.value;
      final referenceAvailable = referenceString != null;
      final engineGeometricEvent =
          engineResult.source == PrayerEventSource.astronomical;
      final comparable = referenceAvailable && engineGeometricEvent;
      if (referenceAvailable != engineGeometricEvent) {
        availabilityMismatch.update(
          entry.key,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      if (!comparable || engineResult.time == null) {
        eventRows[entry.key] = {
          'reference_available': referenceAvailable,
          'engine_geometric_event_available': engineGeometricEvent,
          'engine_source': engineResult.source.name,
          if (engineResult.time != null)
            'engine_utc': engineResult.time!.toIso8601String(),
        };
        continue;
      }
      final reference = DateTime.parse(referenceString).toUtc();
      final seconds =
          engineResult.time!.difference(reference).inMicroseconds / 1e6;
      differences.putIfAbsent(entry.key, () => []).add(seconds / 60);
      eventRows[entry.key] = {
        'reference_available': true,
        'engine_geometric_event_available': true,
        'engine_source': engineResult.source.name,
        'reference_utc': reference.toIso8601String(),
        'engine_utc': engineResult.time!.toIso8601String(),
        'delta_seconds': seconds,
      };
    }
    rows.add({
      'location': record['location'],
      'latitude': record['latitude'],
      'longitude': record['longitude'],
      'civil_timezone': record['civil_timezone'],
      'date': record['date'],
      'events': eventRows,
    });
  }

  final sourceName = source['source'] as String? ?? 'unspecified reference';
  final metrics = <String, dynamic>{};
  final markdown = StringBuffer()
    ..writeln('# Current engine comparison against $sourceName')
    ..writeln()
    ..writeln('- Input reference: `$input`.')
    ..writeln(
      '- Coverage: ${rows.length} location/date records; 8 locations × 4 seasonal dates.',
    )
    ..writeln(
      '- Parameters: Fajr 18°, Isha 17°, Shafi Asr, sea level; times compared in UTC.',
    )
    ..writeln('- Delta: package output minus reference, minutes.')
    ..writeln()
    ..writeln(
      '| Event | Samples | MAE min | P95 abs min | Max abs min | Availability mismatches |',
    )
    ..writeln('|---|---:|---:|---:|---:|---:|');
  for (final entry in differences.entries) {
    final abs = entry.value.map((value) => value.abs()).toList()..sort();
    final mean = abs.reduce((a, b) => a + b) / abs.length;
    final p95 = abs[(abs.length * 0.95).ceil() - 1];
    final max = abs.last;
    final mismatches = availabilityMismatch[entry.key] ?? 0;
    metrics[entry.key] = {
      'samples': abs.length,
      'mae_minutes': mean,
      'p95_abs_minutes': p95,
      'max_abs_minutes': max,
      'availability_mismatch_count': mismatches,
    };
    markdown.writeln(
      '| ${entry.key} | ${abs.length} | ${mean.toStringAsFixed(2)} | ${p95.toStringAsFixed(2)} | ${max.toStringAsFixed(2)} | $mismatches |',
    );
  }
  final output = {
    'reference': input,
    'source': sourceName,
    'engine': 'current worktree',
    'parameters': {
      'fajr_angle_degrees': 18,
      'isha_angle_degrees': 17,
      'asr_shadow_factor': 1,
      'elevation_meters': 0,
      'precision': true,
    },
    'delta_sign': 'engine minus reference, minutes',
    'metrics': metrics,
    'records': rows,
  };
  File(jsonOutput).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(output)}\n',
  );
  File(markdownOutput).writeAsStringSync(markdown.toString());
  stdout.write(markdown);
}
