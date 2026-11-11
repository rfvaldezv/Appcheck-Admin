import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CatalogoTurnosScreen extends StatefulWidget {
  const CatalogoTurnosScreen({super.key});

  @override
  State<CatalogoTurnosScreen> createState() => _CatalogoTurnosScreenState();
}

class _CatalogoTurnosScreenState extends State<CatalogoTurnosScreen> {
  List<dynamic> _turnos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarTurnos();
  }

  Future<void> _cargarTurnos() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.listarTurnos();
      setState(() {
        _turnos = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Turnos'),
        backgroundColor: const Color(0xFF0F766E),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${_turnos.length} turnos',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ElevatedButton.icon(
                        onPressed: _mostrarModalNuevoTurno,
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo Turno'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                        ),
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
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE0F2F1),
                                  child: Icon(
                                    Icons.schedule,
                                    color: Color(int.tryParse(t['colorHex']?.replaceFirst('#', '0xff') ?? '0xff0F766E') ?? 0xff0F766E),
                                  ),
                                ),
                                title: Text(
                                  t['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('${detalles.length} días configurados'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.visibility, color: Colors.blue),
                                  onPressed: () => _mostrarDetalleTurno(t),
                                ),
                              ),
                            );
                          },
                        ),
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
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre (ej. Matutino, Vespertino)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Se creará con horario Lunes a Viernes de 09:00 a 18:00 hrs (10 min de tolerancia) y Sábado/Domingo no laborables.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre es obligatorio'), backgroundColor: Colors.red),
                );
                return;
              }
              try {
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
                  nombre: nombreCtrl.text.trim(),
                  colorHex: '#0F766E', // Color corporativo
                  detalles: detalles,
                );
                if (context.mounted) Navigator.pop(context);
                _cargarTurnos();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
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
        title: Text('Horario: ${turno['nombre']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: detalles.length,
            itemBuilder: (context, index) {
              final d = detalles[index];
              final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
              final int diaSemana = d['diaSemana'] as int;
              final bool laborable = d['esLaborable'] as bool? ?? false;
              
              return ListTile(
                title: Text(dias[diaSemana - 1], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  laborable 
                    ? 'Entrada: ${d['horaEntrada']} - Salida: ${d['horaSalida']} (Tolerancia: ${d['toleranciaMin']} min)'
                    : 'Día no laborable',
                  style: TextStyle(color: laborable ? Colors.black87 : Colors.red),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
