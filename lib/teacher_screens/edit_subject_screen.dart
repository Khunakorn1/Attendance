import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditSubjectScreen extends StatefulWidget {
  final Map<String, dynamic> subjectData;

  const EditSubjectScreen({super.key, required this.subjectData});

  @override
  State<EditSubjectScreen> createState() => _EditSubjectScreenState();
}

class _EditSubjectScreenState extends State<EditSubjectScreen> {
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _secController;
  late TextEditingController _scheduleController;
  late TextEditingController _roomController;

  // Controller สำหรับกรอกรหัสนักศึกษา
  final TextEditingController _studentIdController = TextEditingController();

  List<dynamic> _studentsList = [];
  bool _isLoading = false;
  bool _isFetchingStudents = true;
  bool _isSearchingStudent = false;

  @override
  void initState() {
    super.initState();
    // 🔍 เพิ่มการดึงค่าเผื่อกรณีที่ Backend ส่งมาเป็น 'code' หรือ 'subject_code'
    _codeController = TextEditingController(
      text: widget.subjectData['code'] ?? widget.subjectData['subject_code'] ?? ''
    );
    _nameController = TextEditingController(text: widget.subjectData['name'] ?? '');
    _secController = TextEditingController(text: widget.subjectData['section']?.toString() ?? '');
    _scheduleController = TextEditingController(text: widget.subjectData['schedule'] ?? '');
    _roomController = TextEditingController(text: widget.subjectData['room'] ?? '');
    
    _fetchExistingStudents();
  }

  // ดึงรายชื่อนักศึกษาเดิมจากฐานข้อมูล
Future<void> _fetchExistingStudents() async {
    final subjectId = widget.subjectData['id'];
    final url = Uri.parse('http://127.0.0.1:8000/api/subjects/$subjectId/students');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List loadedStudents = data['students'] ?? [];
        
        // 🔹 เรียงลำดับตามรหัสนักศึกษาจากน้อยไปมาก
        loadedStudents.sort((a, b) => 
          (a['student_id'] ?? '').toString().compareTo((b['student_id'] ?? '').toString())
        );

        setState(() {
          _studentsList = loadedStudents;
          _isFetchingStudents = false;
        });
      } else {
        setState(() { _isFetchingStudents = false; });
      }
    } catch (e) {
      setState(() { _isFetchingStudents = false; });
    }
  }

// 🔎 ค้นหาและเพิ่มนักศึกษาเข้าวิชาทันที
Future<void> _searchAndAddStudent() async {
  String studentCode = _studentIdController.text.trim();
  if (studentCode.isEmpty) return;

  setState(() { _isSearchingStudent = true; });

  final subjectId = widget.subjectData['id'];
  final url = Uri.parse('http://127.0.0.1:8000/api/teacher/subjects/add-student');

  try {
    // 📌 ยิง API ไปเพิ่มนักศึกษาฝั่ง Backend ทันที
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'subject_id': subjectId.toString(),
        'student_code': studentCode,
      },
    );

    setState(() { _isSearchingStudent = false; });

    if (response.statusCode == 200) {
      _studentIdController.clear();
      _fetchExistingStudents(); // 🔄 โหลดรายชื่อใหม่จาก Database ทันทีเพื่อให้รายชื่ออัปเดตและเรียงลำดับ
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มนักศึกษาสำเร็จ!'), backgroundColor: Colors.green),
      );
    } else {
      final errorData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorData['detail'] ?? 'ไม่สามารถเพิ่มนักศึกษาได้'), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    setState(() { _isSearchingStudent = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
    );
  }
}

  // 💾 บันทึกการเปลี่ยนแปลงทั้งหมด
  Future<void> _updateSubject() async {
    if (_codeController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัสวิชาและชื่อวิชา'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final subjectId = widget.subjectData['id'];
    final url = Uri.parse('http://127.0.0.1:8000/api/subjects/$subjectId');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teacher_id': widget.subjectData['teacher_id'],
          'code': _codeController.text.trim(),
          'name': _nameController.text.trim(),
          'section': _secController.text.trim(),
          'schedule': _scheduleController.text.trim(),
          'room': _roomController.text.trim(),
          'students': _studentsList,
        }),
      );

      setState(() { _isLoading = false; });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตข้อมูลสำเร็จ!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  // 📌 ดึง join_code จากข้อมูลวิชาโดยตรง (ถ้าไม่มีให้แสดงเป็น 'ไม่มีรหัส')
  String joinCode = widget.subjectData['join_code'] ?? 'ไม่มีรหัส';

  return Scaffold(
    appBar: AppBar(
      title: const Text('แก้ไขรายวิชา & จัดการนักศึกษา', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔑 การ์ดแสดงรหัสสุ่มประจำวิชา (Join Code) ตัวจริง
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('รหัสเข้าวิชาสำหรับนักศึกษา (Join Code)', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(joinCode, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3, color: Color(0xFF2563EB))),
                    ],
                  ),
                  const Icon(Icons.qr_code_2, size: 40, color: Color(0xFF2563EB)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('ข้อมูลรายวิชา', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 12),
            TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'รหัสวิชา (เช่น CS401)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ชื่อวิชา (เช่น Artificial Intelligence)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _secController, decoration: const InputDecoration(labelText: 'Section (เช่น 01)', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _roomController, decoration: const InputDecoration(labelText: 'ห้องเรียน (เช่น IT-301)', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _scheduleController, decoration: const InputDecoration(labelText: 'ตารางเรียน (เช่น จันทร์ 09:00 - 12:00)', border: OutlineInputBorder())),
            
            const Divider(height: 40, thickness: 1),
            
            const Text('เพิ่มนักศึกษาเข้าวิชาด้วยรหัสนักศึกษา', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            
            // 🔎 ฟอร์มกรอกรหัสนักศึกษาเพื่อค้นหาและเพิ่ม
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _studentIdController, 
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'กรอกรหัสนักศึกษา เช่น 64010001', 
                      isDense: true, 
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSearchingStudent ? null : _searchAndAddStudent,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  icon: _isSearchingStudent 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.person_add, color: Colors.white, size: 18),
                  label: const Text('ค้นหา & เพิ่ม', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text('รายชื่อนักศึกษาในวิชาปัจจุบัน (${_studentsList.length} คน):', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 📋 รายการนักศึกษา
            _isFetchingStudents
                ? const Center(child: CircularProgressIndicator())
                : _studentsList.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: Text('ยังไม่มีนักศึกษาในวิชานี้ (ให้นักศึกษากรอก Join Code หรืออาจารย์เพิ่มด้วยรหัสข้างต้น)', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _studentsList.length,
                        itemBuilder: (context, index) {
                          var std = _studentsList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text('${index + 1}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ),
                              title: Text('${std['student_id'] ?? '-'}  ${std['full_name'] ?? 'ไม่ระบุชื่อ'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('คณะ: ${std['faculty'] ?? '-'}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _studentsList.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateSubject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('บันทึกการเปลี่ยนแปลงทั้งหมด', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}