import 'dart:convert';

class ReadingRecord {
  final String title;
  final DateTime date;

  ReadingRecord({required this.title, required this.date});

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': date.toIso8601String(),
  };

  factory ReadingRecord.fromJson(Map<String, dynamic> json) =>
      ReadingRecord(title: json['title'], date: DateTime.parse(json['date']));

  static String encode(List<ReadingRecord> records) => json.encode(
    records.map<Map<String, dynamic>>((r) => r.toJson()).toList(),
  );

  static List<ReadingRecord> decode(String jsonStr) =>
      (json.decode(jsonStr) as List<dynamic>)
          .map<ReadingRecord>((item) => ReadingRecord.fromJson(item))
          .toList();
}
