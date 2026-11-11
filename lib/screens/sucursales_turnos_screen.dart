import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SucursalesTurnosScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const SucursalesTurnosScreen({super.key, required this.usuario});

  @override
  State<SucursalesTurnosScreen> createState() => _SucursalesTurnosScreenState();
}

class _SucursalesTurnosScreenState extends State<SucursalesTurnosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _sucursales = [];
  List<dynamic> _turnos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      final suc = await ApiService.listarSucursales();
      final tur = await ApiService.listarTurnos();
      setState(() {
        _sucursales = suc;
        _turnos = tur;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sucursales y Turnos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Sucursales'),
            Tab(icon: Icon(Icons.schedule), text: 'Turnos'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSucursalesTab(),
                _buildTurnosTab(),
              ],
            ),
    );
  }

  // --- TAB DE SUCURSALES ---
  Widget _buildSucursalesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ${_sucursales.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _mostrarModalNuevaSucursal,
                icon: const Icon(Icons.add),
                label: const Text('Nueva Sucursal'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _sucursales.isEmpty
              ? const Center(child: Text('No hay sucursales registradas.'))
              : ListView.builder(
                  itemCount: _sucursales.length,
                  itemBuilder: (context, index) {
                    final s = _sucursales[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.store, color: Colors.teal),
                        title: Text(s['nombre'] ?? 'Sin nombre'),
                        subtitle: Text(s['direccion'] ?? 'Sin dirección'),
                        trailing: Text('Radio: ${s['radioMetros']}m'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB DE TURNOS ---
  Widget _buildTurnosTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ${_turnos.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _mostrarModalNuevoTurno,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Turno'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _turnos.isEmpty
              ? const Center(child: Text('No hay turnos registrados.'))
              : ListView.builder(
                  itemCount: _turnos.length,
                  itemBuilder: (context, index) {
                    final t = _turnos[index];
                    final detalles = t['detalles'] as List? ?? [];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.schedule, color: Color(int.parse(t['colorHex']!.replaceFirst('#', '0xff')))),
                        title: Text(t['nombre'] ?? 'Sin nombre'),
                        subtitle: Text('${detalles.length} días configurados'),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _mostrarDetalleTurno(t),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- MODALES ---
  void _mostrarModalNuevaSucursal() {
    final nombreCtrl = TextEditingController();
    final dirCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final radioCtrl = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Sucursal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre de la sucursal')),
              const SizedBox(height: 8),
              TextField(controller: dirCtrl, decoration: const InputDecoration(labelText: 'Dirección (opcional)')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitud'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: 'Longitud'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: radioCtrl, decoration: const InputDecoration(labelText: 'Radio permitido (metros)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.isEmpty) return;
              try {
                await ApiService.crearSucursal(
                  nombre: nombreCtrl.text,
                  direccion: dirCtrl.text.isEmpty ? null : dirCtrl.text,
                  latitud: double.tryParse(latCtrl.text),
                  longitud: double.tryParse(lngCtrl.text),
                  radioMetros: int.tryParse(radioCtrl.text) ?? 100,
                );
                if (context.mounted) Navigator.pop(context);
                _cargarDatos();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarModalNuevoTurno() {
    final nombreCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Turno'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del turno (ej. Matutino)')),
            const SizedBox(height: 16),
            const Text('Se creará con horario L-V de 09:00 a 18:00 por defecto.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.isEmpty) return;
              try {
                // Creamos el horario por defecto
                final detalles = List.generate(7, (index) {
                  final dia = index + 1;
                  final esLaborable = dia <= 5;
                  return {
                    'diaSemana': dia,
                    'horaEntrada': esLaborable ? '09:00:00' : '00:00:00',
                    'horaSalida': esLaborable ? '18:00:00' : '00:00:00',
                    'toleranciaMin': esLaborable ? 10 : 0,
                    'esLaborable': esLaborable,
                  };
                });

                await ApiService.crearTurno(
                  nombre: nombreCtrl.text,
                  colorHex: '#2196F3',
                  detalles: detalles,
                );
                if (context.mounted) Navigator.pop(context);
                _cargarDatos();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleTurno(dynamic turno) {
    final detalles = turno['detalles'] as List? ?? [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Turno: ${turno['nombre']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: detalles.length,
            itemBuilder: (context, index) {
              final d = detalles[index];
              final dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
              return ListTile(
                title: Text(dias[(d['diaSemana'] as int) - 1]),
                subtitle: Text(d['esLaborable'] ? '${d['horaEntrada']} - ${d['horaSalida']}' : 'No laborable'),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }
}
