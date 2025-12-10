import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String kDefaultAvatarUrl =
    'gs://roomrental-d2361.firebasestorage.app/Avatar/Ren.png';

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

  Future<Map<String, dynamic>?> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      _currentUser = userCredential.user;

      await _storage.write(key: 'uid', value: _currentUser!.uid);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (!userDoc.exists) {
        _errorMessage = "Không tìm thấy dữ liệu người dùng!";
        _isLoading = false;
        notifyListeners();
        return null;
      }

      String role = userDoc.get("role");

      _isLoading = false;
      notifyListeners();

      return {"success": true, "role": role, "uid": _currentUser!.uid};
    } catch (e) {
      _errorMessage = _handleAuthError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmPassword, {
    String? phone,
    required String role,
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
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'userId': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone?.trim(),
        'role': role,
        'avatar': kDefaultAvatarUrl,
        'status': 'active',
        'gender': null,
        'createAt': FieldValue.serverTimestamp(),
        'updateAt': FieldValue.serverTimestamp(),
      });

      await _storage.write(key: 'uid', value: uid);

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

    final user = _auth.currentUser;

    if (uid != null && user != null && user.uid == uid) {
      _currentUser = user;
    } else {
      _currentUser = null;
    }

    notifyListeners();
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

  Future<void> logout() async {
    await _auth.signOut();
    await _storage.delete(key: 'uid');
    _currentUser = null;
    notifyListeners();
  }
}
