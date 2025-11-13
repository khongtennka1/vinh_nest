import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String hostelId;
  final String roomNumber;
  final int floor;
  final double area;
  final int capacity;
  final double price;
  final String status;
  final String? description;
  final List<String>? images;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Room({
    required this.id,
    required this.hostelId,
    required this.roomNumber,
    required this.floor,
    required this.area,
    required this.capacity,
    required this.price,
    required this.status,
    this.description,
    this.images,
    required this.createdAt,
    this.updatedAt,
  });

  factory Room.fromMap(Map<String, dynamic> data, String id) {
    DateTime _parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
      return DateTime.now(); 
    }

    return Room(
      id: id,
      hostelId: data['hostelId'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      floor: (data['floor'] ?? 0) as int,
      area: (data['area'] ?? 0).toDouble(),
      capacity: (data['capacity'] ?? 0) as int,
      price: (data['price'] ?? 0).toDouble(),
      status: data['status'] ?? 'available',
      description: data['description'] as String?,
      images: data['images'] != null
          ? List<String>.from(data['images'])
          : null,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? _parseTimestamp(data['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostelId': hostelId,
      'roomNumber': roomNumber,
      'floor': floor,
      'area': area,
      'capacity': capacity,
      'price': price,
      'status': status,
      'description': description,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}