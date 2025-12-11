import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:room_rental_app/screens/room_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final p = price is num
        ? price.toInt()
        : int.tryParse(price.toString()) ?? 0;
    return p.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Future<void> _removeFavorite(String favDocId) async {
    await FirebaseFirestore.instance
        .collection('favorites')
        .doc(favDocId)
        .delete();
  }

  // Try top-level then hostel subcollection. If found under hostel, attach '__hostelId'.
  Future<Map<String, dynamic>?> _resolveRoomDoc(
    String roomId,
    String? hostelId,
  ) async {
    try {
      final top = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();
      if (top.exists) {
        final data = Map<String, dynamic>.from(
          top.data() as Map<String, dynamic>,
        );
        data['__source'] = 'rooms';
        return data;
      }
    } catch (_) {}
    if (hostelId != null && hostelId.isNotEmpty) {
      try {
        final sub = await FirebaseFirestore.instance
            .collection('hostels')
            .doc(hostelId)
            .collection('rooms')
            .doc(roomId)
            .get();
        if (sub.exists) {
          final data = Map<String, dynamic>.from(
            sub.data() as Map<String, dynamic>,
          );
          data['__hostelId'] = hostelId;
          data['__source'] = 'hostels';
          return data;
        }
      } catch (_) {}
    }
    return null;
  }

  // Build a passable room map matching HomeScreen -> RoomDetailScreen expectations.
  Map<String, dynamic> _buildPassRoom(
    Map<String, dynamic> source,
    Map<String, dynamic> favMeta,
    String roomId,
  ) {
    // Source may be the actual room doc or fallback metadata (favMeta).
    final Map<String, dynamic> r = {};

    r['id'] = roomId;
    r['ownerId'] = source['ownerId'] ?? favMeta['ownerId'] ?? '';
    r['title'] = source['title'] ?? favMeta['title'] ?? '';
    r['roomNumber'] =
        source['roomNumber'] ?? favMeta['roomNumber'] ?? source['title'] ?? '';
    r['price'] = source['price'] ?? favMeta['price'] ?? 0;
    r['description'] = source['description'] ?? favMeta['description'] ?? '';
    r['images'] =
        (source['images'] is List && (source['images'] as List).isNotEmpty)
        ? List<String>.from(source['images'])
        : (favMeta['thumbnail'] != null ? [favMeta['thumbnail']] : <String>[]);
    r['floor'] = source['floor'] ?? favMeta['floor'] ?? '';
    r['area'] = source['area'] ?? favMeta['area'] ?? null;
    r['capacity'] = source['capacity'] ?? favMeta['capacity'] ?? null;
    r['createdAt'] = source['createdAt'] ?? favMeta['createdAt'] ?? null;
    r['updatedAt'] = source['updatedAt'] ?? favMeta['updatedAt'] ?? null;
    r['amenities'] = source['amenities'] ?? favMeta['amenities'] ?? [];
    r['furniture'] = source['furniture'] ?? favMeta['furniture'] ?? [];
    // ensure hostelId is present if we resolved from hostel subcollection or favMeta contains it
    r['hostelId'] =
        source['__hostelId'] ??
        source['hostelId'] ??
        favMeta['hostelId'] ??
        null;

    return r;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bài đăng yêu thích')),
        body: const Center(
          child: Text('Vui lòng đăng nhập để xem danh sách yêu thích'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài đăng yêu thích'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, favSnap) {
          if (favSnap.hasError)
            return Center(child: Text('Lỗi: ${favSnap.error}'));
          if (favSnap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final favDocs = favSnap.data?.docs ?? [];
          if (favDocs.isEmpty)
            return const Center(child: Text('Bạn chưa có bài đăng yêu thích'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favDocs.length,
            itemBuilder: (context, index) {
              final fav = favDocs[index];
              final favData = fav.data() as Map<String, dynamic>;
              final roomId = favData['roomId'] as String?;
              final hostelId = favData['hostelId'] as String?;

              if (roomId == null || roomId.isEmpty) {
                return Card(
                  child: ListTile(
                    title: const Text('Bài đăng không tồn tại'),
                    subtitle: const Text(
                      'Bài đăng đã bị xoá hoặc không hợp lệ',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeFavorite(fav.id),
                    ),
                  ),
                );
              }

              return FutureBuilder<Map<String, dynamic>?>(
                future: _resolveRoomDoc(roomId, hostelId),
                builder: (context, roomSnap) {
                  if (roomSnap.connectionState == ConnectionState.waiting) {
                    return Card(
                      child: ListTile(
                        title: const Text('Đang tải...'),
                        leading: Container(
                          width: 80,
                          height: 60,
                          color: Colors.grey[200],
                        ),
                      ),
                    );
                  }

                  final resolved = roomSnap.data; // may be null
                  final hasRoom = resolved != null;

                  // choose source: resolved room doc (best) or favorite metadata as fallback
                  final source = resolved ?? <String, dynamic>{};
                  final passRoom = _buildPassRoom(source, favData, roomId);

                  final images =
                      passRoom['images'] is List &&
                          (passRoom['images'] as List).isNotEmpty
                      ? List<String>.from(passRoom['images'])
                      : <String>[];
                  final thumbnail = images.isNotEmpty ? images.first : null;
                  final title =
                      passRoom['title'] ??
                      passRoom['roomNumber'] ??
                      'Phòng trọ';
                  final priceText = passRoom['price'] != null
                      ? '${_formatPrice(passRoom['price'])}đ/tháng'
                      : '—';
                  final addressDisplay = favData['address'] ?? '';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      onTap: hasRoom
                          ? () {
                              // Navigate with full passRoom map (matching HomeScreen shape)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoomDetailScreen(
                                    room: passRoom,
                                    roomId: roomId,
                                  ),
                                ),
                              );
                            }
                          : () {
                              // If no actual room doc but metadata exists, you can also push RoomDetailScreen (it will show metadata)
                              // Option A: open detail using metadata (uncomment to allow)
                              // Navigator.push(context, MaterialPageRoute(builder: (_) => RoomDetailScreen(room: passRoom, roomId: roomId)));
                              // Option B (default): inform user and let them delete
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Bài đăng đã bị xoá — bạn có thể xoá khỏi yêu thích.',
                                  ),
                                ),
                              );
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: thumbnail != null
                                  ? Image.network(
                                      thumbnail,
                                      width: 110,
                                      height: 82,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 110,
                                        height: 82,
                                        color: Colors.grey[200],
                                      ),
                                    )
                                  : Container(
                                      width: 110,
                                      height: 82,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.home,
                                        size: 36,
                                        color: Colors.white54,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    priceText,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          addressDisplay.toString(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Xoá khỏi yêu thích'),
                                        content: const Text(
                                          'Bạn có chắc muốn xoá bài đăng này khỏi danh sách yêu thích?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Hủy'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Xoá',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true)
                                      await _removeFavorite(fav.id);
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  favData['createdAt'] is Timestamp
                                      ? (favData['createdAt'] as Timestamp)
                                            .toDate()
                                            .toLocal()
                                            .toString()
                                            .split(' ')[0]
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
