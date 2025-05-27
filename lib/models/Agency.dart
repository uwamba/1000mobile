class Agency {
  final int id;
  final String name;
  final String address;
  final String description;

  Agency({required this.id, required this.name, required this.address, required this.description});

  factory Agency.fromJson(Map<String, dynamic> json) => Agency(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    description: json['description'],
  );
}