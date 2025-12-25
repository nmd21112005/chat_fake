import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import '../services/user_session.dart'; // Import Session

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();

  String _displayPhone = "";
  String? _docIdToUpdate;
  String _debugStatus = "Đang tải...";
  bool _isLoading = false;
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _identifyUser();
  }

  // HÀM NHẬN DIỆN NGƯỜI DÙNG THÔNG MINH
  void _identifyUser() async {
    String? phone;

    // 1. Ưu tiên lấy từ Session (Do LoginScreen gửi sang)
    if (UserSession.currentPhone != null && UserSession.currentPhone!.isNotEmpty) {
      phone = UserSession.currentPhone;
      setState(() => _debugStatus = "User từ Login: $phone");
    }
    // 2. Nếu không có session, thử lấy từ Firebase Auth
    else if (FirebaseAuth.instance.currentUser != null) {
      phone = FirebaseAuth.instance.currentUser!.phoneNumber;
      setState(() => _debugStatus = "User từ Auth: $phone");
    }

    if (phone == null || phone.isEmpty) {
      setState(() => _debugStatus = "❌ Lỗi: Mất kết nối. Hãy đăng nhập lại.");
      return;
    }

    _displayPhone = phone;
    _docIdToUpdate = phone; // Chốt ID là số điện thoại luôn

    // Tải dữ liệu từ Firestore
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(phone).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['displayName'] ?? "";
        });
      } else {
        setState(() => _debugStatus = "⚠️ Hồ sơ mới (Chưa có tên)");
      }
    } catch (e) {
      setState(() => _debugStatus = "Lỗi mạng: $e");
    }
  }

  void _updateProfile() async {
    if (_docIdToUpdate == null) return;

    setState(() { _isLoading = true; _statusMessage = ""; });

    try {
      await FirebaseFirestore.instance.collection('users').doc(_docIdToUpdate).set({
        'displayName': _nameController.text.trim(),
        'phoneNumber': _displayPhone,
        // Giữ nguyên các trường cũ nếu có
      }, SetOptions(merge: true));

      setState(() => _statusMessage = "✅ Đã lưu thành công!");
    } catch (e) {
      setState(() => _statusMessage = "❌ Lỗi: $e");
    }

    setState(() => _isLoading = false);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _statusMessage = "");
    });
  }

  void _showChangePassDialog(BuildContext context) {
    final passController = TextEditingController();
    bool localLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text("Đổi mật khẩu mới"),
                content: TextField(
                  controller: passController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: "Nhập mật khẩu mới"),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                  TextButton(
                    onPressed: localLoading ? null : () async {
                      if (passController.text.trim().isEmpty) return;
                      setStateDialog(() => localLoading = true);

                      // Mã hóa MD5 chuẩn như Login
                      var hashed = md5.convert(utf8.encode(passController.text.trim())).toString();

                      try {
                        await FirebaseFirestore.instance.collection('users').doc(_docIdToUpdate).set({
                          'password': hashed
                        }, SetOptions(merge: true));

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đổi mật khẩu thành công!"), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        setStateDialog(() => localLoading = false);
                      }
                    },
                    child: localLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Cập nhật"),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void _handleLogout() async {
    UserSession.clear(); // Xóa session
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purpleLight,
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.purplePrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                  color: AppColors.purplePrimary,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))
              ),
              child: Column(
                children: [
                  CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                          _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : "U",
                          style: const TextStyle(fontSize: 40, color: AppColors.purplePrimary, fontWeight: FontWeight.bold)
                      )
                  ),
                  const SizedBox(height: 15),
                  // HIỂN THỊ SĐT TỪ SESSION
                  Text(_displayPhone.isEmpty ? "..." : _displayPhone,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

                  // DEBUG INFO (Xóa sau nếu muốn)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_debugStatus, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  _buildProfileItem(
                      child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: "Tên hiển thị", border: InputBorder.none, prefixIcon: Icon(Icons.person))
                      )
                  ),
                  const SizedBox(height: 15),
                  _buildProfileItem(
                      child: ListTile(
                          title: const Text("Đổi mật khẩu nhanh"),
                          leading: const Icon(Icons.lock),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => _showChangePassDialog(context)
                      )
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _docIdToUpdate == null ? Colors.grey : (_statusMessage.contains("✅") ? Colors.green : AppColors.purplePrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      onPressed: (_isLoading || _docIdToUpdate == null) ? null : _updateProfile,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_statusMessage.isEmpty ? "LƯU THAY ĐỔI" : _statusMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: TextButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text("ĐĂNG XUẤT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({required Widget child}) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
        child: child
    );
  }
}