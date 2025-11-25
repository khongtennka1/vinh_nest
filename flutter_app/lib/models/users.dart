import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;
  final String? gender;
  final String status;
  final Timestamp createAt;
  final Timestamp updateAt;

  Users({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.role = 'user',
    this.gender,
    this.status = 'active',
    Timestamp? createAt,
    Timestamp? updateAt,
  })  : this.createAt = createAt ?? Timestamp.now(),
        this.updateAt = updateAt ?? Timestamp.now();

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      role: json['role'] ?? 'user',
      gender: json['gender'],    
      status: json['status'] ?? 'active',
      createAt: json['createAt'] is Timestamp
          ? json['createAt']
          : Timestamp.now(),
      updateAt: json['updateAt'] is Timestamp
          ? json['updateAt']
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'gender': gender,
      'role': role,
      'status': status,
      'createAt': createAt,
      'updateAt': updateAt,
    };
  }
}
