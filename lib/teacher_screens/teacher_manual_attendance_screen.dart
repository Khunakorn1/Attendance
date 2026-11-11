import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeacherManualAttendanceScreen extends StatefulWidget {
  final int subjectId;
  final int? sessionId;
  const TeacherManualAttendanceScreen({
    super.key, 
    required this.subjectId,
    this.sessionId,
  });

  @override
  State<TeacherManualAttendanceScreen> createState() => _TeacherManualAttendanceScreenState();
}

class _TeacherManualAttendanceScreenState extends State<TeacherManualAttendanceScreen> {
  List students = [];
  bool isLoading = true;
  bool isSaving = false;
  
  final Map<int, String?> attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

Future<void> _fetchStudents() async {
    String urlStr = 'http://127.0.0.1:8000/api/teacher/subjects/${widget.subjectId}/students';
    if (widget.sessionId != null) {
      urlStr += '?session_id=${widget.sessionId}';
    }

    final url = Uri.parse(urlStr);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List rawStudents = data['students'] ?? [];
        
        final Map<int, dynamic> uniqueMap = {};
        for (var student in rawStudents) {
          int studentId = student['user_id'];
          uniqueMap[studentId] = student;
          
          // 📌 สำคัญ: ให้ค่าเริ่มต้นเป็น null เสมอ (ยังไม่เลือก) 
          // จะดึงค่าจาก DB เฉพาะเมื่อเคยมีการบันทึกใน session_id นี้แล้วเท่านั้น
          attendanceStatus[studentId] = student['current_status']; 
        }

        setState(() {
          students = uniqueMap.values.toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _confirmSaveAttendance() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการบันทึกผล'),
        content: const Text('คุณต้องการบันทึกผลการเช็คชื่อใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              Navigator.pop(context);
              _saveAttendance();
            },
            child: const Text('ยืนยันบันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAttendance() async {
    setState(() => isSaving = true);

    var records = [];
    attendanceStatus.forEach((studentId, status) {
      records.add({
        "student_id": studentId,
        "status": status ?? 'absent',
      });
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/teacher/attendance/manual'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "subject_id": widget.subjectId,
          "session_id": widget.sessionId,
          "records": records,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกผลการเช็คชื่อสำเร็จ!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        throw Exception('บันทึกไม่สำเร็จ');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เช็คชื่อรายบุคคล', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(child: Text('ไม่พบรายชื่อนักศึกษาในรายวิชานี้', style: TextStyle(color: Colors.grey)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: students.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          var student = students[index];
                          int studentId = student['user_id'];
                          String? currentStatus = attendanceStatus[studentId];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(student['full_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 2),
                                      Text('รหัส: ${student['student_id'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildStatusButton(studentId, 'มา', 'present', Colors.green, currentStatus),
                                    const SizedBox(width: 4),
                                    _buildStatusButton(studentId, 'สาย', 'late', Colors.orange, currentStatus),
                                    const SizedBox(width: 4),
                                    _buildStatusButton(studentId, 'ขาด', 'absent', Colors.red, currentStatus),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isSaving ? null : _confirmSaveAttendance,
                          child: isSaving 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('บันทึกผลการเช็คชื่อ', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    )
                  ],
                ),
    );
  }

  Widget _buildStatusButton(int studentId, String label, String statusValue, Color activeColor, String? currentStatus) {
    bool isSelected = currentStatus == statusValue;
    return InkWell(
      onTap: () {
        setState(() {
          attendanceStatus[studentId] = statusValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}