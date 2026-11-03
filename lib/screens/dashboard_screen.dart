import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import '../services/api_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const DashboardScreen({super.key, required this.usuario});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _seccionActual = 0;
  int _totalKioskos = 0;
  int _totalEmpleados = 0;
  bool _cargando = true;
  Map<String, dynamic>? _comisiones;
  bool _cargandoComisiones = false;
  String? _errorComisiones;
  String? _error;

  List<dynamic> _kioskos = [];
  bool _cargandoKioskos = false;

  List<dynamic> _empleados = [];
  bool _cargandoEmpleados = false;

  Map<String, dynamic>? _suscripcionActual;
  bool _cargandoSuscripcion = false;

  List<dynamic> _facturas = [];
  bool _cargandoFacturas = false;

  DateTime _fechaInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fechaFin = DateTime.now();
  bool _cargandoReporte = false;
  Map<String, dynamic>? _reporteActual;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarFacturas();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final kioskos = await ApiService.listarKioskos();
      final empleados = await ApiService.listarEmpleados();
      if (!mounted) return;
      setState(() {
        _totalKioskos = kioskos.length;
        _totalEmpleados = empleados.length;
        _kioskos = kioskos;
        _empleados = empleados;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarKioskos() async {
    setState(() => _cargandoKioskos = true);
    try {
      final kioskos = await ApiService.listarKioskos();
      if (!mounted) return;
      setState(() => _kioskos = kioskos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargandoKioskos = false);
    }
  }

  Future<void> _cargarEmpleados() async {
    setState(() => _cargandoEmpleados = true);
    try {
      final empleados = await ApiService.listarEmpleados();
      if (!mounted) return;
      setState(() => _empleados = empleados);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargandoEmpleados = false);
    }
  }

  Future<void> _cargarSuscripcion() async {
    setState(() => _cargandoSuscripcion = true);
    try {
      final suscripcion = await ApiService.miSuscripcion();
      if (!mounted) return;
      setState(() => _suscripcionActual = suscripcion);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargandoSuscripcion = false);
    }
  }

  Future<void> _cargarFacturas() async {
    setState(() => _cargandoFacturas = true);
    try {
      final facturas = await ApiService.listarFacturas();
      if (!mounted) return;
      setState(() => _facturas = facturas);
    } catch (e) {
      // Silencioso
    } finally {
      if (mounted) setState(() => _cargandoFacturas = false);
    }
  }

  void _cerrarSesion() {
    ApiService.setToken('');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              color: const Color(0xFFF3F4F6),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _cargando
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                            : _buildContenido(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF0F766E),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.qr_code_scanner, size: 60, color: Colors.white),
          const SizedBox(height: 8),
          const Text('AppCheck', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Admin Panel', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 40),
          _menuItem(0, Icons.dashboard, 'Resumen'),
          _menuItem(1, Icons.devices, 'Kioskos'),
          _menuItem(2, Icons.people, 'Empleados'),
          _menuItem(3, Icons.file_download, 'Reportes STPS'),
          _menuItem(4, Icons.receipt_long, 'Mi Suscripción'),
          _menuItem(5, Icons.fact_check, 'Facturas'),
          _menuItem(6, Icons.attach_money, 'Comisiones'),
          const Spacer(),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white70)),
            onTap: _cerrarSesion,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menuItem(int index, IconData icono, String titulo) {
    final seleccionado = _seccionActual == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: seleccionado ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icono, color: Colors.white),
        title: Text(titulo, style: const TextStyle(color: Colors.white)),
        onTap: () => setState(() => _seccionActual = index),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_getTituloSeccion(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.black54),
              const SizedBox(width: 8),
              Text(widget.usuario['nombre'] ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Chip(
                label: Text(widget.usuario['rol'] ?? 'Rol'),
                backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: Color(0xFF0F766E)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTituloSeccion() {
    switch (_seccionActual) {
      case 0: return 'Resumen General';
      case 1: return 'Gestión de Kioskos';
      case 2: return 'Gestión de Empleados';
      case 3: return 'Reportes STPS';
      case 4: return 'Mi Suscripción';
      case 5: return 'Facturas';
      case 6: return 'Mis Comisiones';
      default: return 'Dashboard';
    }
  }

  Widget _buildContenido() {
    switch (_seccionActual) {
      case 0: return _buildResumen();
      case 1: return _buildKioskos();
      case 2: return _buildEmpleados();
      case 3: return _buildReportes();
      case 4: return _buildMiSuscripcion();
      case 5: return _buildFacturas();
      case 6: return _buildComisiones();
      default: return const SizedBox();
    }
  }

  // =====================================================
  // VISTA 1: RESUMEN
  // =====================================================
  Widget _buildResumen() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tarjetaResumen('Kioskos Activos', _totalKioskos.toString(), Icons.devices, const Color(0xFF0F766E)),
              const SizedBox(width: 24),
              _tarjetaResumen('Empleados', _totalEmpleados.toString(), Icons.people, const Color(0xFFF59E0B)),
              const SizedBox(width: 24),
              _tarjetaResumen('Cumplimiento', '100%', Icons.verified, const Color(0xFF3B82F6)),
            ],
          ),
          const SizedBox(height: 40),
          const Text('Bienvenido a AppCheck', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Selecciona una opción del menú para comenzar.', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _tarjetaResumen(String titulo, String valor, IconData icono, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icono, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                Text(valor, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // VISTA 2: KIOSKOS
  // =====================================================
  Widget _buildKioskos() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kioskos Activos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _mostrarDialogoAltaDirectaKiosko,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Alta Directa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _mostrarDialogoGenerarCodigo,
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Generar Código'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cargandoKioskos
                ? const Center(child: CircularProgressIndicator())
                : _kioskos.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay kioskos registrados todavía.\nGenera un código de activación para comenzar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                        ),
                        child: ListView.separated(
                          itemCount: _kioskos.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final kiosko = _kioskos[index];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.devices, color: Color(0xFF0F766E)),
                              ),
                              title: Text(kiosko['nombre'] ?? 'Kiosko sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${kiosko['tipo']} • Device: ${kiosko['deviceId'] ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _chipEstado(kiosko['estadoLicencia'] ?? 'Desconocido'),
                                  const SizedBox(width: 8),
                                  if (kiosko['estadoLicencia'] == 'Pendiente' || kiosko['estadoLicencia'] == 'Suspendido')
                                    IconButton(
                                      icon: const Icon(Icons.vpn_key, color: Colors.purple),
                                      tooltip: 'Regenerar código de activación',
                                      onPressed: () => _mostrarDialogoRegenerarCodigo(kiosko),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Editar kiosko',
                                    onPressed: () => _mostrarDialogoEditarKiosko(kiosko),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.block, color: Colors.orange),
                                    tooltip: 'Revocar kiosko',
                                    onPressed: () => _revocarKiosko(kiosko['puntoLecturaId']),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                                    tooltip: 'Eliminar kiosko',
                                    onPressed: () => _eliminarKiosko(kiosko['puntoLecturaId']),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // VISTA 3: EMPLEADOS
  // =====================================================
  Widget _buildEmpleados() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Empleados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _mostrarDialogoAltaEmpleado,
                icon: const Icon(Icons.person_add),
                label: const Text('Dar de Alta Empleado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cargandoEmpleados
                ? const Center(child: CircularProgressIndicator())
                : _empleados.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay empleados registrados todavía.\nDa de alta a tu primer empleado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                        ),
                        child: ListView.separated(
                          itemCount: _empleados.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final empleado = _empleados[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                child: Text(
                                  (empleado['nombreCompleto'] as String).substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(empleado['nombreCompleto'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Nómina: ${empleado['numeroEmpleado']} • Método: ${empleado['metodoLecturaPreferido']}', style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _chipEstado(empleado['estado'] ?? 'Activo'),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Editar empleado',
                                    onPressed: () => _mostrarDialogoEditarEmpleado(empleado),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                                    tooltip: 'Eliminar empleado',
                                    onPressed: () => _eliminarEmpleado(empleado['empleadoId']),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // VISTA 4: REPORTES STPS
  // =====================================================
  Widget _buildReportes() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reportes de Jornada (STPS)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Selecciona el periodo y descarga el reporte para tu cumplimiento legal.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha de inicio', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fechaInicio,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _fechaInicio = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}'),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha de fin', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fechaFin,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _fechaFin = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_fechaFin.day}/${_fechaFin.month}/${_fechaFin.year}'),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton.icon(
                    onPressed: _cargandoReporte ? null : _generarReporte,
                    icon: _cargandoReporte
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search),
                    label: Text(_cargandoReporte ? 'Generando...' : 'Generar Reporte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _reporteActual == null
                ? const Center(
                    child: Text(
                      'Selecciona un rango de fechas y presiona "Generar Reporte".',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : _reporteActual!['registros'].isEmpty
                    ? const Center(child: Text('No hay registros en el periodo seleccionado.'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total: ${_reporteActual!['totalRegistros']} registros',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                onPressed: _exportarCSV,
                                icon: const Icon(Icons.download),
                                label: const Text('Descargar CSV'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                              ),
                              child: ListView.separated(
                                itemCount: _reporteActual!['registros'].length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final r = _reporteActual!['registros'][index];
                                  return ListTile(
                                    leading: Icon(
                                      r['tipoChecada'] == 'Entrada' ? Icons.login : Icons.logout,
                                      color: r['tipoChecada'] == 'Entrada' ? Colors.green : Colors.orange,
                                    ),
                                    title: Text('${r['empleado']} (${r['numeroEmpleado']})'),
                                    subtitle: Text('${r['tipoChecada']} • ${r['metodoUsado']} • ${r['puntoLectura']}'),
                                    trailing: Text(
                                      _formatearFecha(DateTime.parse(r['timestampServidor'])),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // VISTA 5: MI SUSCRIPCIÓN
  // =====================================================
  Widget _buildMiSuscripcion() {
    if (_suscripcionActual == null && !_cargandoSuscripcion) {
      _cargarSuscripcion();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mi Suscripción', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Información de tu plan actual y límites contratados.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          if (_cargandoSuscripcion)
            const Center(child: CircularProgressIndicator())
          else if (_suscripcionActual == null || _suscripcionActual!['plan'] == null)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.warning_amber, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'No tienes una suscripción activa.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Contacta al SuperAdmin para asignar un plan a tu cuenta.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        _suscripcionActual!['plan']['nombre'] ?? 'Sin plan',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _infoRow('Precio base', '\$${_suscripcionActual!['plan']['precioBase']} MXN/mes'),
                  _infoRow('Límite de empleados', '${_suscripcionActual!['plan']['limiteEmpleados']} empleados'),
                  _infoRow('Límite de kioskos', '${_suscripcionActual!['plan']['limiteKioskos']} kioskos'),
                  _infoRow('Fecha de inicio', _suscripcionActual!['fechaInicio'].toString().substring(0, 10)),
                  _infoRow('Estado', _suscripcionActual!['estado'] ?? 'Activa'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // =====================================================
  // VISTA 6: FACTURAS
  // =====================================================
  Widget _buildFacturas() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Facturas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _cargandoFacturas ? null : _generarFacturaDelMes,
                icon: _cargandoFacturas
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.receipt),
                label: Text(_cargandoFacturas ? 'Generando...' : 'Generar Factura del Mes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cargandoFacturas
                ? const Center(child: CircularProgressIndicator())
                : _facturas.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay facturas generadas.\nPresiona "Generar Factura del Mes" para crear la primera.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                        ),
                        child: ListView.separated(
                          itemCount: _facturas.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final factura = _facturas[index];
                            final periodo = DateTime.parse(factura['periodoInicio']);
                            final mesAnio = '${periodo.month.toString().padLeft(2, '0')}/${periodo.year}';
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt, color: Color(0xFF0F766E)),
                              ),
                              title: Text(
                                'Factura $mesAnio',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Subtotal: \$${factura['subtotal']} + IVA: \$${factura['iva']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _chipEstado(factura['estado'] ?? 'Emitida'),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '\$${factura['total']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        _formatearFecha(DateTime.parse(factura['fechaEmision'])),
                                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'pdf') {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Generación de PDF pendiente de implementar (CFDI 4.0)')),
                                        );
                                      } else if (value == 'pagar') {
                                        await _marcarFacturaPagada(factura['facturaId']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'pdf',
                                        child: Text('Descargar PDF'),
                                      ),
                                      if (factura['estado'] == 'Emitida')
                                        const PopupMenuItem(
                                          value: 'pagar',
                                          child: Text('Marcar como Pagada'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _generarFacturaDelMes() async {
    setState(() => _cargandoFacturas = true);
    try {
      final response = await ApiService.generarFactura();
      await _cargarFacturas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Factura generada: ${response['periodo']} - Total: \$${response['total']}'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargandoFacturas = false);
    }
  }

  Future<void> _marcarFacturaPagada(String facturaId) async {
    try {
      await ApiService.marcarFacturaPagada(facturaId);
      await _cargarFacturas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura marcada como pagada'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // =====================================================
  // MÉTODOS AUXILIARES
  // =====================================================
  Widget _chipEstado(String estado) {
    Color color;
    switch (estado) {
      case 'Activa': color = Colors.green; break;
      case 'Activo': color = Colors.green; break;
      case 'Emitida': color = Colors.blue; break;
      case 'Pagada': color = Colors.green; break;
      case 'Vencida': color = Colors.red; break;
      case 'Gracia': color = Colors.orange; break;
      case 'Restringida':
      case 'Suspendido': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(estado, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  String _formatearFecha(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _generarReporte() async {
    setState(() {
      _cargandoReporte = true;
      _reporteActual = null;
    });
    try {
      final reporte = await ApiService.obtenerReporteJornada(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin.add(const Duration(days: 1)),
      );
      if (!mounted) return;
      setState(() => _reporteActual = reporte);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargandoReporte = false);
    }
  }

  void _exportarCSV() {
    if (_reporteActual == null) return;
    final registros = _reporteActual!['registros'] as List;

    final buffer = StringBuffer();
    buffer.writeln('Empleado,NumeroEmpleado,TipoChecada,Timestamp,Metodo,PuntoLectura,Hash');
    for (final r in registros) {
      final empleado = (r['empleado'] as String).replaceAll(',', ' ');
      final puntoLectura = (r['puntoLectura'] as String).replaceAll(',', ' ');
      buffer.writeln(
        '$empleado,${r['numeroEmpleado']},${r['tipoChecada']},${r['timestampServidor']},${r['metodoUsado']},$puntoLectura,${r['hashRegistro']}'
      );
    }

    final ahora = DateTime.now();
    final nombreArchivo = 'Reporte_STPS_${ahora.year}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}.csv';

    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = nombreArchivo;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte descargado: $nombreArchivo'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  // =====================================================
  // DIÁLOGOS Y MÉTODOS DE KIOSKOS
  // =====================================================
  Future<void> _mostrarDialogoGenerarCodigo() async {
    final nombreController = TextEditingController();
    String tipoSeleccionado = 'KioskoFijo';
    String? codigoGenerado;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Generar Código de Activación'),
              content: codigoGenerado == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Ingresa el nombre del kiosko que vas a activar.', style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nombreController,
                          decoration: const InputDecoration(labelText: 'Nombre del kiosko', hintText: 'Ej: Entrada Oficina Central', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: tipoSeleccionado,
                          decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'KioskoFijo', child: Text('Kiosko Fijo (tablet)')),
                            DropdownMenuItem(value: 'Personal', child: Text('Personal (BYOD)')),
                          ],
                          onChanged: (value) {
                            if (value != null) setStateDialog(() => tipoSeleccionado = value);
                          },
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        const Text('¡Código generado!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Pásale este código al dispositivo. Expira en 72 horas.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF0F766E), width: 2),
                          ),
                          child: Column(
                            children: [
                              SelectableText(
                                codigoGenerado!,
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: Color(0xFF0F766E)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kiosko: ${nombreController.text}',
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              actions: [
                if (codigoGenerado == null) ...[
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  ElevatedButton(
                    onPressed: () async {
                      if (nombreController.text.trim().isEmpty) return;
                      try {
                        final response = await ApiService.generarCodigoKiosko(nombre: nombreController.text.trim(), tipo: tipoSeleccionado);
                        setStateDialog(() => codigoGenerado = response['codigo'] as String);
                        await _cargarKioskos(); // 👈 Refrescar la lista de kioskos
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                    child: const Text('Generar', style: TextStyle(color: Colors.white)),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                    child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDialogoAltaDirectaKiosko() async {
    final nombreController = TextEditingController();
    final deviceIdController = TextEditingController();
    String tipoSeleccionado = 'KioskoFijo';
    String? tokenGenerado;
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Alta Directa de Kiosko'),
              content: tokenGenerado == null
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Registra un kiosko manualmente. Se generará un token único.', style: TextStyle(color: Colors.black54)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: nombreController,
                            decoration: const InputDecoration(labelText: 'Nombre del kiosko', hintText: 'Ej: Entrada Oficina', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: deviceIdController,
                            decoration: const InputDecoration(labelText: 'Device ID (identificador único)', hintText: 'Ej: tablet-oficina-001', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: tipoSeleccionado,
                            decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'KioskoFijo', child: Text('Kiosko Fijo (tablet)')),
                              DropdownMenuItem(value: 'Personal', child: Text('Personal (BYOD)')),
                            ],
                            onChanged: (value) {
                              if (value != null) setStateDialog(() => tipoSeleccionado = value);
                            },
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        const Text('¡Kiosko registrado!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Guarda este token, no se volverá a mostrar:', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SelectableText(
                            tokenGenerado!,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                      ],
                    ),
              actions: [
                if (tokenGenerado == null) ...[
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  ElevatedButton(
                    onPressed: guardando ? null : () async {
                      if (nombreController.text.trim().isEmpty || deviceIdController.text.trim().isEmpty) return;
                      setStateDialog(() => guardando = true);
                      try {
                        final response = await ApiService.altaDirectaKiosko(
                          nombre: nombreController.text.trim(),
                          tipo: tipoSeleccionado,
                          deviceId: deviceIdController.text.trim(),
                        );
                        setStateDialog(() {
                          tokenGenerado = response['tokenPuntoLectura'] as String;
                          guardando = false;
                        });
                        await _cargarKioskos();
                      } catch (e) {
                        setStateDialog(() => guardando = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                    child: guardando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Registrar', style: TextStyle(color: Colors.white)),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                    child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDialogoEditarKiosko(Map<String, dynamic> kiosko) async {
    final nombreController = TextEditingController(text: kiosko['nombre']);
    String tipoSeleccionado = kiosko['tipo'] ?? 'KioskoFijo';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Kiosko'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre del kiosko', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: tipoSeleccionado,
                    decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'KioskoFijo', child: Text('Kiosko Fijo (tablet)')),
                      DropdownMenuItem(value: 'Personal', child: Text('Personal (BYOD)')),
                    ],
                    onChanged: (value) {
                      if (value != null) setStateDialog(() => tipoSeleccionado = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (nombreController.text.trim().isEmpty) return;
                    try {
                      await ApiService.editarKiosko(id: kiosko['puntoLecturaId'], nombre: nombreController.text.trim(), tipo: tipoSeleccionado);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      await _cargarKioskos();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiosko actualizado correctamente')));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _revocarKiosko(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Revocar kiosko?'),
        content: const Text('El kiosko dejará de checar, pero se conservará el historial legal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Revocar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService.revocarKiosko(id);
        await _cargarKioskos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiosko revocado correctamente')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _eliminarKiosko(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar kiosko?'),
        content: const Text('Esta acción eliminará el kiosko permanentemente. Si tiene checadas, usa "Revocar" en su lugar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService.eliminarKiosko(id);
        await _cargarKioskos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiosko eliminado correctamente')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // =====================================================
  // DIÁLOGOS Y MÉTODOS DE EMPLEADOS
  // =====================================================
  Future<void> _mostrarDialogoAltaEmpleado() async {
    final nombreController = TextEditingController();
    final numeroController = TextEditingController();
    final pinController = TextEditingController();
    String metodoSeleccionado = 'Mix';
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Dar de Alta Empleado'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: numeroController,
                      decoration: const InputDecoration(labelText: 'Número de empleado', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pinController,
                      decoration: const InputDecoration(labelText: 'PIN de respaldo (4 dígitos)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: metodoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Método de lectura', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Mix', child: Text('Mix (QR + Facial)')),
                        DropdownMenuItem(value: 'QR', child: Text('Solo QR')),
                        DropdownMenuItem(value: 'Facial', child: Text('Solo Facial')),
                      ],
                      onChanged: (value) {
                        if (value != null) setStateDialog(() => metodoSeleccionado = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: guardando ? null : () async {
                    if (nombreController.text.trim().isEmpty || numeroController.text.trim().isEmpty) return;
                    setStateDialog(() => guardando = true);
                    try {
                      final response = await ApiService.altaEmpleado(
                        numeroEmpleado: numeroController.text.trim(),
                        nombreCompleto: nombreController.text.trim(),
                        pinRespaldo: pinController.text.trim(),
                        metodoLectura: metodoSeleccionado,
                      );

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      await _cargarEmpleados();

                      if (!mounted) return;
                      _mostrarAcuseLegal(response['acuseContenido'] ?? '');
                    } catch (e) {
                      if (!mounted) return;
                      setStateDialog(() => guardando = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                  child: guardando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Dar de Alta', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDialogoEditarEmpleado(Map<String, dynamic> empleado) async {
    final nombreController = TextEditingController(text: empleado['nombreCompleto']);
    final pinController = TextEditingController();
    String metodoSeleccionado = empleado['metodoLecturaPreferido'] ?? 'Mix';
    String estadoSeleccionado = empleado['estado'] ?? 'Activo';
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Empleado'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pinController,
                      decoration: const InputDecoration(labelText: 'Nuevo PIN de respaldo (opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: metodoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Método de lectura', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Mix', child: Text('Mix (QR + Facial)')),
                        DropdownMenuItem(value: 'QR', child: Text('Solo QR')),
                        DropdownMenuItem(value: 'Facial', child: Text('Solo Facial')),
                      ],
                      onChanged: (value) {
                        if (value != null) setStateDialog(() => metodoSeleccionado = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: estadoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                        DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo')),
                      ],
                      onChanged: (value) {
                        if (value != null) setStateDialog(() => estadoSeleccionado = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: guardando ? null : () async {
                    if (nombreController.text.trim().isEmpty) return;
                    setStateDialog(() => guardando = true);
                    try {
                      await ApiService.editarEmpleado(
                        id: empleado['empleadoId'],
                        nombreCompleto: nombreController.text.trim(),
                        pinRespaldo: pinController.text.trim(),
                        metodoLectura: metodoSeleccionado,
                        estado: estadoSeleccionado,
                      );

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      await _cargarEmpleados();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empleado actualizado correctamente')));
                    } catch (e) {
                      if (!mounted) return;
                      setStateDialog(() => guardando = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                  child: guardando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _eliminarEmpleado(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar empleado?'),
        content: const Text('Esta acción eliminará al empleado permanentemente. Si tiene checadas, usa "Inactivar" en su lugar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService.eliminarEmpleado(id);
        await _cargarEmpleados();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empleado eliminado correctamente')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _mostrarAcuseLegal(String acuse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acuse de Acuerdo Legal'),
        content: SingleChildScrollView(
          child: SelectableText(acuse, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarComisiones() async {
    setState(() {
      _cargandoComisiones = true;
      _errorComisiones = null;
    });
    try {
      final comisiones = await ApiService.obtenerComisiones();
      if (!mounted) return;
      setState(() => _comisiones = comisiones);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorComisiones = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargandoComisiones = false);
    }
  }

  Widget _buildComisiones() {
    // Si no es Vendedor, mostrar mensaje de acceso denegado
    final rol = widget.usuario['rol'] ?? '';
    if (rol != 'Vendedor') {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Acceso solo para Vendedores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Esta sección muestra las comisiones del vendedor.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    if (_comisiones == null && !_cargandoComisiones) {
      _cargarComisiones();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mis Comisiones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Resumen de tus ingresos por la cartera de clientes.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          if (_cargandoComisiones)
            const Center(child: CircularProgressIndicator())
          else if (_errorComisiones != null)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    _errorComisiones!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarComisiones,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else if (_comisiones != null)
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      _tarjetaComision(
                        'Clientes Activos',
                        _comisiones!['clientesActivos'].toString(),
                        Icons.people,
                        const Color(0xFF0F766E),
                      ),
                      const SizedBox(width: 16),
                      _tarjetaComision(
                        'MRR Cobrado',
                        '\$${_comisiones!['mrrCobrado']}',
                        Icons.attach_money,
                        const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 16),
                      _tarjetaComision(
                        'Comisión',
                        '\$${_comisiones!['comisionCalculada']}',
                        Icons.trending_up,
                        const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Desglose del Cálculo',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 32),
                          _infoRow('MRR de tu cartera', '\$${_comisiones!['mrrCobrado']}'),
                          _infoRow('Porcentaje de comisión', '${(_comisiones!['porcentajeComision'] * 100).toStringAsFixed(0)}%'),
                          _infoRow('Comisión recurrente', '\$${_comisiones!['comisionCalculada']}'),
                          _infoRow('Sueldo base', '\$${_comisiones!['sueldoBase']}'),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Estimado del Mes',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${_comisiones!['totalEstimado']}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaComision(String titulo, String valor, IconData icono, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icono, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoRegenerarCodigo(Map<String, dynamic> kiosko) async {
    String? codigoGenerado;
    bool generando = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Regenerar Código de Activación'),
              content: codigoGenerado == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Se generará un nuevo código para el kiosko:\n${kiosko['nombre']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'El código anterior quedará inválido.',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        const Text('¡Código regenerado!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Pásale este código al dispositivo. Expira en 72 horas.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF0F766E), width: 2),
                          ),
                          child: Column(
                            children: [
                              SelectableText(
                                codigoGenerado!,
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: Color(0xFF0F766E)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kiosko: ${kiosko['nombre']}',
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              actions: [
                if (codigoGenerado == null) ...[
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  ElevatedButton(
                    onPressed: generando ? null : () async {
                      setStateDialog(() => generando = true);
                      try {
                        final response = await ApiService.regenerarCodigoKiosko(kiosko['puntoLecturaId']);
                        setStateDialog(() {
                          codigoGenerado = response['codigo'] as String;
                          generando = false;
                        });
                      } catch (e) {
                        setStateDialog(() => generando = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    child: generando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Regenerar', style: TextStyle(color: Colors.white)),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                    child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
