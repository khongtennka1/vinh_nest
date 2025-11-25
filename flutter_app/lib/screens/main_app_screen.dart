import 'package:flutter/material.dart';
import 'home_screen.dart';
// import 'video_screen.dart';       
// import 'message_screen.dart';     
import 'profile_screen.dart';
import 'package:room_rental_app/screens/create_post_screen.dart';

class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});
  @override Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ondemand_video, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Video\nSắp ra mắt!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});
  @override Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tin nhắn', style: TextStyle(fontSize: 24)),
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
 Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0
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
          BottomNavigationBarItem(icon: Icon(Icons.ondemand_video), label: 'Video'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}