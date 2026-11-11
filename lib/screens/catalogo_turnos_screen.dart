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
                        onPressed: () => _mostrarModalTurno(),
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
                                title: Text(t['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${detalles.length} días configurados'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: Colors.blue),
                                      tooltip: 'Ver horario',
                                      onPressed: () => _mostrarDetalleTurno(t),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Editar',
                                      onPressed: () => _mostrarModalTurno(turno: t),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Eliminar',
                                      onPressed: () => _eliminarTurno(t),
                                    ),
                                  ],
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

  void _mostrarModalTurno({dynamic turno}) {
    final nombreCtrl = TextEditingController(text: turno?['nombre']);
    final esEdicion = turno != null;
    
    // Lista de detalles (si es edición, cargamos los existentes; si no, generamos L-V)
    List<Map<String, dynamic>> detalles = [];
    if (esEdicion && turno['detalles'] != null) {
      detalles = (turno['detalles'] as List).map((d) => Map<String, dynamic>.from(d)).toList();
    } else {
      for (int i = 1; i <= 7; i++) {
        detalles.add({
          'diaSemana': i,
          'horaEntrada': i <= 5 ? '09:00:00' : '00:00:00',
          'horaSalida': i <= 5 ? '18:00:00' : '00:00:00',
          'toleranciaMin': i <= 5 ? 10 : 0,
          'esLaborable': i <= 5,
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(esEdicion ? 'Editar Turno' : 'Nuevo Turno'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del turno', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      const Text('Configuración por día:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...detalles.map((d) {
                        final index = detalles.indexOf(d);
                        final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
                        final dia = dias[(d['diaSemana'] as int) - 1];
                        final laborable = d['esLaborable'] as bool;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    SizedBox(width: 100, child: Text(dia, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    Switch(
                                      value: laborable,
                                      onChanged: (val) {
                                        setStateDialog(() {
                                          detalles[index]['esLaborable'] = val;
                                        });
                                      },
                                    ),
                                    if (!laborable) const Text('No laborable', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                                if (laborable)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            final hora = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                                            if (hora != null) {
                                              setStateDialog(() {
                                                detalles[index]['horaEntrada'] = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00';
                                              });
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: const InputDecoration(labelText: 'Entrada', border: OutlineInputBorder()),
                                            child: Text(detalles[index]['horaEntrada'] ?? ''),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            final hora = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                                            if (hora != null) {
                                              setStateDialog(() {
                                                detalles[index]['horaSalida'] = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00';
                                              });
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: const InputDecoration(labelText: 'Salida', border: OutlineInputBorder()),
                                            child: Text(detalles[index]['horaSalida'] ?? ''),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: (detalles[index]['toleranciaMin'] ?? 10).toString(),
                                          decoration: const InputDecoration(labelText: 'Tol. (min)', border: OutlineInputBorder()),
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) {
                                            detalles[index]['toleranciaMin'] = int.tryParse(val) ?? 0;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    try {
                      if (esEdicion) {
                        await ApiService.editarTurno(
                          id: turno['turnoId'],
                          nombre: nombreCtrl.text.trim(),
                          colorHex: turno['colorHex'] ?? '#0F766E',
                          detalles: detalles,
                        );
                      } else {
                        await ApiService.crearTurno(
                          nombre: nombreCtrl.text.trim(),
                          colorHex: '#0F766E',
                          detalles: detalles,
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                      _cargarTurnos();
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                  child: Text(esEdicion ? 'Guardar' : 'Crear', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _eliminarTurno(dynamic turno) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Turno'),
        content: Text('¿Estás seguro de eliminar "${turno['nombre']}"?'),
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
        await ApiService.eliminarTurno(turno['turnoId']);
        _cargarTurnos();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Turno eliminado')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
