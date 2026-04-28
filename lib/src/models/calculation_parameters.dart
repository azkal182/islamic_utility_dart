import 'package:islamic_utility/src/models/calculation_method.dart';
import 'package:islamic_utility/src/models/high_latitude_rule.dart';
import 'package:islamic_utility/src/models/madhab.dart';
import 'package:islamic_utility/src/models/prayer.dart';
import 'package:islamic_utility/src/models/shafaq.dart';

class CalculationParameters {
  CalculationParameters(
    this.method,
    this.fajrAngle,
    this.ishaAngle, {
    this.dhuhaOffsetMinutes = 20,
    this.ishaInterval,
    this.maghribAngle,
    this.madhab,
    this.shafaq,
    this.highLatitudeRule,
    Map<Prayer, int>? adjustments,
    Map<Prayer, int>? methodAdjustments,
  })  : adjustments = adjustments ?? _emptyAdjustments(),
        methodAdjustments = methodAdjustments ?? _emptyAdjustments();

  final CalculationMethod method;
  final double fajrAngle;
  final double ishaAngle;
  final int dhuhaOffsetMinutes;
  final int? ishaInterval;
  final double? maghribAngle;
  final Madhab? madhab;
  final Shafaq? shafaq;
  final HighLatitudeRule? highLatitudeRule;
  final Map<Prayer, int> adjustments;
  final Map<Prayer, int> methodAdjustments;

  CalculationParameters copyWith({
    CalculationMethod? method,
    double? fajrAngle,
    double? ishaAngle,
    int? ishaInterval,
    int? dhuhaOffsetMinutes,
    double? maghribAngle,
    Madhab? madhab,
    Shafaq? shafaq,
    HighLatitudeRule? highLatitudeRule,
    Map<Prayer, int>? adjustments,
    Map<Prayer, int>? methodAdjustments,
  }) {
    return CalculationParameters(
      method ?? this.method,
      fajrAngle ?? this.fajrAngle,
      ishaAngle ?? this.ishaAngle,
      dhuhaOffsetMinutes: dhuhaOffsetMinutes ?? this.dhuhaOffsetMinutes,
      ishaInterval: ishaInterval ?? this.ishaInterval,
      maghribAngle: maghribAngle ?? this.maghribAngle,
      madhab: madhab ?? this.madhab,
      shafaq: shafaq ?? this.shafaq,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      adjustments: adjustments ?? Map<Prayer, int>.from(this.adjustments),
      methodAdjustments:
          methodAdjustments ?? Map<Prayer, int>.from(this.methodAdjustments),
    );
  }

  Map<Prayer, double> nightPortions() {
    final rule = highLatitudeRule ?? HighLatitudeRule.middleOfTheNight;
    switch (rule) {
      case HighLatitudeRule.middleOfTheNight:
        return {Prayer.fajr: 0.5, Prayer.isha: 0.5};
      case HighLatitudeRule.seventhOfTheNight:
        return {Prayer.fajr: 1 / 7, Prayer.isha: 1 / 7};
      case HighLatitudeRule.twilightAngle:
        return {
          Prayer.fajr: fajrAngle / 60,
          Prayer.isha: ishaAngle / 60,
        };
    }
  }

  static Map<Prayer, int> _emptyAdjustments() {
    return {
      Prayer.imsak: 0,
      Prayer.fajr: 0,
      Prayer.dhuha: 0,
      Prayer.sunrise: 0,
      Prayer.dhuhr: 0,
      Prayer.asr: 0,
      Prayer.maghrib: 0,
      Prayer.isha: 0,
      Prayer.ishaBefore: 0,
      Prayer.fajrAfter: 0,
    };
  }
}
