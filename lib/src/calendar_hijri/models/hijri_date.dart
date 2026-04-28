import 'package:islamic_utility/src/calendar_hijri/models/hijri_result_meta.dart';

class HijriDate {
  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
    required this.meta,
  });

  final int year;
  final int month;
  final int day;
  final HijriResultMeta meta;
}
