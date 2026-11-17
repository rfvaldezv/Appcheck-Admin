import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CamaraWebDialog extends StatefulWidget {
  const CamaraWebDialog({super.key});

  @override
  State<CamaraWebDialog> createState() => _CamaraWebDialogState();
}

class _CamaraWebDialogState extends State<CamaraWebDialog> {
  CameraController? _controller;
  bool _isReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No se encontró ninguna cámara.');
        return;
      }
      // Usar la primera cámara disponible (usualmente la webcam frontal)
      _controller = CameraController(cameras.first, ResolutionPreset.medium);
      await _controller!.initialize();
      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al iniciar cámara: $e');
    }
  }

  Future<void> _tomarFoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile foto = await _controller!.takePicture();
      final bytes = await foto.readAsBytes();
      final base64 = base64Encode(bytes);
      if (mounted) Navigator.pop(context, base64);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tomar Foto'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
            : !_isReady
                ? const Center(child: CircularProgressIndicator())
                : CameraPreview(_controller!),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        if (_isReady)
          ElevatedButton.icon(
            onPressed: _tomarFoto,
            icon: const Icon(Icons.camera),
            label: const Text('Capturar'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
          ),
      ],
    );
  }
}
