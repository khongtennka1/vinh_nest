import 'dart:async';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:room_rental_app/models/hostel.dart';
import 'package:room_rental_app/screens/message/chat_detail_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final Map<String, dynamic> room;
  final String roomId;

  const RoomDetailScreen({super.key, required this.room, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  bool _isFavorite = false;
  StreamSubscription<QuerySnapshot>? _favSub;

  @override
  void initState() {
    super.initState();
    _initFavoriteListener();
  }

  @override
  void dispose() {
    _favSub?.cancel();
    super.dispose();
  }

  void _initFavoriteListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isFavorite = false);
      return;
    }

    _favSub = FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: uid)
        .where('roomId', isEqualTo: widget.roomId)
        .snapshots()
        .listen(
          (snap) {
            final isFav = snap.docs.isNotEmpty;
            if (mounted) setState(() => _isFavorite = isFav);
          },
          onError: (_) {
            if (mounted) setState(() => _isFavorite = false);
          },
        );
  }

  Future<void> _toggleFavorite(String roomId, String? hostelId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thêm yêu thích')),
      );
      return;
    }

    final uid = user.uid;
    final ownerId = widget.room['ownerId'] ?? '';
    if (ownerId.toString().isNotEmpty && ownerId == uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không thể thích phòng của chính mình'),
        ),
      );
      return;
    }

    final favRef = FirebaseFirestore.instance.collection('favorites');

    setState(() => _isFavorite = !_isFavorite);

    try {
      final snap = await favRef
          .where('userId', isEqualTo: uid)
          .where('roomId', isEqualTo: roomId)
          .where('hostelId', isEqualTo: hostelId)
          .get();

      if (snap.docs.isNotEmpty) {
        await favRef.doc(snap.docs.first.id).delete();
        return;
      }

      final room = widget.room;
      String? thumbnail;
      try {
        if (room['images'] is List && (room['images'] as List).isNotEmpty) {
          thumbnail = (room['images'] as List).first.toString();
        }
      } catch (_) {}

      final title = room['title'] ?? room['roomNumber'] ?? '';
      final price = room['price'];
      String address = '';
      try {
        if (room['address'] is Map) {
          final addr = Map<String, dynamic>.from(room['address']);
          address =
              '${addr['street'] ?? ''}${addr['ward'] != null && addr['street'] != null ? ', ' : ''}${addr['ward'] ?? ''}';
        } else if (room['address'] is String) {
          address = room['address'];
        }
      } catch (_) {}

      await favRef.add({
        'userId': uid,
        'roomId': roomId,
        'hostelId': hostelId,
        'ownerId': ownerId,
        'title': title,
        'price': price,
        'thumbnail': thumbnail,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật yêu thích: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hostelId = widget.room['hostelId'] as String?;

    if (hostelId == null || hostelId.isEmpty) {
      return _buildBasicDetail(context, widget.room);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('hostels')
          .doc(hostelId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        List<Map<String, dynamic>> services = [];
        if (snapshot.hasData && snapshot.data!.exists) {
          final hostelData = snapshot.data!.data() as Map<String, dynamic>;
          final hostel = Hostel.fromMap(hostelData, hostelId);
          services = hostel.customServices;
        }

        return _buildFullDetail(context, widget.room, services, hostelId);
      },
    );
  }

  Widget _buildBasicDetail(BuildContext context, Map<String, dynamic> room) {
    return _buildFullDetail(context, room, [], null);
  }

  Widget _buildFullDetail(
    BuildContext context,
    Map<String, dynamic> room,
    List<Map<String, dynamic>> services,
    String? hostelId,
  ) {
    final images = (room['images'] is List)
        ? List<String>.from(room['images'])
        : <String>[];
    final amenities = (room['amenities'] is List)
        ? List<String>.from(room['amenities'])
        : <String>[];
    final furniture = (room['furniture'] is List)
        ? List<String>.from(room['furniture'])
        : <String>[];
    final ownerId = (room['ownerId'] ?? '').toString();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.white70,
                      ),
                    )
                  : CarouselSlider(
                      options: CarouselOptions(
                        height: 300,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 4),
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
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () => _toggleFavorite(
                  widget.roomId,
                  widget.room['hostelId'] as String?,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
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
                      const Icon(Icons.home, color: Colors.orange, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          room['roomNumber']?.toString() ?? 'Phòng trọ',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${_formatPrice(room['price'])}đ/tháng',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    room['description']?.toString() ?? 'Không có mô tả',
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
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

                  const SizedBox(height: 30),
                  const Text(
                    'Phí dịch vụ cố định',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  services.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Chưa có phí dịch vụ',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: services.map((service) {
                            final name = service['name'] as String;
                            final price = (service['price'] as num).toDouble();
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.white.withAlpha(25),
                                child: Icon(
                                  _getServiceIcon(name),
                                  size: 18,
                                  color: Colors.orange,
                                ),
                              ),
                              label: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_formatPrice(price)}đ/${_getUnit(name)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.orange.withAlpha(15),
                              padding: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 24),
                  const Text(
                    'Nội thất',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: furniture
                        .map(
                          (item) => Chip(
                            label: Text(item),
                            backgroundColor: Colors.green.withAlpha(25),
                            labelStyle: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Tiện nghi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: amenities
                        .map(
                          (item) => Chip(
                            label: Text(item),
                            backgroundColor: Colors.blue.withAlpha(25),
                            labelStyle: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    'Phòng khác trong toà nhà',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  hostelId == null
                      ? const Text(
                          'Không có thông tin toà nhà',
                          style: TextStyle(color: Colors.grey),
                        )
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('hostels')
                              .doc(hostelId)
                              .collection('rooms')
                              .where('status', isEqualTo: 'available')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Hiện chưa có phòng khác',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            final otherRooms = snapshot.data!.docs
                                .where((doc) => doc.id != widget.roomId)
                                .take(10)
                                .map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  data['id'] = doc.id;
                                  return data;
                                })
                                .toList();

                            if (otherRooms.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Hiện chưa có phòng khác',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            return SizedBox(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: otherRooms.length,
                                itemBuilder: (context, i) {
                                  final r = otherRooms[i];
                                  final rImages =
                                      (r['images'] is List &&
                                          (r['images'] as List).isNotEmpty)
                                      ? (r['images'] as List)[0]
                                      : null;

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RoomDetailScreen(
                                            room: r,
                                            roomId: r['id'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 180,
                                      margin: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                            child: rImages != null
                                                ? Image.network(
                                                    rImages,
                                                    height: 110,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    height: 110,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.home,
                                                      size: 50,
                                                    ),
                                                  ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  r['roomNumber']?.toString() ??
                                                      'Phòng ${i + 1}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${_formatPrice(r['price'])}đ/tháng',
                                                  style: const TextStyle(
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.square_foot,
                                                      size: 14,
                                                      color: Colors.grey,
                                                    ),
                                                    Text(
                                                      ' ${r['area'] ?? '-'} m²',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      Icons.people,
                                                      size: 14,
                                                      color: Colors.grey,
                                                    ),
                                                    Text(
                                                      ' ${r['capacity'] ?? '-'} người',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.report, color: Colors.red),
                label: const Text('Báo cáo', style: TextStyle(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _openChat(context: context, ownerId: ownerId),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 15),
                label: const Text('Đặt lịch', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _createAppointment(
                    context: context,
                    roomId: widget.roomId,
                    ownerId: widget.room["ownerId"],
                  );
                },
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
        Icon(icon, color: Colors.orange, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  IconData _getServiceIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('điện')) return Icons.electrical_services;
    if (name.contains('nước')) return Icons.water_drop;
    if (name.contains('mạng') || name.contains('wifi')) return Icons.wifi;
    if (name.contains('xe')) return Icons.local_parking;
    if (name.contains('rác') || name.contains('vệ sinh')) return Icons.delete;
    return Icons.receipt_long;
  }

  String _getUnit(String name) {
    name = name.toLowerCase();
    if (name.contains('điện')) return 'kWh';
    if (name.contains('nước')) return 'm³';
    if (name.contains('mạng') || name.contains('wifi')) return 'phòng';
    if (name.contains('xe')) return 'xe';
    return 'tháng';
  }

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

  Future<void> _createAppointment({
    required BuildContext context,
    required String roomId,
    required String ownerId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt lịch')),
      );
      return;
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    final TextEditingController noteController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Đặt lịch xem phòng",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                          ),
                          child: Text(
                            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (d != null)
                              setModalState(() => selectedDate = d);
                          },
                        ),
                      ),
                    ],
                  ),

                  // chọn giờ
                  Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 10),
                      TextButton(
                        child: Text(selectedTime.format(ctx)),
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                          );
                          if (t != null) setModalState(() => selectedTime = t);
                        },
                      ),
                    ],
                  ),

                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: "Ghi chú (tùy chọn)",
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final DateTime schedule = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          try {
                            // Lưu document theo schema chuẩn AppointmentsScreen
                            final docRef = await FirebaseFirestore.instance
                                .collection("appointments")
                                .add({
                                  "roomId": roomId,
                                  "hostelId": widget.room["hostelId"] ?? '',
                                  // chuẩn hoá: userId + scheduledAt
                                  "userId": user.uid,
                                  "userName": user.displayName ?? 'Khách thuê',
                                  // giữ tenantId cho tương thích cũ
                                  "tenantId": user.uid,
                                  "ownerId": ownerId,
                                  "scheduledAt": Timestamp.fromDate(schedule),
                                  "time": Timestamp.fromDate(
                                    schedule,
                                  ), // giữ bản cũ
                                  "note": noteController.text.trim(),
                                  "status": "pending",
                                  "createdAt": FieldValue.serverTimestamp(),
                                });

                            // Tạo notification cho chủ nhà để hiển thị push/notification list
                            await FirebaseFirestore.instance
                                .collection("notifications")
                                .add({
                                  'toUid': ownerId,
                                  'type': 'new_appointment',
                                  'payload': {
                                    'appointmentId': docRef.id,
                                    'roomId': roomId,
                                    'scheduledAt': Timestamp.fromDate(schedule),
                                    'from': user.displayName ?? 'Khách thuê',
                                  },
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'read': false,
                                });

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Đặt lịch thành công!"),
                              ),
                            );
                          } catch (e) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Lỗi khi tạo lịch: \$e")),
                            );
                          }
                        },
                        child: const Text("Xác nhận"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
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

    await userConversationRef.set({
      'peerId': ownerId,
      'peerName': ownerName,
      'peerAvatarUrl': ownerAvatar,
      'lastMessage': '',
      'lastMessageTime': now,
      'unread': 0,
      'createdAt': now,
    });

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
