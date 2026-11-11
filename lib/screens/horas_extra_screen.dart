import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/api_service.dart';
import '../widgets/reportes_filtros.dart';

class HorasExtraScreen extends StatefulWidget {
  const HorasExtraScreen({super.key});

  @override
  State<HorasExtraScreen> createState() => _HorasExtraScreenState();
}

class _HorasExtraScreenState extends State<HorasExtraScreen> {
  Map<String, dynamic>? _datos;
  bool _cargando = false;
  String? _error;

  Future<void> _cargarReporte({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? cuentaId,
    String? sucursalId,
    String? empleadoId,
  }) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await ApiService.obtenerReporteHorasExtra(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        cuentaId: cuentaId,
        sucursalId: sucursalId,
        empleadoId: empleadoId,
      );
      setState(() {
        _datos = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _exportarExcel() async {
    if (_datos == null) return;
    final detalle = _datos!['detalle'] as List;
    final resumen = _datos!['resumen'] as Map;

    final buffer = StringBuffer();
    buffer.writeln('<html><head><meta charset="UTF-8"></head><body>');
    buffer.writeln('<h2>Reporte de Horas Extra - ${_datos!['fechaInicio']} al ${_datos!['fechaFin']}</h2>');
    buffer.writeln('<table border="1">');
    buffer.writeln('<tr><th>Fecha</th><th>Empleado</th><th>Número</th><th>Turno</th><th>Entrada</th><th>Salida</th><th>Horas Trabajadas</th><th>Horas Esperadas</th><th>Horas Extra</th></tr>');
    
    for (var d in detalle) {
      buffer.writeln('<tr>');
      buffer.writeln('<td>${d['fecha']}</td>');
      buffer.writeln('<td>${d['nombreCompleto']}</td>');
      buffer.writeln('<td>${d['numeroEmpleado']}</td>');
      buffer.writeln('<td>${d['turnoNombre']}</td>');
      buffer.writeln('<td>${d['horaEntrada'] ?? '-'}</td>');
      buffer.writeln('<td>${d['horaSalida'] ?? '-'}</td>');
      buffer.writeln('<td>${d['horasTrabajadas']}</td>');
      buffer.writeln('<td>${d['horasEsperadas']}</td>');
      buffer.writeln('<td>${d['horasExtra']}</td>');
      buffer.writeln('</tr>');
    }
    buffer.writeln('</table>');
    buffer.writeln('<p><b>Resumen:</b> Total Registros: ${resumen['totalRegistros']} | Total Horas Extra: ${resumen['totalHorasExtra']} hrs</p>');
    buffer.writeln('</body></html>');

    final nombreArchivo = 'HorasExtra_${_datos!['fechaInicio']}_${_datos!['fechaFin']}';
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    
    await FileSaver.instance.saveFile(
      name: nombreArchivo,
      bytes: bytes,
      fileExtension: 'xls',
      mimeType: MimeType.microsoftExcel,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel descargado')));
    }
  }

  Future<void> _exportarPDF() async {
    if (_datos == null) return;
    final detalle = _datos!['detalle'] as List;
    final resumen = _datos!['resumen'] as Map;

    final logo = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logo.buffer.asUint8List());
    final fechaGeneracion = DateTime.now();
    final horaGeneracion = '${fechaGeneracion.day}/${fechaGeneracion.month}/${fechaGeneracion.year} '
        '${fechaGeneracion.hour.toString().padLeft(2, '0')}:${fechaGeneracion.minute.toString().padLeft(2, '0')}';

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Image(logoImage, height: 40),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('AppCheck', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                          pw.Text('Reporte de Horas Extra', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Generado el:', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text(horaGeneracion, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.teal, thickness: 2),
              pw.SizedBox(height: 10),
              pw.Text('Período: ${_datos!['fechaInicio']} al ${_datos!['fechaFin']}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('AppCheck - Control de Asistencia', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) => [
          pw.Text('Resumen Ejecutivo', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfKpi('Total Registros', resumen['totalRegistros'].toString()),
              _pdfKpi('Total Horas Extra', '${resumen['totalHorasExtra']}h'),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Detalle de Horas', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Fecha', 'Empleado', 'Número', 'Turno', 'Entrada', 'Salida', 'Hrs Trab.', 'Hrs Esp.', 'Hrs Extra'],
            data: detalle.map((d) => [
              d['fecha'],
              d['nombreCompleto'],
              d['numeroEmpleado'],
              d['turnoNombre'],
              d['horaEntrada'] ?? '-',
              d['horaSalida'] ?? '-',
              d['horasTrabajadas'].toString(),
              d['horasEsperadas'].toString(),
              d['horasExtra'].toString(),
            ]).toList(),
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            cellStyle: const pw.TextStyle(fontSize: 8),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final nombreArchivo = 'HorasExtra_${_datos!['fechaInicio']}_${_datos!['fechaFin']}';
    
    await FileSaver.instance.saveFile(
      name: nombreArchivo,
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF descargado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Horas Extra'),
        backgroundColor: const Color(0xFF0F766E),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'excel') _exportarExcel();
              if (value == 'pdf') _exportarPDF();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'excel', child: Text('Descargar Excel')),
              const PopupMenuItem(value: 'pdf', child: Text('Descargar PDF')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportesFiltros(
              fechaInicio: DateTime.now().subtract(const Duration(days: 7)),
              fechaFin: DateTime.now(),
              onGenerar: ({
                required DateTime fechaInicio,
                required DateTime fechaFin,
                String? cuentaId,
                String? sucursalId,
                String? empleadoId,
              }) {
                _cargarReporte(
                  fechaInicio: fechaInicio,
                  fechaFin: fechaFin,
                  cuentaId: cuentaId,
                  sucursalId: sucursalId,
                  empleadoId: empleadoId,
                );
              },
            ),
            const SizedBox(height: 24),
            if (_cargando)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
            else if (_datos != null) ...[
              Row(
                children: [
                  _kpiCard('Total Registros', _datos!['resumen']['totalRegistros'].toString(), Colors.blue),
                  const SizedBox(width: 12),
                  _kpiCard('Total Horas Extra', '${_datos!['resumen']['totalHorasExtra']}h', Colors.green),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Detalle de Horas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                  ),
                  child: (_datos!['detalle'] as List).isEmpty
                      ? const Center(child: Text('No hay registros para los filtros seleccionados.'))
                      : ListView.separated(
                          itemCount: (_datos!['detalle'] as List).length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final d = _datos!['detalle'][index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE0F2F1),
                                child: Icon(Icons.timer, color: Color(0xFF0F766E)),
                              ),
                              title: Text('${d['fecha']} - ${d['nombreCompleto']} (${d['numeroEmpleado']})'),
                              subtitle: Text('Turno: ${d['turnoNombre']} | Entrada: ${d['horaEntrada'] ?? '-'} | Salida: ${d['horaSalida'] ?? '-'}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${d['horasTrabajadas']}h trabajadas', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${d['horasExtra']}h extra', style: TextStyle(color: d['horasExtra'] > 0 ? Colors.green : Colors.grey)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(valor, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 28)),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfKpi(String label, String valor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.teal, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        children: [
          pw.Text(valor, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }
}
