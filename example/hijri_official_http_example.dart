import 'package:islamic_utility/islamic_utility.dart';

Future<void> main() async {
  final client = HttpHijriAdjustmentClient(
    baseUrl: 'https://api.example.com',
    apiKey: 'YOUR_API_KEY',
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

  final latest = await client.fetchLatest();
  print('Latest status: ${latest.statusCode}, records: ${latest.records.length}');

  final calendar = HijriCalendar.withOfficial(adjustmentClient: client);
  final result = await calendar.fromGregorianOfficial(DateTime.now().toUtc());

  print('Hijri: ${result.year}-${result.month}-${result.day}');
  print('Source: ${result.meta.source}');
  print('Adjusted: ${result.meta.isAdjusted}');
}
