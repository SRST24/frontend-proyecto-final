// lib/api/api_client.dart
// Hotfix v2: tipado fuerte en services() y reviewsForWorker() para encajar con Future<List<Map<String, dynamic>>>.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _defaultBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5271');
  final String baseUrl;
  String? _token;
  String? _role;
  String? _userId;

  ApiClient([String? baseUrl]) : baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _prefsTimeout = Duration(seconds: 2);

  String? get token => _token;
  String? get role => _role;
  String? get userId => _userId;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get hasToken => isLoggedIn;

  bool get isWorker => (_role ?? '').toLowerCase() == 'worker';
  bool get isClient => (_role ?? '').toLowerCase() == 'client';

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> saveSession(String token, String role, String userId) async {
    final sp = await SharedPreferences.getInstance().timeout(_prefsTimeout);
    await sp.setString('token', token).timeout(_prefsTimeout);
    await sp.setString('role', role).timeout(_prefsTimeout);
    await sp.setString('userId', userId).timeout(_prefsTimeout);
    _token = token;
    _role = role;
    _userId = userId;
  }

  Future<void> loadToken() async {
    final sp = await SharedPreferences.getInstance().timeout(_prefsTimeout);
    _token = sp.getString('token');
    _role = sp.getString('role');
    _userId = sp.getString('userId');
  }

  Future<void> logout() => clearSession();
  Future<void> clearSession() async {
    final sp = await SharedPreferences.getInstance().timeout(_prefsTimeout);
    await sp.remove('token').timeout(_prefsTimeout);
    await sp.remove('role').timeout(_prefsTimeout);
    await sp.remove('userId').timeout(_prefsTimeout);
    _token = null;
    _role = null;
    _userId = null;
  }

  // --- Auth ---
  Future<bool> login(String email, String password) async {
    final resp = await http.post(Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    if (resp.statusCode == 200) {
      final m = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = (m['token'] ?? m['Token'] ?? '').toString();
      final role = (m['role'] ?? m['Role'] ?? '').toString();
      final uid = (m['userId'] ?? m['UserId'] ?? '').toString();
      if (token.isNotEmpty) {
        await saveSession(token, role, uid);
        return true;
      }
    }
    return false;
  }

  Future<bool> register(String name, String email, String password, String role) async {
    final resp = await http.post(Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': role}));
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  // --- Services ---
  Future<List<Map<String, dynamic>>> services() async {
    final r = await http.get(Uri.parse('$baseUrl/api/services'), headers: _headers());
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      if (data is List) {
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw Exception('Formato inesperado en /api/services');
    }
    throw Exception('Error al cargar servicios: ${r.statusCode}');
  }

  // --- Workers ---
  Future<List<dynamic>> getWorkers() async {
    final r = await http.get(Uri.parse('$baseUrl/api/workers'), headers: _headers());
    if (r.statusCode == 200) return jsonDecode(r.body) as List<dynamic>;
    throw Exception('Error al cargar workers: ${r.statusCode}');
  }

  Future<void> createWorker(Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$baseUrl/api/workers'), headers: _headers(), body: jsonEncode(body));
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('No se pudo crear worker (${r.statusCode})');
  }

  Future<void> updateWorker(int id, Map<String, dynamic> body) async {
    final r = await http.put(Uri.parse('$baseUrl/api/workers/$id'), headers: _headers(), body: jsonEncode(body));
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('No se pudo actualizar worker (${r.statusCode})');
  }

  Future<void> deleteWorker(int id) async {
    final r = await http.delete(Uri.parse('$baseUrl/api/workers/$id'), headers: _headers());
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('No se pudo eliminar worker (${r.statusCode})');
  }

  // --- Requests ---
  Future<List<dynamic>> getRequests() async {
    final r = await http.get(Uri.parse('$baseUrl/api/requests'), headers: _headers());
    if (r.statusCode == 200) return jsonDecode(r.body) as List<dynamic>;
    throw Exception('Error al cargar requests: ${r.statusCode}');
  }

  Future<void> createRequest({required int workerId, required int serviceId}) async {
    final body = {'workerId': workerId, 'serviceId': serviceId};
    final r = await http.post(Uri.parse('$baseUrl/api/requests'), headers: _headers(), body: jsonEncode(body));
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('No se pudo crear request (${r.statusCode})');
  }

  Future<void> updateRequestStatus(int requestId, String newStatus) async {
    final normalized = (newStatus == 'Cancelled') ? 'Canceled' : newStatus;
    final r = await http.patch(Uri.parse('$baseUrl/api/requests/$requestId/status'),
        headers: _headers(), body: jsonEncode({'status': normalized}));
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('No se pudo actualizar estado (${r.statusCode})');
  }

  // --- Reviews ---
  Future<List<Map<String, dynamic>>> reviewsForWorker(int workerId) async {
    final r = await http.get(Uri.parse('$baseUrl/api/reviews/worker/$workerId'), headers: _headers());
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      if (data is List) {
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw Exception('Formato inesperado en /api/reviews/worker/$workerId');
    }
    throw Exception('Error al cargar reviews: ${r.statusCode}');
  }

  Future<void> createReview(Map<String, dynamic> payload) async {
    final r = await http.post(Uri.parse('$baseUrl/api/reviews'), headers: _headers(), body: jsonEncode(payload));
    if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('No se pudo crear review (${r.statusCode})');
  }
}
