import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';

class CalendarResolveOptions {
  const CalendarResolveOptions({
    this.includeHijri = false,
    this.includeJavanese = false,
    this.hijriMethod = HijriMethod.calculatedLocal,
  });

  final bool includeHijri;
  final bool includeJavanese;
  final HijriMethod hijriMethod;
}
