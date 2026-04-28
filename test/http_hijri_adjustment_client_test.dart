import 'dart:convert';
import 'dart:io';

import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  group('HttpHijriAdjustmentClient', () {
    test('fetchLatest parses records', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        expect(request.uri.path, '/v1/hijri/adjustments/latest');
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'records': [
            {
              'effective_from': '2024-03-01',
              'effective_to': '2024-03-31',
              'adjustment_days': 1,
              'revision': 1,
              'published_at': '2024-03-10T00:00:00Z',
              'authority': 'kemenag_ri',
              'region_scope': 'national',
            }
          ],
        }));
        await request.response.close();
      });

      final client = HttpHijriAdjustmentClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'x',
      );

      final result = await client.fetchLatest();
      expect(result.statusCode, 200);
      expect(result.records.length, 1);
      expect(result.records.first.adjustmentDays, 1);
    });

    test('retries on 5xx and eventually succeeds', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      var calls = 0;

      server.listen((request) async {
        calls += 1;
        if (calls < 2) {
          request.response.statusCode = 500;
          await request.response.close();
          return;
        }
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'records': []}));
        await request.response.close();
      });

      final client = HttpHijriAdjustmentClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'x',
        retryPolicy: const RetryPolicy(
          maxRetries: 2,
          initialDelay: Duration(milliseconds: 1),
          maxDelay: Duration(milliseconds: 5),
          jitter: Duration.zero,
          timeoutPerAttempt: Duration(seconds: 2),
        ),
      );

      final result = await client.fetchLatest();
      expect(result.statusCode, 200);
      expect(calls, greaterThanOrEqualTo(2));
    });

    test('uses Retry-After on 429 and calls retry logger', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      var calls = 0;
      int? loggedStatus;
      Duration? loggedDelay;

      server.listen((request) async {
        calls += 1;
        if (calls == 1) {
          request.response.statusCode = 429;
          request.response.headers.set('retry-after', '1');
          await request.response.close();
          return;
        }
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'records': []}));
        await request.response.close();
      });

      final client = HttpHijriAdjustmentClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'x',
        retryPolicy: const RetryPolicy(
          maxRetries: 2,
          initialDelay: Duration(milliseconds: 1),
          maxDelay: Duration(milliseconds: 5),
          jitter: Duration.zero,
          timeoutPerAttempt: Duration(seconds: 2),
          maxRetryAfter: Duration(seconds: 1),
        ),
        onRetryAttempt: (attempt, uri, statusCode, nextDelay, error) {
          loggedStatus = statusCode;
          loggedDelay = nextDelay;
        },
      );

      final result = await client.fetchLatest();
      expect(result.statusCode, 200);
      expect(calls, 2);
      expect(loggedStatus, 429);
      expect(loggedDelay, const Duration(seconds: 1));
    });
  });
}
