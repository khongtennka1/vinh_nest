import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_rental_app/providers/user_provider.dart';
import 'package:room_rental_app/providers/auth_provider.dart' as MyAuth;
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;

        if (userProvider.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F5),
            body: Center(child: CircularProgressIndicator(color: Colors.red)),
          );
        }

        if (user == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F5),
            body: Center(child: Text('Không tải được thông tin người dùng')),
          );
        }

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 230, 77, 66),
            title: const Text('Cá nhân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            centerTitle: true,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            children: [
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 230, 77, 66),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 33,
                          backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                              ? NetworkImage(user.avatar!)
                              : const AssetImage('assets/images/avatar_default.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(user.phone ?? 'Chưa cập nhật số điện thoại', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('contracts')
                      .where('landlordId', isEqualTo: uid)
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
                  builder: (context, contractSnapshot) {
                    int totalTenants = 0;
                    if (contractSnapshot.hasData) {
                      for (var doc in contractSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        totalTenants += 1;
                        final members = data['additionalMembers'] as List<dynamic>? ?? [];
                        totalTenants += members.length;
                      }
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('hostels')
                          .where('ownerId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, hostelSnapshot) {
                        if (!hostelSnapshot.hasData) {
                          return _buildLoadingStats();
                        }

                        final hostelDocs = hostelSnapshot.data!.docs;

                        return FutureBuilder<Map<String, int>>(
                          future: _countRoomsFromHostels(hostelDocs),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return _buildLoadingStats();
                            }

                            final counts = snapshot.data!;
                            final totalRooms = counts['total'] ?? 0;
                            final rentedRooms = counts['rented'] ?? 0;
                            final availableRooms = counts['available'] ?? 0;

                            return _buildStatCard(
                              totalRooms: totalRooms,
                              rentedRooms: rentedRooms,
                              availableRooms: availableRooms,
                              totalTenants: totalTenants,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              _menuItem(context, Icons.card_giftcard, 'Giới thiệu & nhận thưởng'),
              _menuItem(context, Icons.favorite, 'Danh sách yêu thích phòng', onTap: () {
                Navigator.pushNamed(context, '/favorite-list');
              }),
              _menuItem(context, Icons.account_balance_wallet_outlined, 'Quản lý tài sản'),
              _menuItem(context, Icons.receipt_long, 'Quản lý đơn hàng dịch vụ'),
              _menuItem(context, Icons.report_problem_outlined, 'Báo cáo sự cố'),
              _menuItem(context, Icons.support, 'Quản lý dịch vụ chung'),
              _menuItem(context, Icons.description, 'Điều khoản & chính sách'),
              _menuItem(context, Icons.lock_reset, 'Đổi mật khẩu', onTap: () {
                Navigator.pushNamed(context, '/change_password');
              }),
              _menuItem(context, Icons.logout, 'Đăng xuất', color: Colors.red,
                  onTap: () => _showLogoutDialog(context, userProvider)),
            ],
          ),
        );
      },
    );
  }

  static Future<Map<String, int>> _countRoomsFromHostels(List<QueryDocumentSnapshot> hostelDocs) async {
    int total = 0;
    int available = 0;
    int rented = 0;

    for (var hostel in hostelDocs) {
      final roomsSnap = await FirebaseFirestore.instance
          .collection('hostels')
          .doc(hostel.id)
          .collection('rooms')
          .get();

      for (var room in roomsSnap.docs) {
        total++;
        final status = room['status'] ?? 'available';
        if (status == 'available') available++;
        else if (status == 'rented' || status == 'occupied') rented++;
      }
    }

    return {
      'total': total,
      'available': available,
      'rented': rented,
    };
  }

  Widget _buildStatCard({
    required int totalRooms,
    required int rentedRooms,
    required int availableRooms,
    required int totalTenants,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin cho thuê', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildRentalInfo('Tổng số phòng', totalRooms.toString(), Icons.home)),
              Expanded(child: _buildRentalInfo('Số người thuê', totalTenants.toString(), Icons.person_outline)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildRentalInfo('Đang cho thuê', rentedRooms.toString(), Icons.check_circle_outline, color: Colors.green)),
              Expanded(child: _buildRentalInfo('Số phòng trống', availableRooms.toString(), Icons.home_outlined, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: const Center(child: CircularProgressIndicator(color: Colors.red)),
    );
  }

  Widget _buildRentalInfo(String title, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.red, size: 28),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.red[700]),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ?? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title - Chưa có màn hình'))),
    );
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await Provider.of<MyAuth.AuthProvider>(context, listen: false).logout();
      userProvider.clear();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }
}