import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import 'dart:io';

class AuthService {
  // Fungsi Login
  Future<Map<String, dynamic>> login(String nip, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        body: jsonEncode({
          "nip": nip, 
          "password": password
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Jika login sukses, simpan data user ke memori HP
        if (data['success'] == true) {
          await _saveUserSession(data['data']);
        }
        
        return data;
      } else {
        return {'success': false, 'message': 'Server Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // Simpan Data User ke SharedPreferences
  Future<void> _saveUserSession(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    // Kita simpan sebagai string JSON agar mudah diambil
    await prefs.setString('user_data', jsonEncode(userData));
    await prefs.setBool('is_login', true);
  }

  // Fungsi Logout (Hapus sesi)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    String? password,
    File? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConstants.baseUrl}/auth/update_profile.php"),
      );

      request.fields['user_id'] = userId.toString();
      request.fields['name'] = name;
      
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      if (imageFile != null) {
        var pic = await http.MultipartFile.fromPath('image', imageFile.path);
        request.files.add(pic);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Jika sukses, update data session lokal
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(data['data']));
        }
        return data;
      } else {
        return {'success': false, 'message': 'Server Error'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}