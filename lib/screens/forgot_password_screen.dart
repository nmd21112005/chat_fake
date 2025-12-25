import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _isLoading = false;

  // Hàm băm mật khẩu MD5 đồng bộ với hệ thống
  String _hashPassword(String password) => md5.convert(utf8.encode(password)).toString();

  void _resetPassword() async {
    String phone = _phoneController.text.trim();
    String otp = _otpController.text.trim();
    String newPass = _newPassController.text.trim();

    // 1. Kiểm tra đầu vào cơ bản
    if (phone.isEmpty || otp.length != 6 || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ thông tin và OTP ĐÚNG 6 số!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. Định dạng số điện thoại làm Document ID
    String formattedPhone = phone.startsWith('0') ? '+84${phone.substring(1)}' : phone;

    try {
      // 3. Truy vấn trực tiếp bằng Document ID (Số điện thoại)
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(formattedPhone).get();

      if (userDoc.exists) {
        // 4. So khớp mã OTP bảo mật
        if (userDoc.data()?['loginOTP'] == otp) {
          await FirebaseFirestore.instance.collection('users').doc(formattedPhone).update({
            'password': _hashPassword(newPass),
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Đổi mật khẩu thành công!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Mã OTP không chính xác!"), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Số điện thoại này chưa được đăng ký!"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi hệ thống: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purpleLight,
      appBar: AppBar(
        title: const Text("Khôi phục mật khẩu", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.purplePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.lock_reset, size: 80, color: AppColors.purplePrimary),
            const SizedBox(height: 10),
            const Text(
              "Vui lòng nhập số điện thoại và mã OTP bảo mật đã thiết lập để đặt lại mật khẩu.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            _buildInput(_phoneController, "Số điện thoại đăng ký", Icons.phone, keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            _buildInput(_otpController, "Mã OTP bảo mật (6 số)", Icons.verified_user, keyboardType: TextInputType.number, maxLength: 6),
            const SizedBox(height: 15),
            _buildInput(_newPassController, "Mật khẩu mới", Icons.vpn_key, isPass: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purplePrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("CẬP NHẬT MẬT KHẨU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctr, String hint, IconData icon, {bool isPass = false, TextInputType? keyboardType, int? maxLength}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: TextField(
        controller: ctr,
        obscureText: isPass,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: keyboardType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.purplePrimary, size: 22),
            border: InputBorder.none,
            counterText: ""
        ),
      ),
    );
  }
}