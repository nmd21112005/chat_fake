import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String receiverId;
  final String message;
  final dynamic timestamp;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
  });

  // Getter để lấy DateTime an toàn, dùng trong ListView để hiện HH:mm
  DateTime get dateTime {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    // Nếu là FieldValue (đang gửi) hoặc null, trả về giờ hiện tại để không bị lỗi đỏ
    return DateTime.now();
  }

  // Chuyển từ Map (Firestore) sang Object
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'], // Để dynamic để ChatScreen tự xử lý logic check null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      // Đảm bảo luôn có timestamp khi gửi lên
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }
}