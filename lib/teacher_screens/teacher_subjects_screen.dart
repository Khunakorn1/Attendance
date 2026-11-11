import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_subject_screen.dart';
import 'edit_subject_screen.dart';

class TeacherSubjectsScreen extends StatefulWidget {
  final int userId; 
  const TeacherSubjectsScreen({super.key, required this.userId});

  @override
  State<TeacherSubjectsScreen> createState() => _TeacherSubjectsScreenState();
}

class _TeacherSubjectsScreenState extends State<TeacherSubjectsScreen> {
  List subjectsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/subjects/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          subjectsList = data['subjects'];
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  // 🗑️ ฟังก์ชันแสดง Popup ยืนยันการลบรายวิชา
  Future<void> _deleteSubjectDirectly(int subjectId, String subjectName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบรายวิชา'),
        content: Text('คุณต้องการลบรายวิชา "$subjectName" ใช่หรือไม่?\nข้อมูลนักศึกษาทั้งหมดในรายวิชานี้จะถูกลบด้วย'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final url = Uri.parse('http://127.0.0.1:8000/api/subjects/$subjectId');
      try {
        final response = await http.delete(url);
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบรายวิชาสำเร็จ'), backgroundColor: Colors.green),
          );
          _fetchSubjects(); // รีเฟรชรายการ
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบไม่สำเร็จ กรุณาลองใหม่'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายวิชา', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('รายวิชาของฉัน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddSubjectScreen(userId: widget.userId)),
                    );
                    _fetchSubjects(); 
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('เพิ่ม', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : subjectsList.isEmpty
                      ? const Center(child: Text('ยังไม่มีรายวิชาที่สร้าง', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: subjectsList.length,
                          itemBuilder: (context, index) {
                            var sub = subjectsList[index];
                            int studentCount = sub['student_count'] ?? 0;
                            int subjectId = sub['id'];
                            String subjectName = sub['name'] ?? '-';
                            // ดึงจำนวนรอบ/ครั้งที่เช็คชื่อไปแล้ว (รองรับ Key 'total_sessions' หรือ 'sessions_count' จาก Backend)
                            int totalSessions = sub['total_sessions'] ?? sub['sessions_count'] ?? 0;

                            return InkWell(
                              onTap: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EditSubjectScreen(subjectData: sub)),
                                );
                                if (updated == true) {
                                  _fetchSubjects(); // รีเฟรชหน้าจอเมื่อกลับมา
                                }
                              },
                              child: _buildSubjectCard(
                                sub['code'] ?? '-',
                                subjectName,
                                'Section ${sub['section'] ?? '-'} · 3 หน่วยกิต',
                                sub['schedule'] ?? '-',
                                sub['room'] ?? '-',
                                '$studentCount คน',
                                'เช็คชื่อไปแล้ว $totalSessions ครั้ง',
                                onDelete: () => _deleteSubjectDirectly(subjectId, subjectName),
                              ),
                            );
                          },
                        ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(
    String code, 
    String name, 
    String sec, 
    String time, 
    String room, 
    String students, 
    String checkedSummary, {
    required VoidCallback onDelete,
  }) {
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(8)),
                child: Text(code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(sec, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              // ✏️ ไอคอนแก้ไข
              const Icon(Icons.edit, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              // 🗑️ ปุ่มลบรายวิชา
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                onPressed: onDelete,
                tooltip: 'ลบรายวิชา',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('$time\n$room', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(students, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.assignment_turned_in, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(checkedSummary, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}