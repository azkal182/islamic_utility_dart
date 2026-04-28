import 'package:islamic_utility/src/calendar_hijri/models/hijri_date.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_result_meta.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/hijri_provider.dart';

class LocalHijriProvider implements HijriProvider {
  @override
  bool supports(HijriMethod method) => method == HijriMethod.calculatedLocal;

  @override
  HijriDate fromGregorian(DateTime date, {required HijriMethod method}) {
    if (!supports(method)) {
      throw ArgumentError('Unsupported method for LocalHijriProvider: $method');
    }

    final utc = DateTime.utc(date.year, date.month, date.day);
    final jdn = _gregorianToJdn(utc.year, utc.month, utc.day);
    final hijri = _jdnToIslamicCivil(jdn);

    return HijriDate(
      year: hijri.$1,
      month: hijri.$2,
      day: hijri.$3,
      meta: const HijriResultMeta(source: 'local_calculated_civil'),
    );
  }

  int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + (12 * a) - 3;
    return day +
        ((153 * m + 2) ~/ 5) +
        (365 * y) +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
  }

  (int, int, int) _jdnToIslamicCivil(int jdn) {
    var l = jdn - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - (10631 * n) + 354;
    final j = (((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719)) +
        ((l ~/ 5670) * ((43 * l) ~/ 15238));
    l = l - (((30 - j) ~/ 15) * ((17719 * j) ~/ 50)) - ((j ~/ 16) * ((15238 * j) ~/ 43)) + 29;
    final month = (24 * l) ~/ 709;
    final day = l - ((709 * month) ~/ 24);
    final year = 30 * n + j - 30;
    return (year, month, day);
  }
}
