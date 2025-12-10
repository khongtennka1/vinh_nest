import 'package:cloud_firestore/cloud_firestore.dart';

class Hostel {
  final String id;
  final String ownerId;
  final String name;
  final String addressId;
  final String? description;
  final List<String> facilities;
  final List<String> interiors;
  final List<String> images;
  final int numberParkingSpaces;
  final List<String> roomTypes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status;
  final List<Map<String, dynamic>> customServices;

  Hostel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.addressId = '',
    required this.numberParkingSpaces,
    required this.createdAt,
    required this.roomTypes,
    this.description,
    this.facilities = const [],
    this.interiors = const[],
    this.images = const [],
    this.updatedAt,
    this.status = 'active',
    this.customServices = const [],
  });

  static List<String> _toList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  factory Hostel.fromMap(Map<String, dynamic> data, String id) {
    final rawServices = data['customServices'] as List<dynamic>?;

    List<Map<String, dynamic>> parseCustomServices() {
      if (rawServices == null || rawServices.isEmpty) return [];
      return rawServices.map((item) {
        if (item is Map) {
          return {
            'name': item['name']?.toString() ?? 'Dịch vụ',
            'price': (item['price'] as num?)?.toDouble() ?? 0.0,
          };
        }
        if (item is String && item.contains(':')) {
          final parts = item.split(':');
          final name = parts[0].trim();
          final price = double.tryParse(parts[1].trim()) ?? 0.0;
          return {'name': name, 'price': price};
        }
        return {'name': item.toString(), 'price': 0.0};
      }).toList();
    }

    DateTime parseTime(dynamic t) {
      if (t is Timestamp) return t.toDate();
      if (t is String) return DateTime.parse(t);
      return DateTime.now();
    }

    return Hostel(
      id: id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      addressId: data['addressId'] ?? '',
      description: data['description'],
      numberParkingSpaces: data['number_parking_spaces'] ?? 0,
      facilities: _toList(data['facilities']),
      interiors: _toList(data['interiors']),
      roomTypes: _toList(data['roomTypes']),
      images: _toList(data['images']),
      createdAt: parseTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? parseTime(data['updatedAt']) : null,
      status: data['status'] ?? 'active',
      customServices: parseCustomServices(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'addressId': addressId,
      'description': description,
      'facilities': facilities,
      'interiors': interiors,
      'roomTypes': roomTypes,
      'number_parking_spaces': numberParkingSpaces,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status,
      'customServices': customServices,
    };
  }
}
