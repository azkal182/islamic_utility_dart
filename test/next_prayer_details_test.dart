import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  final parameters = CalculationMethod.indonesian.parameters;
  const coordinates = Coordinates(-6.2, 106.8);

  PrayerTimes schedule(DateTime date) => PrayerTimes(
    date: date,
    coordinates: coordinates,
    calculationParameters: parameters,
    precision: true,
  );

  group('nextPrayerDetails', () {
    test('marks Fajr after Isha as next local day', () {
      final times = schedule(DateTime.utc(2026, 5, 1));
      final afterIsha = times.isha.add(const Duration(minutes: 1));

      final details = times.nextPrayerDetails(
        at: afterIsha,
        locationDate: DateTime.utc(2026, 5, 1),
      );

      expect(details.prayer, Prayer.imsak);
      expect(
        details.time,
        times.fajrAfter.subtract(const Duration(minutes: 10)),
      );
      expect(details.isNextDay, isTrue);
    });

    test('after midnight, Fajr is today rather than tomorrow', () {
      final tomorrow = schedule(DateTime.utc(2026, 5, 2));
      final beforeFajr = tomorrow.fajr.subtract(const Duration(minutes: 1));

      final details = tomorrow.nextPrayerDetails(
        at: beforeFajr,
        locationDate: DateTime.utc(2026, 5, 2),
      );

      expect(details.prayer, Prayer.fajr);
      expect(details.time, tomorrow.fajr);
      expect(details.isNextDay, isFalse);
    });

    test('legacy nextPrayer advances to the requested local date', () {
      const utcCoordinates = Coordinates(0, 0);
      PrayerTimes utcSchedule(DateTime date) => PrayerTimes(
        date: date,
        coordinates: utcCoordinates,
        calculationParameters: parameters,
        precision: true,
      );

      final yesterday = utcSchedule(DateTime.utc(2026, 5, 1));
      final today = utcSchedule(DateTime.utc(2026, 5, 2));
      final afterFajr = today.fajr.add(const Duration(minutes: 1));

      expect(yesterday.nextPrayer(date: afterFajr), Prayer.sunrise);
      expect(yesterday.currentPrayer(date: afterFajr), Prayer.fajr);
    });

    test('legacy lookup advances across multiple stale schedule days', () {
      const utcCoordinates = Coordinates(0, 0);
      PrayerTimes utcSchedule(DateTime date) => PrayerTimes(
        date: date,
        coordinates: utcCoordinates,
        calculationParameters: parameters,
        precision: true,
      );

      final stale = utcSchedule(DateTime.utc(2026, 5, 1));
      final current = utcSchedule(DateTime.utc(2026, 5, 4));
      final afterFajr = current.fajr.add(const Duration(minutes: 1));

      expect(stale.nextPrayer(date: afterFajr), Prayer.sunrise);
      expect(stale.currentPrayer(date: afterFajr), Prayer.fajr);
    });

    test('Imsak is included by default and can be skipped', () {
      final times = schedule(DateTime.utc(2026, 5, 1));
      final beforeImsak = times.imsak.subtract(const Duration(minutes: 1));

      final defaultResult = times.nextPrayerDetails(
        at: beforeImsak,
        locationDate: DateTime.utc(2026, 5, 1),
      );
      final skippedResult = times.nextPrayerDetails(
        at: beforeImsak,
        locationDate: DateTime.utc(2026, 5, 1),
        options: const NextPrayerOptions(skip: {Prayer.imsak}),
      );

      expect(defaultResult.prayer, Prayer.imsak);
      expect(skippedResult.prayer, Prayer.fajr);
    });

    test('Ramadan-only Imsak checks the event date, including tomorrow', () {
      final times = schedule(DateTime.utc(2026, 5, 1));
      final afterIsha = times.isha.add(const Duration(minutes: 1));
      final checkedDates = <DateTime>[];

      final details = times.nextPrayerDetails(
        at: afterIsha,
        locationDate: DateTime.utc(2026, 5, 1),
        options: NextPrayerOptions(
          imsakPolicy: ImsakPolicy.ramadanOnly,
          isRamadanOn: (date) {
            checkedDates.add(date);
            return date.day == 2;
          },
        ),
      );

      expect(details.prayer, Prayer.imsak);
      expect(details.isNextDay, isTrue);
      expect(checkedDates, contains(DateTime.utc(2026, 5, 2)));
    });

    test('ramadanOnly requires a Ramadan callback', () {
      final times = schedule(DateTime.utc(2026, 5, 1));

      expect(
        () => times.nextPrayerDetails(
          at: times.isha,
          locationDate: DateTime.utc(2026, 5, 1),
          options: const NextPrayerOptions(
            imsakPolicy: ImsakPolicy.ramadanOnly,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('skipping Sunrise advances to Dhuha, then Dhuhr', () {
      final times = schedule(DateTime.utc(2026, 5, 1));
      final afterFajr = times.fajr.add(const Duration(minutes: 1));

      final skipSunrise = times.nextPrayerDetails(
        at: afterFajr,
        locationDate: DateTime.utc(2026, 5, 1),
        options: const NextPrayerOptions(skip: {Prayer.sunrise}),
      );
      final skipSunriseAndDhuha = times.nextPrayerDetails(
        at: afterFajr,
        locationDate: DateTime.utc(2026, 5, 1),
        options: const NextPrayerOptions(skip: {Prayer.sunrise, Prayer.dhuha}),
      );

      expect(skipSunrise.prayer, Prayer.dhuha);
      expect(skipSunriseAndDhuha.prayer, Prayer.dhuhr);
    });
  });

  test('high latitude adjacent-day values use their own night durations', () {
    const stockholm = Coordinates(59.3293, 18.0686);
    final date = DateTime.utc(2026, 6, 21);
    final params = CalculationMethod.moonsightingCommittee.parameters;

    final yesterday = PrayerTimes(
      date: date.subtract(const Duration(days: 1)),
      coordinates: stockholm,
      calculationParameters: params,
      precision: true,
    );
    final today = PrayerTimes(
      date: date,
      coordinates: stockholm,
      calculationParameters: params,
      precision: true,
    );
    final tomorrow = PrayerTimes(
      date: date.add(const Duration(days: 1)),
      coordinates: stockholm,
      calculationParameters: params,
      precision: true,
    );

    expect(today.ishaBefore, yesterday.isha);
    expect(today.fajrAfter, tomorrow.fajr);
  });
}
