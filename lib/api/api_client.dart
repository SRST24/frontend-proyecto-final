import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'https://app-251110212719.azurewebsites.net';

  static const Duration _httpTimeout = Duration(seconds: 15);
  static const Duration _prefsTimeout = Duration(seconds: 5);

  String? _token;
  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> loadToken() async {
    final sp = await SharedPreferences.getInstance().timeout(_prefsTimeout);
    _token = sp.getString('token');
  }

  Future<void> saveSession(String token, String role) async {
    final sp = await SharedPreferences.getInstance().timeout(_prefsTimeout);
    await sp.setString('token', token).timeout(_prefsTimeout);
    await sp.setString('role', role).timeout(_prefsTimeout);
    _token = token;
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance().timeout(_prefsTimeout);
    await sp.remove('token').timeout(_prefsTimeout);
    await sp.remove('role').timeout(_prefsTimeout);
    _token = null;
  }

  Map<String, String> _headers({bool auth = false}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (auth && _token != null) 'Authorization': 'Bearer $_token',
      };

  Exception _error(http.Response r) {
    var msg = r.body;
    try {
      final m = jsonDecode(r.body);
      if (m is Map) {
        if (m['message'] is String) msg = m['message'];
        if (m['error'] is String) msg = m['error'];
        if (m['title'] is String) msg = m['title'];
      }
    } catch (_) {}
    return Exception('[${r.statusCode}] $msg');
  }

  // ===== Auth =====
  Future<void> register(String name, String email, String password, String role) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    final res = await http
        .post(url, headers: _headers(), body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': role}))
        .timeout(_httpTimeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _error(res);
    }
  }

  Future<void> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final res = await http
        .post(url, headers: _headers(), body: jsonEncode({'email': email, 'password': password}))
        .timeout(_httpTimeout);
    if (res.statusCode != 200) {
      throw _error(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = (data['token'] ?? data['Token'])?.toString() ?? '';
    final role = (data['role'] ?? data['Role'])?.toString() ?? 'client';
    await saveSession(token, role);
  }

  // ===== Services =====
  Future<List<Map<String, dynamic>>> services() async {
    final url = Uri.parse('$baseUrl/api/services');
    final res = await http.get(url, headers: _headers()).timeout(_httpTimeout);
    if (res.statusCode != 200) throw _error(res);
    final body = jsonDecode(res.body);
    if (body is List) {
      return body.cast<Map>().map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // ===== Workers =====
  Future<List<Map<String, dynamic>>> workers() async {
    final url = Uri.parse('$baseUrl/api/workers');
    final res = await http.get(url, headers: _headers()).timeout(_httpTimeout);
    if (res.statusCode != 200) throw _error(res);
    final body = jsonDecode(res.body);
    if (body is List) {
      return body.cast<Map>().map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createWorker(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/api/workers');
    final res = await http.post(url, headers: _headers(auth: true), body: jsonEncode(payload)).timeout(_httpTimeout);
    if (res.statusCode != 200 && res.statusCode != 201) throw _error(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> updateWorker(int id, Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/api/workers/$id');
    final res = await http.put(url, headers: _headers(auth: true), body: jsonEncode(payload)).timeout(_httpTimeout);
    if (res.statusCode != 200) throw _error(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  Future<void> deleteWorker(int id) async {
    final url = Uri.parse('$baseUrl/api/workers/$id');
    final res = await http.delete(url, headers: _headers(auth: true)).timeout(_httpTimeout);
    if (res.statusCode != 204) throw _error(res);
  }

  // ===== Requests =====
  Future<List<Map<String, dynamic>>> myRequests() async {
    final url = Uri.parse('$baseUrl/api/requests');
    final res = await http.get(url, headers: _headers(auth: true)).timeout(_httpTimeout);
    if (res.statusCode != 200) throw _error(res);
    final body = jsonDecode(res.body);
    if (body is List) {
      return body.cast<Map>().map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/api/requests');
    final res = await http.post(url, headers: _headers(auth: true), body: jsonEncode(payload)).timeout(_httpTimeout);
    if (res.statusCode != 200 && res.statusCode != 201) throw _error(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> updateRequestStatus(int id, String newStatus) async {
    final url = Uri.parse('$baseUrl/api/requests/$id/status');
    final res = await http.patch(url, headers: _headers(auth: true), body: jsonEncode({'status': newStatus})).timeout(_httpTimeout);
    if (res.statusCode != 200) throw _error(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ===== Reviews =====
  Future<List<Map<String, dynamic>>> reviewsForWorker(int workerId) async {
    final url = Uri.parse('$baseUrl/api/reviews/worker/$workerId');
    final res = await http.get(url, headers: _headers()).timeout(_httpTimeout);
    if (res.statusCode != 200) throw _error(res);
    final body = jsonDecode(res.body);
    if (body is List) {
      return body.cast<Map>().map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createReview(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/api/reviews');
    final res = await http.post(url, headers: _headers(auth: true), body: jsonEncode(payload)).timeout(_httpTimeout);
    if (res.statusCode != 200 && res.statusCode != 201) throw _error(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }
}
