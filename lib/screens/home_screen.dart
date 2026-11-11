import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'face_registration_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId; // 👈 รับ userId ของนักศึกษาที่ล็อกอินเข้ามา
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> studentData = {};
  List enrolledCourses = [];
  bool isLoading = true;
  bool isFaceRegistered = false; // 🔹 ตัวแปรเก็บสถานะการลงทะเบียนใบหน้า

  @override
  void initState() {
    super.initState();
    _fetchStudentDashboard();
  }

  // 📥 ดึงข้อมูล Dashboard, รายวิชา และสถานะใบหน้าของนักศึกษาจาก Backend
  Future<void> _fetchStudentDashboard() async {
    try {
      final dashboardUrl = Uri.parse('http://127.0.0.1:8000/api/student/dashboard/${widget.userId}');
      final response = await http.get(dashboardUrl);

      final faceStatusUrl = Uri.parse('http://127.0.0.1:8000/api/student/face-status/${widget.userId}');
      final faceResponse = await http.get(faceStatusUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        bool faceStatus = false;
        if (faceResponse.statusCode == 200) {
          final faceData = jsonDecode(faceResponse.body);
          faceStatus = faceData['has_face'] ?? false;
        }

        setState(() {
          studentData = data['student'] ?? {};
          enrolledCourses = data['courses'] ?? [];
          isFaceRegistered = faceStatus;
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String fullName = studentData['full_name'] ?? 'นักศึกษา';
    String studentId = studentData['student_id'] ?? '-';
    String majorFaculty = "${studentData['major'] ?? '-'} ${studentData['faculty'] ?? ''}";
    
    int presentCount = studentData['present_count'] ?? 3;
    int lateCount = studentData['late_count'] ?? 1;
    int absentCount = studentData['absent_count'] ?? 0;
    int totalClasses = presentCount + lateCount + absentCount;
    double attendancePercentage = totalClasses > 0 ? ((presentCount + lateCount) / totalClasses) * 100 : 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลัก', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        // 📌 นำ CircleAvatar ออกจาก actions แล้ว
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนโปรไฟล์นักศึกษา (เอาวงกลม CircleAvatar ด้านขวาออกแล้ว)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('สวัสดี 👋', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(studentId, style: const TextStyle(color: Colors.grey)),
                Text(majorFaculty, style: const TextStyle(color: Color(0xFF2563EB))),
              ],
            ),
            const SizedBox(height: 16),

            // การ์ดแสดงอัตราการเข้าเรียนภาพรวม
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('อัตราการเข้าเรียนรวม', style: TextStyle(color: Colors.white70)),
                          Text('${attendancePercentage.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        radius: 24,
                        child: Text('😊', style: TextStyle(fontSize: 24)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: attendancePercentage / 100,
                      color: Colors.greenAccent,
                      backgroundColor: Colors.white24,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('เกณฑ์ขั้นต่ำ 80%', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('$totalClasses ครั้ง', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // กล่องสถิติย่อย
            Row(
              children: [
                _buildStatBox(presentCount.toString(), 'มา', Colors.green.shade50, Colors.green),
                _buildStatBox(lateCount.toString(), 'สาย', Colors.orange.shade50, Colors.orange),
                _buildStatBox(absentCount.toString(), 'ขาด', Colors.red.shade50, Colors.red),
              ],
            ),
            const SizedBox(height: 16),

            // สถานะใบหน้าสำหรับเช็คชื่อ
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FaceRegistrationScreen(userId: widget.userId),
                  ),
                );
                _fetchStudentDashboard();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isFaceRegistered ? Colors.white : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isFaceRegistered ? Colors.grey.shade200 : Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Text(isFaceRegistered ? '😊' : '⚠️', style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ใบหน้าสำหรับเช็คชื่อ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          isFaceRegistered ? '☑ ลงทะเบียนแล้ว' : '❌ ยังไม่ได้ลงทะเบียนใบหน้า (คลิกเพื่อลงทะเบียน)', 
                          style: TextStyle(
                            color: isFaceRegistered ? Colors.green : Colors.orange.shade800, 
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('รายวิชาที่ลงทะเบียน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            enrolledCourses.isEmpty
                ? const Text('ยังไม่ได้ลงทะเบียนรายวิชาใดๆ', style: TextStyle(color: Colors.grey))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: enrolledCourses.length,
                    itemBuilder: (context, index) {
                      var course = enrolledCourses[index];
                      int rate = course['attendance_rate'] ?? 100;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildCourseCard(
                          course['code'] ?? '-',
                          course['name'] ?? '-',
                          course['schedule'] ?? 'ไม่ระบุเวลา',
                          '$rate%',
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String count, String label, Color bg, Color text) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
            Text(label, style: TextStyle(fontSize: 12, color: text)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(String code, String title, String time, String percent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(code, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(percent, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}