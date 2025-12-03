class Address {
  final String id;
  final String city;
  final String street;
  final String ward;

  Address({
    required this.id,
    required this.city,
    required this.street,
    required this.ward,
  });

  factory Address.fromMap(Map<String, dynamic> data, String id) {
    return Address(
      id: id,
      city: data['city'] ?? '',
      street: data['street'] ?? '',
      ward: data['ward'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'street': street,
      'ward': ward,
    };
  }
}
