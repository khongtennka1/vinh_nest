import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String id;
  final String contractId;
  final String tenantName;
  final String roomId;      
  final String hostelId;    
  final String landlordId;
  final DateTime dueMonth;
  final DateTime dueDate;

  final double roomRent;
  final List<ServiceItem> services;
  final List<ExtraFee> extraFees;
  final String note;

  final DateTime createdAt;
  final String status;

  Invoice({
    required this.id,
    required this.contractId,
    required this.tenantName,
    required this.roomId,
    required this.hostelId,
    required this.landlordId,
    required this.dueMonth,
    required this.dueDate,
    required this.roomRent,
    this.services = const [],
    this.extraFees = const [],
    this.note = '',
    required this.createdAt,
    this.status = 'pending',
  });

  double get totalAmount =>
      roomRent +
      services.fold(0.0, (a, b) => a + b.price) +
      extraFees.fold(0.0, (a, b) => a + b.price);

  Invoice copyWith({
    String? id,
    String? contractId,
    String? tenantName,
    String? roomId,
    String? hostelId,
    DateTime? dueMonth,
    DateTime? dueDate,
    double? roomRent,
    List<ServiceItem>? services,
    List<ExtraFee>? extraFees,
    String? note,
    DateTime? createdAt,
    String? status,
  }) {
    return Invoice(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      tenantName: tenantName ?? this.tenantName,
      roomId: roomId ?? this.roomId,
      hostelId: hostelId ?? this.hostelId,
      landlordId: landlordId,
      dueMonth: dueMonth ?? this.dueMonth,
      dueDate: dueDate ?? this.dueDate,
      roomRent: roomRent ?? this.roomRent,
      services: services ?? this.services,
      extraFees: extraFees ?? this.extraFees,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      contractId: map['contractId'] ?? '',
      tenantName: map['tenantName'] ?? 'Khách thuê',
      roomId: map['roomId'] ?? 'N/A',
      hostelId: map['hostelId'] ?? 'N/A',
      landlordId: map['landlordId'] ?? 'N/A',
      dueMonth: (map['dueMonth'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      roomRent: (map['roomRent'] as num?)?.toDouble() ?? 0.0,
      services: (map['services'] as List<dynamic>?)
              ?.map((e) => ServiceItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      extraFees: (map['extraFees'] as List<dynamic>?)
              ?.map((e) => ExtraFee.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      note: map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() => {
        'contractId': contractId,
        'tenantName': tenantName,
        'roomId': roomId,       
        'hostelId': hostelId, 
        'landlordId': landlordId,
        'dueMonth': Timestamp.fromDate(DateTime(dueMonth.year, dueMonth.month)),
        'dueDate': Timestamp.fromDate(dueDate),
        'roomRent': roomRent,
        'services': services.map((e) => e.toMap()).toList(),
        'extraFees': extraFees.map((e) => e.toMap()).toList(),
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'status': status,
      };
}

class ServiceItem {
  final String name;
  final double price;
  ServiceItem({required this.name, required this.price});
  factory ServiceItem.fromMap(Map<String, dynamic> map) => ServiceItem(
        name: map['name'] ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
      );
  Map<String, dynamic> toMap() => {'name': name, 'price': price};
}

class ExtraFee {
  final String description;
  final double price;
  ExtraFee({required this.description, required this.price});
  factory ExtraFee.fromMap(Map<String, dynamic> map) => ExtraFee(
        description: map['description'] ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
      );
  Map<String, dynamic> toMap() => {'description': description, 'price': price};
}