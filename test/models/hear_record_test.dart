import 'package:flutter_test/flutter_test.dart';
import 'package:hearassist/models/hear_record.dart';

void main() {
  group('HearRecord', () {
    test('round trips record JSON with UTC timestamp', () {
      final record = HearRecord(
        id: 'record-1',
        kind: 'alert',
        text: 'Sample alert',
        category: 'Alarm',
        timestamp: DateTime.utc(2026, 10, 12, 10, 30),
      );

      final decoded = HearRecord.fromJson(record.toJson());

      expect(decoded.id, 'record-1');
      expect(decoded.kind, 'alert');
      expect(decoded.category, 'Alarm');
      expect(decoded.text, 'Sample alert');
      expect(decoded.timestamp.toUtc(), DateTime.utc(2026, 10, 12, 10, 30));
    });
  });
}
