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
  final Map<int, String> attendanceNotes = {};
  
  // 📌 เพิ่ม Map เก็บ TextEditingController ของแต่ละนักศึกษา เพื่อไม่ให้ช่องพิมพ์หาย/รีเซ็ตเวลาพิมพ์
  final Map<int, TextEditingController> _noteControllers = {};

  @override
  void dispose() {
    // เคลียร์ Controller เมื่อออกจากหน้าจอเพื่อป้องกัน Memory Leak
    for (var controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

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
          
          attendanceStatus[studentId] = student['current_status']; 
          
          String initialNote = student['note'] ?? '';
          if (initialNote.isNotEmpty) {
            attendanceNotes[studentId] = initialNote;
          }
          
          // กำหนดค่าให้ Controller ของแต่ละคนอย่างแม่นยำ
          if (_noteControllers.containsKey(studentId)) {
            _noteControllers[studentId]?.text = initialNote;
          } else {
            _noteControllers[studentId] = TextEditingController(text: initialNote);
          }
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
        "note": attendanceNotes[studentId] ?? _noteControllers[studentId]?.text ?? '',
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
        // หากต้องการให้อยู่หน้าเดิมต่อเพื่อตรวจสอบข้อมูล ให้เอา Navigator.pop ออก 
        // หรือถ้าต้องการกลับหน้าก่อนหน้า ให้แน่ใจว่าบันทึกสำเร็จแล้วค่อย pop
        Navigator.pop(context);
      } else {
        throw Exception('บันทึกไม่สำเร็จ');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
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

                          if (!attendanceStatus.containsKey(studentId)) {
                            attendanceStatus[studentId] = null;
                          }
                          String? currentStatus = attendanceStatus[studentId];

                          // ตรวจสอบและสร้าง Controller สำรองเผื่อกรณีข้อมูลมาทีหลัง
                          if (!_noteControllers.containsKey(studentId)) {
                            _noteControllers[studentId] = TextEditingController();
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
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
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        _buildStatusButton(studentId, 'มา', 'present', Colors.green, currentStatus),
                                        _buildStatusButton(studentId, 'สาย', 'late', Colors.orange, currentStatus),
                                        _buildStatusButton(studentId, 'ขาด', 'absent', Colors.red, currentStatus),
                                        _buildStatusButton(studentId, 'ลา', 'leave', Colors.blue, currentStatus),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                // แสดงช่องหมายเหตุเฉพาะเมื่อเลือกสถานะเป็น "ลา" (leave)
                                if (currentStatus == 'leave') ...[
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _noteControllers[studentId], // 📌 ใช้ Controller ที่ผูกไว้ถาวร
                                    onChanged: (value) {
                                      attendanceNotes[studentId] = value;
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'ระบุเหตุผลการลา...',
                                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
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
          if (statusValue != 'leave') {
            attendanceNotes.remove(studentId);
            _noteControllers[studentId]?.clear(); // เคลียร์ข้อความในช่องพิมพ์เมื่อเปลี่ยนไปสถานะอื่น
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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