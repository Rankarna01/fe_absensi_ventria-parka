import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class AdminService {
  

  // Ambil Lokasi Kantor Tersimpan
  Future<Map<String, dynamic>?> getOfficeLocation() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/admin/get_location.php")
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 1. Tambah Lokasi Kantor (FIXED)
  Future<Map<String, dynamic>> addOfficeLocation({
    required String name,
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    try {
      // Pastikan endpoint ini sesuai. Jika di ApiConstants belum ada, gunakan string manual:
      // "${ApiConstants.baseUrl}/admin/add_location.php"
      final url = "${ApiConstants.baseUrl}/admin/add_location.php"; 
      
      final response = await http.post(
        Uri.parse(url),
        // --- PERBAIKAN UTAMA DI SINI ---
        headers: {
          'Content-Type': 'application/json',
        },
        // -------------------------------
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

  // Ambil Data Pegawai
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

  // 2. Tambah Pegawai (FIXED HEADER)
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
        // Tambahkan header JSON agar backend bisa baca
        headers: {'Content-Type': 'application/json'},
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

  // Update Status Izin (FIXED HEADER)
  Future<bool> updateLeaveStatus(int leaveId, String status) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/admin/update_leave_status.php"),
        // Tambahkan header JSON
        headers: {'Content-Type': 'application/json'},
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

  // Update Setting Kantor (FIXED HEADER)
  Future<bool> updateOfficeSettings(String start, String end, int tolerance) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/admin/update_settings.php"),
        // Tambahkan header JSON
        headers: {'Content-Type': 'application/json'},
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

  // 8. Export Laporan ke Excel (CSV)
  Future<bool> exportReport(int month, int year) async {
    try {
      // A. Ambil Data dari API
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/admin/get_monthly_report.php?month=$month&year=$year")
      );
      
      if (response.statusCode != 200) return false;
      
      final result = jsonDecode(response.body);
      if (result['success'] != true) return false;
      
      List<dynamic> data = result['data'];

      // B. Buat Header CSV
      String csvContent = "No,Tanggal,Jam,NIP,Nama Karyawan,Jabatan,Departemen,Tipe Absen,Status\n";

      // C. Isi Data
      for (var i = 0; i < data.length; i++) {
        var item = data[i];
        csvContent += "${i + 1},${item['date']},${item['time']},${item['nip']},${item['name']},${item['position']},${item['dept']},${item['type']},${item['status']}\n";
      }

      // D. Simpan File ke HP
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/Laporan_Absensi_${month}_$year.csv";
      final file = File(path);
      
      await file.writeAsString(csvContent);

      // E. Buka File Otomatis
      await OpenFile.open(path);
      
      return true;

    } catch (e) {
      print("Error Export: $e");
      return false;
    }
  }
}