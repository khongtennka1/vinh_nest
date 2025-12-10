import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String hostelId;
  final String ownerId;
  final String title;
  final String roomType;
  final int floor;
  final String address;
  final String roomNumber;
  final String description;
  final String genderRequirement;
  final double price;
  final String pricingType;
  final bool includesUtilities;
  final double area;
  final double? deposit;
  final double? promotionalMoney;
  final DateTime? promotionStartDate;
  final DateTime? promotionEndDate;
  final int? numberOfParking;
  final int capacity;
  final int currentResidents;
  final List<String> amenities;
  final List<String> furniture;
  final List<String> images;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Room({
    required this.id,
    required this.hostelId,
    required this.ownerId,
    required this.title,
    required this.address,
    required this.roomNumber,
    required this.description,
    required this.genderRequirement,
    required this.price,
    required this.pricingType,
    required this.includesUtilities,
    required this.roomType,
    required this.floor,
    required this.area,
    required this.capacity,
    required this.currentResidents,
    this.amenities = const [],
    this.furniture = const [],
    this.images = const [],
    this.status = 'available',
    this.deposit,
    this.promotionalMoney,
    this.promotionStartDate,
    this.promotionEndDate,
    this.numberOfParking,
    required this.createdAt,
    this.updatedAt,
  });

  Room copyWith({
    String? id,
    String? hostelId,
    String? ownerId,
    String? title,
    String? roomType,
    int? floor,
    String? address,
    String? roomNumber,
    String? description,
    String? genderRequirement,
    double? price,
    String? pricingType,
    bool? includesUtilities,
    double? area,
    int? capacity,
    int? currentResidents,
    List<String>? amenities,
    List<String>? furniture,
    List<String>? images,
    String? status,
    int? numberOfParking,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      hostelId: hostelId ?? this.hostelId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      address: address ?? this.address,
      roomNumber: roomNumber ?? this.roomNumber,
      price: price ?? this.price,
      roomType: roomType ?? this.roomType,
      floor: floor ?? this.floor,
      area: area ?? this.area,
      capacity: capacity ?? this.capacity,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      genderRequirement: genderRequirement ?? this.genderRequirement,
      pricingType: pricingType ?? this.pricingType,
      includesUtilities: includesUtilities ?? this.includesUtilities,
      currentResidents: currentResidents ?? this.currentResidents,
      amenities: amenities ?? this.amenities,
      furniture: furniture ?? this.furniture,
      numberOfParking: numberOfParking ?? this.numberOfParking,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  factory Room.fromMap(Map<String, dynamic> data, String id) {
    DateTime _parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is String) return DateTime.parse(timestamp);
      return DateTime.now();
    }

    return Room(
      id: id,
      hostelId: data['hostelId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      address: data['address'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      description: data['description'] ?? '',
      genderRequirement: data['genderRequirement'] ?? 'Không yêu cầu',
      price: (data['price'] ?? 0).toDouble(),
      pricingType: data['pricingType'] ?? 'per_room',
      includesUtilities: data['includesUtilities'] ?? false,
      roomType: data['roomType'] ?? 'Trọ thường',
      floor: data['floor'] ?? 1,
      area: (data['area'] ?? 20).toDouble(),
      capacity: data['capacity'] ?? 2,
      currentResidents: data['currentResidents'] ?? 0,
      amenities: _toStringList(data['amenities']),
      furniture: _toStringList(data['furniture']),
      images: _toStringList(data['images']),
      numberOfParking: data['numberOfParking'] ?? 0,
      status: data['status'] ?? 'available',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostelId': hostelId,
      'ownerId': ownerId,
      'title': title,
      'address': address,
      'description': description,
      'genderRequirement': genderRequirement,
      'price': price,
      'pricingType': pricingType,
      'includesUtilities': includesUtilities,
      'roomType': roomType,
      'floor': floor,
      'area': area,
      'capacity': capacity,
      'currentResidents': currentResidents,
      'amenities': amenities,
      'furniture': furniture,
      'images': images,
      'numberOfParking': numberOfParking,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}