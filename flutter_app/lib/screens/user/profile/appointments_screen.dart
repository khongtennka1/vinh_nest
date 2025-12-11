import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:room_rental_app/screens/room_detail_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _appointmentsRef = FirebaseFirestore.instance.collection(
    'appointments',
  );
  final _notificationsRef = FirebaseFirestore.instance.collection(
    'notifications',
  );

  String _statusFilter = 'all';
  DateTimeRange? _dateRange;
  String _search = '';

  String _formatDate(Timestamp? t) {
    if (t == null) return '-';
    final dt = t.toDate();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>?> _resolveRoom(
    String roomId,
    String? hostelId,
  ) async {
    if (roomId.isEmpty) return null;
    try {
      final top = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();
      if (top.exists) {
        return Map<String, dynamic>.from(top.data() as Map<String, dynamic>);
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
          return data;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _updateStatus(String docId, String status) async {
    await _appointmentsRef.doc(docId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _cancelAppointment(String docId) async =>
      _updateStatus(docId, 'cancelled');
  Future<void> _confirmAppointment(String docId) async =>
      _updateStatus(docId, 'confirmed');
  Future<void> _rejectAppointment(String docId) async =>
      _updateStatus(docId, 'rejected');

  Future<void> _createAppointment({
    required String roomId,
    String? hostelId,
    required String ownerId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập')));
      return;
    }

    DateTime? pickedDate;
    TimeOfDay? pickedTime;
    String note = '';

    pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;

    pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (pickedTime == null) return;

    final scheduled = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghi chú cho chủ nhà (tuỳ chọn)'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: Tôi muốn xem vào buổi tối',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bỏ qua'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );

    if (confirmed == true) note = noteController.text.trim();

    final apptDoc = {
      'userId': user.uid,
      'userName': user.displayName ?? 'Khách thuê',
      'ownerId': ownerId,
      'roomId': roomId,
      'hostelId': hostelId ?? '',
      'scheduledAt': Timestamp.fromDate(scheduled),
      'status': 'pending',
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _appointmentsRef.add(apptDoc);

    await _notificationsRef.add({
      'toUid': ownerId,
      'type': 'new_appointment',
      'payload': {
        'appointmentId': docRef.id,
        'roomId': roomId,
        'scheduledAt': Timestamp.fromDate(scheduled),
        'from': user.displayName ?? 'Khách thuê',
      },
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yêu cầu đặt lịch đã được gửi')),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (result != null) setState(() => _dateRange = result);
  }

  Stream<QuerySnapshot> _baseStream() {
    return _appointmentsRef
        .orderBy('scheduledAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lịch hẹn xem phòng')),
        body: const Center(child: Text('Vui lòng đăng nhập để xem lịch hẹn')),
      );
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch hẹn xem phòng'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final s = await showDialog<String?>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Lọc trạng thái'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'all'),
                      child: const Text('Tất cả'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'pending'),
                      child: const Text('Chờ xác nhận'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'confirmed'),
                      child: const Text('Đã xác nhận'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'rejected'),
                      child: const Text('Đã từ chối'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, 'cancelled'),
                      child: const Text('Đã huỷ'),
                    ),
                  ],
                ),
              );
              if (s != null) setState(() => _statusFilter = s);
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) {
              final roomCtrl = TextEditingController();
              final ownerCtrl = TextEditingController();
              return AlertDialog(
                title: const Text('Tạo lịch hẹn mới (nhanh)'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: roomCtrl,
                      decoration: const InputDecoration(labelText: 'Room ID'),
                    ),
                    TextField(
                      controller: ownerCtrl,
                      decoration: const InputDecoration(labelText: 'Owner ID'),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Gợi ý: Tốt nhất tạo lịch từ trang chi tiết phòng',
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _createAppointment(
                        roomId: roomCtrl.text.trim(),
                        hostelId: null,
                        ownerId: ownerCtrl.text.trim(),
                      );
                    },
                    child: const Text('Tạo'),
                  ),
                ],
              );
            },
          );
        },
        label: const Text('Tạo lịch'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Tìm theo tên phòng, ghi chú...',
                      ),
                      onChanged: (v) =>
                          setState(() => _search = v.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_dateRange != null)
                    TextButton.icon(
                      icon: const Icon(Icons.close),
                      label: Text(
                        '${_dateRange!.start.day}/${_dateRange!.start.month} → ${_dateRange!.end.day}/${_dateRange!.end.month}',
                      ),
                      onPressed: () => setState(() => _dateRange = null),
                    ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _baseStream(),
                builder: (context, snap) {
                  if (snap.hasError)
                    return Center(child: Text('Lỗi: ${snap.error}'));
                  if (snap.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());

                  final docs = (snap.data?.docs ?? [])
                      .map(
                        (d) => Map<String, dynamic>.from(
                          d.data() as Map<String, dynamic>,
                        )..['__id'] = d.id,
                      )
                      .where((m) {
                        // fallback userId <- tenantId
                        final u =
                            (m['userId'] ?? m['tenantId'])?.toString() ?? '';
                        final o = m['ownerId']?.toString() ?? '';
                        if (u != uid && o != uid) return false;
                        if (_statusFilter != 'all' &&
                            (m['status']?.toString() ?? 'pending') !=
                                _statusFilter)
                          return false;

                        // thời gian: scheduledAt hoặc time
                        if (_dateRange != null) {
                          final ts =
                              (m['scheduledAt'] as Timestamp?) ??
                              (m['time'] as Timestamp?);
                          if (ts == null) return false;
                          final dt = ts.toDate();
                          if (dt.isBefore(_dateRange!.start) ||
                              dt.isAfter(
                                _dateRange!.end.add(const Duration(days: 1)),
                              ))
                            return false;
                        }

                        if (_search.isNotEmpty) {
                          final hay = ((m['title'] ?? m['note'] ?? ''))
                              .toString()
                              .toLowerCase();
                          if (!hay.contains(_search)) return false;
                        }
                        return true;
                      })
                      .toList();

                  if (docs.isEmpty)
                    return const Center(child: Text('Không tìm thấy lịch hẹn'));

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, idx) {
                      final appt = docs[idx];
                      final docId = appt['__id'] as String;
                      // scheduledAt fallback time
                      final scheduledAt =
                          (appt['scheduledAt'] as Timestamp?) ??
                          (appt['time'] as Timestamp?);
                      final status = (appt['status'] ?? 'pending').toString();
                      final isOwner =
                          (appt['ownerId']?.toString() ?? '') == uid;
                      final isRequester =
                          ((appt['userId'] ?? appt['tenantId'])?.toString() ??
                              '') ==
                          uid;
                      final roomId = appt['roomId'] as String? ?? '';
                      final hostelId = (appt['hostelId'] as String?) ?? '';

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _resolveRoom(roomId, hostelId),
                        builder: (context, roomSnap) {
                          final room = roomSnap.data;
                          final title = room != null
                              ? (room['title'] ?? room['roomNumber'] ?? 'Phòng')
                              : (appt['title'] ??
                                    appt['roomNumber'] ??
                                    'Phòng');
                          final subtitle = appt['note'] ?? '';

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Thời gian: ${_formatDate(scheduledAt)}',
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(
                                                status[0].toUpperCase() +
                                                    status.substring(1),
                                              ),
                                              backgroundColor:
                                                  status == 'confirmed'
                                                  ? Colors.green.withAlpha(30)
                                                  : (status == 'pending'
                                                        ? Colors.orange
                                                              .withAlpha(30)
                                                        : Colors.red.withAlpha(
                                                            30,
                                                          )),
                                            ),
                                            const SizedBox(width: 8),
                                            if (subtitle.toString().isNotEmpty)
                                              Expanded(
                                                child: Text(
                                                  'Ghi chú: ${subtitle}',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                        icon: const Icon(Icons.remove_red_eye),
                                        onPressed: roomId.isNotEmpty
                                            ? () async {
                                                // Nếu chưa resolve room, fetch trực tiếp trước khi push
                                                Map<String, dynamic>? passRoom =
                                                    room;
                                                String hostelIdToUse =
                                                    hostelId.isNotEmpty
                                                    ? hostelId
                                                    : (appt['hostelId'] ?? '');
                                                if (passRoom == null) {
                                                  try {
                                                    final top =
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection('rooms')
                                                            .doc(roomId)
                                                            .get();
                                                    if (top.exists) {
                                                      passRoom =
                                                          Map<
                                                            String,
                                                            dynamic
                                                          >.from(
                                                            top.data()
                                                                as Map<
                                                                  String,
                                                                  dynamic
                                                                >,
                                                          );
                                                    } else if ((hostelIdToUse ??
                                                            '')
                                                        .isNotEmpty) {
                                                      final sub =
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'hostels',
                                                              )
                                                              .doc(
                                                                hostelIdToUse,
                                                              )
                                                              .collection(
                                                                'rooms',
                                                              )
                                                              .doc(roomId)
                                                              .get();
                                                      if (sub.exists) {
                                                        passRoom =
                                                            Map<
                                                              String,
                                                              dynamic
                                                            >.from(
                                                              sub.data()
                                                                  as Map<
                                                                    String,
                                                                    dynamic
                                                                  >,
                                                            );
                                                        passRoom['__hostelId'] =
                                                            hostelIdToUse;
                                                      }
                                                    }
                                                  } catch (_) {}
                                                }

                                                final pass =
                                                    Map<String, dynamic>.from(
                                                      passRoom ?? appt,
                                                    );
                                                if (passRoom != null) {
                                                  pass['hostelId'] =
                                                      passRoom['__hostelId'] ??
                                                      passRoom['hostelId'] ??
                                                      appt['hostelId'];
                                                }

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        RoomDetailScreen(
                                                          room: pass,
                                                          roomId: roomId,
                                                        ),
                                                  ),
                                                );
                                              }
                                            : null,
                                      ),

                                      const SizedBox(height: 4),

                                      if (isRequester && status == 'pending')
                                        TextButton(
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Huỷ lịch hẹn',
                                                ),
                                                content: const Text(
                                                  'Bạn có chắc muốn huỷ lịch hẹn này?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: const Text('Hủy'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      'Huỷ',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true)
                                              await _cancelAppointment(docId);
                                          },
                                          child: const Text(
                                            'Huỷ',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        )
                                      else if (isOwner && status == 'pending')
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextButton(
                                              onPressed: () =>
                                                  _rejectAppointment(docId),
                                              child: const Text(
                                                'Từ chối',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _confirmAppointment(docId),
                                              child: const Text('Xác nhận'),
                                            ),
                                          ],
                                        )
                                      else if ((isRequester || isOwner) &&
                                          status == 'confirmed')
                                        TextButton(
                                          onPressed: () =>
                                              _cancelAppointment(docId),
                                          child: const Text(
                                            'Huỷ',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: docs.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
