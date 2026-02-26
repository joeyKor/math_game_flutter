class FxTransaction {
  final String type; // 'BUY' or 'SELL'
  final double amount;
  final int pricePerUnit;
  final int totalPoints;
  final DateTime date;

  FxTransaction({
    required this.type,
    required this.amount,
    required this.pricePerUnit,
    required this.totalPoints,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'amount': amount,
    'pricePerUnit': pricePerUnit,
    'totalPoints': totalPoints,
    'date': date.toIso8601String(),
  };

  factory FxTransaction.fromJson(Map<String, dynamic> json) => FxTransaction(
    type: json['type'],
    amount: (json['amount'] as num).toDouble(),
    pricePerUnit: json['pricePerUnit'],
    totalPoints: json['totalPoints'],
    date: DateTime.parse(json['date']),
  );
}
