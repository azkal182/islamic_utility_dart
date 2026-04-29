import 'package:islamic_utility/src/calendar_javanese/models/javanese_date.dart';
import 'package:islamic_utility/src/calendar_javanese/models/pasaran.dart';

class JavaneseCalendar {
  const JavaneseCalendar();

  // Reference anchor:
  // 2024-01-01 (Senin) is mapped as Pahing for the 5-day pasaran cycle.
  static final DateTime _anchorDate = DateTime.utc(2024, 1, 1);
  static const Pasaran _anchorPasaran = Pasaran.pahing;

  JavaneseDate fromGregorian(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final dayOffset = day.difference(_anchorDate).inDays;

    final index = _positiveModulo(
      _anchorPasaran.index + dayOffset,
      Pasaran.values.length,
    );
    final pasaran = Pasaran.values[index];
    final weton = '${_weekdayLabel(day.weekday)} ${pasaran.label}';

    return JavaneseDate(pasaran: pasaran, weton: weton);
  }

  List<JavaneseDate> fromGregorianRange({
    required DateTime from,
    required DateTime to,
  }) {
    final start = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(to.year, to.month, to.day);
    if (end.isBefore(start)) {
      throw ArgumentError.value(to, 'to', 'must be on or after from');
    }

    final results = <JavaneseDate>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      results.add(fromGregorian(day));
    }
    return results;
  }

  int _positiveModulo(int value, int modulo) {
    final rem = value % modulo;
    return rem < 0 ? rem + modulo : rem;
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Ahad';
      default:
        return '';
    }
  }
}
