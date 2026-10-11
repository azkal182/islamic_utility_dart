import 'package:islamic_utility/src/models/prayer.dart';

/// Describes the next scheduled prayer-time event relative to a local date.
///
/// [time] is always expressed as a UTC [DateTime]. [isNextDay] is based on
/// the target location's calendar date, not the UTC date of [time].
class NextPrayerDetails {
  const NextPrayerDetails({
    required this.prayer,
    required this.time,
    required this.isNextDay,
  });

  final Prayer prayer;
  final DateTime time;
  final bool isNextDay;
}
