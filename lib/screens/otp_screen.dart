import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_screen.dart'; // QUAN TRỌNG: Import MainScreen để hiện Footer
import '../theme/app_colors.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  void _verifyOtp() async {
    String inputOtp = _otpController.text.trim();

    if (inputOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ 6 chữ số mã xác thực!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    // So sánh OTP
    if (inputOtp == widget.verificationId) {
      if (!mounted) return;

      // CHUYỂN HƯỚNG VÀO MAIN SCREEN (CÓ FOOTER)
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false
      );
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Mã xác thực không chính xác. Vui lòng thử lại!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purpleLight,
      appBar: AppBar(
        // DÒNG NÀY ĐỂ TẮT MŨI TÊN QUAY LẠI
        automaticallyImplyLeading: false,
        // Căn giữa tiêu đề cho đẹp
        title: const Center(
            child: Text("Xác thực bảo mật", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
        ),
        backgroundColor: AppColors.purplePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.shield_outlined, size: 100, color: AppColors.purplePrimary),
            const SizedBox(height: 30),
            const Text(
              "Mã OTP đã được thiết lập cho số:",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              widget.phoneNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.purplePrimary),
            ),
            const SizedBox(height: 40),

            // Ô nhập mã OTP
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 28, letterSpacing: 15, fontWeight: FontWeight.bold, color: AppColors.purplePrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                counterText: "",
                hintText: "000000",
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.3), letterSpacing: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.purpleSoft, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.purplePrimary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purplePrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("XÁC NHẬN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),

            // Nút quay lại (Duy nhất)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Quay lại màn hình đăng nhập", style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }
}