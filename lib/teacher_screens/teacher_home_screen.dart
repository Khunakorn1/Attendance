import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeacherHomeScreen extends StatefulWidget {
  final int userId; // 🔹 รับ userId ของอาจารย์เข้ามาเพื่อดึงข้อมูลจริง
  const TeacherHomeScreen({super.key, required this.userId});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  Map<String, dynamic> teacherData = {};
  Map<String, dynamic> statsData = {'subjects_count': 0, 'students_count': 0};
  List subjectsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ดึงข้อมูล Dashboard จาก FastAPI
  Future<void> _fetchDashboardData() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/teacher/dashboard/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          teacherData = data['teacher'] ?? {};
          statsData = data['stats'] ?? {'subjects_count': 0, 'students_count': 0};
          subjectsList = data['subjects'] ?? [];
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

    String fullName = teacherData['full_name'] ?? 'อาจารย์ผู้สอน';
    String faculty = teacherData['faculty'] ?? 'สาขาวิชาในระบบ';

    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลักอาจารย์', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนต้อนรับ
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ยินดีต้อนรับ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(faculty, style: const TextStyle(color: Color(0xFF2563EB))),
              ],
            ),
            const SizedBox(height: 20),

            // 📊 2 กล่องสถิติรวม
            Row(
              children: [
                _buildStatBox('${statsData['subjects_count']}', 'รายวิชาที่สอน', Colors.blue.shade50, Colors.blue),
                const SizedBox(width: 8),
                _buildStatBox('${statsData['students_count']}', 'นักศึกษาทั้งหมด', Colors.indigo.shade50, Colors.indigo),
              ],
            ),
            const SizedBox(height: 24),

            // 📌 เปลี่ยนหัวข้อจาก "รายวิชาล่าสุดของฉัน" เป็น "รายวิชาทั้งหมดของฉัน"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('รายวิชาทั้งหมดของฉัน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${subjectsList.length} รายวิชา', style: const TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // แสดงรายการวิชาทั้งหมด
            subjectsList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30.0),
                    child: Center(child: Text('ยังไม่มีรายวิชาในระบบ', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subjectsList.length,
                    itemBuilder: (context, index) {
                      var sub = subjectsList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text(sub['code'] ?? '-', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(sub['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text('${sub['schedule'] ?? '-'} · ${sub['student_count'] ?? 0} คน', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(6)),
                                  child: Text('Sec ${sub['section'] ?? '-'}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ห้องเรียน: ${sub['room'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                Text('Join Code: ${sub['join_code'] ?? '-'}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ],
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: text)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}