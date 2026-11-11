import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddSubjectScreen extends StatefulWidget {
  final int userId;
  const AddSubjectScreen({super.key, required this.userId});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _secController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  
  bool _isLoading = false;

  // 💾 บันทึกรายวิชาและรับ Join Code จาก Backend
  Future<void> _saveSubject() async {
    if (_codeController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัสวิชาและชื่อวิชาให้ครบถ้วน'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final url = Uri.parse('http://127.0.0.1:8000/api/subjects');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teacher_id': widget.userId,
          'code': _codeController.text.trim(),
          'name': _nameController.text.trim(),
          'section': _secController.text.trim(),
          'schedule': _scheduleController.text.trim(),
          'room': _roomController.text.trim(),
        }),
      );

      setState(() { _isLoading = false; });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String joinCode = data['join_code'] ?? '';
        
        // 🔑 แสดง Dialog แจ้งรหัสสุ่มประจำวิชา
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('สร้างรายวิชาสำเร็จ!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('รหัสสุ่มประจำวิชาให้นักศึกษานำไปกรอกคือ:'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50, 
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    joinCode, 
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2563EB), letterSpacing: 4),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('(รหัสนี้จะใช้ถาวรให้นักศึกษากรอกเข้าระบบ)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // ปิด Dialog
                  Navigator.pop(context, true); // กลับไปหน้าหลักและส่งค่ารีเฟรช
                },
                child: const Text('ตกลง', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มรายวิชาใหม่', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('รหัสวิชา', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _codeController, 
              decoration: InputDecoration(
                hintText: 'เช่น CS401',
                filled: true, 
                fillColor: Colors.grey.shade50, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('ชื่อวิชา', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController, 
              decoration: InputDecoration(
                hintText: 'เช่น Artificial Intelligence',
                filled: true, 
                fillColor: Colors.grey.shade50, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Section', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _secController, 
              decoration: InputDecoration(
                hintText: 'เช่น 01 หรือ 02',
                filled: true, 
                fillColor: Colors.grey.shade50, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('ตารางเรียน', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _scheduleController, 
              decoration: InputDecoration(
                hintText: 'เช่น จันทร์ 09:00 - 12:00',
                filled: true, 
                fillColor: Colors.grey.shade50, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('ห้องเรียน', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _roomController, 
              decoration: InputDecoration(
                hintText: 'เช่น อาคาร IT ห้อง 301',
                filled: true, 
                fillColor: Colors.grey.shade50, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ยกเลิก', style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSubject, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), 
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('สร้างวิชา & รับรหัส', style: TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}