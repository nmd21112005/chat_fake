import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'user_session.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1. Chuẩn hóa SĐT (09.. -> +84..)
  // Giúp đồng bộ ID giữa các máy
  String _normalizePhone(String? phone) {
    if (phone == null || phone.isEmpty) return "";
    String cleanPhone = phone.trim();
    if (cleanPhone.startsWith('0')) {
      return '+84${cleanPhone.substring(1)}';
    }
    return cleanPhone;
  }

  // Lấy ID hiện tại
  String get _currentId {
    String rawId = UserSession.currentPhone ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? "";
    return _normalizePhone(rawId);
  }

  // Tạo ID phòng chat từ 2 số điện thoại
  String _getChatRoomId(String otherUserId) {
    String myId = _currentId;
    String otherId = _normalizePhone(otherUserId);
    List<String> ids = [myId, otherId];
    ids.sort(); // Sắp xếp để đảm bảo A nhắn B hay B nhắn A thì ID phòng vẫn giống nhau
    return ids.join("_");
  }

  // 2. GỬI TIN NHẮN (QUAN TRỌNG: LOGIC HIỆN LẠI CHAT)
  Future<void> sendMessage(String receiverId, String message) async {
    if (_currentId.isEmpty) return;

    String cleanReceiverId = _normalizePhone(receiverId);
    String chatRoomId = _getChatRoomId(cleanReceiverId);

    // Kiểm tra xem có bị chặn không
    var roomDoc = await _db.collection('chat_rooms').doc(chatRoomId).get();
    if (roomDoc.exists && roomDoc.data()!.containsKey('blockedBy')) {
      // Logic chặn (nếu có)
    }

    Map<String, dynamic> messageData = {
      'senderId': _currentId,
      'receiverId': cleanReceiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // a. Lưu tin nhắn vào sub-collection
    await _db.collection('chat_rooms').doc(chatRoomId).collection('messages').add(messageData);

    // b. Cập nhật thông tin phòng chat
    // QUAN TRỌNG: Dùng arrayUnion để thêm lại ID của cả 2 người vào danh sách 'users'.
    // Nếu trước đó mày đã bấm "Ẩn" (xóa mình khỏi users), dòng này sẽ đưa mày quay lại -> Chat hiện lên Home.
    await _db.collection('chat_rooms').doc(chatRoomId).set({
      'users': FieldValue.arrayUnion([_currentId, cleanReceiverId]),
      'lastMessage': message.startsWith('[IMAGE]') ? 'Hình ảnh' :
      message.startsWith('[STICKER]') ? 'Sticker' : message,
      'lastTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 3. HÀM ẨN TRÒ CHUYỆN (SOFT DELETE)
  // Thay vì xóa sạch dữ liệu, ta chỉ xóa ID mình khỏi mảng 'users'
  Future<void> hideChat(String otherUserId) async {
    String chatRoomId = _getChatRoomId(otherUserId);

    try {
      // arrayRemove: Gỡ ID mình ra -> Query ở HomeScreen sẽ không tìm thấy phòng này nữa
      await _db.collection('chat_rooms').doc(chatRoomId).update({
        'users': FieldValue.arrayRemove([_currentId])
      });
      print("✅ Đã ẩn cuộc trò chuyện với $otherUserId");
    } catch (e) {
      print("❌ Lỗi ẩn chat: $e");
    }
  }

  // 4. Lấy tin nhắn Real-time
  Stream<QuerySnapshot> getMessages(String otherUserId) {
    return _db.collection('chat_rooms')
        .doc(_getChatRoomId(otherUserId))
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // 5. Gửi ảnh
  Future<void> sendImage(String receiverId, File imageFile) async {
    try {
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = _storage.ref().child('chat_images').child(fileName);
      await ref.putFile(imageFile);
      String imageUrl = await ref.getDownloadURL();
      await sendMessage(receiverId, "[IMAGE]$imageUrl");
    } catch (e) { print("Lỗi ảnh: $e"); }
  }

  // 6. Theo dõi trạng thái phòng (để biết có bị chặn không)
  Stream<DocumentSnapshot> getChatRoomStream(String otherUserId) {
    return _db.collection('chat_rooms').doc(_getChatRoomId(otherUserId)).snapshots();
  }

  // 7. Chặn / Bỏ chặn
  Future<void> toggleBlockUser(String otherUserId, bool isBlocking) async {
    String chatRoomId = _getChatRoomId(otherUserId);
    if (isBlocking) {
      await _db.collection('chat_rooms').doc(chatRoomId).set({'blockedBy': _currentId}, SetOptions(merge: true));
    } else {
      await _db.collection('chat_rooms').doc(chatRoomId).update({'blockedBy': FieldValue.delete()});
    }
  }
}