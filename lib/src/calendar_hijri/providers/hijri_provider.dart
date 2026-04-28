import 'package:islamic_utility/src/calendar_hijri/models/hijri_date.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';

abstract class HijriProvider {
  bool supports(HijriMethod method);

  HijriDate fromGregorian(DateTime date, {required HijriMethod method});
}
