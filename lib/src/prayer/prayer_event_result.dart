import 'package:islamic_utility/src/models/prayer.dart';
import 'package:islamic_utility/src/prayer/prayer_times.dart';

/// How a prayer event time was obtained by [PrayerTimes].
enum PrayerEventSource {
  /// A real solar-angle crossing or solar transit was calculated.
  astronomical,

  /// The event follows a method-defined interval from sunset.
  calculationInterval,

  /// The configured high-latitude rule supplied the event instead of an
  /// unreachable twilight crossing.
  highLatitudeFallback,

  /// The event's required solar crossing does not occur for this date.
  unavailable,
}

/// Availability and provenance for one event in a [PrayerTimes] schedule.
///
/// [time] is null when the required geometric event is unavailable. Existing
/// non-null `PrayerTimes` fields remain for API compatibility; callers that
/// need to distinguish a real event from a legacy placeholder should use
/// [PrayerTimes.eventForPrayer].
class PrayerEventResult {
  const PrayerEventResult({
    required this.prayer,
    required this.time,
    required this.source,
  });

  final Prayer prayer;
  final DateTime? time;
  final PrayerEventSource source;

  bool get isAvailable => time != null;
  bool get isAstronomical => source == PrayerEventSource.astronomical;
}
