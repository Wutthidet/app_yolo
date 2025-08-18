import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_detection_result.dart';
import '../utils/constants.dart';

class ApiService {
  static Future<ApiDetectionResult?> detectAndOcr(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.apiDetectAndOcrUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(utf8.decode(response.bodyBytes));
        return ApiDetectionResult.fromJson(responseData);
      } else {
        print('Error: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.apiLoginUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['detect'] == 'true';
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}