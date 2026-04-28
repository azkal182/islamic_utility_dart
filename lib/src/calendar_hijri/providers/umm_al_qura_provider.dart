import 'package:islamic_utility/src/calendar_hijri/data/umm_al_qura_data.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_date.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_result_meta.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/hijri_provider.dart';

class UmmAlQuraProvider implements HijriProvider {
  static const int _hijriMonthOffset = 16260;

  @override
  bool supports(HijriMethod method) => method == HijriMethod.ummAlQura;

  @override
  HijriDate fromGregorian(DateTime date, {required HijriMethod method}) {
    if (!supports(method)) {
      throw ArgumentError('Unsupported method for UmmAlQuraProvider: $method');
    }

    if (ummAlquraDateArray.isEmpty) {
      throw StateError('Umm al-Qura dataset is empty');
    }

    final mcjdn = _gregorianToMcjdn(date.toUtc());
    final first = ummAlquraDateArray.first;
    final last = ummAlquraDateArray.last;

    if (mcjdn < first || mcjdn >= last) {
      throw RangeError(
        'Date ${date.toIso8601String()} is outside Umm al-Qura supported range',
      );
    }

    final monthIndex = _findMonthIndex(mcjdn);
    final iln = monthIndex + _hijriMonthOffset;
    final year = ((iln - 1) ~/ 12) + 1;
    final month = iln - 12 * ((iln - 1) ~/ 12);
    final day = mcjdn - ummAlquraDateArray[monthIndex - 1] + 1;

    return HijriDate(
      year: year,
      month: month,
      day: day,
      meta: const HijriResultMeta(source: 'ummalqura_local'),
    );
  }

  int _findMonthIndex(int mcjdn) {
    var low = 0;
    var high = ummAlquraDateArray.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (ummAlquraDateArray[mid] <= mcjdn) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  int _gregorianToMcjdn(DateTime date) {
    var y = date.year;
    var m = date.month;
    final d = date.day;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + (a ~/ 4);
    final cjdn =
        (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + d + b - 1524;
    return cjdn - 2400000;
  }
}
