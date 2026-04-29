import 'package:islamic_utility/islamic_utility.dart';

Future<void> main() async {
  final calendar = UnifiedCalendar.withOfficialHijri(
    adjustmentClient: HttpHijriAdjustmentClient(
      baseUrl: 'http://localhost:3000/api',
      apiKey: 'replace-with-your-api-key',
    ),
  );

  final results = await calendar.resolveRange(
    from: DateTime.utc(2026, 3, 15),
    to: DateTime.utc(2026, 3, 20),
    options: const CalendarResolveOptions(
      includeHijri: true,
      includeJavanese: true,
      hijriMethod: HijriMethod.kemenagRiOfficial,
    ),
  );

  for (final item in results) {
    final g = item.gregorian.toIso8601String().split('T').first;
    final h = item.hijri == null
        ? '-'
        : '${item.hijri!.year}-${item.hijri!.month}-${item.hijri!.day}'
              ' [${item.hijri!.meta.source}]';
    final j = item.javanese == null
        ? '-'
        : '${item.javanese!.pasaran.label} (${item.javanese!.weton})';
    print('$g -> Hijri: $h | Pasaran: $j');
  }
}
