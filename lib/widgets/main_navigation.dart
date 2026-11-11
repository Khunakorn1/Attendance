import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/face_registration_screen.dart';
import '../screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int userId; // 🔹 รับ userId ข้ามมาจากหน้า Login

  const MainNavigationScreen({super.key, required this.userId});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 🔹 กำหนดรายการหน้าจอ โดยส่ง widget.userId ไปให้ ProfileScreen
    _pages = [
      HomeScreen(userId: widget.userId), 
      StudentCoursesScreen(userId: widget.userId),
      FaceRegistrationScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId), 
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'ประวัติ'),
          BottomNavigationBarItem(icon: Icon(Icons.sentiment_satisfied_alt_rounded), label: 'ใบหน้า'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}