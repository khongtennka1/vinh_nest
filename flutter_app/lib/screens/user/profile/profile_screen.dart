import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_rental_app/providers/auth_provider.dart';
import 'package:room_rental_app/providers/user_provider.dart';
import 'package:room_rental_app/screens/user/room/my_posts_screen.dart';
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

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.red,
            title: const Text(
              'Cá nhân',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: true,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            children: [
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'user_avatar',
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 39,
                            backgroundImage:
                                user.avatar != null && user.avatar!.isNotEmpty
                                ? NetworkImage(user.avatar!)
                                : const AssetImage(
                                        'assets/images/avatar_default.png',
                                      )
                                      as ImageProvider,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  user.phone?.isNotEmpty == true
                                      ? user.phone!
                                      : 'Chưa có số điện thoại',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 36,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _buildMenuItem(
                icon: Icons.home_work,
                title: 'Quản lý bài đăng',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyPostsScreen()),
                ),
              ),
              _buildMenuItem(
                icon: Icons.favorite_border,
                title: 'Bài đăng yêu thích',
              ),
              _buildMenuItem(
                icon: Icons.calendar_today,
                title: 'Lịch hẹn xem phòng',
                badge: '31',
              ),
              _buildMenuItem(icon: Icons.receipt_long, title: 'Hoá đơn'),
              _buildMenuItem(icon: Icons.description, title: 'Hợp đồng'),
              _buildMenuItem(
                icon: Icons.card_giftcard,
                title: 'Giới thiệu & nhận thưởng',
              ),
              _buildMenuItem(
                icon: Icons.policy,
                title: 'Điều khoản & chính sách',
              ),
              _buildMenuItem(
                icon: Icons.report_problem_outlined,
                title: 'Báo cáo sự cố',
              ),

              const Divider(
                height: 32,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),

              _buildMenuItem(
                icon: Icons.logout,
                title: 'Đăng xuất',
                color: Colors.red,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Đăng xuất'),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Đăng xuất',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).logout;
                    userProvider.clear();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  }
                },
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng đang phát triển'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    'Yêu cầu xoá tài khoản',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

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
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? badge,
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.red[700], size: 26),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          if (badge != null) const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey[600]),
        ],
      ),
      onTap: onTap ?? () {},
    );
  }
}
