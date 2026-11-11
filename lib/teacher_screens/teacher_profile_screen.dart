import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart'; // 📌 1. นำเข้าแพ็กเกจเลือกรูป
import '../screens/login_screen.dart'; // ปรับ Path หน้า Login ตามโครงสร้างโปรเจกต์ของคุณ

class TeacherProfileScreen extends StatefulWidget {
  final int userId; // 🔹 1. รับค่า userId ข้ามมา

  const TeacherProfileScreen({super.key, required this.userId});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isUploadingImage = false; // 🔹 ตัวแปรเช็คสถานะตอนอัปโหลดรูปโปรไฟล์

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 🔹 2. ฟังก์ชันดึงข้อมูลโปรไฟล์อาจารย์จาก FastAPI Backend
  Future<void> _fetchUserData() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/user/${widget.userId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userData = data['user'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 📸 3. ฟังก์ชันเลือกรูปภาพและส่งอัปโหลดไป Backend
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image == null) return;

    setState(() => isUploadingImage = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/api/user/upload-profile-image'),
      );

      request.fields['user_id'] = widget.userId.toString();
      
      var bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตรูปโปรไฟล์สำเร็จ!'), backgroundColor: Colors.green),
        );
        _fetchUserData(); // โหลดข้อมูลโปรไฟล์ใหม่เพื่อรีเฟรชรูปภาพ
      } else {
        throw Exception('อัปโหลดรูปไม่สำเร็จ');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('โปรไฟล์อาจารย์')),
        body: const Center(child: Text('ไม่พบข้อมูลผู้ใช้')),
      );
    }

    String fullName = userData!['full_name'] ?? '-';
    String username = userData!['username'] ?? '-';
    String faculty = userData!['faculty'] ?? 'ยังไม่ได้ระบุคณะ';
    String email = userData!['email'] ?? '$username@university.ac.th';
    String? profileImage = userData!['profile_image_path']; // 📌 URL รูปภาพจาก Database
    String initials = fullName.length >= 2 ? fullName.substring(0, 2) : 'อาจารย์';

    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์อาจารย์', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 📌 4. Stack และ GestureDetector สำหรับกดเปลี่ยนรูปโปรไฟล์ พร้อมไอคอนกล้อง
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: isUploadingImage ? null : _pickAndUploadImage,
                    child: CircleAvatar(
                      radius: 40, 
                      backgroundColor: const Color(0xFF2563EB), 
                      backgroundImage: (profileImage != null && profileImage.isNotEmpty)
                          ? NetworkImage(profileImage)
                          : null,
                      child: isUploadingImage
                          ? const CircularProgressIndicator(color: Colors.white)
                          : (profileImage == null || profileImage.isEmpty)
                              ? Text(initials, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold))
                              : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(blurRadius: 3, color: Colors.black26)],
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Username: $username', style: const TextStyle(color: Colors.grey)),
            Text(faculty, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Text('👨‍🏫 อาจารย์', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            
            // แสดงข้อมูลรายละเอียด
            _buildProfileInfoItem(Icons.vpn_key_outlined, 'Username', username),
            _buildProfileInfoItem(Icons.email_outlined, 'อีเมล', email),
            _buildProfileInfoItem(Icons.school_outlined, 'บทบาทในระบบ', 'อาจารย์ผู้สอน'),
            _buildProfileInfoItem(Icons.business_outlined, 'คณะ/วิทยาลัย', faculty),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('ออกจากระบบ'),
                      content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoItem(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade300, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}