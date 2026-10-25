class HearRecord {
  const HearRecord({
    required this.id,
    required this.kind,
    required this.text,
    required this.timestamp,
    this.category = '',
  });

  final String id;
  final String kind;
  final String text;
  final DateTime timestamp;
  final String category;

  factory HearRecord.fromJson(Map<String, dynamic> json) => HearRecord(
        id: json['id'] as String,
        kind: json['kind'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        category: json['category'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'text': text,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'category': category,
      };
}
