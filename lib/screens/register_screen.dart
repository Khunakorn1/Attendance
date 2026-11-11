import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isTeacherRegister = true; // true = อาจารย์, false = นักศึกษา

  // Controllers สำหรับเก็บข้อมูลฟอร์ม
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true; // ตัวแปรควบคุมการซ่อน/แสดงรหัสผ่าน

  // 🔹 ตัวแปรและรายชื่อคณะ/วิทยาลัย
  String? _selectedFaculty;
  final List<String> _facultyList = [
    'วิทยาลัยครีเอทีฟดีไซน์ แอนด์ เอ็นเตอร์เทนเมนต์ เทคโนโลยี',
    'วิทยาลัยวิศวกรรมศาสตร์และเทคโนโลยี',
    'วิทยาลัยการพัฒนาและฝึกอบรมด้านการบิน',
    'วิทยาลัยการแพทย์แบบบูรณาการ',
    'วิทยาลัยพยาบาลศาสตร์',
    'วิทยาลัยทัศนมาตรศาสตร์',
    'International College',
    'คณะบริหารธุรกิจ',
    'คณะการบัญชี',
    'คณะนิเทศศาสตร์',
    'คณะศิลปกรรมศาสตร์',
    'คณะศิลปศาสตร์',
    'คณะนิติศาสตร์ปรีดี พนมยงค์',
    'คณะรัฐประศาสนศาสตร์',
    'คณะการท่องเที่ยวและการโรงแรม',
    'คณะวิทยาศาสตร์',
    'คณะวิทยาศาสตร์การกีฬาสุขภาพ',
    'คณะการแพทย์แผนตะวันออกบูรณาการ',
    'คณะเทคนิคการแพทย์',
    'คณะกายภาพบำบัด',
  ];

  // ฟังก์ชันส่งข้อมูลสมัครสมาชิกไปที่ FastAPI Backend
Future<void> _handleRegister() async {
    String fullName = _nameController.text.trim();
    String username = _idController.text.trim();
    String email = _emailController.text.trim();
    String password = _passController.text.trim();

    // 🔹 เช็คว่าเลือกคณะหรือยัง (ถ้ายัง ให้แจ้งเตือน)
    if (fullName.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลสำคัญให้ครบถ้วน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedFaculty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกวิทยาลัย/คณะด้วยครับ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://127.0.0.1:8000/api/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'full_name': fullName,
          'role': isTeacherRegister ? 'teacher' : 'student',
          'student_id': isTeacherRegister ? null : username,
          'faculty': _selectedFaculty, // ส่งค่าคณะที่เลือก
          'email': email.isNotEmpty ? email : null,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'ลงทะเบียนสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'ลงทะเบียนไม่สำเร็จ';
        if (errorData['detail'] is String) {
          errorMessage = errorData['detail'];
        } else if (errorData['detail'] is List) {
          errorMessage = errorData['detail'].map((e) => e['msg'] ?? e.toString()).join(', ');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อ Server ได้: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วนหัวสีน้ำเงิน
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 30, left: 16, right: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ปุ่มย้อนกลับ
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'FA',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'สร้างบัญชีใหม่',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ลงทะเบียนเพื่อเริ่มใช้งานระบบเช็คชื่อ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // ส่วนฟอร์มลงทะเบียน
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ปุ่มสลับโหมด อาจารย์ / นักศึกษา
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isTeacherRegister = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isTeacherRegister ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isTeacherRegister
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                                      : [],
                                ),
                                child: Text(
                                  'อาจารย์',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isTeacherRegister ? const Color(0xFF2563EB) : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isTeacherRegister = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: !isTeacherRegister ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !isTeacherRegister
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                                      : [],
                                ),
                                child: Text(
                                  'นักศึกษา',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !isTeacherRegister ? const Color(0xFF2563EB) : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // ชื่อ-นามสกุล
                    const Text('ชื่อ-นามสกุล', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: isTeacherRegister ? 'เช่น ผศ.ดร.สมชาย ใจดี' : 'เช่น นายธนวัฒน์ สุขสมบูรณ์',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // เลขประจำตัว / รหัสนักศึกษา
                    Text(
                      isTeacherRegister ? 'เลขประจำตัวอาจารย์ (Username)' : 'รหัสนักศึกษา (Username)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        hintText: isTeacherRegister ? 'กรอกเลขประจำตัวอาจารย์' : 'กรอกรหัสนักศึกษา',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 🔹 เมนูดรอปดาวน์เลือกวิทยาลัย / คณะ
                    const Text('วิทยาลัย/คณะ', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedFaculty,
                      hint: const Text('--- กรุณาเลือกคณะ/วิทยาลัย ---', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: _facultyList.map((String faculty) {
                        return DropdownMenuItem<String>(
                          value: faculty,
                          child: Text(faculty, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFaculty = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // อีเมล
                    const Text('อีเมล', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'name@dpu.ac.th',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // รหัสผ่าน
                    const Text('รหัสผ่าน', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'อย่างน้อย 4 ตัวอักษร',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // ปุ่มลงทะเบียน
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'ลงทะเบียน',
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // ลิงก์กลับไปหน้าเข้าสู่ระบบ
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ',
                          style: TextStyle(color: Color(0xFF2563EB), fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}