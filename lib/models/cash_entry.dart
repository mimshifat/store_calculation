class CashEntry {
  int? id;
  String type; // 'expense'
  String category;
  double amount;
  String description;
  DateTime date;
  String paymentMethod;
  String? shopName;
  String? ownerName;
  String? receiptNumber;
  String? paidVia;

  CashEntry({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.paymentMethod = 'Cash',
    this.shopName,
    this.ownerName,
    this.receiptNumber,
    this.paidVia,
  });

  bool get isRentEntry => category == 'দোকান ভাড়া';

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
    if (shopName != null) map['shopName'] = shopName;
    if (ownerName != null) map['ownerName'] = ownerName;
    if (receiptNumber != null) map['receiptNumber'] = receiptNumber;
    if (paidVia != null) map['paidVia'] = paidVia;
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
      shopName: map['shopName'],
      ownerName: map['ownerName'],
      receiptNumber: map['receiptNumber'],
      paidVia: map['paidVia'],
    );
  }
}
