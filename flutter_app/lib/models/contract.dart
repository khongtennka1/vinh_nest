import 'package:cloud_firestore/cloud_firestore.dart';

class Contract {
  final String id;
  final String roomId;
  final String hostelId;
  final String landlordId;
  final String? roomNumber;
  final String? hostelName;
  final String tenantName;
  final String tenantPhone;
  final String tenantEmail;
  final String tenantIdNumber;
  final List<String> tenantIdImages;
  final List<String> additionalMembers;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final DateTime rentStartCalcDate;
  final String paymentCycle;

  final List<Map<String, dynamic>> services;
  final List<String> interiorItems;
  final List<String> contractImages;
  final String note;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status;

  Contract({
    required this.id,
    required this.roomId,
    required this.hostelId,
    required this.landlordId,
    required this.tenantName,
    required this.tenantPhone,
    this.roomNumber,
    this.hostelName,
    this.tenantEmail = '',
    required this.tenantIdNumber,
    this.tenantIdImages = const [],
    this.additionalMembers = const [],
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.rentStartCalcDate,
    this.paymentCycle = 'Hàng tháng',
    this.services = const [],
    this.interiorItems = const [],
    this.contractImages = const [],
    this.note = '',
    required this.createdAt,
    this.updatedAt,
    this.status = 'active',
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  static List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  factory Contract.fromMap(Map<String, dynamic> data, String id) {
    return Contract(
      id: id,
      roomId: data['roomId'] ?? '',
      roomNumber: data['roomNumber'] as String?, 
      hostelName: data['hostelName'] as String?,
      hostelId: data['hostelId'] ?? '',
      landlordId: data['landlordId'] ?? '',
      tenantName: data['tenantName'] ?? '',
      tenantPhone: data['tenantPhone'] ?? '',
      tenantEmail: data['tenantEmail'] ?? '',
      tenantIdNumber: data['tenantIdNumber'] ?? '',
      tenantIdImages: _toStringList(data['tenantIdImages']),
      additionalMembers: _toStringList(data['additionalMembers']),
      startDate: _parseDate(data['startDate']),
      endDate: _parseDate(data['endDate']),
      rentStartCalcDate: _parseDate(data['rentStartCalcDate']),
      monthlyRent: (data['monthlyRent'] ?? 0).toDouble(),
      paymentCycle: data['paymentCycle'] ?? 'Hàng tháng',
      services: _toMapList(data['services']),
      interiorItems: _toStringList(data['interiorItems']),
      contractImages: _toStringList(data['contractImages']),
      note: data['note'] ?? '',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseDate(data['updatedAt']) : null,
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'hostelId': hostelId,
      'landlordId': landlordId,
      'tenantName': tenantName,
      'tenantPhone': tenantPhone,
      'tenantEmail': tenantEmail,
      'tenantIdNumber': tenantIdNumber,
      'tenantIdImages': tenantIdImages,
      'additionalMembers': additionalMembers,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'rentStartCalcDate': Timestamp.fromDate(rentStartCalcDate),
      'monthlyRent': monthlyRent,
      'paymentCycle': paymentCycle,
      'services': services,
      'interiorItems': interiorItems,
      'contractImages': contractImages,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status,
    };
  }
}