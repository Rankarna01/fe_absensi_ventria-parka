import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class AdminService {
  // Pastikan URL ini ditambahkan di api_constants.dart:
  // static const String addLocation = "$baseUrl/admin/add_location.php";

  Future<Map<String, dynamic>> addOfficeLocation({
    required String name,
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    try {
      // GANTI dengan URL endpoint kamu yang benar
      // Sementara saya tulis manual, idealnya pakai ApiConstants.addLocation
      final url = "${ApiConstants.baseUrl}/admin/add_location.php"; 
      
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          "name": name,
          "latitude": latitude,
          "longitude": longitude,
          "radius": radius
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Server Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi Gagal: $e'};
    }
  }

  Future<List<dynamic>> getEmployees() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/admin/get_employees.php")
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Tambah Pegawai
  Future<Map<String, dynamic>> addEmployee({
    required String nip,
    required String name,
    required String password,
    required String position,
    required String department,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/admin/add_employee.php"),
        body: jsonEncode({
          "nip": nip,
          "name": name,
          "password": password,
          "position": position,
          "department": department
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 3. Ambil Laporan Absensi per Tanggal
  Future<List<dynamic>> getAttendanceReport(String date) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/admin/get_attendance_report.php?date=$date")
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getPendingLeaves() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/admin/get_pending_leaves.php")
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateLeaveStatus(int leaveId, String status) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/admin/update_leave_status.php"),
        body: jsonEncode({
          "leave_id": leaveId,
          "status": status
        })
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getOfficeSettings() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/admin/get_settings.php")
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> updateOfficeSettings(String start, String end, int tolerance) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/admin/update_settings.php"),
        body: jsonEncode({
          "office_start_time": start,
          "office_end_time": end,
          "late_tolerance_minutes": tolerance
        })
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

