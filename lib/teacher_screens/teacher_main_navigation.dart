import 'package:flutter/material.dart';
import 'teacher_home_screen.dart';
import 'teacher_subjects_screen.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_reports_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherMainNavigation extends StatefulWidget {
  final int userId; // 🔹 1. รับค่า userId ข้ามมาจากหน้า Login

  const TeacherMainNavigation({super.key, required this.userId});

  @override
  State<TeacherMainNavigation> createState() => _TeacherMainNavigationState();
}

class _TeacherMainNavigationState extends State<TeacherMainNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _pages; // 🔹 ใช้ late เพื่อกำหนดค่าใน initState

  @override
  void initState() {
    super.initState();
    // 🔹 2. กำหนดรายชื่อหน้าจอทั้งหมด และส่ง widget.userId ไปยังหน้าที่ต้องใช้งาน
    _pages = [
      TeacherHomeScreen(userId: widget.userId),        
      TeacherSubjectsScreen(userId: widget.userId),     
      TeacherAttendanceScreen(teacherId: widget.userId),              
      TeacherReportsScreen(userId: widget.userId),     
      TeacherProfileScreen(userId: widget.userId),      
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
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), label: 'รายวิชา'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), label: 'เช็คชื่อ'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'รายงาน'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}