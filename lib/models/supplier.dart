class Supplier {
  int? id;
  String name;
  String companyName;
  String mobile;
  double dueAmount; // How much we owe the supplier

  Supplier({
    this.id,
    required this.name,
    this.companyName = '',
    this.mobile = '',
    this.dueAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'companyName': companyName,
      'mobile': mobile,
      'dueAmount': dueAmount,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      companyName: map['companyName'] ?? '',
      mobile: map['mobile'] ?? '',
      dueAmount: (map['dueAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
