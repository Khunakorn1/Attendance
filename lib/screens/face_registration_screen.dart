import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart'; // 📌 ใช้เลือกรูปภาพจำลองกล้อง

class FaceRegistrationScreen extends StatefulWidget {
  final int userId; // 👈 รับ ID นักศึกษาที่ล็อกอิน
  const FaceRegistrationScreen({super.key, required this.userId});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  bool isCameraMode = false;
  bool isUploading = false;
  bool isLoadingStatus = true; // 🔹 ตัวแปรโหลดสถานะ
  bool isRegistered = false;   // 🔹 ตัวแปรเช็คว่าลงทะเบียนหรือยัง

  @override
  void initState() {
    super.initState();
    _checkFaceStatus(); // 🔍 เช็คสถานะเมื่อเปิดหน้าจอ
  }

  // 📥 ฟังก์ชันเช็คสถานะใบหน้าจาก Backend (เช็คจาก face_encoding)
  Future<void> _checkFaceStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/student/face-status/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // เช็คว่ามีค่า face_encoding หรือไม่ (ถ้ามีและไม่เป็น null/empty ถือว่าลงทะเบียนแล้ว)
          isRegistered = data['has_face'] ?? false; 
          isLoadingStatus = false;
        });
      } else {
        setState(() => isLoadingStatus = false);
      }
    } catch (e) {
      setState(() => isLoadingStatus = false);
    }
  }

  // 📤 ฟังก์ชันถ่ายรูปและส่งข้อมูลไป Backend
  Future<void> _uploadFaceImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image == null) return;

    setState(() => isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/api/student/register-face'), // หรือ /api/student/register-face-encoding ตาม Backend คุณ
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
          const SnackBar(content: Text('บันทึกใบหน้าลงระบบสำเร็จ!'), backgroundColor: Colors.green),
        );
        setState(() {
          isCameraMode = false;
          isUploading = false;
          isRegistered = true; // อัปเดตสถานะเป็นลงทะเบียนแล้วทันที
        });
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'อัปเดตไม่สำเร็จ');
      }
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงทะเบียนใบหน้า', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoadingStatus
          ? const Center(child: CircularProgressIndicator())
          : (isCameraMode ? _buildCameraUI() : _buildStatusUI()),
    );
  }

  Widget _buildStatusUI() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(isRegistered ? '😊' : '⚠️', style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('สถานะใบหน้า', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          isRegistered ? '☑ ลงทะเบียนแล้ว' : '❌ ยังไม่ได้ลงทะเบียนใบหน้า', 
                          style: TextStyle(
                            color: isRegistered ? Colors.green : Colors.red, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 📌 กรอบสีฟ้าปรับให้ยืดเต็มซ้ายขวาด้วย width: double.infinity
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRegistered ? Colors.blue.shade50 : Colors.orange.shade50, 
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRegistered ? 'คำแนะนำ:' : 'คำเตือน:', 
                        style: TextStyle(
                          color: isRegistered ? Colors.blue : Colors.orange.shade800, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('• อยู่ในที่มีแสงสว่างเพียงพอ'),
                      const Text('• มองตรงไปที่กล้อง'),
                      const Text('• ไม่สวมแว่นตาหรือหน้ากาก'),
                      if (!isRegistered) ...[
                        const SizedBox(height: 4),
                        const Text('• กรุณาลงทะเบียนใบหน้าก่อนใช้งานเช็คชื่อ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ]
                    ],
                  ),
                )
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRegistered ? const Color(0xFF2563EB) : Colors.orange, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => isCameraMode = true),
              icon: Icon(isRegistered ? Icons.camera_alt : Icons.warning_amber_rounded, color: Colors.white),
              label: Text(
                isRegistered ? 'อัปเดตใบหน้า' : 'ลงทะเบียนใบหน้าตอนนี้', 
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCameraUI() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const Text('😊', style: TextStyle(fontSize: 80)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: isUploading ? null : _uploadFaceImage, 
              icon: isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.camera, color: Colors.white),
              label: Text(
                isUploading ? 'กำลังอัปโหลด...' : 'ถ่ายและบันทึกใบหน้า', 
                style: const TextStyle(fontSize: 16, color: Colors.white)
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => isCameraMode = false),
            child: const Text('← ย้อนกลับ', style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }
}