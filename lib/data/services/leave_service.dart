import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class LeaveService {
  // 1. Submit Izin
  Future<Map<String, dynamic>> submitLeave({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    File? attachment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final user = jsonDecode(prefs.getString('user_data')!);
    final userId = user['id'];

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConstants.baseUrl}/leaves/submit_leave.php"),
      );

      request.fields['user_id'] = userId.toString();
      request.fields['type'] = type;
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;
      request.fields['reason'] = reason;

      if (attachment != null) {
        var pic = await http.MultipartFile.fromPath('attachment', attachment.path);
        request.files.add(pic);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Server Error'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 2. Ambil Riwayat
  Future<List<dynamic>> getUserLeaves() async {
    final prefs = await SharedPreferences.getInstance();
    final user = jsonDecode(prefs.getString('user_data')!);
    final userId = user['id'];

    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/leaves/get_user_leaves.php?user_id=$userId")
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
}