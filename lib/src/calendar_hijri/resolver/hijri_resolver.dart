import 'package:islamic_utility/src/calendar_hijri/models/hijri_date.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/hijri_provider.dart';

class HijriResolver {
  const HijriResolver(this.providers);

  final List<HijriProvider> providers;

  HijriDate fromGregorian(DateTime date, {required HijriMethod method}) {
    for (final provider in providers) {
      if (provider.supports(method)) {
        return provider.fromGregorian(date, method: method);
      }
    }
    throw StateError('No provider available for method: $method');
  }
}
