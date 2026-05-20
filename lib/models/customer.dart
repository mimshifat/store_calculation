class Customer {
  int? id;
  String name;
  String pageNo;
  String khataNo;
  String suchiNo;
  String mobile;
  String address;
  double dueAmount;

  Customer({
    this.id,
    required this.name,
    required this.pageNo,
    required this.khataNo,
    required this.suchiNo,
    required this.mobile,
    this.address = '',
    this.dueAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pageNo': pageNo,
      'khataNo': khataNo,
      'suchiNo': suchiNo,
      'mobile': mobile,
      'address': address,
      'dueAmount': dueAmount,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'] ?? '',
      pageNo: map['pageNo'] ?? '',
      khataNo: map['khataNo'] ?? '',
      suchiNo: map['suchiNo'] ?? '',
      mobile: map['mobile'] ?? '',
      address: map['address'] ?? '',
      dueAmount: (map['dueAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
