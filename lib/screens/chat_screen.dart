import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/message_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../services/user_session.dart';

class ChatScreen extends StatefulWidget {
  final String receiverName;
  final String receiverId;

  const ChatScreen({super.key, required this.receiverName, required this.receiverId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();

  bool _showMenu = false;
  bool _isShowingStickers = true;
  bool _isBlocked = false;
  String? _blockedBy;

  String get currentUserId => UserSession.currentPhone ?? "";

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void sendSticker(String stickerName) async {
    String fullPath = "assets/stickers/$stickerName";
    try {
      await _chatService.sendMessage(widget.receiverId, "[STICKER]$fullPath");
      setState(() => _showMenu = false);
      _scrollToBottom();
    } catch (e) {
      debugPrint("Lỗi gửi sticker: $e");
    }
  }

  void selectAndSendImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      await _chatService.sendImage(widget.receiverId, imageFile);
      setState(() => _showMenu = false);
    }
  }

  void _insertIconToTextField(String iconChar) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(
      selection.start != -1 ? selection.start : text.length,
      selection.end != -1 ? selection.end : text.length,
      iconChar,
    );
    _messageController.text = newText;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: (selection.start != -1 ? selection.start : text.length) + iconChar.length),
    );
  }

  // --- XỬ LÝ MENU: ẨN & CHẶN ---
  void _handleMenuOption(String value) async {
    if (value == 'hide') { // Key là 'hide'
      bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Ẩn trò chuyện?"),
            content: const Text(
              "Cuộc trò chuyện này sẽ biến mất khỏi danh sách.\nNó sẽ hiện lại khi bạn nhắn tin mới.",
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey))
              ),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  // Nút xác nhận màu tím
                  child: const Text("Ẩn ngay", style: TextStyle(color: AppColors.purplePrimary, fontWeight: FontWeight.bold))
              ),
            ],
          )
      ) ?? false;

      if (confirm) {
        if (!mounted) return;

        // Hiện Loading xoay xoay
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.purplePrimary)),
        );

        // Gọi hàm ẨN (Hide) bên Service
        await _chatService.hideChat(widget.receiverId);

        if (mounted) {
          Navigator.pop(context); // Tắt loading
          Navigator.pop(context); // Thoát khỏi màn hình Chat về Home

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đã ẩn cuộc trò chuyện"))
          );
        }
      }
    } else if (value == 'block') {
      bool isBlockingNow = (_blockedBy == currentUserId);
      await _chatService.toggleBlockUser(widget.receiverId, !isBlockingNow);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPrivateNote = currentUserId == widget.receiverId;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            if (isPrivateNote)
              const Text("Kho lưu trữ cá nhân", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppColors.purplePrimary,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // NÚT 3 CHẤM MENU
          StreamBuilder<DocumentSnapshot>(
            stream: _chatService.getChatRoomStream(widget.receiverId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                _blockedBy = data['blockedBy'];
                _isBlocked = _blockedBy != null;
              } else {
                _isBlocked = false;
                _blockedBy = null;
              }

              bool amIBlocker = _blockedBy == currentUserId;

              return PopupMenuButton<String>(
                onSelected: _handleMenuOption,
                itemBuilder: (BuildContext context) {
                  return [
                    // ITEM 1: ẨN TRÒ CHUYỆN
                    const PopupMenuItem(
                      value: 'hide', // Giá trị để xử lý trong hàm _handleMenuOption
                      child: Row(
                          children: [
                            Icon(Icons.visibility_off_outlined, color: Colors.grey),
                            SizedBox(width: 8),
                            Text("Ẩn trò chuyện")
                          ]
                      ),
                    ),
                    // ITEM 2: CHẶN/BỎ CHẶN
                    PopupMenuItem(
                      value: 'block',
                      child: Row(children: [
                        Icon(amIBlocker ? Icons.check_circle_outline : Icons.block, color: amIBlocker ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Text(amIBlocker ? "Bỏ chặn" : "Chặn người này")
                      ]),
                    ),
                  ];
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/chat_background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFF3E5F5)),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessages(widget.receiverId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.purplePrimary));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState(isPrivateNote);
                    }
                    _scrollToBottom();
                    var docs = snapshot.data!.docs;
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        DateTime date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                        return MessageBubble(
                          message: data['message'] ?? "",
                          isMe: data['senderId'] == currentUserId,
                          time: DateFormat('HH:mm').format(date),
                        );
                      },
                    );
                  },
                ),
              ),

              // KHUNG NHẬP LIỆU HOẶC THÔNG BÁO CHẶN
              if (_isBlocked)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: Text(
                    _blockedBy == currentUserId
                        ? "Bạn đã chặn người dùng này.\nBỏ chặn để tiếp tục nhắn tin."
                        : "Người này hiện không thể nhận tin nhắn.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Column(
                  children: [
                    _buildInputArea(),
                    if (_showMenu) _buildExpandedMenu(),
                  ],
                )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isPrivate) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isPrivate ? Icons.bookmark_border : Icons.chat_bubble_outline, size: 80, color: AppColors.purpleSoft),
          const SizedBox(height: 10),
          const Text("Chưa có tin nhắn nào.\nHãy gửi lời chào!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.white.withOpacity(0.95),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(_showMenu ? Icons.keyboard : Icons.grid_view_rounded, color: AppColors.purplePrimary),
              onPressed: () {
                setState(() => _showMenu = !_showMenu);
                if (_showMenu) FocusScope.of(context).unfocus();
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: const Color(0xFFF1F0F5), borderRadius: BorderRadius.circular(25)),
                child: TextField(
                  controller: _messageController,
                  onTap: () => setState(() => _showMenu = false),
                  maxLines: null,
                  decoration: const InputDecoration(hintText: "Nhập tin nhắn...", border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                String content = _messageController.text.trim();
                if (content.isNotEmpty) {
                  _chatService.sendMessage(widget.receiverId, content);
                  _messageController.clear();
                  _scrollToBottom();
                }
              },
              child: const CircleAvatar(
                backgroundColor: AppColors.purplePrimary,
                radius: 22,
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMenu() {
    return Container(
      height: 250,
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _menuBtn(Icons.image, "Ảnh", Colors.blue, selectAndSendImage),
                _menuBtn(Icons.emoji_emotions, "Icon", Colors.orange, () => setState(() => _isShowingStickers = false)),
                _menuBtn(Icons.auto_awesome, "Stickers", Colors.purple, () => setState(() => _isShowingStickers = true)),
                _menuBtn(Icons.folder_copy, "File", Colors.red, () {}),
              ],
            ),
          ),
          Expanded(child: _isShowingStickers ? _buildStickerList() : _buildIconList()),
        ],
      ),
    );
  }

  Widget _menuBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildIconList() {
    final icons = ["😀", "🤣", "😍", "👍", "🙌", "🔥", "❤️", "🎉", "🤔", "😭", "👏", "✨", "🙏", "🚀"];
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: icons.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => _insertIconToTextField(icons[index]),
        child: Center(child: Text(icons[index], style: const TextStyle(fontSize: 28))),
      ),
    );
  }

  Widget _buildStickerList() {
    final stickers = ["cry.png", "hehe.png", "huh.png", "kitty.png", "loading.png", "meo.png", "oe.png"];
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => sendSticker(stickers[index]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Image.asset("assets/stickers/${stickers[index]}", width: 80, height: 80),
          ),
        );
      },
    );
  }
}