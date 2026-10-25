import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/hear_record.dart';

abstract interface class RecordsRepository {
  Future<List<HearRecord>> listRecords();
  Future<HearRecord> createRecord(HearRecord record);
}

class LocalRecordsRepository implements RecordsRepository {
  @override
  Future<List<HearRecord>> listRecords() async => const [];

  @override
  Future<HearRecord> createRecord(HearRecord record) async => record;
}

/// Configurable REST adapter example. No real endpoint is configured or called.
class HttpRecordsRepository implements RecordsRepository {
  HttpRecordsRepository({required this.baseUri, HttpClient? client}) : _client = client ?? HttpClient();

  final Uri baseUri;
  final HttpClient _client;
  static const _timeout = Duration(seconds: 8);

  Future<dynamic> _request(String path, {HearRecord? body}) async {
    final request = await _client.openUrl(body == null ? 'GET' : 'POST', baseUri.resolve(path)).timeout(_timeout);
    request.headers.contentType = ContentType.json;
    if (body != null) request.write(jsonEncode(body.toJson()));
    final response = await request.close().timeout(_timeout);
    final payload = await utf8.decoder.bind(response).join().timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Service returned HTTP ${response.statusCode}', uri: baseUri.resolve(path));
    }
    if (response.statusCode == HttpStatus.noContent || payload.isEmpty) return null;
    return jsonDecode(payload);
  }

  @override
  Future<List<HearRecord>> listRecords() async {
    final result = await _request('/records');
    if (result == null) return [];
    if (result is! List) throw const FormatException('Expected a JSON array of records');
    return result.map((row) => HearRecord.fromJson(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<HearRecord> createRecord(HearRecord record) async {
    final result = await _request('/records', body: record);
    if (result == null) return record;
    if (result is! Map<String, dynamic>) throw const FormatException('Expected a JSON record object');
    return HearRecord.fromJson(result);
  }
}
