import 'dart:io';

import 'package:hive/hive.dart';
import 'package:islamic_utility/islamic_utility.dart';

Future<void> main() async {
  // In Flutter app, initialize Hive in app layer (e.g. Hive.initFlutter()).
  final hiveDir = Directory('.hive_cache');
  if (!hiveDir.existsSync()) {
    hiveDir.createSync(recursive: true);
  }
  Hive.init(hiveDir.path);

  final adjustmentBox = await Hive.openBox<dynamic>(
    'islamic_utility_adjustment_cache',
  );
  final anchorBox = await Hive.openBox<dynamic>('islamic_utility_anchor_cache');

  final client = HttpHijriAdjustmentClient(
    baseUrl: 'http://localhost:3000/api',
    apiKey: 'replace-with-your-api-key',
  );

  final calendar = HijriCalendar.withOfficial(
    adjustmentClient: client,
    cache: HiveHijriAdjustmentCache(adjustmentBox),
    anchorCache: HiveHijriAnchorCache(anchorBox),
  );

  final results = await calendar.fromGregorianOfficialRange(
    from: DateTime.utc(2026, 3, 15),
    to: DateTime.utc(2026, 3, 20),
  );

  var day = DateTime.utc(2026, 3, 15);
  for (final item in results) {
    print(
      '${day.toIso8601String().split('T').first} -> ${item.year}-${item.month}-${item.day}'
      ' (source=${item.meta.source}, adjusted=${item.meta.isAdjusted},'
      ' rev=${item.meta.revision})',
    );
    day = day.add(const Duration(days: 1));
  }
}
