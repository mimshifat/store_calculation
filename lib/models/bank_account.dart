class BankAccount {
  int? id;
  String name;
  String type; // "bkash", "nagad", "rocket", "upay", "bank", "cash", "other"
  String accountNumber;
  double balance;

  BankAccount({
    this.id,
    required this.name,
    required this.type,
    required this.accountNumber,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'type': type,
      'accountNumber': accountNumber,
      'balance': balance,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      accountNumber: map['accountNumber'],
      balance: (map['balance'] as num).toDouble(),
    );
  }
}
