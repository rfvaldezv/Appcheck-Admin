import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _error;

  List<dynamic> _kioskos = [];
  bool _cargandoKioskos = false;
  String _filtroKioskos = '';

  List<dynamic> _empleados = [];
  bool _cargandoEmpleados = false;
  String _filtroEmpleados = '';
  String _filtroEstadoEmpleados = 'Todos';
  String _filtroEmpresaEmpleados = 'Todas';
  String _filtroVendedorEmpleados = 'Todos';

  Map<String, dynamic>? _suscripcionActual;
  bool _cargandoSuscripcion = false;

  List<dynamic> _facturas = [];
  bool _cargandoFacturas = false;

  DateTime _fechaInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fechaFin = DateTime.now();
  bool _cargandoReporte = false;
  Map<String, dynamic>? _reporteActual;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      key: _scaffoldKey,
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(_getTituloSeccion()),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Chip(
                    label: Text(widget.usuario['rol'] ?? 'Rol'),
                    backgroundColor: Colors.white24,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            )
          : null,
      drawer: !isDesktop ? _buildDrawer() : null,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: Container(
              color: const Color(0xFFF3F4F6),
              child: Column(
                children: [
                  if (isDesktop) _buildHeader(),
                  Expanded(
                    child: _cargando
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                            : _buildContenido(isDesktop),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF0F766E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0F766E)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 50, color: Colors.white),
                  SizedBox(height: 8),
                  Text('AppCheck', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _menuItem(0, Icons.dashboard, 'Resumen'),
            _menuItem(1, Icons.devices, 'Kioskos'),
            _menuItem(2, Icons.people, 'Empleados'),
            _menuItem(3, Icons.file_download, 'Reportes STPS'),
            _menuItem(4, Icons.receipt_long, 'Mi Suscripción'),
            _menuItem(5, Icons.fact_check, 'Facturas'),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white70)),
              onTap: _cerrarSesion,
            ),
          ],
        ),
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
        onTap: () {
          setState(() => _seccionActual = index);
          if (MediaQuery.of(context).size.width < 800) {
            Navigator.pop(context);
          }
        },
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
      default: return 'Dashboard';
    }
  }

  Widget _buildContenido(bool isDesktop) {
    switch (_seccionActual) {
      case 0: return _buildResumen(isDesktop);
      case 1: return _buildKioskos(isDesktop);
      case 2: return _buildEmpleados(isDesktop);
      case 3: return _buildReportes();
      case 4: return _buildMiSuscripcion();
      case 5: return _buildFacturas();
      default: return const SizedBox();
    }
  }

  Widget _buildResumen(bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isDesktop
              ? Row(
                  children: [
                    _tarjetaResumen('Kioskos Activos', _totalKioskos.toString(), Icons.devices, const Color(0xFF0F766E)),
                    const SizedBox(width: 24),
                    _tarjetaResumen('Empleados', _totalEmpleados.toString(), Icons.people, const Color(0xFFF59E0B)),
                    const SizedBox(width: 24),
                    _tarjetaResumen('Cumplimiento', '100%', Icons.verified, const Color(0xFF3B82F6)),
                  ],
                )
              : Column(
                  children: [
                    _tarjetaResumen('Kioskos Activos', _totalKioskos.toString(), Icons.devices, const Color(0xFF0F766E)),
                    const SizedBox(height: 16),
                    _tarjetaResumen('Empleados', _totalEmpleados.toString(), Icons.people, const Color(0xFFF59E0B)),
                    const SizedBox(height: 16),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
    );
  }

  Widget _buildKioskos(bool isDesktop) {
    final kioskosFiltrados = _kioskos.where((k) {
      final nombre = (k['nombre'] ?? '').toString().toLowerCase();
      return nombre.contains(_filtroKioskos.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kioskos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final response = await ApiService.limpiarInactivos();
                        await _cargarKioskos();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(response['mensaje']), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Limpiar Inactivos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Buscar kiosko por nombre...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _filtroKioskos = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cargandoKioskos
                ? const Center(child: CircularProgressIndicator())
                : kioskosFiltrados.isEmpty
                    ? Center(
                        child: Text(
                          _kioskos.isEmpty
                              ? 'No hay kioskos registrados todavía.\nUsa "Alta Directa" para crear uno.'
                              : 'No se encontraron kioskos con ese nombre.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                        ),
                        child: ListView.separated(
                          itemCount: kioskosFiltrados.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final kiosko = kioskosFiltrados[index];
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
                                  if (isDesktop) _chipEstado(kiosko['estadoLicencia'] ?? 'Desconocido'),
                                  const SizedBox(width: 8),
                                  if (kiosko['estadoLicencia'] == 'Pendiente' || kiosko['estadoLicencia'] == 'Suspendido')
                                    IconButton(
                                      icon: const Icon(Icons.vpn_key, color: Colors.purple),
                                      tooltip: 'Regenerar código',
                                      onPressed: () => _regenerarCodigoYMostrar(kiosko),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Editar',
                                    onPressed: () => _mostrarDialogoEditarKiosko(kiosko),
                                  ),
                                  if (kiosko['estadoLicencia'] == 'Activa')
                                    IconButton(
                                      icon: const Icon(Icons.block, color: Colors.orange),
                                      tooltip: 'Revocar',
                                      onPressed: () => _revocarKiosko(kiosko['puntoLecturaId']),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                                    tooltip: 'Eliminar',
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

  Widget _buildEmpleados(bool isDesktop) {
    final empresas = _empleados.map((e) => e['empresa'] ?? 'N/A').toSet().toList();
    final vendedores = _empleados.map((e) => e['vendedor'] ?? 'Sin vendedor').toSet().toList();

    final empleadosFiltrados = _empleados.where((e) {
      final nombre = (e['nombreCompleto'] ?? '').toString().toLowerCase();
      final numero = (e['numeroEmpleado'] ?? '').toString().toLowerCase();
      final coincideTexto = nombre.contains(_filtroEmpleados.toLowerCase()) ||
                            numero.contains(_filtroEmpleados.toLowerCase());
      
      final estado = e['estado'] ?? 'Activo';
      final coincideEstado = _filtroEstadoEmpleados == 'Todos' || estado == _filtroEstadoEmpleados;

      final empresa = e['empresa'] ?? 'N/A';
      final coincideEmpresa = _filtroEmpresaEmpleados == 'Todas' || empresa == _filtroEmpresaEmpleados;

      final vendedor = e['vendedor'] ?? 'Sin vendedor';
      final coincideVendedor = _filtroVendedorEmpleados == 'Todos' || vendedor == _filtroVendedorEmpleados;

      return coincideTexto && coincideEstado && coincideEmpresa && coincideVendedor;
    }).toList();

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
                label: const Text('Dar de Alta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar por nombre o número...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() => _filtroEmpleados = value),
                ),
              ),
              DropdownButton<String>(
                value: _filtroEstadoEmpleados,
                items: const [
                  DropdownMenuItem(value: 'Todos', child: Text('Todos (Estado)')),
                  DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _filtroEstadoEmpleados = value);
                },
              ),
              DropdownButton<String>(
                value: _filtroEmpresaEmpleados,
                items: [
                  const DropdownMenuItem(value: 'Todas', child: Text('Todas (Empresa)')),
                  ...empresas.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _filtroEmpresaEmpleados = value);
                },
              ),
              DropdownButton<String>(
                value: _filtroVendedorEmpleados,
                items: [
                  const DropdownMenuItem(value: 'Todos', child: Text('Todos (Vendedor)')),
                  ...vendedores.map((v) => DropdownMenuItem(value: v, child: Text(v))),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _filtroVendedorEmpleados = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cargandoEmpleados
                ? const Center(child: CircularProgressIndicator())
                : empleadosFiltrados.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay empleados que coincidan con los filtros.',
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
                          itemCount: empleadosFiltrados.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final empleado = empleadosFiltrados[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                child: Text(
                                  (empleado['nombreCompleto'] as String).substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(empleado['nombreCompleto'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nómina: ${empleado['numeroEmpleado']} • Método: ${empleado['metodoLecturaPreferido']}'),
                                  Text('Empresa: ${empleado['empresa'] ?? 'N/A'} • Vendedor: ${empleado['vendedor'] ?? 'Sin vendedor'}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isDesktop) _chipEstado(empleado['estado'] ?? 'Activo'),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _mostrarDialogoEditarEmpleado(empleado),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red),
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

  Widget _buildReportes() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reportes de Jornada (STPS)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Selecciona el periodo y descarga el reporte.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fecha inicio', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: _fechaInicio, firstDate: DateTime(2020), lastDate: DateTime.now());
                              if (picked != null) setState(() => _fechaInicio = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
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
                          const Text('Fecha fin', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: _fechaFin, firstDate: DateTime(2020), lastDate: DateTime.now());
                              if (picked != null) setState(() => _fechaFin = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
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
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cargandoReporte ? null : _generarReporte,
                    icon: const Icon(Icons.search),
                    label: Text(_cargandoReporte ? 'Generando...' : 'Generar Reporte'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _reporteActual == null
                ? const Center(child: Text('Selecciona un rango y genera el reporte.', style: TextStyle(color: Colors.black54)))
                : _reporteActual!['registros'].isEmpty
                    ? const Center(child: Text('No hay registros.'))
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total: ${_reporteActual!['totalRegistros']} registros', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                onPressed: _exportarCSV,
                                icon: const Icon(Icons.download, color: Colors.green),
                                tooltip: 'Descargar CSV',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: ListView.separated(
                                itemCount: _reporteActual!['registros'].length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final r = _reporteActual!['registros'][index];
                                  return ListTile(
                                    leading: Icon(r['tipoChecada'] == 'Entrada' ? Icons.login : Icons.logout, color: r['tipoChecada'] == 'Entrada' ? Colors.green : Colors.orange),
                                    title: Text('${r['empleado']} (${r['numeroEmpleado']})'),
                                    subtitle: Text('${r['tipoChecada']} • ${_formatearFecha(DateTime.parse(r['timestampServidor']))}'),
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

  Widget _buildMiSuscripcion() {
    if (_suscripcionActual == null && !_cargandoSuscripcion) {
      _cargarSuscripcion();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mi Suscripción', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (_cargandoSuscripcion)
            const Center(child: CircularProgressIndicator())
          else if (_suscripcionActual == null || _suscripcionActual!['plan'] == null)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Column(
                children: [
                  Icon(Icons.warning_amber, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text('No tienes una suscripción activa.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 32),
                      const SizedBox(width: 12),
                      Text(_suscripcionActual!['plan']['nombre'] ?? 'Sin plan', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 32),
                  _infoRow('Precio base', '\$${_suscripcionActual!['plan']['precioBase']} MXN/mes'),
                  _infoRow('Límite de empleados', '${_suscripcionActual!['plan']['limiteEmpleados']} empleados'),
                  _infoRow('Límite de kioskos', '${_suscripcionActual!['plan']['limiteKioskos']} kioskos'),
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
                icon: const Icon(Icons.receipt),
                label: const Text('Generar'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cargandoFacturas
                ? const Center(child: CircularProgressIndicator())
                : _facturas.isEmpty
                    ? const Center(child: Text('No hay facturas generadas.', style: TextStyle(color: Colors.black54)))
                    : Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
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
                                decoration: BoxDecoration(color: const Color(0xFF0F766E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.receipt, color: Color(0xFF0F766E)),
                              ),
                              title: Text('Factura $mesAnio', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Total: \$${factura['total']}', style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _chipEstado(factura['estado'] ?? 'Emitida'),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'pagar') {
                                        await _marcarFacturaPagada(factura['facturaId']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (factura['estado'] == 'Emitida')
                                        const PopupMenuItem(value: 'pagar', child: Text('Marcar Pagada')),
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

  Widget _chipEstado(String estado) {
    Color color;
    switch (estado) {
      case 'Activa':
      case 'Activo':
      case 'Pagada':
        color = Colors.green; break;
      case 'Emitida':
        color = Colors.blue; break;
      case 'Pendiente':
        color = Colors.orange; break;
      case 'Vencida':
      case 'Suspendido':
        color = Colors.red; break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(estado, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  String _formatearFecha(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _generarReporte() async {
    setState(() { _cargandoReporte = true; _reporteActual = null; });
    try {
      final reporte = await ApiService.obtenerReporteJornada(fechaInicio: _fechaInicio, fechaFin: _fechaFin.add(const Duration(days: 1)));
      if (!mounted) return;
      setState(() => _reporteActual = reporte);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
      buffer.writeln('$empleado,${r['numeroEmpleado']},${r['tipoChecada']},${r['timestampServidor']},${r['metodoUsado']},$puntoLectura,${r['hashRegistro']}');
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reporte descargado: $nombreArchivo'), backgroundColor: Colors.green.shade700));
  }

  Future<void> _generarFacturaDelMes() async {
    setState(() => _cargandoFacturas = true);
    try {
      final response = await ApiService.generarFactura();
      await _cargarFacturas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Factura generada: ${response['periodo']}'), backgroundColor: Colors.green.shade700));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _cargandoFacturas = false);
    }
  }

  Future<void> _marcarFacturaPagada(String facturaId) async {
    try {
      await ApiService.marcarFacturaPagada(facturaId);
      await _cargarFacturas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Factura marcada como pagada'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
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
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: tokenGenerado == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Registra un kiosko manualmente.', style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 16),
                            TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre del kiosko', border: OutlineInputBorder())),
                            const SizedBox(height: 16),
                            TextField(controller: deviceIdController, decoration: const InputDecoration(labelText: 'Device ID', border: OutlineInputBorder())),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: tipoSeleccionado,
                              decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'KioskoFijo', child: Text('Kiosko Fijo')),
                                DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                              ],
                              onChanged: (value) { if (value != null) setStateDialog(() => tipoSeleccionado = value); },
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 64),
                            const SizedBox(height: 16),
                            const Text('¡Kiosko registrado!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Guarda este token:', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                              child: SelectableText(tokenGenerado!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                            ),
                          ],
                        ),
                ),
              ),
              actions: [
                if (tokenGenerado == null) ...[
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  ElevatedButton(
                    onPressed: guardando ? null : () async {
                      if (nombreController.text.trim().isEmpty || deviceIdController.text.trim().isEmpty) return;
                      setStateDialog(() => guardando = true);
                      try {
                        final response = await ApiService.altaDirectaKiosko(nombre: nombreController.text.trim(), tipo: tipoSeleccionado, deviceId: deviceIdController.text.trim());
                        setStateDialog(() { tokenGenerado = response['tokenPuntoLectura'] as String; guardando = false; });
                        await _cargarKioskos();
                      } catch (e) {
                        setStateDialog(() => guardando = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                    child: guardando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Registrar', style: TextStyle(color: Colors.white)),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _cargarKioskos();
                    },
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
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre del kiosko', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: tipoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'KioskoFijo', child: Text('Kiosko Fijo')),
                        DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                      ],
                      onChanged: (value) { if (value != null) setStateDialog(() => tipoSeleccionado = value); },
                    ),
                  ],
                ),
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
        content: const Text('El kiosko dejará de checar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('Revocar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await ApiService.revocarKiosko(id);
        await _cargarKioskos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiosko revocado')));
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
        content: const Text('Esta acción es permanente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await ApiService.eliminarKiosko(id);
        await _cargarKioskos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiosko eliminado')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _regenerarCodigoYMostrar(Map<String, dynamic> kiosko) async {
    try {
      final response = await ApiService.regenerarCodigoKiosko(kiosko['puntoLecturaId']);
      if (!mounted) return;
      await _cargarKioskos();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Código Generado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text('Kiosko: ${kiosko['nombre']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF0F766E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: SelectableText(response['codigo'], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
              ),
              const SizedBox(height: 16),
              const Text('Expira en 72 horas', style: TextStyle(color: Colors.black54)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cargarKioskos();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
              child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al regenerar: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _mostrarDialogoAltaEmpleado() async {
    final nombreController = TextEditingController();
    final numeroController = TextEditingController();
    final pinController = TextEditingController();
    String metodoSeleccionado = 'QR';
    bool guardando = false;
    String? fotoBase64;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Dar de Alta Empleado'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: numeroController, decoration: const InputDecoration(labelText: 'Número de empleado', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: pinController, decoration: const InputDecoration(labelText: 'PIN de respaldo (4 dígitos)', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: metodoSeleccionado,
                        decoration: const InputDecoration(labelText: 'Método de lectura', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'QR', child: Text('QR')),
                          DropdownMenuItem(value: 'PIN', child: Text('PIN')),
                          DropdownMenuItem(value: 'QR+Rostro', child: Text('QR + Rostro')),
                          DropdownMenuItem(value: 'PIN+Rostro', child: Text('PIN + Rostro')),
                          DropdownMenuItem(value: 'Rostro', child: Text('Solo Rostro (próximamente)')),
                        ],
                        onChanged: (value) { if (value != null) setStateDialog(() => metodoSeleccionado = value); },
                      ),
                      const SizedBox(height: 16),
                      const Text('Rostro del Empleado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(source: ImageSource.camera, maxWidth: 300, imageQuality: 50);
                                  if (image != null) {
                                    final bytes = await image.readAsBytes();
                                    setStateDialog(() => fotoBase64 = base64Encode(bytes));
                                  }
                                } catch (e) {
                                  try {
                                    final picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, imageQuality: 50);
                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      setStateDialog(() => fotoBase64 = base64Encode(bytes));
                                    }
                                  } catch (e2) {
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e2'), backgroundColor: Colors.red));
                                  }
                                }
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Tomar'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, imageQuality: 50);
                                  if (image != null) {
                                    final bytes = await image.readAsBytes();
                                    setStateDialog(() => fotoBase64 = base64Encode(bytes));
                                  }
                                } catch (e) {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                }
                              },
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Subir'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700, foregroundColor: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if (fotoBase64 != null) ...[
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Rostro cargado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(base64Decode(fotoBase64!), height: 80, width: 80, fit: BoxFit.cover),
                        ),
                      ],
                    ],
                  ),
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
                        fotoBase64: fotoBase64,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      await _cargarEmpleados();
                      if (!mounted) return;
                      _mostrarAcuseLegal(response['acuseContenido'] ?? '');
                    } catch (e) {
                      if (!mounted) return;
                      setStateDialog(() => guardando = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                  child: guardando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Dar de Alta', style: TextStyle(color: Colors.white)),
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
    String metodoSeleccionado = empleado['metodoLecturaPreferido'] ?? 'QR';
    String estadoSeleccionado = empleado['estado'] ?? 'Activo';
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Empleado'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: pinController, decoration: const InputDecoration(labelText: 'Nuevo PIN (opcional)', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: metodoSeleccionado,
                        decoration: const InputDecoration(labelText: 'Método de lectura', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'QR', child: Text('QR')),
                          DropdownMenuItem(value: 'PIN', child: Text('PIN')),
                          DropdownMenuItem(value: 'QR+Rostro', child: Text('QR + Rostro')),
                          DropdownMenuItem(value: 'PIN+Rostro', child: Text('PIN + Rostro')),
                          DropdownMenuItem(value: 'Rostro', child: Text('Solo Rostro (próximamente)')),
                        ],
                        onChanged: (value) { if (value != null) setStateDialog(() => metodoSeleccionado = value); },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: estadoSeleccionado,
                        decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                          DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo')),
                        ],
                        onChanged: (value) { if (value != null) setStateDialog(() => estadoSeleccionado = value); },
                      ),
                    ],
                  ),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empleado actualizado')));
                    } catch (e) {
                      if (!mounted) return;
                      setStateDialog(() => guardando = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                  child: guardando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Guardar', style: TextStyle(color: Colors.white)),
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
        content: const Text('Esta acción es permanente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await ApiService.eliminarEmpleado(id);
        await _cargarEmpleados();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empleado eliminado')));
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
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(acuse, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
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
}
