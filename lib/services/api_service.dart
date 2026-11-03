import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //static const String baseUrl = 'https://localhost:7123';
  // Si no se pasa la variable en compilación, usamos una URL de emergencia (producción)
  // para evitar que la app compile apuntando a localhost por error.
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.appcheck.com.mx', 
  );
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

  // =====================================================
  // REPORTES
  // =====================================================
  static Future<Map<String, dynamic>> obtenerReporteJornada({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? empleadoId,
  }) async {
    final queryParams = {
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      if (empleadoId != null) 'empleadoId': empleadoId,
    };
    final uri = Uri.parse('$baseUrl/api/checada/reporte').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers(withAuth: true));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al obtener reporte');
  }

  // =====================================================
  // FACTURACIÓN
  // =====================================================
  static Future<List<dynamic>> listarPlanes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/facturacion/planes'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al listar planes');
  }

  static Future<Map<String, dynamic>> miSuscripcion() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/facturacion/mi-suscripcion'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al obtener suscripción');
  }

  static Future<Map<String, dynamic>> asignarPlan({required String cuentaId, required String planId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/facturacion/asignar-plan'),
      headers: _headers(withAuth: true),
      body: jsonEncode({'cuentaId': cuentaId, 'planId': planId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al asignar plan');
  }

  static Future<List<dynamic>> listarFacturas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/facturacion/facturas'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al listar facturas');
  }

  static Future<Map<String, dynamic>> generarFactura() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/facturacion/facturas/generar'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al generar factura');
  }

  static Future<void> marcarFacturaPagada(String facturaId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/facturacion/facturas/$facturaId/pagar'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al marcar factura como pagada');
    }
  }

  // 19. Comisiones: Obtener mis comisiones (solo Vendedor)
  static Future<Map<String, dynamic>> obtenerComisiones() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/facturacion/comisiones'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al obtener comisiones');
  }

  // 20. Kioskos: Regenerar código de activación
  static Future<Map<String, dynamic>> regenerarCodigoKiosko(String puntoLecturaId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kiosko/$puntoLecturaId/regenerar-codigo'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al regenerar código');
  }
}
