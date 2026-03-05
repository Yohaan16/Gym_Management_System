import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://10.0.0.3:5001/api';

  static Map<String, String> _headers({String? token, int? memberId}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (memberId != null) 'x-member-id': memberId.toString(),
    };
  }

  // ===================== GET =====================
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    int? memberId,
  }) async {
    Uri uri = Uri.parse("$baseUrl$endpoint");
    final response = await http.get(
      uri,
      headers: _headers(token: token, memberId: memberId),
    );
    return _handleResponse(response);
  }

  // ===================== POST =====================
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
    int? memberId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: _headers(token: token, memberId: memberId),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // ===================== PUT =====================
  static Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // ===================== DELETE =====================
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
    int? memberId,
  }) async {
    final response = await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: _headers(token: token, memberId: memberId),
    );

    return _handleResponse(response);
  }

  // ===================== RESPONSE HANDLER =====================
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          "success": true,
          "data": decoded,
        };
      } else {
        return {
          "success": false,
          "message": decoded['message'] ?? 'Something went wrong',
          "status": response.statusCode,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Invalid server response",
      };
    }
  }
}
