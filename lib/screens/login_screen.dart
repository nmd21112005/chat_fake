import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../theme/app_colors.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../services/user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return md5.convert(bytes).toString();
  }

  void _handleLogin() async {
    String inputPhone = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    String inputPass = _passwordController.text.trim();

    if (inputPhone.isEmpty || inputPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng nhập đủ SĐT và mật khẩu!"))
      );
      return;
    }

    setState(() => _isLoading = true);

    String formattedPhone = inputPhone.startsWith('0') ? '+84${inputPhone.substring(1)}' : inputPhone;

    try {
      var userCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .get();

      if (userCheck.docs.isNotEmpty) {
        var userData = userCheck.docs.first.data();

        if (_hashPassword(inputPass) == userData['password']) {
          if (!mounted) return;

          // Lưu Session
          UserSession.currentPhone = formattedPhone;
          print("✅ Đã lưu phiên đăng nhập cho: $formattedPhone");

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                verificationId: userData['loginOTP'] ?? "",
                phoneNumber: formattedPhone,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sai mật khẩu!")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Số điện thoại chưa được đăng ký!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purpleLight,
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- SỬA LOGO TẠI ĐÂY ---
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30), // Độ bo tròn (số càng lớn càng tròn)
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // Màu bóng
                      blurRadius: 15, // Độ nhòe bóng
                      offset: const Offset(0, 8), // Bóng đổ xuống dưới
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30), // Bo tròn ảnh bên trong
                  child: Image.asset(
                      'assets/images/logo.png',
                      width: 120, // Kích thước logo
                      height: 120,
                      fit: BoxFit.cover, // Đảm bảo ảnh phủ kín khung
                      errorBuilder: (c, e, s) => Container(
                        width: 120, height: 120,
                        color: Colors.white,
                        child: const Icon(Icons.chat_bubble_rounded, size: 80, color: AppColors.purplePrimary),
                      )
                  ),
                ),
              ),
              // ------------------------

              const SizedBox(height: 30),
              const Text(
                  "Chào mừng trở lại!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.purplePrimary)
              ),
              const SizedBox(height: 8),
              const Text("Đăng nhập để tiếp tục kết nối", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 35),

              _buildInput(controller: _phoneController, hint: "Số điện thoại", icon: Icons.phone_android_rounded),
              const SizedBox(height: 15),
              _buildInput(
                controller: _passwordController,
                hint: "Mật khẩu",
                icon: Icons.lock_outline_rounded,
                isPass: true,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purplePrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ĐĂNG NHẬP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: const Text("Quên mật khẩu?", style: TextStyle(color: AppColors.purplePrimary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text("Tạo tài khoản", style: TextStyle(color: AppColors.purplePrimary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({required TextEditingController controller, required String hint, required IconData icon, bool isPass = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.purpleSoft.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass ? _isObscure : false,
        keyboardType: isPass ? TextInputType.text : TextInputType.phone,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          prefixIcon: Icon(icon, color: AppColors.purplePrimary, size: 22),
          suffixIcon: isPass
              ? IconButton(
              icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
              onPressed: () => setState(() => _isObscure = !_isObscure)
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}