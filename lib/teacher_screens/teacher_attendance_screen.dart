import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'teacher_manual_attendance_screen.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final int teacherId; 
  const TeacherAttendanceScreen({super.key, required this.teacherId});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  List subjects = [];
  List activeSessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    await _fetchTeacherSubjects();
    await _fetchActiveSessions();
    setState(() => isLoading = false);
  }

  Future<void> _fetchTeacherSubjects() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/subjects/${widget.teacherId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => subjects = data['subjects'] ?? []);
      }
    } catch (_) {}
  }

  Future<void> _fetchActiveSessions() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/teacher/attendance/active-sessions/${widget.teacherId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => activeSessions = data['active_sessions'] ?? []);
      }
    } catch (_) {}
  }

  void _showStartSessionDialog() {
    int? selectedSubId;
    String sessionName = 'รอบเช้า';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('เปิดรอบเช็คชื่อใหม่'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedSubId,
                    hint: const Text('— เลือกรายวิชา —'),
                    isExpanded: true,
                    items: subjects.map<DropdownMenuItem<int>>((sub) {
                      return DropdownMenuItem<int>(
                        value: sub['id'],
                        child: Text("${sub['code']} ${sub['name']} (Sec ${sub['section']})"),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedSubId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: 'ชื่อรอบ (เช่น รอบเช้า, รอบบ่าย)'),
                    controller: TextEditingController(text: sessionName),
                    onChanged: (val) => sessionName = val,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
                ElevatedButton(
                  onPressed: selectedSubId == null ? null : () async {
                    Navigator.pop(context);
                    await _startSession(selectedSubId!, sessionName);
                  },
                  child: const Text('เปิดรอบ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _startSession(int subjectId, String sessionName) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/teacher/attendance/session/start'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"subject_id": subjectId, "session_name": sessionName}),
      );
      if (response.statusCode == 200) {
        _fetchActiveSessions();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เปิดรอบเช็คชื่อสำเร็จ!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  Future<void> _startAttendanceScan(int subjectId, int sessionId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      var bytes = await pickedFile.readAsBytes();
      var fileName = pickedFile.name;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/api/teacher/attendance/scan'),
      );

      request.fields['subject_id'] = subjectId.toString();
      request.fields['session_id'] = sessionId.toString();

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['message'] ?? 'สแกนใบหน้าเช็คชื่อสำเร็จ!'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('เกิดข้อผิดพลาดในการประมวลผล AI');
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmCloseSession(int sessionId, String sessionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการปิดรอบ'),
        content: Text('คุณต้องการปิด "$sessionName" ใช่หรือไม่? เมื่อปิดแล้วจะไม่สามารถแก้ไขหรือเช็คชื่อในรอบนี้ได้อีก'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _closeSession(sessionId);
            },
            child: const Text('ยืนยันปิดรอบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _closeSession(int sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/teacher/attendance/session/close'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"session_id": sessionId}),
      );
      if (response.statusCode == 200) {
        _fetchActiveSessions();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ปิดรอบเช็คชื่อเรียบร้อยแล้ว'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการรอบเช็คชื่อ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showStartSessionDialog,
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: const Text('เปิดรอบเช็คชื่อใหม่', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('รอบที่กำลังดำเนินการอยู่', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: activeSessions.isEmpty
                        ? const Center(child: Text('ยังไม่มีรอบเช็คชื่อที่เปิดอยู่ตอนนี้', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: activeSessions.length,
                            itemBuilder: (context, index) {
                              var ses = activeSessions[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("${ses['code']} - ${ses['name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                                            child: Text(ses['session_name'], style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Sec: ${ses['section']} · วันที่: ${ses['session_date']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      const Divider(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                                            onPressed: () => _startAttendanceScan(ses['subject_id'], ses['session_id']),
                                            icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                            label: const Text('สแกนหน้า', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ),
                                          Row(
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => TeacherManualAttendanceScreen(
                                                        subjectId: ses['subject_id'],
                                                        sessionId: ses['session_id'],
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.list_alt, size: 16),
                                                label: const Text('ติ๊กรายชื่อ', style: TextStyle(fontSize: 12)),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                onPressed: () => _confirmCloseSession(ses['session_id'], ses['session_name']),
                                                child: const Text('ปิดรอบ', style: TextStyle(color: Colors.white, fontSize: 12)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}