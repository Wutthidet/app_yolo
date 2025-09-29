import 'dart:convert';
import 'dart:developer' as developer;
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
        developer.log('API Error: ${response.statusCode}', name: 'ApiService');
        developer.log('Response: ${response.body}', name: 'ApiService');
        return null;
      }
    } catch (e) {
      developer.log('Exception: $e', name: 'ApiService');
      return null;
    }
  }

  static Future<ApiDetectionResult?> detectAndOcrGpu(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.apiDetectAndOcrGpuUrl),
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
        developer.log('API Error: ${response.statusCode}', name: 'ApiService');
        developer.log('Response: ${response.body}', name: 'ApiService');
        return null;
      }
    } catch (e) {
      developer.log('Exception: $e', name: 'ApiService');
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