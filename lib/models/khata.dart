class Khata {
  int? id;
  String name;

  Khata({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Khata.fromMap(Map<String, dynamic> map) {
    return Khata(
      id: map['id'],
      name: map['name'],
    );
  }
}
