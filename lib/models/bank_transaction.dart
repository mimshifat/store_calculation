class BankTransaction {
  int? id;
  int accountId;
  String type; // "deposit", "cash_out", "payment", "receive"
  double amount;
  String description;
  DateTime date;

  BankTransaction({
    this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'accountId': accountId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory BankTransaction.fromMap(Map<String, dynamic> map) {
    return BankTransaction(
      id: map['id'],
      accountId: map['accountId'],
      type: map['type'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
    );
  }
}
