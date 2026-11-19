import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

final _locations = <({String name, Coordinates coordinates})>[
  (name: 'Jakarta', coordinates: const Coordinates(-6.2, 106.8)),
  (name: 'Singapore', coordinates: const Coordinates(1.3521, 103.8198)),
  (name: 'Makkah', coordinates: const Coordinates(21.4225, 39.8262)),
  (name: 'London', coordinates: const Coordinates(51.5072, -0.1276)),
  (name: 'Reykjavik', coordinates: const Coordinates(64.1466, -21.9426)),
  (name: 'Sydney', coordinates: const Coordinates(-33.8688, 151.2093)),
  (name: 'Ushuaia', coordinates: const Coordinates(-54.8019, -68.3030)),
];

final _dates = <DateTime>[
  DateTime.utc(2026, 1, 15),
  DateTime.utc(2026, 4, 15),
  DateTime.utc(2026, 7, 15),
  DateTime.utc(2026, 10, 15),
];

CalculationParameters _parameters(CalculationMethod method) {
  if (method == CalculationMethod.other) {
    return method.parameters.copyWith(fajrAngle: 18, ishaAngle: 17);
  }
  return method.parameters;
}

List<DateTime> _events(PrayerTimes times) => [
  times.imsak,
  times.fajr,
  times.sunrise,
  times.dhuha,
  times.dhuhr,
  times.asr,
  times.maghrib,
  times.isha,
];

void main() {
  group('Prayer engine method × location × season matrix', () {
    test('all presets produce finite, ordered UTC event schedules', () {
      var schedulesChecked = 0;
      for (final method in CalculationMethod.values) {
        for (final location in _locations) {
          for (final date in _dates) {
            final times = PrayerTimes(
              date: date,
              coordinates: location.coordinates,
              calculationParameters: _parameters(method),
              precision: true,
            );
            final events = _events(times);
            final label = '${method.name}, ${location.name}, $date';

            expect(events.every((event) => event.isUtc), isTrue, reason: label);
            for (var i = 0; i < events.length - 1; i++) {
              expect(
                events[i].isBefore(events[i + 1]),
                isTrue,
                reason: '$label: event index $i must precede ${i + 1}',
              );
            }
            expect(
              times.ishaBefore.isBefore(times.fajrAfter),
              isTrue,
              reason: '$label: adjacent-night boundaries must be ordered',
            );
            schedulesChecked++;
          }
        }
      }
      expect(
        schedulesChecked,
        CalculationMethod.values.length * _locations.length * _dates.length,
      );
    });

    test('minute precision stays within 30 seconds across the full matrix', () {
      var schedulesChecked = 0;
      for (final method in CalculationMethod.values) {
        for (final location in _locations) {
          for (final date in _dates) {
            final parameters = _parameters(method);
            final exact = PrayerTimes(
              date: date,
              coordinates: location.coordinates,
              calculationParameters: parameters,
              precision: true,
            );
            final rounded = PrayerTimes(
              date: date,
              coordinates: location.coordinates,
              calculationParameters: parameters,
              precision: false,
            );
            final exactEvents = _events(exact);
            final roundedEvents = _events(rounded);
            final label = '${method.name}, ${location.name}, $date';

            for (var i = 0; i < exactEvents.length; i++) {
              final delta = exactEvents[i]
                  .difference(roundedEvents[i])
                  .inSeconds
                  .abs();
              expect(delta <= 30, isTrue, reason: '$label, event index $i');
              expect(roundedEvents[i].second, 0, reason: label);
            }
            schedulesChecked++;
          }
        }
      }
      expect(
        schedulesChecked,
        CalculationMethod.values.length * _locations.length * _dates.length,
      );
    });
  });
}
