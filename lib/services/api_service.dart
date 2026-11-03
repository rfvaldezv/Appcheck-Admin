import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ En desarrollo local, la API corre en HTTPS 7123
  static const String baseUrl = 'https://localhost:7123';
  static String? _token;

  static void setToken(String token) => _token = token;
  static String? getToken() => _token;

  static Map<String, String> _headers({bool withAuth = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // 1. Login
  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      return data;
    }
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al iniciar sesión');
  }

  // =====================================================
  // KIOSKOS
  // =====================================================
  static Future<List<dynamic>> listarKioskos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/kiosko'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al listar kioskos');
  }

  static Future<Map<String, dynamic>> generarCodigoKiosko({required String nombre, required String tipo}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kiosko/generar-codigo'),
      headers: _headers(withAuth: true),
      body: jsonEncode({'nombreKiosko': nombre, 'tipo': tipo}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al generar código');
  }

  static Future<Map<String, dynamic>> altaDirectaKiosko({
    required String nombre,
    required String tipo,
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kiosko/alta-directa'),
      headers: _headers(withAuth: true),
      body: jsonEncode({'nombre': nombre, 'tipo': tipo, 'deviceId': deviceId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error en alta directa');
  }

  static Future<void> editarKiosko({required String id, required String nombre, required String tipo}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/kiosko/$id'),
      headers: _headers(withAuth: true),
      body: jsonEncode({'nombre': nombre, 'tipo': tipo}),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al editar kiosko');
    }
  }

  static Future<void> revocarKiosko(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kiosko/revocar/$id'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al revocar kiosko');
    }
  }

  static Future<void> eliminarKiosko(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/kiosko/$id'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al eliminar kiosko');
    }
  }

  // =====================================================
  // EMPLEADOS
  // =====================================================
  static Future<List<dynamic>> listarEmpleados() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/employee'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al listar empleados');
  }

  static Future<Map<String, dynamic>> altaEmpleado({
    required String numeroEmpleado,
    required String nombreCompleto,
    required String pinRespaldo,
    required String metodoLectura,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/employee'),
      headers: _headers(withAuth: true),
      body: jsonEncode({
        'numeroEmpleado': numeroEmpleado,
        'nombreCompleto': nombreCompleto,
        'pinRespaldo': pinRespaldo,
        'metodoLecturaPreferido': metodoLectura,
      }),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al dar de alta empleado');
  }

  static Future<void> editarEmpleado({
    required String id,
    required String nombreCompleto,
    required String pinRespaldo,
    required String metodoLectura,
    required String estado,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/employee/$id'),
      headers: _headers(withAuth: true),
      body: jsonEncode({
        'nombreCompleto': nombreCompleto,
        'pinRespaldo': pinRespaldo,
        'metodoLecturaPreferido': metodoLectura,
        'estado': estado,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al editar empleado');
    }
  }

  static Future<void> eliminarEmpleado(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/employee/$id'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al eliminar empleado');
    }
  }
}
