import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:room_rental_app/screens/message/chat_detail_screen.dart';

class RoomDetailScreen extends StatelessWidget {
  final Map<String, dynamic> room;
  final String roomId;

  const RoomDetailScreen({super.key, required this.room, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final images = (room['images'] is List)
        ? List<String>.from(room['images'].map((e) => e.toString()))
        : <String>[];

    final amenities = (room['amenities'] is List)
        ? List<String>.from(room['amenities'].map((e) => e.toString()))
        : <String>[];

    final furniture = (room['furniture'] is List)
        ? List<String>.from(room['furniture'].map((e) => e.toString()))
        : <String>[];

    final String ownerId = (room['ownerId'] ?? '').toString();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? const Center(
                      child: Icon(Icons.image_not_supported, size: 80),
                    )
                  : CarouselSlider(
                      options: CarouselOptions(
                        height: 300,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        autoPlay: true,
                      ),
                      items: images
                          .map(
                            (url) => Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            ),
                          )
                          .toList(),
                    ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.home, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        room['roomNumber']?.toString() ?? 'Phòng trọ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_formatPrice(room['price'])}đ/tháng',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    room['description']?.toString() ?? 'Không có mô tả',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoChip(
                        Icons.stairs,
                        'Tầng',
                        room['floor']?.toString() ?? '—',
                      ),
                      _infoChip(
                        Icons.square_foot,
                        'Diện tích',
                        '${room['area'] ?? '-'} m²',
                      ),
                      _infoChip(
                        Icons.people,
                        'Sức chứa',
                        '${room['capacity'] ?? '-'} người',
                      ),
                      _infoChip(Icons.attach_money, 'Đặt cọc', '1 tháng'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('Phí dịch vụ'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _serviceChip(
                        Icons.electrical_services,
                        'Điện',
                        '${room['electricPrice'] ?? '0'}đ/kWh',
                      ),
                      _serviceChip(
                        Icons.water_drop,
                        'Nước',
                        '${room['waterPrice'] ?? '0'}đ/m³',
                      ),
                      _serviceChip(
                        Icons.wifi,
                        'Mạng',
                        '${room['wifiPrice'] ?? '0'}đ/phòng',
                      ),
                      _serviceChip(
                        Icons.cleaning_services,
                        'Dịch vụ chung',
                        '${room['serviceFee'] ?? '0'}đ/người',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('Nội thất'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: furniture
                        .map(
                          (item) => Chip(
                            label: Text(item),
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            labelStyle: const TextStyle(color: Colors.orange),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('Tiện nghi'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: amenities
                        .map(
                          (item) => Chip(
                            label: Text(item),
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            labelStyle: const TextStyle(color: Colors.blue),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('Đánh giá'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '0.0',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(
                          5,
                          (i) => const Icon(
                            Icons.star_border,
                            size: 20,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('0 đánh giá'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('Bài đăng liên quan'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (ctx, i) => Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://via.placeholder.com/160',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'HOMESTAY MỚI...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Từ 1.100.000đ/tháng',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.report, color: Colors.red),
                label: const Text('Báo cáo'),
                onPressed: () {},
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat'),
                onPressed: () => _openChat(context: context, ownerId: ownerId),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text('Đặt lịch xem phòng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _serviceChip(IconData icon, String label, String price) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Text(price, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final p = (price is num)
        ? price.toInt()
        : int.tryParse(price.toString()) ?? 0;
    return p.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

Future<void> _openChat({
  required BuildContext context,
  required String ownerId,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để chat')));
    return;
  }

  final String currentUserId = currentUser.uid;
  final String currentUserName = currentUser.displayName ?? 'Khách thuê';
  final String currentUserAvatar =
      currentUser.photoURL ?? 'https://i.pravatar.cc/150?u=$currentUserId';

  if (ownerId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không tìm thấy chủ phòng (ownerId rỗng)')),
    );
    return;
  }

  if (ownerId == currentUserId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bạn không thể chat với chính mình')),
    );
    return;
  }

  final ownerSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(ownerId)
      .get();

  if (!ownerSnap.exists) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không tìm thấy thông tin chủ phòng')),
    );
    return;
  }

  final ownerData = ownerSnap.data() as Map<String, dynamic>;
  final String ownerName = ownerData['name'] ?? 'Chủ phòng';
  final String ownerAvatar =
      ownerData['avatar'] ?? 'https://i.pravatar.cc/150?u=$ownerId';

  final String conversationId = currentUserId.compareTo(ownerId) < 0
      ? '$currentUserId-$ownerId'
      : '$ownerId-$currentUserId';

  final userConversationRef = FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('conversations')
      .doc(conversationId);

  final ownerConversationRef = FirebaseFirestore.instance
      .collection('users')
      .doc(ownerId)
      .collection('conversations')
      .doc(conversationId);

  final doc = await userConversationRef.get();

  if (!doc.exists) {
    final now = Timestamp.now();

    // conversation phía người thuê
    await userConversationRef.set({
      'peerId': ownerId,
      'peerName': ownerName,
      'peerAvatarUrl': ownerAvatar,
      'lastMessage': '',
      'lastMessageTime': now,
      'unread': 0,
      'createdAt': now,
    });

    // conversation phía chủ phòng
    await ownerConversationRef.set({
      'peerId': currentUserId,
      'peerName': currentUserName,
      'peerAvatarUrl': currentUserAvatar,
      'lastMessage': '',
      'lastMessageTime': now,
      'unread': 0,
      'createdAt': now,
    });
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatDetailScreen(
        userName: ownerName,
        conversationId: conversationId,
        peerId: ownerId,
      ),
    ),
  );
}
