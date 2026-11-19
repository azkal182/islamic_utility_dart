import 'dart:convert';
import 'dart:io';

import 'package:islamic_utility/islamic_utility.dart';

const _datasetPath = 'test/data/reference/lfnu/bangsri-2026.json';
const _events = <({Prayer prayer, String key, String label})>[
  (prayer: Prayer.imsak, key: 'imsak', label: 'Imsak'),
  (prayer: Prayer.fajr, key: 'fajr', label: 'Fajr/Subuh'),
  (prayer: Prayer.sunrise, key: 'sunrise', label: 'Sunrise/Terbit'),
  (prayer: Prayer.dhuha, key: 'dhuha', label: 'Dhuha'),
  (prayer: Prayer.dhuhr, key: 'dhuhr', label: 'Dhuhr/Zuhur'),
  (prayer: Prayer.asr, key: 'asr', label: 'Asr/Ashar'),
  (prayer: Prayer.maghrib, key: 'maghrib', label: 'Maghrib'),
  (prayer: Prayer.isha, key: 'isha', label: 'Isha/Isya'),
];

String _clock(DateTime utc, int offsetMinutes) {
  final minuteOfDay = (utc.hour * 60 + utc.minute + offsetMinutes) % 1440;
  return '${(minuteOfDay ~/ 60).toString().padLeft(2, '0')}:${(minuteOfDay % 60).toString().padLeft(2, '0')}:${utc.second.toString().padLeft(2, '0')}';
}

int _parseClock(String value) {
  final parts = value.split(':').map(int.parse).toList();
  if (parts.length != 2) throw FormatException('Invalid time $value');
  return parts[0] * 60 + parts[1];
}

double _delta(DateTime computedUtc, String published, int offsetMinutes) {
  final actual =
      (computedUtc.hour * 60 +
          computedUtc.minute +
          computedUtc.second / 60 +
          offsetMinutes) %
      1440;
  final expected = _parseClock(published);
  var delta = actual - expected;
  if (delta > 720) delta -= 1440;
  if (delta < -720) delta += 1440;
  return delta.toDouble();
}

String _fmt(double value) => value.toStringAsFixed(2);
String _csv(String value) => '"${value.replaceAll('"', '""')}"';

Map<String, dynamic> _stats(List<({double delta, String date})> values) {
  final ordered = values.map((v) => v.delta).toList()..sort();
  final absolute = ordered.map((v) => v.abs()).toList()..sort();
  final mean = ordered.reduce((a, b) => a + b) / ordered.length;
  final median = ordered.length.isOdd
      ? ordered[ordered.length ~/ 2]
      : (ordered[ordered.length ~/ 2 - 1] + ordered[ordered.length ~/ 2]) / 2;
  final mae = absolute.reduce((a, b) => a + b) / absolute.length;
  final p95 = absolute[(absolute.length * 0.95).ceil() - 1];
  final maxDelta = values.reduce(
    (a, b) => a.delta.abs() >= b.delta.abs() ? a : b,
  );
  return {
    'samples': values.length,
    'mean_minutes': mean,
    'median_minutes': median,
    'mae_minutes': mae,
    'p95_abs_minutes': p95,
    'within_1_minute': values.where((v) => v.delta.abs() <= 1).length,
    'over_5_minutes': values.where((v) => v.delta.abs() > 5).length,
    'max_abs_minutes': maxDelta.delta,
    'max_case': maxDelta.date,
  };
}

void main(List<String> args) {
  final datasetPath = args.isEmpty ? _datasetPath : args.first;
  if (args.length > 1) {
    throw ArgumentError(
      'Usage: dart run scripts/analyze_lfnu_parity.dart [dataset.json]',
    );
  }
  final dataset =
      jsonDecode(File(datasetPath).readAsStringSync()) as Map<String, dynamic>;
  final location = dataset['location'] as Map<String, dynamic>;
  final records = dataset['records'] as List<dynamic>;
  final coordinates = Coordinates(
    (location['latitude'] as num).toDouble(),
    (location['longitude'] as num).toDouble(),
    elevation: (location['elevation_m'] as num).toDouble(),
  );
  final offsetMinutes = 7 * 60;
  final differences = <String, List<({double delta, String date})>>{
    for (final event in _events) event.key: <({double delta, String date})>[],
  };
  final detail = StringBuffer('date,is_ramadan');
  for (final event in _events) {
    detail
      ..write(',source_${event.key}')
      ..write(',engine_${event.key}')
      ..write(',delta_${event.key}_minutes');
  }
  for (final raw in records) {
    final record = raw as Map<String, dynamic>;
    final dateParts = (record['date'] as String)
        .split('-')
        .map(int.parse)
        .toList();
    final date = DateTime.utc(dateParts[0], dateParts[1], dateParts[2]);
    final isRamadan = record['is_ramadan'] as bool;
    final times = record['times_wib'] as Map<String, dynamic>;
    final schedule = PrayerTimes(
      date: date,
      coordinates: coordinates,
      calculationParameters: CalculationMethod.lfnu.parameters,
      precision: true,
      isRamadanOn: (_) => isRamadan,
    );
    detail.write('\n${_csv(record['date'] as String)},${isRamadan.toString()}');
    for (final event in _events) {
      final sourceTime = times[event.key] as String;
      final engineTime = schedule.timeForPrayer(event.prayer);
      final difference = _delta(engineTime, sourceTime, offsetMinutes);
      differences[event.key]!.add((
        delta: difference,
        date: record['date'] as String,
      ));
      detail
        ..write(',${_csv(sourceTime)}')
        ..write(',${_csv(_clock(engineTime, offsetMinutes))}')
        ..write(',${_fmt(difference)}');
    }
  }

  final metrics = <String, Map<String, dynamic>>{
    for (final event in _events) event.key: _stats(differences[event.key]!),
  };
  final jsonResult = {
    'dataset': datasetPath,
    'location': location,
    'method': 'CalculationMethod.lfnu, precision=true',
    'sample_days': records.length,
    'delta_sign': 'engine minus NU Online LFNU schedule, minutes',
    'metrics': metrics,
  };
  final markdown = StringBuffer()
    ..writeln('# LFNU Bangsri 2026: engine comparison')
    ..writeln()
    ..writeln('- Dataset: `$datasetPath`')
    ..writeln('- Location: Bangsri, Kabupaten Jepara, Jawa Tengah')
    ..writeln(
      '- Coordinates: ${location['latitude']}, ${location['longitude']}; elevation ${location['elevation_m']} m',
    )
    ..writeln(
      '- Method: `CalculationMethod.lfnu`, `precision=true`; Ramadan Maghrib adjustment follows each PDF Hijri month',
    )
    ..writeln('- Samples: ${records.length} days per event')
    ..writeln(
      '- Delta sign: engine minus NU Online, in minutes; negative means engine is earlier',
    )
    ..writeln(
      '- Engine retains second precision; NU Online publishes whole-minute times, so up to ±0.5 minute may come from source rounding.',
    )
    ..writeln()
    ..writeln(
      '| Event | Mean delta | Median | MAE | P95 abs | Within ±1 min | >5 min | Max abs case |',
    )
    ..writeln('|---|---:|---:|---:|---:|---:|---:|---|');
  for (final event in _events) {
    final stats = metrics[event.key]!;
    markdown.writeln(
      '| ${event.label} | ${_fmt((stats['mean_minutes'] as num).toDouble())} | ${_fmt((stats['median_minutes'] as num).toDouble())} | ${_fmt((stats['mae_minutes'] as num).toDouble())} | ${_fmt((stats['p95_abs_minutes'] as num).toDouble())} | ${stats['within_1_minute']} (${_fmt((stats['within_1_minute'] as int) * 100 / records.length)}%) | ${stats['over_5_minutes']} (${_fmt((stats['over_5_minutes'] as int) * 100 / records.length)}%) | ${stats['max_case']} (${_fmt((stats['max_abs_minutes'] as num).toDouble())}) |',
    );
  }
  stdout.write(markdown);
  File(
    'test/data/reference/lfnu/bangsri-2026-comparison.json',
  ).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(jsonResult)}\n',
  );
  File(
    'test/data/reference/lfnu/bangsri-2026-comparison.md',
  ).writeAsStringSync(markdown.toString());
  File(
    'test/data/reference/lfnu/bangsri-2026-engine-comparison.csv',
  ).writeAsStringSync('${detail.toString()}\n');
}
