import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/users.dart';

class AuthProvider with ChangeNotifier {
  String? _errorMessage;
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email.trim(), password: password.trim());
      await _storage.write(key: 'uid', value: userCredential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _handleAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String confirmPassword, {String? phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (password != confirmPassword) {
      _errorMessage = 'Mật khẩu xác nhận không khớp';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email.trim(), password: password.trim());

      Users user = Users(
        userId: userCredential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone?.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toJson());

      await _storage.write(key: 'uid', value: userCredential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _handleAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email đã được sử dụng.';
        case 'invalid-email':
          return 'Email không hợp lệ.';
        case 'weak-password':
          return 'Mật khẩu quá yếu.';
        case 'user-not-found':
        case 'wrong-password':
          return 'Email hoặc mật khẩu không đúng.';
        default:
          return 'Đã có lỗi xảy ra: ${e.message}';
      }
    }
    return 'Đã có lỗi xảy ra: $e';
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}