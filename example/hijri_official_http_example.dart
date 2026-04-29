import 'package:islamic_utility/islamic_utility.dart';

Future<void> main() async {
  final targetDate = DateTime.utc(2026, 3, 20);

  final client = HttpHijriAdjustmentClient(
    baseUrl: 'http://localhost:3000/api',
    apiKey: 'iuk_cf3ac869684fc686411962e39eca106f82b1934c3018bc4e',
    retryPolicy: const RetryPolicy(
      maxRetries: 2,
      initialDelay: Duration(milliseconds: 300),
    ),
    onRetryAttempt: (attempt, uri, statusCode, nextDelay, error) {
      print(
        'Retry #$attempt -> $uri (status=$statusCode, error=$error), next in ${nextDelay.inMilliseconds}ms',
      );
    },
  );

  print('[DEBUG] Looking up Gregorian date: ${targetDate.toIso8601String()}');
  print('[DEBUG] Fetching latest anchors...');
  final latest = await client.fetchLatestAnchors();
  print(
    '[DEBUG] Latest status: ${latest.statusCode}, records: ${latest.records.length}, etag: ${latest.etag}',
  );
  if (latest.records.isNotEmpty) {
    final r = latest.records.first;
    print(
      '[DEBUG] Latest[0] official=${r.officialGregorianDate.toIso8601String()}, hijri=${r.hijriYear}-${r.hijriMonth}-${r.hijriDay}, revision=${r.revision}, published_at=${r.publishedAt.toIso8601String()}, authority=${r.authority}, region_scope=${r.regionScope}',
    );
  }

  final calendar = HijriCalendar.withOfficial(adjustmentClient: client);
  final localCalendar = HijriCalendar();

  print('[DEBUG] Resolving local base (calculatedLocal)...');
  final local = localCalendar.fromGregorian(
    targetDate,
    method: HijriMethod.calculatedLocal,
  );
  print(
    '[DEBUG] Local base Hijri: ${local.year}-${local.month}-${local.day} (source=${local.meta.source})',
  );

  print('[DEBUG] Resolving official Hijri (anchor/delta fallback)...');
  final result = await calendar.fromGregorianOfficial(targetDate);

  print('[DEBUG] Resolved Hijri: ${result.year}-${result.month}-${result.day}');
  print('[DEBUG] Source: ${result.meta.source}');
  print('[DEBUG] Adjusted: ${result.meta.isAdjusted}');
  print('[DEBUG] AdjustmentDays: ${result.meta.adjustmentDays}');
  print('[DEBUG] Authority: ${result.meta.authority}');
  print('[DEBUG] Revision: ${result.meta.revision}');
}
