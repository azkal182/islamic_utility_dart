import 'package:islamic_utility/src/calendar_hijri/models/hijri_date.dart';
import 'package:islamic_utility/src/calendar_javanese/models/javanese_date.dart';

class UnifiedCalendarDate {
  const UnifiedCalendarDate({
    required this.gregorian,
    this.hijri,
    this.javanese,
  });

  final DateTime gregorian;
  final HijriDate? hijri;
  final JavaneseDate? javanese;
}
