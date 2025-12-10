import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  final String id;
  final String userId;
  final String hostelId;
  final String roomId;
  final DateTime createdAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.hostelId,
    required this.roomId,
    required this.createdAt,
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

  factory Favorite.fromMap(Map<String, dynamic> data, String id) {
    return Favorite(
      id: id,
      userId: data['userId'],
      hostelId: data['hostelId'],
      roomId: data['roomId'],
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'hostelId': hostelId,
      'roomId': roomId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
