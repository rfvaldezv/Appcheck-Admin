import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.appcheck.com.mx',
  );

  static String? _token;

  static void setToken(String token) => _token = token;

  static Map<String, String> _headers({bool withAuth = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // =====================================================
  // AUTH
  // =====================================================
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
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Backend devuelve {value: [...], Count: N}
      if (data is Map && data['value'] is List) return data['value'];
      // O devuelve un array directo
      if (data is List) return data;
      return [];
    }
    throw Exception('Error al listar kioskos');
  }

  // =====================================================
  // EMPLEADOS
  // =====================================================
  static Future<List<dynamic>> listarEmpleados() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/employee'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Backend devuelve un array directo
      if (data is List) return data;
      // O devuelve {value: [...], Count: N}
      if (data is Map && data['value'] is List) return data['value'];
      return [];
    }
    throw Exception('Error al listar empleados');
  }

  static Future<Map<String, dynamic>> generarCodigoKiosko({required String nombre, required String tipo}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kiosko/generar-codigo'),
      headers: _headers(withAuth: true),
      body: jsonEncode({'nombre': nombre, 'tipo': tipo}),
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
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al dar de alta kiosko');
  }

  static Future<void> editarKiosko({required String id, required String nombre, required String tipo}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/kiosko/$id'),
      headers: _headers(withAuth: true),
      body: jsonEncode({'nombre': nombre, 'tipo': tipo}),
    );
    if (response.statusCode != 200) throw Exception('Error al editar kiosko');
  }

  static Future<void> revocarKiosko(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kiosko/revocar/$id'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode != 200) throw Exception('Error al revocar kiosko');
  }

  static Future<void> eliminarKiosko(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/kiosko/$id'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode != 200) throw Exception('Error al eliminar kiosko');
  }

  static Future<Map<String, dynamic>> regenerarCodigoKiosko(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kiosko/$id/regenerar-codigo'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al regenerar código');
  }

  static Future<Map<String, dynamic>> limpiarInactivos() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kiosko/limpiar-inactivos'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al limpiar inactivos');
  }

  static Future<Map<String, dynamic>> altaEmpleado({
    required String numeroEmpleado,
    required String nombreCompleto,
    required String pinRespaldo,
    required String metodoLectura,
    String? fotoBase64,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/employee'),
      headers: _headers(withAuth: true),
      body: jsonEncode({
        'numeroEmpleado': numeroEmpleado,
        'nombreCompleto': nombreCompleto,
        'pinRespaldo': pinRespaldo,
        'metodoLecturaPreferido': metodoLectura,
        'fotoBase64': fotoBase64,
      }),
    ).timeout(const Duration(seconds: 120));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al dar de alta empleado');
  }

  static Future<void> editarEmpleado({
    required String id,
    required String nombreCompleto,
    required String pinRespaldo,
    required String metodoLectura,
    required String estado,
    String? fotoBase64,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/employee/$id'),
      headers: _headers(withAuth: true),
      body: jsonEncode({
        'nombreCompleto': nombreCompleto,
        'pinRespaldo': pinRespaldo,
        'metodoLecturaPreferido': metodoLectura,
        'estado': estado,
        'fotoBase64': fotoBase64,
      }),
    ).timeout(const Duration(seconds: 120));
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al editar empleado');
    }
  }

  static Future<void> eliminarEmpleado(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/employee/$id'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode != 200) throw Exception('Error al eliminar empleado');
  }

  // =====================================================
  // REPORTES (con filtros)
  // =====================================================
  static Future<Map<String, dynamic>> obtenerReporteJornada({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? cuentaId,
    String? vendedorId,
    String? metodoUsado,
    String? empleadoId,
  }) async {
    final queryParams = {
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      if (cuentaId != null) 'cuentaId': cuentaId,
      if (vendedorId != null) 'vendedorId': vendedorId,
      if (metodoUsado != null) 'metodoUsado': metodoUsado,
      if (empleadoId != null) 'empleadoId': empleadoId,
    };
    final uri = Uri.parse('$baseUrl/api/checada/reporte').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers(withAuth: true));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data is Map<String, dynamic>) ? data : {'registros': [], 'totalRegistros': 0};
    }
    throw Exception('Error al obtener reporte');
  }

  // =====================================================
  // FILTROS (empresas y vendedores)
  // =====================================================
  static Future<List<dynamic>> listarEmpresas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/empresas'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data is List) ? data : [];
    }
    return [];
  }

  static Future<List<dynamic>> listarVendedores() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/vendedores'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data is List) ? data : [];
    }
    return [];
  }

  // =====================================================
  // FACTURACIÓN
  // =====================================================
  static Future<List<dynamic>> listarPlanes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/facturacion/planes'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data is List) ? data : [];
    }
    throw Exception('Error al listar planes');
  }

  static Future<Map<String, dynamic>> miSuscripcion() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/facturacion/mi-suscripcion'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data is Map<String, dynamic>) ? data : {};
    }
    throw Exception('Error al obtener suscripción');
  }

  static Future<Map<String, dynamic>> asignarPlan({required String cuentaId, required String planId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/facturacion/asignar-plan'),
      headers: _headers(withAuth: true),
      body: jsonEncode({'cuentaId': cuentaId, 'planId': planId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al asignar plan');
  }

  static Future<List<dynamic>> listarFacturas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/facturacion/facturas'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data is List) ? data : [];
    }
    throw Exception('Error al listar facturas');
  }

  static Future<Map<String, dynamic>> generarFactura() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/facturacion/facturas/generar'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al generar factura');
  }

  static Future<void> marcarFacturaPagada(String facturaId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/facturacion/facturas/$facturaId/pagar'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode != 200) throw Exception('Error al marcar factura como pagada');
  }

  static Future<Map<String, dynamic>> editarChecada({
    required String registroId,
    required String tipoChecada,
    String? timestampServidor,
    String? motivoCorreccion,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/checada/$registroId'),
      headers: _headers(withAuth: true),
      body: jsonEncode({
        'tipoChecada': tipoChecada,
        if (timestampServidor != null) 'timestampServidor': timestampServidor,
        'motivoCorreccion': motivoCorreccion,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al editar checada');
  }

  // =====================================================
  // DASHBOARD (KPIs + gráficos)
  // =====================================================
  static Future<Map<String, dynamic>> obtenerDashboard({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final queryParams = {
      if (fechaInicio != null) 'fechaInicio': fechaInicio.toIso8601String(),
      if (fechaFin != null) 'fechaFin': fechaFin.toIso8601String(),
    };
    final uri = Uri.parse('$baseUrl/api/analytics/dashboard').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers(withAuth: true));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al obtener dashboard');
  }
}
