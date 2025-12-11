import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:room_rental_app/screens/message/chat_detail_screen.dart';

class OtherProfileScreen extends StatefulWidget {
  final String userId;
  const OtherProfileScreen({super.key, required this.userId});

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreen();
}

class _OtherProfileScreen extends State<OtherProfileScreen> {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  Future<_RelationStatus> _fetchRelationStatus(String otherId) async {
    if (_currentUid == null) return _RelationStatus.unknown;

    final myContactsDoc = await _fire
        .collection('users')
        .doc(_currentUid)
        .collection('contacts')
        .doc(otherId)
        .get();

    if (myContactsDoc.exists) {
      final blockedDoc = await _fire
          .collection('users')
          .doc(_currentUid)
          .collection('blocks')
          .doc(otherId)
          .get();
      if (blockedDoc.exists) return _RelationStatus.blocked;
      return _RelationStatus.friends;
    }

    final theirRequestsQuery = await _fire
        .collection('users')
        .doc(otherId)
        .collection('friend_requests')
        .where('from', isEqualTo: _currentUid)
        .limit(1)
        .get();
    if (theirRequestsQuery.docs.isNotEmpty) return _RelationStatus.requested;

    final myRequestsQuery = await _fire
        .collection('users')
        .doc(_currentUid)
        .collection('friend_requests')
        .where('from', isEqualTo: otherId)
        .limit(1)
        .get();
    if (myRequestsQuery.docs.isNotEmpty) return _RelationStatus.received;

    final blockedDoc = await _fire
        .collection('users')
        .doc(_currentUid)
        .collection('blocks')
        .doc(otherId)
        .get();
    if (blockedDoc.exists) return _RelationStatus.blocked;

    return _RelationStatus.notFriends;
  }

  Future<void> _sendFriendRequest(String otherId) async {
    if (_currentUid == null) return;

    final myDoc = await _fire.collection('users').doc(_currentUid).get();
    final myName = (myDoc.data()?['name'] ?? '') as String;
    final myAvatar = (myDoc.data()?['avatar'] ?? '') as String;

    final docRef = _fire
        .collection('users')
        .doc(otherId)
        .collection('friend_requests')
        .doc();

    await docRef.set({
      'from': _currentUid,
      'name': myName,
      'avatar': myAvatar,
      'sentAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi lời mời kết bạn')));
      setState(() {});
    }
  }

  Future<void> _acceptFriend(
    String otherId,
    String otherName,
    String otherAvatar,
  ) async {
    if (_currentUid == null) return;

    final myDoc = await _fire.collection('users').doc(_currentUid).get();
    await _fire.collection('users').doc(otherId).get();

    final myName = (myDoc.data()?['name'] ?? '') as String;
    final myAvatar = (myDoc.data()?['avatar'] ?? '') as String;

    final ids = [_currentUid!, otherId]..sort();
    final convoId = '${ids[0]}_${ids[1]}';
    final convoRef = _fire.collection('conversations').doc(convoId);
    final convoSnap = await convoRef.get();
    if (!convoSnap.exists) {
      await convoRef.set({
        'id': convoId,
        'members': [_currentUid!, otherId],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final batch = _fire.batch();

    final myContactRef = _fire
        .collection('users')
        .doc(_currentUid)
        .collection('contacts')
        .doc(otherId);
    final theirContactRef = _fire
        .collection('users')
        .doc(otherId)
        .collection('contacts')
        .doc(_currentUid);

    batch.set(myContactRef, {
      'peerId': otherId,
      'name': otherName,
      'avatar': otherAvatar,
      'conversationId': convoId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(theirContactRef, {
      'peerId': _currentUid,
      'name': myName,
      'avatar': myAvatar,
      'conversationId': convoId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final reqsSnapshot = await _fire
        .collection('users')
        .doc(_currentUid)
        .collection('friend_requests')
        .where('from', isEqualTo: otherId)
        .get();
    for (final d in reqsSnapshot.docs) batch.delete(d.reference);

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chấp nhận lời mời kết bạn')),
      );
      setState(() {});
    }
  }

  Future<void> _removeFriend(String otherId) async {
    if (_currentUid == null) return;
    final batch = _fire.batch();
    final myContactRef = _fire
        .collection('users')
        .doc(_currentUid)
        .collection('contacts')
        .doc(otherId);
    final theirContactRef = _fire
        .collection('users')
        .doc(otherId)
        .collection('contacts')
        .doc(_currentUid);
    batch.delete(myContactRef);
    batch.delete(theirContactRef);
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Huỷ kết bạn thành công')));
      setState(() {});
    }
  }

  Future<void> _cancelSentRequest(String otherId) async {
    if (_currentUid == null) return;
    final q = await _fire
        .collection('users')
        .doc(otherId)
        .collection('friend_requests')
        .where('from', isEqualTo: _currentUid)
        .get();
    final batch = _fire.batch();
    for (final d in q.docs) batch.delete(d.reference);
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã huỷ lời mời')));
      setState(() {});
    }
  }

  Future<void> _blockUser(String otherId) async {
    if (_currentUid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chặn người dùng'),
        content: const Text(
          'Bạn có chắc chắn muốn chặn người dùng này? Hành động này sẽ huỷ kết bạn và chặn họ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Chặn', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final batch = _fire.batch();
    final blockRef = _fire
        .collection('users')
        .doc(_currentUid)
        .collection('blocks')
        .doc(otherId);
    batch.set(blockRef, {'blockedAt': FieldValue.serverTimestamp()});

    final myContactRef = _fire
        .collection('users')
        .doc(_currentUid)
        .collection('contacts')
        .doc(otherId);
    final theirContactRef = _fire
        .collection('users')
        .doc(otherId)
        .collection('contacts')
        .doc(_currentUid);
    batch.delete(myContactRef);
    batch.delete(theirContactRef);

    final theirReqs = await _fire
        .collection('users')
        .doc(_currentUid)
        .collection('friend_requests')
        .where('from', isEqualTo: otherId)
        .get();
    for (final d in theirReqs.docs) batch.delete(d.reference);

    final mySent = await _fire
        .collection('users')
        .doc(otherId)
        .collection('friend_requests')
        .where('from', isEqualTo: _currentUid)
        .get();
    for (final d in mySent.docs) batch.delete(d.reference);

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã chặn người dùng')));
      setState(() {});
    }
  }

  Future<void> _unblockUser(String otherId) async {
    if (_currentUid == null) return;
    final blockRef = _fire
        .collection('users')
        .doc(_currentUid)
        .collection('blocks')
        .doc(otherId);
    await blockRef.delete();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã bỏ chặn')));
      setState(() {});
    }
  }

  Widget _buildHeader(String name, String avatar, String phone, String gender) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'user_avatar_${widget.userId}',
            child: Container(
              width: 140,
              height: 140,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 4),
                borderRadius: BorderRadius.circular(80),
              ),
              child: CircleAvatar(
                radius: 66,
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : const AssetImage('assets/images/avatar_default.png')
                          as ImageProvider,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        phone.isNotEmpty ? phone : 'Chưa có số điện thoại',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (gender.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.wc, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        gender,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _styledPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    Color? background,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background ?? Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _styledOutlinedButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  // ------------------ helper to generate conversationId ------------------
  String _generateConversationId(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}-${list[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _fire.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F5),
            body: Center(child: CircularProgressIndicator(color: Colors.red)),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F5),
            body: Center(child: Text('Không tìm thấy người dùng')),
          );
        }

        final data = snap.data!.data()!;
        final name = (data['name'] as String?) ?? '';
        final avatar = (data['avatar'] as String?) ?? '';
        final phone = (data['phone'] as String?) ?? '';
        final bio = (data['bio'] as String?) ?? '';
        final gender = (data['gender'] as String?) ?? '';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.red,
            title: const Text(
              'Trang cá nhân',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: true,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          body: FutureBuilder<_RelationStatus>(
            future: _fetchRelationStatus(widget.userId),
            builder: (context, relSnap) {
              final relation = relSnap.data ?? _RelationStatus.unknown;

              return ListView(
                children: [
                  _buildHeader(name, avatar, phone, gender),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (bio.isNotEmpty) ...[
                          const Text(
                            'Giới thiệu',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(bio),
                          const SizedBox(height: 16),
                        ],
                        if (createdAt != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tham gia: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 8),

                        if (_currentUid == null) ...[
                          _styledPrimaryButton(
                            label: 'Đăng nhập để nhắn tin',
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vui lòng đăng nhập'),
                                  ),
                                ),
                          ),
                        ] else ...[
                          if (relation == _RelationStatus.notFriends) ...[
                            _styledPrimaryButton(
                              label: 'Thêm bạn',
                              onPressed: () =>
                                  _sendFriendRequest(widget.userId),
                            ),
                            const SizedBox(height: 10),
                            _styledOutlinedButton(
                              label: 'Chặn',
                              onPressed: () => _blockUser(widget.userId),
                            ),
                          ] else if (relation == _RelationStatus.requested) ...[
                            _styledOutlinedButton(
                              label: 'Đã gửi yêu cầu (Huỷ)',
                              onPressed: () =>
                                  _cancelSentRequest(widget.userId),
                            ),
                            const SizedBox(height: 10),
                            _styledOutlinedButton(
                              label: 'Chặn',
                              onPressed: () => _blockUser(widget.userId),
                            ),
                          ] else if (relation == _RelationStatus.received) ...[
                            _styledPrimaryButton(
                              label: 'Chấp nhận lời mời',
                              onPressed: () =>
                                  _acceptFriend(widget.userId, name, avatar),
                              background: Colors.green,
                            ),
                            const SizedBox(height: 10),
                            _styledOutlinedButton(
                              label: 'Từ chối',
                              onPressed: () async {
                                final reqs = await _fire
                                    .collection('users')
                                    .doc(_currentUid)
                                    .collection('friend_requests')
                                    .where('from', isEqualTo: widget.userId)
                                    .get();
                                final batch = _fire.batch();
                                for (final d in reqs.docs)
                                  batch.delete(d.reference);
                                await batch.commit();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã từ chối lời mời'),
                                    ),
                                  );
                                  setState(() {});
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            _styledOutlinedButton(
                              label: 'Chặn',
                              onPressed: () => _blockUser(widget.userId),
                            ),
                          ] else if (relation == _RelationStatus.friends) ...[
                            _styledPrimaryButton(
                              label: 'Nhắn tin',
                              onPressed: () async {
                                try {
                                  final currentUser =
                                      FirebaseAuth.instance.currentUser;
                                  if (currentUser == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vui lòng đăng nhập'),
                                      ),
                                    );
                                    return;
                                  }

                                  final meId = currentUser.uid;
                                  final peerId = widget.userId;

                                  // Tạo conversationId cố định (giống RoomDetailScreen)
                                  final conversationId =
                                      _generateConversationId(meId, peerId);

                                  // prepare conversation doc ref
                                  final convoRef = _fire
                                      .collection('conversations')
                                      .doc(conversationId);
                                  final convoSnap = await convoRef.get();

                                  if (!convoSnap.exists) {
                                    await convoRef.set({
                                      'id': conversationId,
                                      'members': [meId, peerId],
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                  }

                                  // Lấy thông tin current user để lưu vào contact (name/avatar)
                                  final myDoc = await _fire
                                      .collection('users')
                                      .doc(meId)
                                      .get();
                                  final myName =
                                      (myDoc.data()?['name'] ?? '') as String;
                                  final myAvatar =
                                      (myDoc.data()?['avatar'] ?? '') as String;

                                  // Cập nhật contacts cho cả hai bên (merge để không ghi đè)
                                  await _fire
                                      .collection('users')
                                      .doc(meId)
                                      .collection('contacts')
                                      .doc(peerId)
                                      .set({
                                        'peerId': peerId,
                                        'name': name,
                                        'avatar': avatar,
                                        'conversationId': conversationId,
                                        'updatedAt':
                                            FieldValue.serverTimestamp(),
                                      }, SetOptions(merge: true));

                                  await _fire
                                      .collection('users')
                                      .doc(peerId)
                                      .collection('contacts')
                                      .doc(meId)
                                      .set({
                                        'peerId': meId,
                                        'name': myName,
                                        'avatar': myAvatar,
                                        'conversationId': conversationId,
                                        'updatedAt':
                                            FieldValue.serverTimestamp(),
                                      }, SetOptions(merge: true));

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatDetailScreen(
                                        userName: name,
                                        conversationId: conversationId,
                                        peerId: peerId,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Lỗi mở cuộc trò chuyện: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            _styledOutlinedButton(
                              label: 'Bạn bè (Huỷ kết bạn)',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Huỷ kết bạn'),
                                    content: const Text(
                                      'Bạn có chắc muốn huỷ kết bạn?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Huỷ'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text(
                                          'Huỷ kết bạn',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true)
                                  await _removeFriend(widget.userId);
                              },
                            ),
                            const SizedBox(height: 10),
                            _styledOutlinedButton(
                              label: 'Chặn',
                              onPressed: () => _blockUser(widget.userId),
                            ),
                          ] else if (relation == _RelationStatus.blocked) ...[
                            _styledOutlinedButton(
                              label: 'Bỏ chặn',
                              onPressed: () => _unblockUser(widget.userId),
                            ),
                          ],
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          '© 2025 VINHNEST JSC',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Phiên bản 1.0.0',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

enum _RelationStatus {
  unknown,
  notFriends,
  requested,
  received,
  friends,
  blocked,
}
