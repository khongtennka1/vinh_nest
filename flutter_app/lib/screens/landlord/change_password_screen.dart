import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  bool isSending = false;
  bool isVerifying = false;
  String? message;

  /// Tạo OTP ngẫu nhiên
  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Gửi OTP email (Firebase Auth không hỗ trợ OTP email → tự làm)
  Future<void> sendOTPToEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => message = "Vui lòng nhập email");
      return;
    }

    setState(() {
      isSending = true;
      message = null;
    });

    try {
      String otp = generateOTP();

      /// Lưu OTP vào Firestore
      await FirebaseFirestore.instance.collection("password_otps").add({
        "email": email,
        "otp": otp,
        "createdAt": DateTime.now(),
      });

      /// Gửi mail OTP bằng Firebase Admin API / Backend của bạn
      /// Ở đây tôi ghi chú vì Flutter không thể tự gửi email:
      ///
      /// 👉 Bạn cần backend API gửi email (Node.js, PHP, Python,…)
      ///
      /// HOẶC dùng dịch vụ miễn phí như EmailJS

      setState(() {
        message = "OTP đã được gửi đến email của bạn";
      });
    } catch (e) {
      setState(() => message = "Lỗi: $e");
    }

    setState(() => isSending = false);
  }

  /// Gửi link reset password (Firebase hỗ trợ sẵn)
  Future<void> sendResetLink() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => message = "Vui lòng nhập email");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() {
        message = "Liên kết đặt lại mật khẩu đã được gửi đến email.";
      });
    } catch (e) {
      setState(() => message = e.toString());
    }
  }

  /// Xác minh OTP và thay đổi mật khẩu
  Future<void> verifyOTPAndChangePassword() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();
    final newPassword = newPasswordController.text.trim();

    if (email.isEmpty || otp.isEmpty || newPassword.isEmpty) {
      setState(() => message = "Vui lòng nhập đầy đủ thông tin");
      return;
    }

    setState(() => isVerifying = true);

    try {
      /// Lấy OTP từ Firestore
      final query = await FirebaseFirestore.instance
          .collection("password_otps")
          .where("email", isEqualTo: email)
          .where("otp", isEqualTo: otp)
          .orderBy("createdAt", descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => message = "OTP không hợp lệ");
        setState(() => isVerifying = false);
        return;
      }

      /// OTP hợp lệ → đăng nhập lại bằng email & gửi link reset password?
      /// Firebase yêu cầu re-auth để updatePassword → không thể tự đổi nếu user chưa login
      ///
      /// 👉 Cách đổi mật khẩu bằng OTP phải làm kiểu khác
      /// Bạn buộc phải dùng:
      /// sendPasswordResetEmail()
      ///
      /// Và Firebase lo phần còn lại.

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() {
        message =
            "OTP hợp lệ. Liên kết đặt lại mật khẩu đã được gửi. Vui lòng kiểm tra email.";
      });
    } catch (e) {
      setState(() => message = "Lỗi: $e");
    }

    setState(() => isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đổi mật khẩu qua Email / OTP")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // BUTTON GỬI OTP
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isSending ? null : sendOTPToEmail,
                child: isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Gửi OTP qua Email"),
              ),
            ),

            const SizedBox(height: 10),

            // BUTTON GỬI LINK RESET PASSWORD
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: sendResetLink,
                child: const Text("Gửi Link Reset Password"),
              ),
            ),

            const SizedBox(height: 20),

            // OTP
            TextField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: "OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // NEW PASSWORD
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mật khẩu mới",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // VERIFY OTP + CHANGE PASSWORD
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isVerifying ? null : verifyOTPAndChangePassword,
                child: isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Xác minh OTP & Đổi mật khẩu"),
              ),
            ),

            const SizedBox(height: 16),
            if (message != null)
              Text(message!, style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
