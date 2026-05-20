class AppTransaction {
  int? id;
  int customerId;
  String type; // 'sale' or 'payment'
  double amount;
  String description;
  DateTime date;
  String paymentMethod;

  AppTransaction({
    this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.paymentMethod = 'Cash',
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'customerId': customerId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory AppTransaction.fromMap(Map<String, dynamic> map) {
    return AppTransaction(
      id: map['id'],
      customerId: map['customerId'],
      type: map['type'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
    );
  }
}
