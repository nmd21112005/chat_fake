import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';
import '../services/user_session.dart'; // Import để check số bản thân

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  void _searchUser() async {
    String inputPhone = _searchController.text.trim();
    if (inputPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập số điện thoại!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. CHUYỂN ĐỔI: Chuẩn hóa đầu số 0... -> +84... để khớp database
    String formattedPhone = inputPhone;
    if (inputPhone.startsWith('0')) {
      formattedPhone = '+84${inputPhone.substring(1)}';
    }

    // 2. CHECK: Không cho phép tự tìm chính mình
    if (formattedPhone == UserSession.currentPhone) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đây là số điện thoại của bạn!")),
      );
      return;
    }

    try {
      // 3. TRUY VẤN: Tìm kiếm user có ID (hoặc trường phoneNumber) là số này
      // Lưu ý: Do RegisterScreen lưu ID là SĐT, nên ta tìm thẳng doc(formattedPhone) cho nhanh
      var docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(formattedPhone)
          .get();

      // Nếu không tìm thấy theo ID, thử tìm theo trường phoneNumber (phòng hờ)
      if (!docSnapshot.exists) {
        var querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: formattedPhone)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          docSnapshot = querySnapshot.docs.first;
        }
      }

      if (docSnapshot.exists) {
        var userData = docSnapshot.data() as Map<String, dynamic>;

        if (!mounted) return;

        String receiverName = userData['displayName'] ?? "Người dùng";
        // ID người nhận chính là ID của document (Số điện thoại)
        String receiverId = docSnapshot.id;

        // 4. ĐIỀU HƯỚNG: Chuyển sang màn hình Chat
        Navigator.pushReplacement( // Dùng pushReplacement để khi back thì về Home luôn
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              receiverName: receiverName,
              receiverId: receiverId,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Không tìm thấy người dùng này!"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tìm kiếm: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purpleLight,
      appBar: AppBar(
        title: const Text("Tìm kiếm bạn bè", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.purplePrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                border: Border.all(color: AppColors.purpleSoft.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "Nhập số điện thoại (VD: 0912...)",
                  prefixIcon: Icon(Icons.search, color: AppColors.purplePrimary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purplePrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _searchUser,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("TÌM KIẾM & NHẮN TIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}