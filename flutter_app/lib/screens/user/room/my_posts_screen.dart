import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:room_rental_app/widgets/my_room_card.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý bài đăng')),
        body: const Center(child: Text('Vui lòng đăng nhập lại')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Quản lý bài đăng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('rooms')
            .where('ownerId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final roomId = docs[index].id;
              final hostelId = (docs[index].reference.parent.parent)?.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MyRoomCard(
                  roomData: data,
                  roomId: roomId,
                  hostelId: hostelId,
                  onDelete: () => _showDeleteConfirm(context, roomId, hostelId),
                  onToggleStatus: () => _toggleStatus(
                    roomId,
                    hostelId,
                    data['status'] == 'available',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 90, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'Bạn chưa có bài đăng nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/create_post');
            },
            icon: const Icon(Icons.add),
            label: const Text('Đăng tin ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    String? roomId,
    String? hostelId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài đăng?'),
        content: const Text('Bạn chắc chắn muốn xóa? Không thể khôi phục.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (roomId != null && hostelId != null) {
                await FirebaseFirestore.instance
                    .collection('hostels')
                    .doc(hostelId)
                    .collection('rooms')
                    .doc(roomId)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa bài đăng'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(
    String? roomId,
    String? hostelId,
    bool isAvailable,
  ) async {
    if (roomId == null || hostelId == null) return;

    await FirebaseFirestore.instance
        .collection('hostels')
        .doc(hostelId)
        .collection('rooms')
        .doc(roomId)
        .update({
          'status': isAvailable ? 'rented' : 'available',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
}
