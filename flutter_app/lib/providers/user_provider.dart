import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/users.dart';

class UserProvider with ChangeNotifier {
  Users? _currentUser;
  bool _isLoading = false;

  Users? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<void> loadCurrentUser() async {
    if (FirebaseAuth.instance.currentUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        _currentUser = Users.fromJson(doc.data()!);
      } else {
        _currentUser = Users(
          userId: uid,
          name: FirebaseAuth.instance.currentUser!.displayName ?? 'Người dùng VinhNest',
          email: FirebaseAuth.instance.currentUser!.email ?? '',
        );
        await saveUserToFirestore();
      }
    } catch (e) {
      debugPrint('Lỗi load user: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser({
    required String name,
    required String phone,
    String? gender,
    String? avatar,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = Users(
        userId: _currentUser!.userId,
        name: name.trim(),
        email: _currentUser!.email,
        phone: phone.trim().isEmpty ? null : phone.trim(),
        avatar: avatar ?? _currentUser!.avatar,
        gender: gender,
        role: _currentUser!.role,
        status: _currentUser!.status,
        createAt: _currentUser!.createAt,
        updateAt: Timestamp.now(),
      );

      _currentUser = updatedUser;
      await saveUserToFirestore();
    } catch (e) {
      debugPrint('Lỗi cập nhật: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveUserToFirestore() async {
    if (_currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.userId)
        .set(_currentUser!.toJson(), SetOptions(merge: true));
  }

  void clear() {
    _currentUser = null;
    notifyListeners();
  }
}