import 'dart:io';

import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  final apiKey = Platform.environment['IUK_API_KEY'];
  final baseUrl =
      Platform.environment['IUK_API_BASE_URL'] ??
      'https://islamic-utility.amtsilatipusat.com/api';

  test('official Hijri API smoke test for 2026-06-01..2026-07-31', () async {
    if (apiKey == null || apiKey.isEmpty) {
      markTestSkipped('Set IUK_API_KEY to run the live API smoke test.');
      return;
    }

    final client = HttpHijriAdjustmentClient(baseUrl: baseUrl, apiKey: apiKey);

    final from = DateTime.utc(2026, 6, 1);
    final to = DateTime.utc(2026, 7, 31);
    final anchors = await client.fetchAnchorsRange(from: from, to: to);
    final adjustments = await client.fetchRange(from: from, to: to);

    expect(anchors.statusCode, 200);
    expect(adjustments.statusCode, 200);
    expect(
      adjustments.records,
      isEmpty,
      reason: 'Review expected no adjustment records for this range.',
    );

    for (final anchor in anchors.records) {
      stdout.writeln(
        'ANCHOR ${anchor.officialGregorianDate.toIso8601String()} '
        '=> ${anchor.hijriYear}-${anchor.hijriMonth}-${anchor.hijriDay} '
        'revision=${anchor.revision}',
      );
      if (anchor.officialGregorianDate.isAfter(from)) {
        stdout.writeln(
          'WARNING anchor is after the range start; historical dates must '
          'not resolve from this future anchor.',
        );
      }
    }

    final calendar = HijriCalendar.withOfficial(adjustmentClient: client);
    final results = await calendar.fromGregorianOfficialRange(
      from: from,
      to: to,
    );

    expect(results.length, 61);
    expect(results.first.meta.source, contains('anchor'));
    for (var i = 0; i < results.length; i++) {
      final date = from.add(Duration(days: i));
      final result = results[i];
      stdout.writeln(
        '${date.toIso8601String().split('T').first} => '
        '${result.year}-${result.month}-${result.day} '
        'source=${result.meta.source}',
      );
    }
  });

  test(
    'official Hijri API continuity test for 2026-02-01..2026-09-07',
    () async {
      if (apiKey == null || apiKey.isEmpty) {
        markTestSkipped('Set IUK_API_KEY to run the live API smoke test.');
        return;
      }

      final client = HttpHijriAdjustmentClient(
        baseUrl: baseUrl,
        apiKey: apiKey,
      );
      final from = DateTime.utc(2026, 2, 1);
      final to = DateTime.utc(2026, 9, 7);
      final results = await HijriCalendar.withOfficial(
        adjustmentClient: client,
      ).fromGregorianOfficialRange(from: from, to: to);

      expect(results.length, 219);
      for (var i = 1; i < results.length; i++) {
        final previous = results[i - 1];
        final current = results[i];
        final sameMonth = previous.year == current.year &&
            previous.month == current.month &&
            current.day == previous.day + 1;
        final monthBoundary = previous.day >= 29 &&
            current.day == 1 &&
            (current.month == previous.month + 1 ||
                (previous.month == 12 && current.month == 1));
        expect(sameMonth || monthBoundary, isTrue,
            reason: 'Invalid transition at ${from.add(Duration(days: i - 1))}: '
                '${previous.year}-${previous.month}-${previous.day} -> '
                '${current.year}-${current.month}-${current.day}');
      }

      expect(results[17].year, 1447);
      expect(results[17].month, 8);
      expect(results[17].day, 30);
      expect(results[18].year, 1447);
      expect(results[18].month, 9);
      expect(results[18].day, 1);
      expect(results[18].meta.source, contains('anchor'));
    },
  );
}
