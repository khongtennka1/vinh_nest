import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_rental_app/providers/user_provider.dart';

import 'package:room_rental_app/screens/message/message_screen.dart';
import 'package:room_rental_app/screens/user/profile/profile_screen.dart';
import 'package:room_rental_app/screens/user/room/create_post_screen.dart';
import 'home_screen.dart';

class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ondemand_video, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Video\nSắp ra mắt!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const VideoScreen(),
    const MessageScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<UserProvider>(context, listen: false).loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: _screens),
      floatingActionButton: safeIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: safeIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.ondemand_video),
            label: 'Video',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}
