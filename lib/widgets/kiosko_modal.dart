import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Muestra el diálogo de Alta Directa de Kiosko.
Future<void> mostrarModalAltaKiosko(BuildContext context, {required VoidCallback onGuardado}) async {
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
                  onPressed: guardando
                      ? null
                      : () async {
                          if (nombreController.text.trim().isEmpty || deviceIdController.text.trim().isEmpty) return;
                          setStateDialog(() => guardando = true);
                          try {
                            final response = await ApiService.altaDirectaKiosko(
                              nombre: nombreController.text.trim(),
                              tipo: tipoSeleccionado,
                              deviceId: deviceIdController.text.trim(),
                            );
                            setStateDialog(() { tokenGenerado = response['tokenPuntoLectura'] as String? ?? 'Sin token'; guardando = false; });
                            onGuardado();
                          } catch (e) {
                            setStateDialog(() => guardando = false);
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                  child: guardando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Registrar', style: TextStyle(color: Colors.white)),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () { Navigator.pop(context); onGuardado(); },
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

/// Muestra el diálogo de edición de Kiosko.
Future<void> mostrarModalEditarKiosko(BuildContext context, Map<String, dynamic> kiosko, {required VoidCallback onGuardado}) async {
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
                  final dialogContext = context;
                  try {
                    await ApiService.editarKiosko(id: kiosko['puntoLecturaId'], nombre: nombreController.text.trim(), tipo: tipoSeleccionado);
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    onGuardado();
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiosko actualizado correctamente')));
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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

/// Muestra el diálogo de revocación de Kiosko.
Future<void> mostrarModalRevocarKiosko(BuildContext context, String id, {required VoidCallback onGuardado}) async {
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
      onGuardado();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiosko revocado')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}

/// Muestra el diálogo para regenerar el código de un Kiosko.
Future<void> mostrarModalRegenerarCodigo(BuildContext context, Map<String, dynamic> kiosko, {required VoidCallback onGuardado}) async {
  try {
    final response = await ApiService.regenerarCodigoKiosko(kiosko['puntoLecturaId']);
    if (!context.mounted) return;
    onGuardado();
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
            onPressed: () { Navigator.pop(context); onGuardado(); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al regenerar: $e'), backgroundColor: Colors.red));
  }
}
