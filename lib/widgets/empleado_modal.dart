import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import 'camara_web_dialog.dart';

/// Muestra el diálogo de alta de empleado.
/// [onGuardado] se ejecuta después de guardar exitosamente.
Future<void> mostrarModalAltaEmpleado(BuildContext context, {required VoidCallback onGuardado}) async {
  final nombreController = TextEditingController();
  final numeroController = TextEditingController();
  final pinController = TextEditingController();
  String metodoSeleccionado = 'QR';
  String? sucursalSeleccionada;
  String? turnoSeleccionado;
  bool guardando = false;
  final List<String?> fotos = [null, null, null];
  final List<String> etiquetas = ['Foto Frontal (Obligatoria)', 'Perfil Izquierdo (Recomendada)', 'Perfil Derecho (Recomendada)'];

  List<dynamic> sucursales = [];
  List<dynamic> turnos = [];
  try {
    sucursales = await ApiService.listarSucursales();
    turnos = await ApiService.listarTurnos();
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando catálogos: $e'), backgroundColor: Colors.red));
  }

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
                        DropdownMenuItem(value: 'QR', child: Text('QR solo')),
                        DropdownMenuItem(value: 'QR+Rostro', child: Text('QR + Rostro')),
                        DropdownMenuItem(value: 'ID+PIN', child: Text('ID + PIN')),
                        DropdownMenuItem(value: 'ID+Rostro', child: Text('ID + Rostro')),
                        DropdownMenuItem(value: 'Rostro', child: Text('Solo Rostro')),
                      ],
                      onChanged: (value) => setStateDialog(() => metodoSeleccionado = value!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: sucursalSeleccionada,
                      decoration: const InputDecoration(labelText: 'Sucursal', border: OutlineInputBorder()),
                      items: sucursales.map((s) => DropdownMenuItem(value: s['sucursalId'] as String, child: Text(s['nombre'] ?? 'Sin nombre'))).toList(),
                      onChanged: (value) => setStateDialog(() => sucursalSeleccionada = value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: turnoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Turno', border: OutlineInputBorder()),
                      items: turnos.map((t) => DropdownMenuItem(value: t['turnoId'] as String, child: Text(t['nombre'] ?? 'Sin nombre'))).toList(),
                      onChanged: (value) => setStateDialog(() => turnoSeleccionado = value),
                    ),
                    const SizedBox(height: 16),
                    const Text('Registro Facial (3 Fotos)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...List.generate(3, (index) {
                      final tieneFoto = fotos[index] != null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  String? fotoBase64;
                                  if (kIsWeb) {
                                    try {
                                      final cameras = await availableCameras();
                                      if (cameras.isNotEmpty) {
                                        fotoBase64 = await showDialog<String>(
                                          context: context,
                                          builder: (context) => const CamaraWebDialog(),
                                        );
                                      } else {
                                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se detectó cámara web.'), backgroundColor: Colors.orange));
                                      }
                                    } catch (e) {
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al abrir cámara: $e'), backgroundColor: Colors.red));
                                    }
                                  } else {
                                    try {
                                      final picker = ImagePicker();
                                      final XFile? image = await picker.pickImage(source: ImageSource.camera, maxWidth: 300, imageQuality: 50);
                                      if (image != null) {
                                        final bytes = await image.readAsBytes();
                                        fotoBase64 = base64Encode(bytes);
                                      }
                                    } catch (e) {
                                      try {
                                        final picker = ImagePicker();
                                        final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, imageQuality: 50);
                                        if (image != null) {
                                          final bytes = await image.readAsBytes();
                                          fotoBase64 = base64Encode(bytes);
                                        }
                                      } catch (e2) {
                                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e2'), backgroundColor: Colors.red));
                                      }
                                    }
                                  }
                                  if (fotoBase64 != null) setStateDialog(() => fotos[index] = fotoBase64);
                                },
                                icon: Icon(tieneFoto ? Icons.check_circle : Icons.camera_alt, color: Colors.white),
                                label: Text(etiquetas[index]),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tieneFoto ? Colors.green : (index == 0 ? Colors.blue.shade700 : Colors.grey.shade600),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            if (tieneFoto)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setStateDialog(() => fotos[index] = null),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: guardando
                    ? null
                    : () async {
                        if (nombreController.text.trim().isEmpty || numeroController.text.trim().isEmpty) return;
                        final metodosConRostro = ['QR+Rostro', 'ID+Rostro', 'Rostro'];
                        if (metodosConRostro.contains(metodoSeleccionado) && fotos[0] == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El método seleccionado requiere al menos la foto frontal.'), backgroundColor: Colors.red));
                          return;
                        }
                        setStateDialog(() => guardando = true);
                        try {
                          final fotosValidas = fotos.where((f) => f != null).cast<String>().toList();
                          final response = await ApiService.altaEmpleado(
                            numeroEmpleado: numeroController.text.trim(),
                            nombreCompleto: nombreController.text.trim(),
                            pinRespaldo: pinController.text.trim(),
                            metodoLectura: metodoSeleccionado,
                            fotosBase64: fotosValidas,
                            sucursalId: sucursalSeleccionada,
                            turnoId: turnoSeleccionado,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          onGuardado();
                          if (context.mounted) {
                            _mostrarAcuseLegal(context, response['acuseContenido'] ?? '');
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          setStateDialog(() => guardando = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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

/// Muestra el diálogo de edición de empleado.
Future<void> mostrarModalEditarEmpleado(BuildContext context, Map<String, dynamic> empleado, {required VoidCallback onGuardado}) async {
  // Implementación similar a la de alta, adaptada para editar
  // ... (puedes copiar la lógica de _mostrarDialogoEditarEmpleado aquí)
}

/// Muestra el acuse legal en un diálogo.
void _mostrarAcuseLegal(BuildContext context, String acuse) {
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
