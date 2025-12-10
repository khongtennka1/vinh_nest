import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String type;
  final DateTime time;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.type,
    required this.time,
  });

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['time'] as Timestamp?;

    return ChatMessage(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      imageUrl: data['imageUrl'] as String?,
      type: (data['type'] as String?) ?? 'text',
      time: ts?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'type': type,
      'time': Timestamp.fromDate(time),
    };
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String userName;
  final String conversationId;
  final String peerId;

  const ChatDetailScreen({
    super.key,
    required this.userName,
    required this.conversationId,
    required this.peerId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _isSendingImage = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để gửi tin nhắn')),
      );
      return;
    }

    final now = Timestamp.now();
    final String currentUserId = user.uid;

    final messageRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages');

    await messageRef.add({
      'senderId': currentUserId,
      'text': text,
      'imageUrl': null,
      'type': 'text',
      'time': now,
    });

    final currentConvRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('conversations')
        .doc(widget.conversationId);

    await currentConvRef.update({
      'lastMessage': text,
      'lastMessageTime': now,
      'lastMessageType': 'text',
    });

    final peerConvRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.peerId)
        .collection('conversations')
        .doc(widget.conversationId);

    await peerConvRef.set({
      'lastMessage': text,
      'lastMessageTime': now,
      'lastMessageType': 'text',
      'unread': FieldValue.increment(1),
    }, SetOptions(merge: true));

    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndSendImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để gửi hình ảnh')),
      );
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    setState(() {
      _isSendingImage = true;
    });

    try {
      final file = File(pickedFile.path);
      if (!await file.exists()) {
        throw Exception('File ảnh không tồn tại trên thiết bị');
      }

      final now = Timestamp.now();
      final String currentUserId = user.uid;

      final storage = FirebaseStorage.instance;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$currentUserId.jpg';

      final ref = storage
          .ref()
          .child('chat_images')
          .child(widget.conversationId)
          .child(fileName);

      debugPrint('📤 Uploading to path: ${ref.fullPath}');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;

      if (snapshot.state != TaskState.success) {
        throw Exception('Upload ảnh thất bại: ${snapshot.state}');
      }

      final imageUrl = await ref.getDownloadURL();
      debugPrint('✅ Image uploaded, url: $imageUrl');

      final messageRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages');

      await messageRef.add({
        'senderId': currentUserId,
        'text': '',
        'imageUrl': imageUrl,
        'type': 'image',
        'time': now,
      });

      final currentConvRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('conversations')
          .doc(widget.conversationId);

      await currentConvRef.update({
        'lastMessage': '[Hình ảnh]',
        'lastMessageTime': now,
        'lastMessageType': 'image',
      });

      final peerConvRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.peerId)
          .collection('conversations')
          .doc(widget.conversationId);

      await peerConvRef.set({
        'lastMessage': '[Hình ảnh]',
        'lastMessageTime': now,
        'lastMessageType': 'image',
        'unread': FieldValue.increment(1),
      }, SetOptions(merge: true));

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } on FirebaseException catch (e) {
      debugPrint(
        '🔥 Firebase Storage error: code=${e.code}, message=${e.message}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi hình ảnh (Firebase): ${e.code}')),
      );
    } catch (e) {
      debugPrint('🔥 Other upload error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi gửi hình ảnh: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSendingImage = false;
        });
      }
    }
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildMessageContent(ChatMessage msg, Color textColor) {
    if (msg.type == 'image' &&
        msg.imageUrl != null &&
        msg.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          msg.imageUrl!,
          width: 150,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 150,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 150,
              height: 200,
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image),
            );
          },
        ),
      );
    }

    return Text(msg.text, style: TextStyle(color: textColor));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: const TextStyle(fontSize: 16)),
                Text(
                  'Đang hoạt động',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade200),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('conversations')
                    .doc(widget.conversationId)
                    .collection('messages')
                    .orderBy('time', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Lỗi tải tin nhắn: ${snapshot.error}'),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final messages = docs
                      .map((d) => ChatMessage.fromFirestore(d))
                      .toList();

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent,
                      );
                    }
                  });

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('Hãy bắt đầu cuộc trò chuyện đầu tiên!'),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe =
                          currentUser != null &&
                          msg.senderId == currentUser.uid;

                      final align = isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft;
                      final bgColor = isMe ? const Color.fromARGB(255, 41, 151, 241) : Colors.white;
                      final textColor = isMe ? Colors.white : Colors.black87;
                      final radius = BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      );

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        alignment: align,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: msg.type == 'image'
                                  ? const EdgeInsets.all(4)
                                  : const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                              decoration: BoxDecoration(
                                color: msg.type == 'image'
                                    ? Colors.transparent
                                    : bgColor,
                                borderRadius: radius,
                                boxShadow: [
                                  if (msg.type != 'image')
                                    BoxShadow(
                                      color: Colors.black.withAlpha(15),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                ],
                              ),
                              child: _buildMessageContent(msg, textColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(msg.time),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    onPressed: () {
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _pickAndSendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSendingImage ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 41, 151, 241),
                      ),
                      child: _isSendingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
