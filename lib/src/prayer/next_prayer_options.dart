import 'package:islamic_utility/src/models/prayer.dart';

/// Controls which prayer-time events can be returned as the next event.
enum ImsakPolicy {
  /// Include Imsak on every date. This is the default.
  always,

  /// Include Imsak only when [NextPrayerOptions.isRamadanOn] returns true.
  ramadanOnly,

  /// Never include Imsak as a next event.
  never,
}

/// Options used to select the next prayer-time event.
class NextPrayerOptions {
  const NextPrayerOptions({
    this.skip = const {},
    this.imsakPolicy = ImsakPolicy.always,
    this.isRamadanOn,
  });

  /// Events to omit when choosing the next event.
  ///
  /// Supported events are Imsak, Fajr, sunrise, Dhuha, Dhuhr, Asr, Maghrib,
  /// and Isha. `fajrAfter` is treated as Fajr for compatibility.
  final Set<Prayer> skip;

  /// Determines whether Imsak is considered, independently of [skip].
  final ImsakPolicy imsakPolicy;

  /// Returns whether the supplied target-location calendar date is in Ramadan.
  /// Required when [imsakPolicy] is [ImsakPolicy.ramadanOnly].
  ///
  /// The date is normalized to UTC midnight, but its year, month, and day are
  /// the target location's civil date. The callback is checked for both today
  /// and tomorrow when building the next-event candidates.
  final bool Function(DateTime locationDate)? isRamadanOn;

  bool includesImsak(DateTime locationDate) {
    switch (imsakPolicy) {
      case ImsakPolicy.always:
        return true;
      case ImsakPolicy.ramadanOnly:
        final predicate = isRamadanOn;
        if (predicate == null) {
          throw ArgumentError(
            'isRamadanOn is required when imsakPolicy is ramadanOnly',
          );
        }
        return predicate(
          DateTime.utc(locationDate.year, locationDate.month, locationDate.day),
        );
      case ImsakPolicy.never:
        return false;
    }
  }
}
