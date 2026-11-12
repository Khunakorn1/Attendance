import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'subject_history_screen.dart';

class StudentCoursesScreen extends StatefulWidget {
  final int userId;
  const StudentCoursesScreen({super.key, required this.userId});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  List enrolledCourses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentCourses();
  }

  Future<void> _fetchStudentCourses() async {
    setState(() { isLoading = true; });
    final url = Uri.parse('http://127.0.0.1:8000/api/student/dashboard/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          enrolledCourses = data['courses'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  void _showJoinSubjectDialog() {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('เข้าร่วมรายวิชา', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('กรุณากรอกรหัส Join Code (4 ตัวอักษร) ที่ได้รับจากอาจารย์', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'รหัสเข้าร่วม (Join Code)',
                  hintText: 'เช่น DCZS',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.vpn_key),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                String joinCode = codeController.text.trim();
                if (joinCode.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกรหัสให้ครบ 4 ตัวอักษร'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                Navigator.pop(context);
                await _joinSubjectApi(joinCode);
              },
              child: const Text('เข้าร่วม', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinSubjectApi(String joinCode) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/subjects/join');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': widget.userId,
          'join_code': joinCode,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'เข้าร่วมรายวิชาสำเร็จ!'), backgroundColor: Colors.green),
        );
        _fetchStudentCourses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['detail'] ?? 'เกิดข้อผิดพลาด'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเชื่อมต่อกับ Server ได้: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายวิชาของฉัน', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              style: TextButton.styleFrom(backgroundColor: Colors.blue.shade50),
              onPressed: _showJoinSubjectDialog,
              icon: const Icon(Icons.add, color: Color(0xFF2563EB), size: 18),
              label: const Text('เข้าร่วมวิชา', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : enrolledCourses.isEmpty
                ? const Center(
                    child: Text('ยังไม่ได้ลงทะเบียนรายวิชาใดๆ\nกดปุ่ม "เข้าร่วมวิชา" ด้านบนเพื่อกรอกรหัส', 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: enrolledCourses.length,
                    itemBuilder: (context, index) {
                      final course = enrolledCourses[index];
                      return _buildCourseCard(
                        context,
                        course['id'],
                        course['code'] ?? '-',
                        course['name'] ?? '-',
                        course['schedule'] ?? 'ไม่ระบุเวลา',
                        course['room'] ?? '-',
                        course['present_count'] ?? 0,
                        course['late_count'] ?? 0,
                        course['absent_count'] ?? 0,
                        course['leave_count'] ?? 0,
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context, 
    int subjectId, 
    String code, 
    String title, 
    String schedule, 
    String room,
    int present,
    int late,
    int absent,
    int leave,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(code, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              const Text('ห้อง: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(room, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showLeaveConfirmationDialog(subjectId, title),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('⏰ เวลาเรียน: $schedule', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          
          // 📌 แสดง Badge สรุปสถานะการเข้าเรียน (รวมถึง "ลา")
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildBadge('มา: $present', Colors.green),
              _buildBadge('สาย: $late', Colors.orange),
              _buildBadge('ขาด: $absent', Colors.red),
              _buildBadge('ลา: $leave', Colors.blue),
            ],
          ),

          const Divider(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Color(0xFF2563EB)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubjectHistoryScreen(
                      userId: widget.userId,
                      subjectId: subjectId,
                      subjectTitle: title,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.history, size: 16, color: Color(0xFF2563EB)),
              label: const Text('ดูประวัติการเข้าเรียน', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  void _showLeaveConfirmationDialog(int subjectId, String subjectTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากรายวิชา'),
        content: Text('คุณต้องการออกจากวิชา "$subjectTitle" ใช่หรือไม่?\n\n(ประวัติการเข้าเรียนจะยังคงอยู่ หากกรอง Join Code กลับเข้ามาใหม่ข้อมูลจะแสดงเหมือนเดิม)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _leaveSubjectApi(subjectId);
            },
            child: const Text('ออกจากวิชา', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveSubjectApi(int subjectId) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/student/subjects/${widget.userId}/$subjectId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ออกจากรายวิชาเรียบร้อยแล้ว'), backgroundColor: Colors.green),
        );
        _fetchStudentCourses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถออกจากรายวิชาได้'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }
}