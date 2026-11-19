import 'dart:convert';
import 'dart:io';

import 'package:islamic_utility/islamic_utility.dart';

const _defaultDataset = 'test/data/reference/kemenag/national-2026.jsonl.gz';

const _prayers = <({Prayer prayer, String sourceKey, String label})>[
  (prayer: Prayer.imsak, sourceKey: 'imsak', label: 'Imsak'),
  (prayer: Prayer.fajr, sourceKey: 'subuh', label: 'Fajr/Subuh'),
  (prayer: Prayer.sunrise, sourceKey: 'terbit', label: 'Sunrise/Terbit'),
  (prayer: Prayer.dhuha, sourceKey: 'dhuha', label: 'Dhuha'),
  (prayer: Prayer.dhuhr, sourceKey: 'dzuhur', label: 'Dhuhr/Zuhur'),
  (prayer: Prayer.asr, sourceKey: 'ashar', label: 'Asr/Ashar'),
  (prayer: Prayer.maghrib, sourceKey: 'maghrib', label: 'Maghrib'),
  (prayer: Prayer.isha, sourceKey: 'isya', label: 'Isha/Isya'),
];

int _utcOffsetHours(String province) {
  final name = province.toUpperCase();
  if (name.contains('MALUKU') || name.contains('PAPUA')) return 9;
  if (name.contains('BALI') ||
      name.contains('NUSA TENGGARA') ||
      name.contains('SULAWESI') ||
      name.contains('GORONTALO') ||
      name.contains('KALIMANTAN SELATAN') ||
      name.contains('KALIMANTAN TIMUR') ||
      name.contains('KALIMANTAN UTARA')) {
    return 8;
  }
  return 7;
}

int _clockMinutes(String value) {
  final parts = value.split(':');
  if (parts.length != 2) throw FormatException('Invalid clock time: $value');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

double _differenceMinutes(DateTime actualUtc, int expectedLocal, int offset) {
  final actualLocal =
      (actualUtc.hour * 60 +
          actualUtc.minute +
          actualUtc.second / 60 +
          offset * 60) %
      1440;
  var difference = actualLocal - expectedLocal;
  if (difference > 720) difference -= 1440;
  if (difference < -720) difference += 1440;
  return difference;
}

String _fmt(double value) => value.toStringAsFixed(2);

String _csv(String value) => '"${value.replaceAll('"', '""')}"';

String _localClock(DateTime utc, int offset) {
  final minuteOfDay = (utc.hour * 60 + utc.minute + offset * 60) % 1440;
  final hour = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
  final minute = (minuteOfDay % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _option(List<String> arguments, String name, {String? fallback}) {
  final prefix = '$name=';
  final inline = arguments.where((arg) => arg.startsWith(prefix)).toList();
  if (inline.length > 1) throw ArgumentError('Use $name only once.');
  if (inline.isNotEmpty) return inline.single.substring(prefix.length);
  final index = arguments.indexOf(name);
  if (index >= 0) {
    if (index + 1 >= arguments.length ||
        arguments[index + 1].startsWith('--')) {
      throw ArgumentError('Missing value for $name.');
    }
    return arguments[index + 1];
  }
  if (fallback != null) return fallback;
  throw ArgumentError('Missing required option $name.');
}

Map<String, dynamic> _summarize(
  List<({double minutes, String location, String date})> values,
) {
  values.sort((a, b) => a.minutes.compareTo(b.minutes));
  final raw = values.map((x) => x.minutes).toList();
  final absValues = raw.map((x) => x.abs()).toList()..sort();
  final mean = raw.reduce((a, b) => a + b) / raw.length;
  final median = raw.length.isOdd
      ? raw[raw.length ~/ 2]
      : (raw[raw.length ~/ 2 - 1] + raw[raw.length ~/ 2]) / 2;
  final mae = absValues.reduce((a, b) => a + b) / raw.length;
  final p95 = absValues[(absValues.length * 0.95).ceil() - 1];
  final withinOne = raw.where((x) => x.abs() <= 1).length;
  final overFive = raw.where((x) => x.abs() > 5).length;
  final maxCase = raw.reduce((a, b) => a.abs() >= b.abs() ? a : b);
  final caseRecord = values.firstWhere((x) => x.minutes == maxCase);
  return {
    'samples': raw.length,
    'mean_minutes': mean,
    'median_minutes': median,
    'mae_minutes': mae,
    'p95_abs_minutes': p95,
    'within_1_minute': withinOne,
    'over_5_minutes': overFive,
    'max_abs_minutes': maxCase,
    'max_case': '${caseRecord.date}, ${caseRecord.location}',
  };
}

void main(List<String> arguments) {
  const allowedOptions = {
    '--dataset',
    '--compare',
    '--json-output',
    '--output',
    '--details-output',
  };
  final positional = <String>[];
  for (var i = 0; i < arguments.length; i++) {
    final argument = arguments[i];
    if (argument.startsWith('--')) {
      final key = argument.contains('=')
          ? argument.substring(0, argument.indexOf('='))
          : argument;
      if (!allowedOptions.contains(key)) {
        throw ArgumentError('Unknown option: $key');
      }
      if (!argument.contains('=')) i++;
    } else {
      positional.add(argument);
    }
  }
  if (positional.length > 1 ||
      (positional.isNotEmpty &&
          arguments.any((x) => x.startsWith('--dataset')))) {
    throw ArgumentError(
      'Pass the dataset either positionally or with --dataset, not both.',
    );
  }
  final path = positional.isNotEmpty
      ? positional.single
      : _option(arguments, '--dataset', fallback: _defaultDataset);
  final comparePath =
      arguments.any((x) => x == '--compare' || x.startsWith('--compare='))
      ? _option(arguments, '--compare')
      : null;
  final jsonOutput =
      arguments.any(
        (x) => x == '--json-output' || x.startsWith('--json-output='),
      )
      ? _option(arguments, '--json-output')
      : null;
  final markdownOutput =
      arguments.any((x) => x == '--output' || x.startsWith('--output='))
      ? _option(arguments, '--output')
      : null;
  final detailsOutput =
      arguments.any(
        (x) => x == '--details-output' || x.startsWith('--details-output='),
      )
      ? _option(arguments, '--details-output')
      : null;
  final compressed = File(path).readAsBytesSync();
  final lines = utf8.decode(gzip.decode(compressed)).split('\n');
  final differences =
      <Prayer, List<({double minutes, String location, String date})>>{
        for (final item in _prayers)
          item.prayer: <({double minutes, String location, String date})>[],
      };
  var dayCount = 0;
  var locationMonths = 0;
  final detailRows = <StringBuffer>[];
  if (detailsOutput != null) {
    final header = StringBuffer('date,province,city,latitude,longitude');
    for (final item in _prayers) {
      header
        ..write(',kemenag_${item.prayer.name}')
        ..write(',engine_${item.prayer.name}')
        ..write(',delta_${item.prayer.name}_minutes');
    }
    detailRows.add(header);
  }

  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final record = jsonDecode(line) as Map<String, dynamic>;
    final request = record['request'] as Map<String, dynamic>;
    final coordinates = record['coordinates'] as Map<String, dynamic>;
    final response = record['response'] as Map<String, dynamic>;
    final province = request['province'] as String;
    final city = request['city'] as String;
    final offset = _utcOffsetHours(province);
    locationMonths++;

    final scheduleDays = response['data'] as Map<String, dynamic>;
    for (final entry in scheduleDays.entries) {
      final parts = entry.key.split('-').map(int.parse).toList();
      final date = DateTime.utc(parts[0], parts[1], parts[2]);
      final official = entry.value as Map<String, dynamic>;
      final computed = PrayerTimes(
        date: date,
        coordinates: Coordinates(
          (coordinates['latitude'] as num).toDouble(),
          (coordinates['longitude'] as num).toDouble(),
        ),
        calculationParameters: CalculationMethod.indonesian.parameters,
        precision: true,
      );
      dayCount++;

      StringBuffer? detail;
      if (detailsOutput != null) {
        detail = StringBuffer()
          ..write('${_csv(entry.key)},${_csv(province)},${_csv(city)},')
          ..write('${coordinates['latitude']},${coordinates['longitude']}');
      }
      for (final item in _prayers) {
        final officialValue = official[item.sourceKey];
        if (officialValue == null) {
          detail?.write(',,,');
          continue;
        }
        final officialTime = officialValue as String;
        final engineTime = computed.timeForPrayer(item.prayer);
        final delta = _differenceMinutes(
          engineTime,
          _clockMinutes(officialTime),
          offset,
        );
        differences[item.prayer]!.add((
          minutes: delta,
          location: '$city, $province',
          date: entry.key,
        ));
        detail
          ?..write(',${_csv(officialTime)}')
          ..write(',${_csv(_localClock(engineTime, offset))}')
          ..write(',${_fmt(delta)}');
      }
      if (detail != null) detailRows.add(detail);
    }
  }

  if (detailsOutput != null) {
    final csv = '${detailRows.join('\n')}\n';
    File(detailsOutput).writeAsBytesSync(gzip.encode(utf8.encode(csv)));
  }

  final metrics = <String, Map<String, dynamic>>{};
  for (final item in _prayers) {
    final values = differences[item.prayer]!;
    if (values.isEmpty) continue;
    metrics[item.prayer.name] = _summarize(values);
  }

  final result = <String, dynamic>{
    'dataset': path,
    'location_month_records': locationMonths,
    'location_days': dayCount,
    'method': 'CalculationMethod.indonesian, precision=true',
    'delta_sign': 'package result minus Kemenag, in minutes',
    'metrics': metrics,
  };
  if (jsonOutput != null) {
    File(jsonOutput).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(result)}\n',
    );
  }

  final baseline = comparePath == null
      ? null
      : jsonDecode(File(comparePath).readAsStringSync())
            as Map<String, dynamic>;
  final output = StringBuffer()
    ..writeln(
      baseline == null
          ? '# Kemenag SIHAT 2026 parity baseline'
          : '# Kemenag SIHAT 2026 parity comparison',
    )
    ..writeln()
    ..writeln('- Dataset: `$path`')
    ..writeln('- Location-month records: $locationMonths')
    ..writeln('- Location-days: $dayCount')
    ..writeln('- Method: `CalculationMethod.indonesian`, `precision=true`')
    ..writeln('- Delta sign: package result minus Kemenag, in minutes')
    ..writeln();

  if (baseline == null) {
    output
      ..writeln(
        '| Prayer | Samples | Mean | Median | MAE | P95 abs | Within ±1 min | >5 min | Max abs case |',
      )
      ..writeln('|---|---:|---:|---:|---:|---:|---:|---:|---|');
    for (final item in _prayers) {
      final stats = metrics[item.prayer.name]!;
      final n = stats['samples'] as int;
      output.writeln(
        '| ${item.label} | $n | ${_fmt((stats['mean_minutes'] as num).toDouble())} | '
        '${_fmt((stats['median_minutes'] as num).toDouble())} | ${_fmt((stats['mae_minutes'] as num).toDouble())} | '
        '${_fmt((stats['p95_abs_minutes'] as num).toDouble())} | '
        '${stats['within_1_minute']} (${_fmt((stats['within_1_minute'] as int) * 100 / n)}%) | '
        '${stats['over_5_minutes']} (${_fmt((stats['over_5_minutes'] as int) * 100 / n)}%) | '
        '${stats['max_case']} (${_fmt((stats['max_abs_minutes'] as num).toDouble())}) |',
      );
    }
  } else {
    if (baseline['dataset'] != path) {
      throw StateError(
        'Dataset path differs from baseline. Compare reports using the same dataset.',
      );
    }
    if (baseline['location_days'] != dayCount ||
        baseline['location_month_records'] != locationMonths) {
      throw StateError(
        'Baseline coverage differs. Compare only reports with identical dataset coverage.',
      );
    }
    final baselineMetrics = baseline['metrics'] as Map<String, dynamic>;
    output
      ..writeln(
        'Negative MAE/P95 change means the updated engine is closer to Kemenag.',
      )
      ..writeln()
      ..writeln(
        '| Prayer | Baseline MAE | Updated MAE | MAE change | Baseline P95 | Updated P95 | P95 change |',
      )
      ..writeln('|---|---:|---:|---:|---:|---:|---:|');
    for (final item in _prayers) {
      final before = baselineMetrics[item.prayer.name] as Map<String, dynamic>;
      final after = metrics[item.prayer.name]!;
      final beforeMae = (before['mae_minutes'] as num).toDouble();
      final afterMae = (after['mae_minutes'] as num).toDouble();
      final beforeP95 = (before['p95_abs_minutes'] as num).toDouble();
      final afterP95 = (after['p95_abs_minutes'] as num).toDouble();
      output.writeln(
        '| ${item.label} | ${_fmt(beforeMae)} | ${_fmt(afterMae)} | ${_fmt(afterMae - beforeMae)} | '
        '${_fmt(beforeP95)} | ${_fmt(afterP95)} | ${_fmt(afterP95 - beforeP95)} |',
      );
    }
  }
  if (markdownOutput == null) {
    stdout.write(output);
  } else {
    File(markdownOutput).writeAsStringSync(output.toString());
  }
}
