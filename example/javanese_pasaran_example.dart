import 'package:islamic_utility/islamic_utility.dart';

void main() {
  final calendar = const JavaneseCalendar();
  final from = DateTime.utc(2026, 3, 15);
  final to = DateTime.utc(2026, 3, 20);
  final results = calendar.fromGregorianRange(from: from, to: to);

  var day = from;
  for (final item in results) {
    print(
      '${day.toIso8601String().split('T').first} -> ${item.pasaran.label} (${item.weton})',
    );
    day = day.add(const Duration(days: 1));
  }
}
