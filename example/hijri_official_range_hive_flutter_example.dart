import 'package:hive/hive.dart';
import 'package:islamic_utility/islamic_utility.dart';

Future<List<HijriDate>> convertRangeWithFlutterHive({
  required Box<dynamic> adjustmentBox,
  required Box<dynamic> anchorBox,
  required String baseUrl,
  required String apiKey,
  required DateTime from,
  required DateTime to,
}) async {
  final client = HttpHijriAdjustmentClient(
    baseUrl: baseUrl,
    apiKey: apiKey,
  );

  final calendar = HijriCalendar.withOfficial(
    adjustmentClient: client,
    cache: HiveHijriAdjustmentCache(adjustmentBox),
    anchorCache: HiveHijriAnchorCache(anchorBox),
  );

  return calendar.refreshGregorianOfficialRange(from: from, to: to);
}
