import 'package:flutter/material.dart';
import '../ui/components/room_post_card.dart'; 

class MyRoomCard extends StatelessWidget {
  final Map<String, dynamic> roomData;
  final String roomId;
  final String? hostelId;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const MyRoomCard({
    super.key,
    required this.roomData,
    required this.roomId,
    this.hostelId,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final images = (roomData['images'] as List<dynamic>?) ?? [];
    final imageUrl = images.isNotEmpty ? images[0].toString() : '';
    final isAvailable = roomData['status'] == 'available';

    return Column(
      children: [
        RoomPostCard(
          title: roomData['title'] ?? 'Phòng trọ đẹp',
          price: '${roomData['price']?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ/tháng',
          address: roomData['address'] ?? 'Chưa có địa chỉ',
          district: roomData['district'] ?? 'Chưa xác định',
          availableRooms: isAvailable ? 1 : 0,
          imageUrl: imageUrl,
          isTrusted: roomData['isTrusted'] ?? false,
          ownerName: 'Bạn', 
        ),

        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleStatus,
                  icon: Icon(
                    isAvailable ? Icons.block : Icons.check_circle,
                    size: 18,
                    color: isAvailable ? Colors.red : Colors.green,
                  ),
                  label: Text(
                    isAvailable ? 'Đánh dấu đã thuê' : 'Mở lại phòng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isAvailable ? Colors.red : Colors.green[700],
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isAvailable ? Colors.red : Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              SizedBox(
                width: 90,
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Xóa', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}