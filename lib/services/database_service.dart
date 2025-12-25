import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Lưu thông tin người dùng: Dùng SĐT làm ID tài liệu để đồng bộ
  Future<void> saveUser(UserModel user) async {
    // Ưu tiên dùng phoneNumber làm ID tài liệu thay vì UID Auth
    String docId = user.phoneNumber.isNotEmpty ? user.phoneNumber : user.uid;

    try {
      await _db.collection('users').doc(docId).set(user.toMap());
    } catch (e) {
      print("❌ Lỗi khi lưu User vào Firestore: $e");
    }
  }

  // 2. Tìm kiếm người dùng theo số điện thoại
  Future<UserModel?> searchUserByPhone(String phone) async {
    try {
      // Chuẩn hóa số điện thoại đầu vào
      String formattedPhone = phone.startsWith('0') ? '+84${phone.substring(1)}' : phone;

      var result = await _db
          .collection('users')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .get();

      if (result.docs.isNotEmpty) {
        return UserModel.fromMap(result.docs.first.data());
      }
    } catch (e) {
      print("❌ Lỗi khi tìm kiếm User: $e");
    }
    return null;
  }

  // 3. Lấy thông tin User hiện tại một cách an toàn
  Future<UserModel?> getUserById(String id) async {
    try {
      var doc = await _db.collection('users').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      print("❌ Lỗi khi lấy thông tin User: $e");
    }
    return null;
  }
}