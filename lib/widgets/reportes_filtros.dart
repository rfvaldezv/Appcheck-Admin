import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportesFiltros extends StatefulWidget {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? cuentaId;
  final String? sucursalId;
  final String? empleadoId;
  final Function({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? cuentaId,
    String? sucursalId,
    String? empleadoId,
  }) onGenerar;

  const ReportesFiltros({
    super.key,
    required this.fechaInicio,
    required this.fechaFin,
    this.cuentaId,
    this.sucursalId,
    this.empleadoId,
    required this.onGenerar,
  });

  @override
  State<ReportesFiltros> createState() => _ReportesFiltrosState();
}

class _ReportesFiltrosState extends State<ReportesFiltros> {
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  String? _cuentaId;
  String? _sucursalId;
  String? _empleadoId;

  List<dynamic> _empresas = [];
  List<dynamic> _sucursales = [];
  List<dynamic> _empleados = [];

  @override
  void initState() {
    super.initState();
    _fechaInicio = widget.fechaInicio;
    _fechaFin = widget.fechaFin;
    _cuentaId = widget.cuentaId;
    _sucursalId = widget.sucursalId;
    _empleadoId = widget.empleadoId;
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final results = await Future.wait([
        ApiService.listarEmpresas(),
        ApiService.listarSucursales(),
        ApiService.listarEmpleados(),
      ]);
      if (mounted) {
        setState(() {
          _empresas = results[0];
          _sucursales = results[1];
          _empleados = results[2];
        });
      }
    } catch (e) {
      // Silencioso
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Fechas
          _buildFechaSelector('Fecha Inicio', _fechaInicio, (d) => setState(() => _fechaInicio = d)),
          _buildFechaSelector('Fecha Fin', _fechaFin, (d) => setState(() => _fechaFin = d)),
          
          // Empresa
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              value: _cuentaId,
              decoration: const InputDecoration(labelText: 'Empresa', border: OutlineInputBorder(), isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._empresas.map((e) => DropdownMenuItem(value: e['cuentaId'] as String, child: Text(e['nombreComercial'] ?? ''))),
              ],
              onChanged: (val) => setState(() => _cuentaId = val),
            ),
          ),

          // Sucursal
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              value: _sucursalId,
              decoration: const InputDecoration(labelText: 'Sucursal', border: OutlineInputBorder(), isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._sucursales.map((s) => DropdownMenuItem(value: s['sucursalId'] as String, child: Text(s['nombre'] ?? ''))),
              ],
              onChanged: (val) => setState(() => _sucursalId = val),
            ),
          ),

          // Empleado
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              value: _empleadoId,
              decoration: const InputDecoration(labelText: 'Empleado', border: OutlineInputBorder(), isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ..._empleados.map((e) => DropdownMenuItem(value: e['empleadoId'] as String, child: Text('${e['nombreCompleto']} (${e['numeroEmpleado']})', overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (val) => setState(() => _empleadoId = val),
            ),
          ),

          // Botón Generar
          ElevatedButton.icon(
            onPressed: () {
              widget.onGenerar(
                fechaInicio: _fechaInicio,
                fechaFin: _fechaFin,
                cuentaId: _cuentaId,
                sucursalId: _sucursalId,
                empleadoId: _empleadoId,
              );
            },
            icon: const Icon(Icons.search),
            label: const Text('Generar Reporte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFechaSelector(String label, DateTime fecha, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: fecha, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, suffixIcon: const Icon(Icons.calendar_today, size: 16)),
        child: Text('${fecha.day}/${fecha.month}/${fecha.year}'),
      ),
    );
  }
}
