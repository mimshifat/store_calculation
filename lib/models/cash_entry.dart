class CashEntry {
  int? id;
  String type; // 'expense'
  String category;
  double amount;
  String description;
  DateTime date;
  String paymentMethod;

  CashEntry({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.paymentMethod = 'Cash',
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory CashEntry.fromMap(Map<String, dynamic> map) {
    return CashEntry(
      id: map['id'],
      type: map['type'],
      category: map['category'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
    );
  }
}
