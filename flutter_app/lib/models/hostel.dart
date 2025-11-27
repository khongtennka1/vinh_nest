import 'package:cloud_firestore/cloud_firestore.dart';

class Hostel {
  final String id;
  final String ownerId;
  final String name;
  final String addressId;
  final String? description;
  final List<String> facilities;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? status;

  Hostel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.addressId,
    this.description,
    this.facilities = const [],
    this.images = const [],
    required this.createdAt,
    this.updatedAt,
    this.status,
  });

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  factory Hostel.fromMap(Map<String, dynamic> data, String id) {
    DateTime _parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is String) return DateTime.parse(timestamp);
      return DateTime.now();
    }

    return Hostel(
      id: id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      addressId: data['addressId'] ?? '',
      description: data['description'],
      facilities: _toStringList(data['facilities']),
      images: _toStringList(data['images']),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? _parseTimestamp(data['updatedAt'])
          : null,
      status: data['status'],
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'name': name,
    'addressId': addressId,
    'description': description,
    'facilities': facilities,
    'images': images,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'status': status,
  };
}
