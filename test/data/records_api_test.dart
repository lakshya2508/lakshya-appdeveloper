import 'package:flutter_test/flutter_test.dart';
import 'package:hearassist/data/records_api.dart';
import 'package:hearassist/models/hear_record.dart';

void main() {
  group('LocalRecordsRepository', () {
    test('returns empty list by default and returns created record', () async {
      final repo = LocalRecordsRepository();
      expect(await repo.listRecords(), isEmpty);

      final record = HearRecord(
        id: 'rec-1',
        kind: 'caption',
        text: 'Test caption',
        timestamp: DateTime.utc(2026, 10, 12),
      );
      final created = await repo.createRecord(record);
      expect(created.id, 'rec-1');
      expect(created.text, 'Test caption');
    });
  });

  group('HttpRecordsRepository contract', () {
    test('constructs with baseUri', () {
      final repo = HttpRecordsRepository(baseUri: Uri.parse('https://example.com/api'));
      expect(repo.baseUri.toString(), 'https://example.com/api');
    });
  });
}
