import 'dart:convert';
import 'dart:io';

import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

const _datasetPath = 'test/data/reference/lfnu/bangsri-2026.json';
const _events = <({Prayer prayer, String key})>[
  (prayer: Prayer.imsak, key: 'imsak'),
  (prayer: Prayer.fajr, key: 'fajr'),
  (prayer: Prayer.sunrise, key: 'sunrise'),
  (prayer: Prayer.dhuha, key: 'dhuha'),
  (prayer: Prayer.dhuhr, key: 'dhuhr'),
  (prayer: Prayer.asr, key: 'asr'),
  (prayer: Prayer.maghrib, key: 'maghrib'),
  (prayer: Prayer.isha, key: 'isha'),
];

DateTime _roundUp(DateTime value) {
  final seconds = value.second;
  return value.add(Duration(seconds: seconds == 0 ? 0 : 60 - seconds));
}

DateTime _roundNearest(DateTime value) {
  final seconds = value.second;
  return value.add(Duration(seconds: seconds >= 30 ? 60 - seconds : -seconds));
}

String _clockWib(DateTime utc) {
  final local = utc.add(const Duration(hours: 7));
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

void main() {
  group('LFNU Bangsri annual reference dataset', () {
    test('compares all 2026 events under the documented display policies', () {
      final dataset =
          jsonDecode(File(_datasetPath).readAsStringSync())
              as Map<String, dynamic>;
      final location = dataset['location'] as Map<String, dynamic>;
      final records = dataset['records'] as List<dynamic>;
      final coordinates = Coordinates(
        (location['latitude'] as num).toDouble(),
        (location['longitude'] as num).toDouble(),
        elevation: (location['elevation_m'] as num).toDouble(),
      );
      final mismatches = {for (final event in _events) event.key: 0};
      final signedDeltas = {for (final event in _events) event.key: <int>[]};

      expect(dataset['schema'], 'lfnu-prayer-schedule/v1');
      expect(records, hasLength(365));

      for (final rawRecord in records) {
        final record = rawRecord as Map<String, dynamic>;
        final dateParts = (record['date'] as String)
            .split('-')
            .map(int.parse)
            .toList();
        final date = DateTime.utc(dateParts[0], dateParts[1], dateParts[2]);
        final published = record['times_wib'] as Map<String, dynamic>;
        final schedule = PrayerTimes(
          date: date,
          coordinates: coordinates,
          calculationParameters: CalculationMethod.lfnu.parameters,
          precision: true,
          isRamadanOn: (_) => record['is_ramadan'] as bool,
        );

        for (final event in _events) {
          final exact = schedule.timeForPrayer(event.prayer);
          // The source PDFs are minute-only. The comparison keeps their
          // observed sunrise minute behavior; other events use round-up.
          final displayed = event.prayer == Prayer.sunrise
              ? _roundNearest(exact)
              : _roundUp(exact);
          final expectedClock = published[event.key] as String;
          final actualClock = _clockWib(displayed);
          final expectedMinutes =
              int.parse(expectedClock.substring(0, 2)) * 60 +
              int.parse(expectedClock.substring(3, 5));
          final actualMinutes =
              int.parse(actualClock.substring(0, 2)) * 60 +
              int.parse(actualClock.substring(3, 5));
          var deltaMinutes = actualMinutes - expectedMinutes;
          if (deltaMinutes > 720) deltaMinutes -= 1440;
          if (deltaMinutes < -720) deltaMinutes += 1440;
          signedDeltas[event.key]!.add(deltaMinutes);

          if (actualClock != expectedClock) {
            mismatches[event.key] = mismatches[event.key]! + 1;
          }
        }
      }

      expect(mismatches, {
        'imsak': 0,
        'fajr': 0,
        'sunrise': 0,
        'dhuha': 1,
        'dhuhr': 0,
        'asr': 32,
        'maghrib': 0,
        'isha': 2,
      });
      expect(signedDeltas['dhuha']!.reduce((a, b) => a > b ? a : b), 1);
      expect(signedDeltas['asr']!.reduce((a, b) => a < b ? a : b), -1);
      expect(signedDeltas['asr']!.reduce((a, b) => a > b ? a : b), 1);
      expect(signedDeltas['isha']!.reduce((a, b) => a < b ? a : b), -1);
      expect(signedDeltas['isha']!.reduce((a, b) => a > b ? a : b), 1);
    });
  });
}
