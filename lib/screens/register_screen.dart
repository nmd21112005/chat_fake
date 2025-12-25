  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'dart:convert';
  import 'package:crypto/crypto.dart';
  import '../theme/app_colors.dart';

  class RegisterScreen extends StatefulWidget {
    const RegisterScreen({super.key});

    @override
    State<RegisterScreen> createState() => _RegisterScreenState();
  }

  class _RegisterScreenState extends State<RegisterScreen> {
    final _phoneController = TextEditingController();
    final _passController = TextEditingController();
    final _nameController = TextEditingController();
    final _otpController = TextEditingController();
    bool _isLoading = false;

    // Hàm băm mật khẩu MD5 đảm bảo tính bảo mật khi lưu trữ
    String _hashPassword(String password) {
      return md5.convert(utf8.encode(password)).toString();
    }

    void _register() async {
      String phone = _phoneController.text.trim();
      String pass = _passController.text.trim();
      String name = _nameController.text.trim();
      String otp = _otpController.text.trim();

      // 1. Kiểm tra đầu vào
      if (phone.isEmpty || pass.isEmpty || name.isEmpty || otp.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin!")));
        return;
      }

      if (otp.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mã OTP bảo mật phải nhập đúng 6 số!"), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      // 2. Chuẩn hóa số điện thoại làm ID duy nhất (+84...)
      String formattedPhone = phone.startsWith('0') ? '+84${phone.substring(1)}' : phone;

      try {
        // 3. Tạo Document mới với ID là số điện thoại
        await FirebaseFirestore.instance.collection('users').doc(formattedPhone).set({
          'uid': formattedPhone, // Sử dụng SĐT làm UID để đồng bộ
          'displayName': name,
          'phoneNumber': formattedPhone,
          'password': _hashPassword(pass), // Lưu mật khẩu đã mã hóa
          'loginOTP': otp, // Lưu mã OTP bảo mật
          'avatarUrl': '',
          'isOnline': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đăng ký thành công!")));
          Navigator.pop(context); // Quay về màn hình Login
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi đăng ký: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: AppColors.purpleLight,
        appBar: AppBar(
          title: const Text("Tạo tài khoản mới", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.purplePrimary,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.person_add_alt_1_rounded, size: 80, color: AppColors.purplePrimary),
              const SizedBox(height: 20),
              _buildInput(_nameController, "Họ và tên", Icons.person_outline),
              const SizedBox(height: 15),
              _buildInput(_phoneController, "Số điện thoại (Dùng để đăng nhập)", Icons.phone_android, keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildInput(_passController, "Mật khẩu truy cập", Icons.lock_outline, isPass: true),
              const SizedBox(height: 15),
              _buildInput(
                  _otpController,
                  "Mã OTP tự chọn (6 số bảo mật)",
                  Icons.security_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 6
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purplePrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ĐĂNG KÝ NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Đã có tài khoản? Đăng nhập", style: TextStyle(color: AppColors.purplePrimary)),
              )
            ],
          ),
        ),
      );
    }

    Widget _buildInput(TextEditingController ctr, String hint, IconData icon,
        {bool isPass = false, TextInputType? keyboardType, int? maxLength}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.purplePrimary, size: 22),
            border: InputBorder.none,
            counterText: "",
          ),
        ),
      );
    }
  }