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
                        onPressed: _mostrarModalNuevaSucursal,
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
                                trailing: Text(
                                  'Radio: ${s['radioMetros']}m',
                                  style: const TextStyle(color: Colors.grey),
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
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre (Obligatorio)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dirCtrl,
                decoration: const InputDecoration(labelText: 'Dirección (Opcional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latCtrl,
                      decoration: const InputDecoration(labelText: 'Latitud', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lngCtrl,
                      decoration: const InputDecoration(labelText: 'Longitud', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: radioCtrl,
                decoration: const InputDecoration(labelText: 'Radio permitido (metros)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
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
                await ApiService.crearSucursal(
                  nombre: nombreCtrl.text.trim(),
                  direccion: dirCtrl.text.trim().isEmpty ? null : dirCtrl.text.trim(),
                  latitud: double.tryParse(latCtrl.text),
                  longitud: double.tryParse(lngCtrl.text),
                  radioMetros: int.tryParse(radioCtrl.text) ?? 100,
                );
                if (context.mounted) Navigator.pop(context);
                _cargarSucursales();
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
}
