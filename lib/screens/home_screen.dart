import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../services/user_session.dart';
import 'chat_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String get currentUserId {
    String raw = UserSession.currentPhone ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? "";
    String clean = raw.trim();
    if (clean.startsWith('0')) return '+84${clean.substring(1)}';
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        backgroundColor: AppColors.purplePrimary,
        elevation: 0,
        title: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.white70),
                SizedBox(width: 10),
                Text("Tìm kiếm bạn bè...", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Chỉ hiện những chat mà 'users' có chứa ID của mình
        // Nếu đã bấm Ẩn (ChatService.hideChat), ID mình bị xóa khỏi 'users' -> Không hiện ở đây
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('users', arrayContains: currentUserId)
            .orderBy('lastTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.purplePrimary));
          }

          // NẾU KHÔNG CÓ TIN NHẮN (HOẶC ĐÃ ẨN HẾT) -> HIỆN DANH SÁCH GỢI Ý (CODE CŨ CỦA BẠN)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildAllUsersList();
          }

          // NẾU CÓ TIN NHẮN -> HIỆN LIST CHAT
          return Container(
            color: Colors.white,
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var roomData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                List<dynamic> users = roomData['users'];
                String otherUserId = users.firstWhere((id) => id != currentUserId, orElse: () => "");
                if (otherUserId.isEmpty) return const SizedBox.shrink();

                return _ChatListItem(
                  otherUserId: otherUserId,
                  lastMessage: roomData['lastMessage'] ?? "",
                  lastTime: roomData['lastTime'] as Timestamp?,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // --- GIỮ NGUYÊN CODE CŨ CỦA BẠN: HIỆN GỢI Ý KHI TRỐNG ---
  Widget _buildAllUsersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').limit(20).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var users = snapshot.data!.docs
                  .where((doc) => doc['phoneNumber'] != currentUserId)
                  .toList();

              if (users.isEmpty) {
                return const Center(child: Text("Chưa có ai dùng app này ngoài bạn!"));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  var user = users[index].data() as Map<String, dynamic>;
                  String name = user['displayName'] ?? user['phoneNumber'];
                  String phone = user['phoneNumber'] ?? "";
                  String firstChar = name.isNotEmpty ? name[0].toUpperCase() : "?";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))
                        ]
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.purplePrimary,
                        child: Text(firstChar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: const Text("Nhấn để bắt đầu trò chuyện", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(receiverName: name, receiverId: phone),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Widget Item Chat (Giữ nguyên)
class _ChatListItem extends StatelessWidget {
  final String otherUserId;
  final String lastMessage;
  final Timestamp? lastTime;

  const _ChatListItem({required this.otherUserId, required this.lastMessage, this.lastTime});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        String name = otherUserId;
        if (snapshot.hasData && snapshot.data!.exists) {
          var d = snapshot.data!.data() as Map<String, dynamic>;
          name = d['displayName'] ?? otherUserId;
        }
        String firstChar = name.isNotEmpty ? name[0].toUpperCase() : "?";
        String timeStr = "";
        if (lastTime != null) {
          DateTime date = lastTime!.toDate();
          timeStr = DateFormat(date.day == DateTime.now().day ? 'HH:mm' : 'dd/MM').format(date);
        }

        return Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5))
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.purplePrimary,
              child: Text(firstChar, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
            trailing: Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(receiverName: name, receiverId: otherUserId))),
          ),
        );
      },
    );
  }
}