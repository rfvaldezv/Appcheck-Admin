import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CatalogoSucursalesScreen extends StatefulWidget {
  const CatalogoSucursalesScreen({super.key});

  @override
  State<CatalogoSucursalesScreen> createState() => _CatalogoSucursalesScreenState();
}

class _CatalogoSucursalesScreenState extends State<CatalogoSucursalesScreen> {
  List<dynamic> _sucursales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  Future<void> _cargarSucursales() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.listarSucursales();
      setState(() {
        _sucursales = data;
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
        title: const Text('Catálogo de Sucursales'),
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
                        'Total: ${_sucursales.length} sucursales',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _mostrarModalSucursal(),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva Sucursal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                        ),
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
                              elevation: 2,
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE0F2F1),
                                  child: Icon(Icons.store, color: Color(0xFF0F766E)),
                                ),
                                title: Text(
                                  s['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(s['direccion'] ?? 'Sin dirección registrada'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Radio: ${s['radioMetros']}m', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _mostrarModalSucursal(sucursal: s),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarSucursal(s),
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

  void _mostrarModalSucursal({dynamic sucursal}) {
    final nombreCtrl = TextEditingController(text: sucursal?['nombre']);
    final dirCtrl = TextEditingController(text: sucursal?['direccion']);
    final latCtrl = TextEditingController(text: sucursal?['latitud']?.toString());
    final lngCtrl = TextEditingController(text: sucursal?['longitud']?.toString());
    final radioCtrl = TextEditingController(text: sucursal?['radioMetros']?.toString() ?? '100');
    final esEdicion = sucursal != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(esEdicion ? 'Editar Sucursal' : 'Nueva Sucursal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: dirCtrl, decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitud', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: 'Longitud', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: radioCtrl, decoration: const InputDecoration(labelText: 'Radio (metros)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty) return;
              try {
                if (esEdicion) {
                  await ApiService.editarSucursal(
                    id: sucursal['sucursalId'],
                    nombre: nombreCtrl.text.trim(),
                    direccion: dirCtrl.text.trim().isEmpty ? null : dirCtrl.text.trim(),
                    latitud: double.tryParse(latCtrl.text),
                    longitud: double.tryParse(lngCtrl.text),
                    radioMetros: int.tryParse(radioCtrl.text) ?? 100,
                  );
                } else {
                  await ApiService.crearSucursal(
                    nombre: nombreCtrl.text.trim(),
                    direccion: dirCtrl.text.trim().isEmpty ? null : dirCtrl.text.trim(),
                    latitud: double.tryParse(latCtrl.text),
                    longitud: double.tryParse(lngCtrl.text),
                    radioMetros: int.tryParse(radioCtrl.text) ?? 100,
                  );
                }
                if (context.mounted) Navigator.pop(context);
                _cargarSucursales();
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
            child: Text(esEdicion ? 'Guardar' : 'Crear', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarSucursal(dynamic sucursal) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Sucursal'),
        content: Text('¿Estás seguro de eliminar "${sucursal['nombre']}"?'),
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
        await ApiService.eliminarSucursal(sucursal['sucursalId']);
        _cargarSucursales();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sucursal eliminada')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
