import 'dart:convert';
import 'dart:io'; // Wajib untuk Android/iOS
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class AttendanceService {
  
  // 1. Cek Status Harian (Sudah masuk/pulang belum?)
  Future<Map<String, dynamic>> getTodayStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_data');
    if (userString == null) return {'success': false};

    final user = jsonDecode(userString);
    final userId = user['id'];

    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/attendance/get_today_status.php?user_id=$userId")
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 2. Submit Absen (Upload Foto + Lokasi)
  Future<Map<String, dynamic>> submitAttendance({
    required String type, // 'IN' atau 'OUT'
    required double latitude,
    required double longitude,
    required File photoFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_data');
    final user = jsonDecode(userString!);
    final userId = user['id'];

    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse("${ApiConstants.baseUrl}/attendance/submit_attendance.php")
      );

      request.fields['user_id'] = userId.toString();
      request.fields['type'] = type;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      // Attach Foto
      var pic = await http.MultipartFile.fromPath('photo', photoFile.path);
      request.files.add(pic);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Server Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengirim data: $e'};
    }
  }

  // 3. Ambil Riwayat Absensi (INI YANG TADI ERROR/HILANG)
  Future<List<dynamic>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_data');
    if (userString == null) return [];

    final user = jsonDecode(userString);
    final userId = user['id'];

    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/attendance/get_history.php?user_id=$userId")
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']; // Kembalikan list riwayat
        }
      }
      return [];
    } catch (e) {
      print("Error History: $e");
      return [];
    }
  }

}