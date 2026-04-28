import 'package:islamic_utility/src/models/calculation_parameters.dart';
import 'package:islamic_utility/src/models/prayer.dart';

enum CalculationMethod {
  muslimWorldLeague,
  egyptian,
  indonesian,
  karachi,
  ummAlQura,
  qatar,
  dubai,
  kuwait,
  moonsightingCommittee,
  singapore,
  turkiye,
  tehran,
  northAmerica,
  morocco,
  other;

  CalculationParameters get parameters {
    switch (this) {
      case CalculationMethod.muslimWorldLeague:
        return CalculationParameters(this, 18, 17)
          ..methodAdjustments[Prayer.dhuhr] = 1;
      case CalculationMethod.egyptian:
        return CalculationParameters(this, 19.5, 17.5)
          ..methodAdjustments[Prayer.dhuhr] = 1;
      case CalculationMethod.indonesian:
        return CalculationParameters(this, 20, 18)
          ..methodAdjustments[Prayer.dhuhr] = 1;
      case CalculationMethod.karachi:
        return CalculationParameters(this, 18, 18)
          ..methodAdjustments[Prayer.dhuhr] = 1;
      case CalculationMethod.ummAlQura:
        return CalculationParameters(this, 18.5, 0, ishaInterval: 90);
      case CalculationMethod.qatar:
        return CalculationParameters(this, 18, 0, ishaInterval: 90);
      case CalculationMethod.dubai:
        return CalculationParameters(this, 18.2, 18.2)
          ..methodAdjustments[Prayer.sunrise] = -3
          ..methodAdjustments[Prayer.dhuhr] = 3
          ..methodAdjustments[Prayer.asr] = 3
          ..methodAdjustments[Prayer.maghrib] = 3;
      case CalculationMethod.kuwait:
        return CalculationParameters(this, 18, 17.5);
      case CalculationMethod.moonsightingCommittee:
        return CalculationParameters(this, 18, 18)
          ..methodAdjustments[Prayer.dhuhr] = 5
          ..methodAdjustments[Prayer.maghrib] = 3;
      case CalculationMethod.singapore:
        return CalculationParameters(this, 20, 18)
          ..methodAdjustments[Prayer.dhuhr] = 1;
      case CalculationMethod.turkiye:
        return CalculationParameters(this, 18, 17)
          ..methodAdjustments[Prayer.sunrise] = -7
          ..methodAdjustments[Prayer.dhuhr] = 5
          ..methodAdjustments[Prayer.asr] = 4
          ..methodAdjustments[Prayer.maghrib] = 7;
      case CalculationMethod.tehran:
        return CalculationParameters(this, 17.7, 14, maghribAngle: 4.5);
      case CalculationMethod.northAmerica:
        return CalculationParameters(this, 15, 15)
          ..methodAdjustments[Prayer.dhuhr] = 1;
      case CalculationMethod.morocco:
        return CalculationParameters(this, 19, 17)
          ..methodAdjustments[Prayer.sunrise] = -3
          ..methodAdjustments[Prayer.dhuhr] = 5
          ..methodAdjustments[Prayer.maghrib] = 5;
      case CalculationMethod.other:
        return CalculationParameters(this, 0, 0);
    }
  }
}
