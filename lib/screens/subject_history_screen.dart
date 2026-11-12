import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubjectHistoryScreen extends StatefulWidget {
  final int userId;
  final int subjectId;
  final String subjectTitle;

  const SubjectHistoryScreen({
    super.key,
    required this.userId,
    required this.subjectId,
    required this.subjectTitle,
  });

  @override
  State<SubjectHistoryScreen> createState() => _SubjectHistoryScreenState();
}

class _SubjectHistoryScreenState extends State<SubjectHistoryScreen> {
  List historyList = [];
  bool isLoading = true;

  int presentCount = 0;
  int lateCount = 0;
  int absentCount = 0;
  int leaveCount = 0; // 📌 เพิ่มตัวแปรนับจำนวนลา

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/student/history/${widget.userId}/${widget.subjectId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List fetchedList = data['history'] ?? [];

        // 🔄 จัดเรียงลำดับตาม วันที่และเวลา (ล่าสุดอยู่บนสุด)
        fetchedList.sort((a, b) {
          String dateA = "${a['session_date'] ?? ''} ${a['check_in_time'] ?? '00:00:00'}";
          String dateB = "${b['session_date'] ?? ''} ${b['check_in_time'] ?? '00:00:00'}";
          return dateB.compareTo(dateA); 
        });

        // 📊 คำนวณจำนวนสถิติ มา, สาย, ขาด, ลา
        int p = 0, l = 0, a = 0, le = 0;
        for (var item in fetchedList) {
          String status = item['status'] ?? '';
          if (status == 'present') p++;
          else if (status == 'late') l++;
          else if (status == 'absent') a++;
          else if (status == 'leave') le++;
        }

        setState(() {
          historyList = fetchedList;
          presentCount = p;
          lateCount = l;
          absentCount = a;
          leaveCount = le; // 📌 อัปเดตค่าลา
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  // 📅 ฟังก์ชันแปลงรูปแบบวันที่
  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return '-';
    String dateStr = rawDate.toString(); 
    if (dateStr.isEmpty) return '-';
    try {
      String dateOnly = dateStr.split('T')[0]; 
      List<String> parts = dateOnly.split('-');
      if (parts.length == 3) {
        String year = parts[0];
        String month = parts[1];
        String day = parts[2];
        return '$day/$month/$year'; 
      }
    } catch (_) {}
    return dateStr;
  }

  // ⏰ ฟังก์ชันจัดรูปแบบเวลา
  String _formatTime(dynamic rawTime) {
    if (rawTime == null) return '-';
    if (rawTime is int) {
      int hours = rawTime ~/ 3600;
      int minutes = (rawTime % 3600) ~/ 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
    String timeStr = rawTime.toString();
    if (timeStr.isEmpty || timeStr == 'null') return '-';
    try {
      if (timeStr.length >= 5) {
        return timeStr.substring(0, 5);
      }
    } catch (_) {}
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectTitle, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📊 กล่องสรุปสถิติภาพรวม (4 สถานะ: มา, สาย, ขาด, ลา)
                  Row(
                    children: [
                      _buildSummaryCard('มา', presentCount.toString(), Colors.green.shade50, Colors.green),
                      const SizedBox(width: 6),
                      _buildSummaryCard('สาย', lateCount.toString(), Colors.orange.shade50, Colors.orange),
                      const SizedBox(width: 6),
                      _buildSummaryCard('ขาด', absentCount.toString(), Colors.red.shade50, Colors.red),
                      const SizedBox(width: 6),
                      _buildSummaryCard('ลา', leaveCount.toString(), Colors.blue.shade50, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('ประวัติการเช็คชื่อย้อนหลัง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // 📜 รายการประวัติ
                  Expanded(
                    child: historyList.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('ยังไม่มีประวัติการเช็คชื่อในวิชานี้', style: TextStyle(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: historyList.length,
                            itemBuilder: (context, index) {
                              final item = historyList[index];
                              String status = item['status'] ?? 'unknown';
                              String? note = item['note'];
                              
                              Color color = Colors.green;
                              String statusText = 'เข้าเรียน';
                              IconData statusIcon = Icons.check_circle;

                              if (status == 'late') {
                                color = Colors.orange;
                                statusText = 'มาสาย';
                                statusIcon = Icons.access_time_filled;
                              } else if (status == 'absent') {
                                color = Colors.red;
                                statusText = 'ขาดเรียน';
                                statusIcon = Icons.cancel;
                              } else if (status == 'leave') {
                                color = Colors.blue;
                                statusText = 'ลา';
                                statusIcon = Icons.event_busy;
                              }

                              String formattedDate = _formatDate(item['session_date']);
                              String formattedTime = _formatTime(item['check_in_time']);

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
                                        Icon(statusIcon, color: color, size: 28),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('วันที่: $formattedDate', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text('เวลา: $formattedTime', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      ],
                                    ),
                                    // 📌 แสดงหมายเหตุการลา (ถ้ามี)
                                    if (status == 'leave' && note != null && note.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Divider(height: 16),
                                      Row(
                                        children: [
                                          const Icon(Icons.notes, size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'หมายเหตุ: $note',
                                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
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

  Widget _buildSummaryCard(String title, String count, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}