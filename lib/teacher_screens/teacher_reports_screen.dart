import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:html' as html; // ใช้สำหรับดาวน์โหลดไฟล์บน Web

class TeacherReportsScreen extends StatefulWidget {
  final int userId; 
  const TeacherReportsScreen({super.key, required this.userId});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  List subjectsList = [];
  var selectedSubject;
  List studentsReportList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherSubjects();
  }

  Future<void> _fetchTeacherSubjects() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/subjects/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          subjectsList = data['subjects'] ?? [];
          if (subjectsList.isNotEmpty) {
            selectedSubject = subjectsList[0];
            _fetchReportData(selectedSubject['id']);
          } else {
            isLoading = false;
          }
        });
      } else {
        setState(() { isLoading = false; });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  Future<void> _fetchReportData(int subjectId) async {
    setState(() { isLoading = true; });
    final url = Uri.parse('http://127.0.0.1:8000/api/reports/subject/$subjectId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          studentsReportList = data['students_report'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  // 📥 ฟังก์ชัน Export ข้อมูลเป็นไฟล์ Excel (เพิ่มช่อง ลา และ สาเหตุการลา)
  void _exportToExcel() {
    if (selectedSubject == null || studentsReportList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลนักศึกษาสำหรับ Export ไฟล์'), backgroundColor: Colors.orange),
      );
      return;
    }

    var excel = excel_lib.Excel.createExcel();
    String sheetName = 'Report_${selectedSubject['code']}';
    excel.rename('Sheet1', sheetName);
    var sheet = excel[sheetName];

    sheet.appendRow([
      excel_lib.TextCellValue('รหัสวิชา'),
      excel_lib.TextCellValue('ชื่อวิชา'),
      excel_lib.TextCellValue('รหัสนักศึกษา'),
      excel_lib.TextCellValue('ชื่อ-นามสกุล'),
      excel_lib.TextCellValue('คณะ'),
      excel_lib.TextCellValue('มา (ครั้ง)'),
      excel_lib.TextCellValue('สาย (ครั้ง)'),
      excel_lib.TextCellValue('ขาด (ครั้ง)'),
      excel_lib.TextCellValue('ลา (ครั้ง)'),
      excel_lib.TextCellValue('สาเหตุการลา'),
    ]);

    for (var std in studentsReportList) {
      sheet.appendRow([
        excel_lib.TextCellValue(selectedSubject['code'].toString()),
        excel_lib.TextCellValue(selectedSubject['name'].toString()),
        excel_lib.TextCellValue(std['student_id'].toString()),
        excel_lib.TextCellValue(std['full_name'].toString()),
        excel_lib.TextCellValue(std['faculty']?.toString() ?? '-'),
        excel_lib.IntCellValue(std['present_count'] ?? 0),
        excel_lib.IntCellValue(std['late_count'] ?? 0),
        excel_lib.IntCellValue(std['absent_count'] ?? 0),
        excel_lib.IntCellValue(std['leave_count'] ?? 0),
        excel_lib.TextCellValue(std['leave_notes']?.toString() ?? '-'),
      ]);
    }

    var fileBytes = excel.encode();
    if (fileBytes != null) {
      final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'Attendance_Report_${selectedSubject['code']}.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export ไฟล์ Excel สำเร็จ!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงาน', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('รายงานการเข้าเรียน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.download, color: Colors.white, size: 16),
                  label: const Text('Export Excel', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            subjectsList.isEmpty
                ? const Text('ยังไม่มีรายวิชาในระบบ', style: TextStyle(color: Colors.grey))
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<dynamic>(
                        value: selectedSubject,
                        isExpanded: true,
                        items: subjectsList.map((sub) {
                          return DropdownMenuItem(
                            value: sub,
                            child: Text('${sub['code']} ${sub['name']} (Sec ${sub['section']})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedSubject = val;
                          });
                          if (val != null) {
                            _fetchReportData(val['id']);
                          }
                        },
                      ),
                    ),
                  ),
            const SizedBox(height: 16),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : studentsReportList.isEmpty
                      ? const Center(child: Text('ยังไม่มีรายชื่อนักศึกษาในรายวิชานี้', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: studentsReportList.length,
                          itemBuilder: (context, index) {
                            var std = studentsReportList[index];
                            int present = std['present_count'] ?? 0;
                            int late = std['late_count'] ?? 0;
                            int absent = std['absent_count'] ?? 0;
                            int leave = std['leave_count'] ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${std['student_id']}  ${std['full_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('คณะ: ${std['faculty'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      _buildBadge('มา: $present', Colors.green),
                                      _buildBadge('สาย: $late', Colors.orange),
                                      _buildBadge('ขาด: $absent', Colors.red),
                                      _buildBadge('ลา: $leave', Colors.blue),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
            )
          ],
        ),
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
}