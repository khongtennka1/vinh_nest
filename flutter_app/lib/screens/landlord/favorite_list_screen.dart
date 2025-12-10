import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:room_rental_app/screens/room_detail_screen.dart';
import 'package:room_rental_app/ui/components/room_post_card.dart';
import 'package:room_rental_app/models/room.dart';

class FavoriteListScreen extends StatefulWidget {
  const FavoriteListScreen({super.key});

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> {
  String? selectedRoomId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Danh sách yêu thích')),
        body: const Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách yêu thích'),
        backgroundColor: Colors.orange,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, favSnapshot) {
          if (favSnapshot.hasError) {
            return Center(child: Text("Lỗi: ${favSnapshot.error}"));
          }
          if (favSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favDocs = favSnapshot.data?.docs ?? [];

          if (favDocs.isEmpty) {
            return const Center(child: Text("Bạn chưa có phòng yêu thích"));
          }

          final roomIdList = favDocs
              .map((d) => (d.data() as Map<String, dynamic>)['roomId'] as String?)
              .where((id) => id != null)
              .cast<String>()
              .toList();

          final filteredFavDocs = selectedRoomId == null
              ? favDocs
              : favDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['roomId'] == selectedRoomId;
                }).toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFavDocs.length,
                  itemBuilder: (context, index) {
                    final favDoc = filteredFavDocs[index];
                    final favData = favDoc.data() as Map<String, dynamic>;

                    final hostelId = favData["hostelId"] as String? ?? "";
                    final roomId = favData["roomId"] as String? ?? "";

                    if (hostelId.isEmpty || roomId.isEmpty) {
                      return _buildInvalidFavoriteTile(favDoc.id);
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('hostels')
                          .doc(hostelId)
                          .collection('rooms')
                          .doc(roomId)
                          .get(),

                      builder: (context, roomSnap) {
                        if (roomSnap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (!roomSnap.hasData || !roomSnap.data!.exists) {
                          return _buildNonExistRoomTile(favDoc.id, hostelId, roomId);
                        }

                        final roomData = roomSnap.data!.data() as Map<String, dynamic>;

                        final room = Room.fromMap(
                          {...roomData, "id": roomId},
                          roomId,
                        );

                        final imageUrl = room.images.isNotEmpty
                            ? room.images.first
                            : 'https://via.placeholder.com/300';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              RoomPostCard(
                                title: '${room.title} - P.${room.roomNumber}',
                                price:
                                    '${room.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                        (m) => '${m[1]}.')}đ/tháng',
                                address: room.address,
                                district: 'TP. Vinh',
                                availableRooms: room.currentResidents < room.capacity ? 1 : 0,
                                imageUrl: imageUrl,
                                isTrusted: true,
                                ownerName: 'Bạn',
                              ),

                              Positioned(
                                top: 20,
                                right: 30,
                                child: GestureDetector(
                                  onTap: () async {
                                    await FirebaseFirestore.instance
                                        .collection('favorites')
                                        .doc(favDoc.id)
                                        .delete();
                                  },
                                    
                                    child: const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                      size: 22,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );

                      },
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildInvalidFavoriteTile(String favId) {
    return ListTile(
      leading: const Icon(Icons.error, color: Colors.red),
      title: const Text("Dữ liệu yêu thích bị lỗi"),
      subtitle: const Text("Thiếu hostelId hoặc roomId - hãy xóa mục này"),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          await FirebaseFirestore.instance.collection('favorites').doc(favId).delete();
        },
      ),
    );
  }

  Widget _buildNonExistRoomTile(String favId, String hostelId, String roomId) {
    return ListTile(
      leading: const Icon(Icons.home_outlined),
      title: const Text("Phòng không tồn tại"),
      subtitle: Text("Hostel: $hostelId - Room: $roomId"),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          await FirebaseFirestore.instance.collection('favorites').doc(favId).delete();
        },
      ),
    );
  }
}
