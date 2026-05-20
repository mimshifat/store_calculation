class SupplierTransaction {
  int? id;
  int supplierId;
  String type; // 'purchase' (মাল কেনা) or 'payment' (টাকা দেওয়া)
  double amount;
  String description;
  DateTime date;
  String paymentMethod;

  SupplierTransaction({
    this.id,
    required this.supplierId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.paymentMethod = 'Cash',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
    };
  }

  factory SupplierTransaction.fromMap(Map<String, dynamic> map) {
    return SupplierTransaction(
      id: map['id'],
      supplierId: map['supplierId'],
      type: map['type'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
    );
  }
}
