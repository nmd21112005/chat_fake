import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String? _verificationId;

  // 1. Hàm băm mật khẩu MD5
  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    return md5.convert(bytes).toString();
  }

  // 2. Gửi mã OTP
  Future<void> sendOTP(String phoneNumber, Function(String) onCodeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("❌ Lỗi gửi OTP: ${e.message}");
      },
      codeSent: (String verId, int? resendToken) {
        _verificationId = verId;
        onCodeSent(verId);
      },
      codeAutoRetrievalTimeout: (String verId) {
        _verificationId = verId;
      },
    );
  }

  // 3. Xác thực OTP
  Future<User?> verifyOTP(String smsCode) async {
    try {
      if (_verificationId == null) return null;
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("❌ Lỗi xác thực OTP: $e");
      return null;
    }
  }

  // 4. FIX LOGIC: Tìm đúng ID (Phone hoặc UID) để cập nhật Online
  Future<void> updateUserStatus(bool isOnline) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      String docIdToUpdate = currentUser.uid; // Mặc định là UID
      String? phone = currentUser.phoneNumber;

      // QUAN TRỌNG: Kiểm tra xem SĐT có phải là ID tài liệu không (Do RegisterScreen tạo theo SĐT)
      if (phone != null && phone.isNotEmpty) {
        try {
          var doc = await _db.collection('users').doc(phone).get();
          if (doc.exists) {
            docIdToUpdate = phone; // Nếu tìm thấy theo SĐT, dùng SĐT làm ID
          }
        } catch (e) {
          print("⚠️ Không check được doc theo phone: $e");
        }
      }

      try {
        // Cập nhật trạng thái vào đúng document tìm được
        await _db.collection('users').doc(docIdToUpdate).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
        print("✅ Đã cập nhật trạng thái $isOnline cho ID: $docIdToUpdate");
      } catch (e) {
        // Nếu update thất bại (do doc không tồn tại), dùng set merge để tạo mới luôn
        await _db.collection('users').doc(docIdToUpdate).set({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
          'phoneNumber': phone ?? "",
          'uid': currentUser.uid
        }, SetOptions(merge: true));
        print("✅ Đã tạo mới và cập nhật trạng thái cho ID: $docIdToUpdate");
      }
    }
  }

  // 5. Đăng xuất
  Future<void> signOut() async {
    // Cập nhật Offline trước khi thoát
    await updateUserStatus(false);
    await _auth.signOut();
  }
}