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
  final List<String> services;
  final List<String> roomTypes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status;

  Hostel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.addressId,
    required this.services,
    required this.numberParkingSpaces,
    required this.createdAt,
    required this.roomTypes,
    this.description,
    this.facilities = const [],
    this.interiors = const[],
    this.images = const [],
    this.updatedAt,
    this.status = 'active',
  });

  static List<String> _toList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  factory Hostel.fromMap(Map<String, dynamic> data, String id) {
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
      services: _toList(data['services']),
      numberParkingSpaces: data['number_parking_spaces'] ?? 0,
      facilities: _toList(data['facilities']),
      interiors: _toList(data['interiors']),
      roomTypes: _toList(data['roomTypes']),
      images: _toList(data['images']),
      createdAt: parseTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? parseTime(data['updatedAt']) : null,
      status: data['status'] ?? 'active',
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
      'services': services,
      'roomTypes': roomTypes,
      'number_parking_spaces': numberParkingSpaces,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status,
    };
  }
}
