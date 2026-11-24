import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'dashboard_home_screen.dart';
import 'catalogo_sucursales_screen.dart';
import 'catalogo_turnos_screen.dart';
import 'asistencia_diaria_screen.dart';
import 'horas_extra_screen.dart';
import 'retardos_screen.dart';
import 'ausencias_screen.dart';
import '../widgets/empleado_modal.dart';
import '../widgets/kiosko_modal.dart';
import '../widgets/reportes_ui.dart';
import '../widgets/empleados_ui.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const DashboardScreen({super.key, required this.usuario});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _seccionActual = 0;
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

  // Filtros de reporte
  String? _filtroEmpresa;
  String? _filtroVendedor;
  String? _filtroMetodo;
  List<dynamic> _empresas = [];
  List<dynamic> _vendedores = [];
  final List<String> _metodos = [
    'QR',
    'QR+Rostro',
    'ID+PIN',
    'ID+Rostro',
    'Rostro',
    'Huella',
  ];

  Map<String, dynamic>? _suscripcionActual;
  bool _cargandoSuscripcion = false;

  List<dynamic> _facturas = [];
  bool _cargandoFacturas = false;

  DateTime _fechaInicio = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _fechaFin = DateTime.now();
  bool _cargandoReporte = false;
  Map<String, dynamic>? _reporteActual;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarFacturas();
    _cargarEmpresasYVendedores();
  }

  Future<void> _cargarEmpresasYVendedores() async {
    try {
      final empresas = await ApiService.listarEmpresas();
      final vendedores = await ApiService.listarVendedores();
      if (!mounted) return;
      setState(() {
        _empresas = empresas;
        _vendedores = vendedores;
      });
    } catch (e) {
      debugPrint('Error cargando empresas/vendedores: $e');
    }
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
        _kioskos = kioskos;
        _empleados = empleados;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
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
                        ? Center(
                            child: Text(
                              'Error: $_error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
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
                  Text(
                    'AppCheck',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _menuItem(0, Icons.dashboard, 'Resumen'),
            _menuItem(1, Icons.devices, 'Kioskos'),
            
            // 👇 SUCURSALES Y TURNOS (catálogos) 👇
            ListTile(
              leading: const Icon(Icons.store, color: Colors.white70),
              title: const Text('Sucursales', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CatalogoSucursalesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.white70),
              title: const Text('Turnos', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CatalogoTurnosScreen()),
                );
              },
            ),
            // 👆 FIN DE CATÁLOGOS 👆

            _menuItem(2, Icons.people, 'Empleados'),
            
            // 👇 REPORTES 👇
            _menuItem(3, Icons.file_download, 'Reportes STPS'),
            ListTile(
              leading: const Icon(Icons.assessment, color: Colors.white70),
              title: const Text('Asistencia Diaria', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AsistenciaDiariaScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.white70),
              title: const Text('Horas Extra', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HorasExtraScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.white70),
              title: const Text('Retardos', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RetardosScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_off, color: Colors.white70),
              title: const Text('Ausencias', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AusenciasScreen()),
                );
              },
            ),
            // 👆 FIN DE REPORTES 👆

            _menuItem(4, Icons.receipt_long, 'Mi Suscripción'),
            _menuItem(5, Icons.fact_check, 'Facturas'),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.white70),
              ),
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
          const Text(
            'AppCheck',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Admin Panel',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 40),
          _menuItem(0, Icons.dashboard, 'Resumen'),
          _menuItem(1, Icons.devices, 'Kioskos'),
          
          // 👇 NUEVOS CATÁLOGOS EN ESCRITORIO 👇
          ListTile(
            leading: const Icon(Icons.store, color: Colors.white70),
            title: const Text('Sucursales', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CatalogoSucursalesScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule, color: Colors.white70),
            title: const Text('Turnos', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CatalogoTurnosScreen(),
                ),
              );
            },
          ),
          // 👆 FIN DE NUEVOS CATÁLOGOS 👆

          _menuItem(2, Icons.people, 'Empleados'),
          _menuItem(3, Icons.file_download, 'Reportes STPS'),
	  ListTile(
	    leading: const Icon(Icons.assessment, color: Colors.white70),
	    title: const Text('Asistencia Diaria', style: TextStyle(color: Colors.white)),
	    onTap: () {
	      Navigator.push(
	        context,
	        MaterialPageRoute(builder: (context) => const AsistenciaDiariaScreen()),
	      );
	    },
	  ),
	  ListTile(
	    leading: const Icon(Icons.timer, color: Colors.white70),
	    title: const Text('Horas Extra', style: TextStyle(color: Colors.white)),
	    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HorasExtraScreen())),
	  ),
	  ListTile(
	    leading: const Icon(Icons.warning, color: Colors.white70),
	    title: const Text('Retardos', style: TextStyle(color: Colors.white)),
	    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RetardosScreen())),
	  ),
	  ListTile(
	    leading: const Icon(Icons.person_off, color: Colors.white70),
	    title: const Text('Ausencias', style: TextStyle(color: Colors.white)),
	    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AusenciasScreen())),
	  ),
          _menuItem(4, Icons.receipt_long, 'Mi Suscripción'), // Corregido acento
          _menuItem(5, Icons.fact_check, 'Facturas'),
          const Spacer(),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text(
              'Cerrar Sesión', // Corregido acento
              style: TextStyle(color: Colors.white70),
            ),
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
        color: seleccionado
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.transparent,
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
          Text(
            _getTituloSeccion(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                widget.usuario['nombre'] ?? 'Usuario',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
      case 0:
        return 'Resumen General';
      case 1:
        return 'Gestión de Kioskos';
      case 2:
        return 'Gestión de Empleados';
      case 3:
        return 'Reportes STPS';
      case 4:
        return 'Mi Suscripción';
      case 5:
        return 'Facturas';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildContenido(bool isDesktop) {
    switch (_seccionActual) {
      case 0:
        return const DashboardHomeScreen();
      case 1:
        return _buildKioskos(isDesktop);
      case 2:
	  return buildEmpleadosUI(
	    context: context,
	    isDesktop: isDesktop,
	    empleados: _empleados,
	    cargandoEmpleados: _cargandoEmpleados,
	    filtroEmpleados: _filtroEmpleados,
	    filtroEstadoEmpleados: _filtroEstadoEmpleados,
	    filtroEmpresaEmpleados: _filtroEmpresaEmpleados,
	    filtroVendedorEmpleados: _filtroVendedorEmpleados,
	    onFiltroEmpleadosChanged: (v) => setState(() => _filtroEmpleados = v),
	    onFiltroEstadoChanged: (v) => setState(() => _filtroEstadoEmpleados = v),
	    onFiltroEmpresaChanged: (v) => setState(() => _filtroEmpresaEmpleados = v),
	    onFiltroVendedorChanged: (v) => setState(() => _filtroVendedorEmpleados = v),
	    onAltaEmpleado: () => mostrarModalAltaEmpleado(context, onGuardado: () => _cargarEmpleados()),
	    onEditarEmpleado: (empleado) => mostrarModalEditarEmpleado(context, empleado, onGuardado: () => _cargarEmpleados()),
	    onEliminarEmpleado: _eliminarEmpleado,
	    chipEstado: _chipEstado,
	  );
      case 3:
  	return buildReportesUI(
	    context: context,
	    isDesktop: isDesktop,
	    rolUsuario: widget.usuario['rol'] ?? '',
	    fechaInicio: _fechaInicio,
	    fechaFin: _fechaFin,
	    onFechaInicioChanged: (d) => setState(() => _fechaInicio = d),
	    onFechaFinChanged: (d) => setState(() => _fechaFin = d),
	    filtroEmpresa: _filtroEmpresa,
	    filtroVendedor: _filtroVendedor,
	    filtroMetodo: _filtroMetodo,
	    empresas: _empresas,
	    vendedores: _vendedores,
	    metodos: _metodos,
	    onFiltroEmpresaChanged: (v) => setState(() => _filtroEmpresa = v),
	    onFiltroVendedorChanged: (v) => setState(() => _filtroVendedor = v),
	    onFiltroMetodoChanged: (v) => setState(() => _filtroMetodo = v),
	    cargandoReporte: _cargandoReporte,
	    onGenerarReporte: _generarReporte,
	    onNuevaChecada: _nuevaChecada,
	    reporteActual: _reporteActual,
	    onExportarCSV: _exportarCSV,
	    onExportarExcel: _exportarExcel,
	    onEditarChecada: _editarChecada,
	    onEliminarChecada: _eliminarChecada,
	    formatearFechaSimple: _formatearFechaSimple,
	    formatearFecha: _formatearFecha,
	  );
      case 4:
        return _buildMiSuscripcion();
      case 5:
        return _buildFacturas();
      default:
        return const SizedBox();
    }
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
              const Text(
                'Kioskos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => mostrarModalAltaKiosko(context, onGuardado: () => _cargarKioskos()),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Alta Directa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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
                            SnackBar(
                              content: Text(response['mensaje']),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Limpiar Inactivos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
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
                              color: const Color(
                                0xFF0F766E,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.devices,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          title: Text(
                            kiosko['nombre'] ?? 'Kiosko sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${kiosko['tipo']} - Device: ${kiosko['deviceId'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isDesktop)
                                _chipEstado(
                                  kiosko['estadoLicencia'] ?? 'Desconocido',
                                ),
                              const SizedBox(width: 8),
                              if (kiosko['estadoLicencia'] == 'Pendiente' ||
                                  kiosko['estadoLicencia'] == 'Suspendido')
                                IconButton(
                                  icon: const Icon(
                                    Icons.vpn_key,
                                    color: Colors.purple,
                                  ),
                                  tooltip: 'Regenerar código',
                                  onPressed: () =>
                                      mostrarModalRegenerarCodigo(context, kiosko, onGuardado: () => _cargarKioskos()),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Editar',
                                onPressed: () =>
                                    mostrarModalEditarKiosko(context, kiosko, onGuardado: () => _cargarKioskos()),
                              ),
                              if (kiosko['estadoLicencia'] == 'Activa')
                                IconButton(
                                  icon: const Icon(
                                    Icons.block,
                                    color: Colors.orange,
                                  ),
                                  tooltip: 'Revocar',
                                  onPressed: () =>
                                      mostrarModalRevocarKiosko(context, kiosko['puntoLecturaId'], onGuardado: () => _cargarKioskos()),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                tooltip: 'Eliminar',
                                onPressed: () =>
                                    _eliminarKiosko(kiosko['puntoLecturaId']),
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

  Widget _buildMiSuscripcion() {
    if (_suscripcionActual == null && !_cargandoSuscripcion) {
      _cargarSuscripcion();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mi Suscripción',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (_cargandoSuscripcion)
            const Center(child: CircularProgressIndicator())
          else if (_suscripcionActual == null ||
              _suscripcionActual!['plan'] == null)
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
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
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
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _infoRow(
                    'Precio base',
                    '\$${_suscripcionActual!['plan']['precioBase']} MXN/mes',
                  ),
                  _infoRow(
                    'L­ímite de empleados',
                    '${_suscripcionActual!['plan']['limiteEmpleados']} empleados',
                  ),
                  _infoRow(
                    'Lí­mite de kioskos',
                    '${_suscripcionActual!['plan']['limiteKioskos']} kioskos',
                  ),
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
              const Text(
                'Facturas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _cargandoFacturas ? null : _generarFacturaDelMes,
                icon: const Icon(Icons.receipt),
                label: const Text('Generar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
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
                      'No hay facturas generadas.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: _facturas.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final factura = _facturas[index];
                        final periodo = DateTime.parse(
                          factura['periodoInicio'],
                        );
                        final mesAnio =
                            '${periodo.month.toString().padLeft(2, '0')}/${periodo.year}';
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0F766E,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.receipt,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          title: Text(
                            'Factura $mesAnio',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Total: \$${factura['total']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _chipEstado(factura['estado'] ?? 'Emitida'),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'pagar') {
                                    await _marcarFacturaPagada(
                                      factura['facturaId'],
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (factura['estado'] == 'Emitida')
                                    const PopupMenuItem(
                                      value: 'pagar',
                                      child: Text('Marcar Pagada'),
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

  Widget _chipEstado(String estado) {
    Color color;
    switch (estado) {
      case 'Activa':
      case 'Activo':
      case 'Pagada':
        color = Colors.green;
        break;
      case 'Emitida':
        color = Colors.blue;
        break;
      case 'Pendiente':
        color = Colors.orange;
        break;
      case 'Vencida':
      case 'Suspendido':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
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
        cuentaId: _filtroEmpresa,
        vendedorId: _filtroVendedor,
        metodoUsado: _filtroMetodo,
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

  Future<void> _generarFacturaDelMes() async {
    setState(() => _cargandoFacturas = true);
    try {
      final factura = await ApiService.generarFactura();
      if (!mounted) return;
      setState(() {
        _facturas.insert(0, factura);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Factura generada: ${factura['folio'] ?? 'N/A'}'),
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

  Future<void> _exportarCSV() async {
    if (_reporteActual == null) return;
    final registros = _reporteActual!['registros'] as List;
    final buffer = StringBuffer();

    buffer.writeln(
      'Empleado,NumeroEmpleado,TipoChecada,Timestamp,Metodo,Latitud,Longitud,Hash',
    );

    for (final r in registros) {
      final empleado = (r['empleado'] as String? ?? '').replaceAll(',', ' ');
      final tipo = (r['tipoChecada'] as String? ?? '');
      final timestamp = (r['timestampServidor'] as String? ?? '');
      final metodo = (r['metodoUsado'] as String? ?? '');
      final latitud = r['latitud']?.toString() ?? '';
      final longitud = r['longitud']?.toString() ?? '';
      final hash = (r['hashRegistro'] as String? ?? '');
      final numero = (r['numeroEmpleado'] as String? ?? '');

      buffer.writeln(
        '$empleado,$numero,$tipo,$timestamp,$metodo,$latitud,$longitud,$hash',
      );
    }

    final ahora = DateTime.now();
    final nombreArchivo =
        'Reporte_STPS_${ahora.year}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}.csv';

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));

    await FileSaver.instance.saveFile(
      name: nombreArchivo,
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte descargado: $nombreArchivo'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _marcarFacturaPagada(String facturaId) async {
    try {
      await ApiService.marcarFacturaPagada(facturaId);
      await _cargarFacturas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Factura marcada como pagada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _eliminarKiosko(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar kiosko?'),
        content: const Text('Esta acción es permanente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await ApiService.eliminarKiosko(id);
        await _cargarKioskos();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kiosko eliminado')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _eliminarEmpleado(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar empleado?'),
        content: const Text('Esta acción es permanente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await ApiService.eliminarEmpleado(id);
        await _cargarEmpleados();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Empleado eliminado')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportarExcel() async {
    if (_reporteActual == null) return;
    final registros = _reporteActual!['registros'] as List;

    final buffer = StringBuffer();
    buffer.writeln('<html><head><meta charset="UTF-8"></head><body>');
    buffer.writeln('<table border="1">');
    buffer.writeln('<tr>');
    buffer.writeln('<th>Empleado</th>');
    buffer.writeln('<th>Número</th>');
    buffer.writeln('<th>Tipo</th>');
    buffer.writeln('<th>Timestamp</th>');
    buffer.writeln('<th>Método</th>');
    buffer.writeln('<th>Latitud</th>');
    buffer.writeln('<th>Longitud</th>');
    buffer.writeln('<th>Hash</th>');
    buffer.writeln('</tr>');

    for (var r in registros) {
      final empleado = (r['empleado'] as String? ?? '');
      final numero = (r['numeroEmpleado'] as String? ?? '');
      final tipo = (r['tipoChecada'] as String? ?? '');
      final timestamp = (r['timestampServidor'] as String? ?? '');
      final metodo = (r['metodoUsado'] as String? ?? '');
      final latitud = r['latitud']?.toString() ?? '';
      final longitud = r['longitud']?.toString() ?? '';
      final hash = (r['hashRegistro'] as String? ?? '');

      buffer.writeln('<tr>');
      buffer.writeln('<td>$empleado</td>');
      buffer.writeln('<td>$numero</td>');
      buffer.writeln('<td>$tipo</td>');
      buffer.writeln('<td>$timestamp</td>');
      buffer.writeln('<td>$metodo</td>');
      buffer.writeln('<td>$latitud</td>');
      buffer.writeln('<td>$longitud</td>');
      buffer.writeln('<td>$hash</td>');
      buffer.writeln('</tr>');
    }

    buffer.writeln('</table></body></html>');

    final ahora = DateTime.now();
    final nombreArchivo =
        'Reporte_STPS_${ahora.year}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}';

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));

    await FileSaver.instance.saveFile(
      name: nombreArchivo,
      bytes: bytes,
      fileExtension: 'xls',
      mimeType: MimeType.microsoftExcel,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte Excel descargado: $nombreArchivo.xls'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  String _formatearFechaSimple(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _editarChecada(Map<String, dynamic> registro) async {
    final tipoController = TextEditingController(
      text: registro['tipoChecada'] ?? 'Entrada',
    );
    final motivoController = TextEditingController();

    // Parsear el timestamp actual
    DateTime? timestampSeleccionado;
    final timestampStr = registro['timestampServidor'] as String?;
    if (timestampStr != null) {
      try {
        timestampSeleccionado = DateTime.parse(timestampStr).toLocal();
      } catch (_) {
        timestampSeleccionado = DateTime.now();
      }
    }

    bool guardando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Checada'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Empleado: ${registro['empleado']} (${registro['numeroEmpleado']})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Empresa: ${registro['empresa'] ?? 'N/A'}'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Tipo de checada
                DropdownButtonFormField<String>(
                  value: tipoController.text,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de checada',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Entrada', child: Text('Entrada')),
                    DropdownMenuItem(value: 'Salida', child: Text('Salida')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => tipoController.text = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Fecha y hora del registro
                InkWell(
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: timestampSeleccionado ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (fecha == null) return;

                    if (!context.mounted) return;
                    final hora = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        timestampSeleccionado ?? DateTime.now(),
                      ),
                    );
                    if (hora == null) return;

                    setDialogState(() {
                      timestampSeleccionado = DateTime(
                        fecha.year,
                        fecha.month,
                        fecha.day,
                        hora.hour,
                        hora.minute,
                      );
                    });
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha y hora del registro',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      timestampSeleccionado != null
                          ? '${timestampSeleccionado!.day.toString().padLeft(2, '0')}/${timestampSeleccionado!.month.toString().padLeft(2, '0')}/${timestampSeleccionado!.year} ${timestampSeleccionado!.hour.toString().padLeft(2, '0')}:${timestampSeleccionado!.minute.toString().padLeft(2, '0')}'
                          : 'Sin fecha',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Motivo
                TextField(
                  controller: motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de la corrección',
                    hintText: 'Ej. El empleado marcó entrada por error',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nota: La corrección quedará registrada en la bitácora de auditoría.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      setDialogState(() => guardando = true);
                      try {
                        // Convertir el timestamp a UTC (ISO 8601)
                        final timestampUtc = timestampSeleccionado
                            ?.toUtc()
                            .toIso8601String();

                        await ApiService.editarChecada(
                          registroId: registro['registroId'],
                          tipoChecada: tipoController.text,
                          timestampServidor: timestampUtc,
                          motivoCorreccion: motivoController.text.trim().isEmpty
                              ? null
                              : motivoController.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checada editada correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _generarReporte();
                        }
                      } catch (e) {
                        setDialogState(() => guardando = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
              child: guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarChecada(Map<String, dynamic> registro) async {
    final motivoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Checada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de eliminar esta checada?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Empleado: ${registro['empleado']} (${registro['numeroEmpleado']})',
            ),
            Text('Tipo: ${registro['tipoChecada']}'),
            Text('Método: ${registro['metodoUsado']}'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo de la eliminación',
                hintText: 'Ej. Checada duplicada por error',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nota: La eliminación quedará registrada en la bitácora de auditorí­a.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.eliminarChecada(
        registroId: registro['registroId'],
        motivo: motivoController.text.trim().isEmpty
            ? null
            : motivoController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checada eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _generarReporte();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _nuevaChecada() async {
    // Cargar lista de empleados (para el dropdown)
    List<dynamic> empleados = [];
    try {
      empleados = await ApiService.listarEmpleados();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando empleados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (empleados.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay empleados registrados. Crea uno primero.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    String? empleadoSeleccionado = empleados[0]['empleadoId'] as String?;
    String tipoChecada = 'Entrada';
    DateTime timestampSeleccionado = DateTime.now();
    final motivoController = TextEditingController();
    bool guardando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva Checada Manual'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crea una checada manualmente. Quedará registrada en la auditoría.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),

                // Empleado
                DropdownButtonFormField<String>(
                  value: empleadoSeleccionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Empleado',
                    border: OutlineInputBorder(),
                  ),
                  items: empleados
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e['empleadoId'] as String,
                          child: Text(
                            '${e['nombreCompleto']} (${e['numeroEmpleado']})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => empleadoSeleccionado = value),
                ),
                const SizedBox(height: 16),

                // Tipo
                DropdownButtonFormField<String>(
                  value: tipoChecada,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de checada',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Entrada', child: Text('Entrada')),
                    DropdownMenuItem(value: 'Salida', child: Text('Salida')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => tipoChecada = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Fecha y hora
                InkWell(
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: timestampSeleccionado,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (fecha == null) return;

                    if (!context.mounted) return;
                    final hora = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        timestampSeleccionado,
                      ),
                    );
                    if (hora == null) return;

                    setDialogState(() {
                      timestampSeleccionado = DateTime(
                        fecha.year,
                        fecha.month,
                        fecha.day,
                        hora.hour,
                        hora.minute,
                      );
                    });
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha y hora',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${timestampSeleccionado.day.toString().padLeft(2, '0')}/${timestampSeleccionado.month.toString().padLeft(2, '0')}/${timestampSeleccionado.year} ${timestampSeleccionado.hour.toString().padLeft(2, '0')}:${timestampSeleccionado.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Motivo
                TextField(
                  controller: motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de la creación',
                    hintText: 'Ej. El empleado olvidó checar',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      if (empleadoSeleccionado == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selecciona un empleado'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => guardando = true);
                      try {
                        await ApiService.crearChecadaManual(
                          empleadoId: empleadoSeleccionado!,
                          tipoChecada: tipoChecada,
                          timestampServidor: timestampSeleccionado
                              .toUtc()
                              .toIso8601String(),
                          metodoUsado: 'Manual',
                          motivoCreacion: motivoController.text.trim().isEmpty
                              ? null
                              : motivoController.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checada creada correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _generarReporte();
                        }
                      } catch (e) {
                        setDialogState(() => guardando = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
              child: guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Crear Checada'),
            ),
          ],
        ),
      ),
    );
  }
}
