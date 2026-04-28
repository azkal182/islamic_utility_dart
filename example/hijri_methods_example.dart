import 'package:islamic_utility/islamic_utility.dart';

void main() {
  final date = DateTime.utc(2026, 4, 28);
  final hijri = HijriCalendar();

  final local = hijri.fromGregorian(
    date,
    method: HijriMethod.calculatedLocal,
  );
  final umm = hijri.fromGregorian(
    date,
    method: HijriMethod.ummAlQura,
  );

  print('Gregorian: ${date.toIso8601String()}');
  print('Local civil : ${local.year}-${local.month}-${local.day}');
  print('Umm al-Qura : ${umm.year}-${umm.month}-${umm.day}');
}
