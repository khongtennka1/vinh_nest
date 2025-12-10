import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:room_rental_app/models/conversation.dart';
import 'package:room_rental_app/screens/message/chat_detail_screen.dart';
import 'package:room_rental_app/screens/user/profile/other_profile_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập để xem tin nhắn')),
      );
    }
    final String currentUserId = user.uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tin nhắn'),
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tin nhắn'),
              Tab(text: 'Danh bạ'),
              Tab(text: 'Lời mời'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Tìm kiếm...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMessagesTab(currentUserId),
                  _buildContactsTab(currentUserId),
                  _buildRequestsTab(currentUserId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesTab(String currentUserId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('conversations')
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải tin nhắn: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        final allConversations = docs
            .map((doc) => Conversation.fromFirestore(doc))
            .toList();

        final filtered = allConversations
            .where(
              (c) => c.name.toLowerCase().contains(
                _searchText.toLowerCase().trim(),
              ),
            )
            .toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('Chưa có cuộc trò chuyện nào'));
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade300),
          itemBuilder: (context, index) {
            final c = filtered[index];

            return Slidable(
              key: ValueKey(c.id),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (ctx) async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUserId)
                          .collection('conversations')
                          .doc(c.id)
                          .update({'unread': 1});
                    },
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    icon: Icons.markunread,
                    label: 'Chưa đọc',
                  ),
                  SlidableAction(
                    onPressed: (ctx) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Xoá cuộc trò chuyện'),
                            content: Text(
                              'Bạn có chắc muốn xoá cuộc trò chuyện với "${c.name}" không?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Huỷ'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text(
                                  'Xoá',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUserId)
                            .collection('conversations')
                            .doc(c.id)
                            .delete();
                      }
                    },
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Xoá',
                  ),
                ],
              ),

              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(c.peerId)
                    .snapshots(),
                builder: (context, userSnap) {
                  String displayName = c.name;
                  String avatarUrl = c.avatarUrl;

                  if (userSnap.hasData && userSnap.data!.exists) {
                    final data = userSnap.data!.data()!;
                    displayName = (data['name'] as String?) ?? displayName;
                    avatarUrl = (data['avatar'] as String?) ?? avatarUrl;
                  }

                  return ListTile(
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUserId)
                          .collection('conversations')
                          .doc(c.id)
                          .update({'unread': 0});

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            userName: displayName,
                            conversationId: c.id,
                            peerId: c.peerId,
                          ),
                        ),
                      );
                    },
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: (avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl.isEmpty
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      c.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(c.time),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (c.unread > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${c.unread}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContactsTab(String currentUserId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        final filtered = docs.where((doc) {
          final data = doc.data();
          final name = (data['name'] as String?) ?? '';
          return name.toLowerCase().contains(_searchText.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('Chưa có danh bạ'));
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade300),
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data();
            final peerId = (data['peerId'] as String?) ?? '';
            final name = (data['name'] as String?) ?? 'Không tên';
            final avatar = (data['avatar'] as String?) ?? '';
            final conversationId = (data['conversationId'] as String?) ?? '';

            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: (avatar.isNotEmpty)
                    ? NetworkImage(avatar)
                    : null,
                child: avatar.isEmpty
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                    : null,
              ),
              title: Text(name),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtherProfileScreen(userId: peerId),
                  ),
                );
              },

              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == "chat") {
                    try {
                      String convoId = conversationId;
                      if (convoId.isEmpty) {
                        convoId = await _createConversationForUsers(
                          currentUserId,
                          peerId,
                          name,
                          avatar,
                        );

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUserId)
                            .collection('contacts')
                            .doc(doc.id)
                            .set({
                              'conversationId': convoId,
                            }, SetOptions(merge: true));

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(peerId)
                            .collection('contacts')
                            .doc(currentUserId)
                            .set({
                              'conversationId': convoId,
                            }, SetOptions(merge: true));
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            userName: name,
                            conversationId: convoId,
                            peerId: peerId,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi mở cuộc trò chuyện: $e')),
                      );
                    }
                  } else if (value == "remove") {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Xóa bạn"),
                        content: Text(
                          "Bạn có chắc muốn xóa \"$name\" khỏi danh bạ không?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Huỷ"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              "Xóa",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _removeFriendFromContacts(currentUserId, peerId);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: "chat", child: Text("Nhắn tin")),
                  const PopupMenuItem(value: "remove", child: Text("Xóa bạn")),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsTab(String currentUserId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friend_requests')
          .orderBy('sentAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        final filtered = docs.where((doc) {
          final data = doc.data();
          final name = (data['name'] as String?) ?? '';
          return name.toLowerCase().contains(_searchText.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('Không có lời mời kết bạn'));
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade300),
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data();
            final requesterId = (data['from'] as String?) ?? '';
            final name = (data['name'] as String?) ?? 'Người dùng';
            final avatar = (data['avatar'] as String?) ?? '';

            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: (avatar.isNotEmpty)
                    ? NetworkImage(avatar)
                    : null,
                child: avatar.isEmpty
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                    : null,
              ),
              title: Text(name),
              subtitle: Text('Đã gửi lời mời'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      await _acceptFriendRequest(
                        currentUserId,
                        doc.id,
                        requesterId,
                        name,
                        avatar,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUserId)
                          .collection('friend_requests')
                          .doc(doc.id)
                          .delete();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _acceptFriendRequest(
    String currentUserId,
    String requestDocId,
    String fromUserId,
    String name,
    String avatar,
  ) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final senderSnap = await firestore
          .collection('users')
          .doc(fromUserId)
          .get();
      final senderData = senderSnap.data() ?? {};
      final senderName = (senderData['name'] as String?) ?? name;
      final senderAvatar = (senderData['avatar'] as String?) ?? avatar;

      final myProfileSnap = await firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      final myProfile = myProfileSnap.data() ?? {};
      final myName = (myProfile['name'] as String?) ?? '';
      final myAvatar = (myProfile['avatar'] as String?) ?? '';

      final batch = firestore.batch();

      final myContactRef = firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(fromUserId);

      final theirContactRef = firestore
          .collection('users')
          .doc(fromUserId)
          .collection('contacts')
          .doc(currentUserId);

      batch.set(myContactRef, {
        'peerId': fromUserId,
        'name': senderName,
        'avatar': senderAvatar,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(theirContactRef, {
        'peerId': currentUserId,
        'name': myName,
        'avatar': myAvatar,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final requestRef = firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friend_requests')
          .doc(requestDocId);

      batch.delete(requestRef);

      await batch.commit();

      final convoId = await _createConversationForUsers(
        currentUserId,
        fromUserId,
        senderName,
        senderAvatar,
        meName: myName,
        meAvatar: myAvatar,
      );

      await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(fromUserId)
          .set({'conversationId': convoId}, SetOptions(merge: true));

      await firestore
          .collection('users')
          .doc(fromUserId)
          .collection('contacts')
          .doc(currentUserId)
          .set({'conversationId': convoId}, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chấp nhận lời mời và lưu vào danh bạ'),
          ),
        );
        setState(() {});
      }
    } catch (e, st) {
      debugPrint('Lỗi acceptFriendRequest: $e\n$st');
      final msg = e.toString().toLowerCase().contains('permission_denied')
          ? 'Không có quyền ghi vào contacts của người khác. Kiểm tra Firestore rules hoặc dùng Cloud Function.'
          : 'Lỗi khi chấp nhận lời mời: $e';

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<String> _createConversationForUsers(
    String meId,
    String peerId,
    String peerName,
    String peerAvatar, {
    String? meName,
    String? meAvatar,
  }) async {
    final firestore = FirebaseFirestore.instance;

    String finalMeName = meName ?? '';
    String finalMeAvatar = meAvatar ?? '';
    if (finalMeName.isEmpty || finalMeAvatar.isEmpty) {
      final mySnap = await firestore.collection('users').doc(meId).get();
      final myData = mySnap.data() ?? {};
      finalMeName = (myData['name'] as String?) ?? finalMeName;
      finalMeAvatar = (myData['avatar'] as String?) ?? finalMeAvatar;
    }

    final ids = [meId, peerId]..sort();
    final convoId = ids.join('_');

    final myConvoRef = firestore
        .collection('users')
        .doc(meId)
        .collection('conversations')
        .doc(convoId);

    final theirConvoRef = firestore
        .collection('users')
        .doc(peerId)
        .collection('conversations')
        .doc(convoId);

    final now = FieldValue.serverTimestamp();

    final mySnapshot = await myConvoRef.get();
    if (!mySnapshot.exists) {
      await myConvoRef.set({
        'id': convoId,
        'peerId': peerId,
        'name': peerName,
        'avatarUrl': peerAvatar,
        'lastMessage': '',
        'lastMessageTime': now,
        'unread': 0,
      }, SetOptions(merge: true));
    } else {
      await myConvoRef.set({
        'peerId': peerId,
        'name': peerName,
        'avatarUrl': peerAvatar,
      }, SetOptions(merge: true));
    }

    final theirSnapshot = await theirConvoRef.get();
    if (!theirSnapshot.exists) {
      await theirConvoRef.set({
        'id': convoId,
        'peerId': meId,
        'name': finalMeName,
        'avatarUrl': finalMeAvatar,
        'lastMessage': '',
        'lastMessageTime': now,
        'unread': 0,
      }, SetOptions(merge: true));
    } else {
      await theirConvoRef.set({
        'peerId': meId,
        'name': finalMeName,
        'avatarUrl': finalMeAvatar,
      }, SetOptions(merge: true));
    }

    return convoId;
  }

  Future<void> _removeFriendFromContacts(String meId, String peerId) async {
    final firestore = FirebaseFirestore.instance;

    final batch = firestore.batch();

    final myContactRef = firestore
        .collection('users')
        .doc(meId)
        .collection('contacts')
        .doc(peerId);

    final theirContactRef = firestore
        .collection('users')
        .doc(peerId)
        .collection('contacts')
        .doc(meId);

    batch.delete(myContactRef);
    batch.delete(theirContactRef);

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã xóa bạn khỏi danh bạ")));
    }
  }
}
