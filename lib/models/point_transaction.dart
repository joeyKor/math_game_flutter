import 'dart:convert';

class PointTransaction {
  final DateTime date;
  final String gameName;
  final int points;

  PointTransaction({
    required this.date,
    required this.gameName,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'gameName': gameName,
    'points': points,
  };

  factory PointTransaction.fromJson(Map<String, dynamic> json) =>
      PointTransaction(
        date: DateTime.parse(json['date']),
        gameName: json['gameName'],
        points: json['points'],
      );

  static String encode(List<PointTransaction> transactions) => json.encode(
    transactions.map<Map<String, dynamic>>((t) => t.toJson()).toList(),
  );

  static List<PointTransaction> decode(String transactions) =>
      (json.decode(transactions) as List<dynamic>)
          .map<PointTransaction>((item) => PointTransaction.fromJson(item))
          .toList();
}
