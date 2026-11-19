import 'dart:convert';
import 'dart:io';

import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  final source =
      jsonDecode(
            File(
              'test/data/reference/astronomy/jpl-de421-2026.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  test('engine matches JPL DE421 references for multiple method profiles', () {
    var schedulesChecked = 0;
    final profiles = source['calculation_profiles'] as List<dynamic>;
    for (final raw in source['records'] as List<dynamic>) {
      final record = raw as Map<String, dynamic>;
      final latitude = (record['latitude'] as num).toDouble();
      final coords = Coordinates(
        latitude,
        (record['longitude'] as num).toDouble(),
      );
      final date = DateTime.parse(record['date'] as String);
      final baseReference = record['events_utc'] as Map<String, dynamic>;
      final profileReferences =
          record['method_events_utc'] as Map<String, dynamic>;

      for (final profileRaw in profiles) {
        final profile = profileRaw as Map<String, dynamic>;
        final profileId = profile['id'] as String;
        final shadowFactor = (profile['asr_shadow_factor'] as num).toDouble();
        final times = PrayerTimes(
          date: date,
          coordinates: coords,
          calculationParameters: CalculationMethod.other.parameters.copyWith(
            fajrAngle: (profile['fajr_angle_degrees'] as num).toDouble(),
            ishaAngle: (profile['isha_angle_degrees'] as num).toDouble(),
            madhab: shadowFactor == 2 ? Madhab.hanafi : Madhab.shafi,
          ),
          precision: true,
        );
        final profileReference =
            profileReferences[profileId] as Map<String, dynamic>;
        final events = <String, PrayerEventResult>{
          'transit': times.eventForPrayer(Prayer.dhuhr),
          'sunrise': times.eventForPrayer(Prayer.sunrise),
          'sunset': times.eventForPrayer(Prayer.maghrib),
          'asr': times.eventForPrayer(Prayer.asr),
          'fajr': times.eventForPrayer(Prayer.fajr),
          'isha': times.eventForPrayer(Prayer.isha),
        };
        final expected = <String, String?>{
          'transit': baseReference['transit'] as String?,
          'sunrise': baseReference['sunrise'] as String?,
          'sunset': baseReference['sunset'] as String?,
          'asr': profileReference['asr'] as String?,
          'fajr': profileReference['fajr'] as String?,
          'isha': profileReference['isha'] as String?,
        };

        for (final entry in events.entries) {
          final timestamp = expected[entry.key];
          final result = entry.value;
          final label =
              '${profile['label']} ${record['location']} ${record['date']} ${entry.key}';
          if (timestamp == null) {
            expect(
              result.source,
              PrayerEventSource.highLatitudeFallback,
              reason: label,
            );
            expect(result.time, isNotNull, reason: label);
            continue;
          }
          expect(result.source, PrayerEventSource.astronomical, reason: label);
          expect(result.time, isNotNull, reason: label);
          final error = result.time!
              .difference(DateTime.parse(timestamp).toUtc())
              .inSeconds
              .abs();
          final toleranceSeconds = switch (entry.key) {
            'transit' => 60,
            'sunrise' || 'sunset' => latitude.abs() < 55 ? 120 : 300,
            'asr' => latitude.abs() < 55 ? 120 : 300,
            'fajr' || 'isha' => latitude.abs() < 55 ? 180 : 600,
            _ => throw StateError('Unexpected reference event ${entry.key}'),
          };
          expect(error, lessThanOrEqualTo(toleranceSeconds), reason: label);
        }
        schedulesChecked++;
      }
    }
    expect(schedulesChecked, 192);
  });
}
