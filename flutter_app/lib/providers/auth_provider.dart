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

  User? _currentUser;
  User? get currentUser => _currentUser;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

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

  Future<bool> register(
  String name,
  String email,
  String password,
  String confirmPassword, {
  String? phone,
}) async {
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
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'userId': userCredential.user!.uid,
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone?.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _storage.write(key: 'uid', value: userCredential.user!.uid);

    _isLoading = false;
    notifyListeners();
    return true;
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'email-already-in-use':
        _errorMessage = 'Email đã được sử dụng.';
        break;
      case 'invalid-email':
        _errorMessage = 'Email không hợp lệ.';
        break;
      case 'weak-password':
        _errorMessage = 'Mật khẩu quá yếu.';
        break;
      default:
        _errorMessage = 'Lỗi không xác định: ${e.message}';
    }
  } catch (e) {
    _errorMessage = 'Đăng ký thất bại: $e';
  }

  _isLoading = false;
  notifyListeners();
  return false;
}

Future<void> checkAuthState() async {
  final uid = await _storage.read(key: 'uid');
  if(uid != null) {
    try {
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        _currentUser = user;
      } else {
        await _auth.signInAnonymously();
      }
      notifyListeners();
    } catch (e) {
      await _storage.delete(key: 'uid');
    }
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
