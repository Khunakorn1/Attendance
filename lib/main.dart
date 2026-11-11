import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance System',
      theme: ThemeData(
        fontFamily: 'Sukhumvit Set',
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const LoginScreen(),
    );
  }
}