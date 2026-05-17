import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static String get _baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return "http://10.0.2.2:8000/api/request";
    }
    return "http://127.0.0.1:8000/api/request";
  }

  Future<Map<String, dynamic>> getServiceRecommendation(String userQuery) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('user_lat') ?? 33.6844;
      final lng = prefs.getDouble('user_lng') ?? 73.0479;

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Bypass-Tunnel-Reminder": "true",
        },
        body: jsonEncode({
          "message": userQuery,
          "user_id": "demo_user_001",
          "lat": lat,
          "lng": lng
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to connect to KhidmatYar Backend: $e");
    }
  }
}
