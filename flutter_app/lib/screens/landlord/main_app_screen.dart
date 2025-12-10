import 'package:flutter/material.dart';
import 'package:room_rental_app/screens/landlord/profile_screen.dart';
import 'package:room_rental_app/screens/message/message_screen.dart';
import 'package:room_rental_app/screens/landlord/home_screen.dart';
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

class LandlordMainAppScreen extends StatefulWidget {
  const LandlordMainAppScreen({super.key});

  @override
  State<LandlordMainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<LandlordMainAppScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LandlordHomeScreen(),
    const VideoScreen(),
    const MessageScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
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
