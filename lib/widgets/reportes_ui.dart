import 'package:flutter/material.dart';

/// Construye la pantalla de Reportes STPS.
/// Recibe todos los datos y callbacks desde el DashboardScreen.
Widget buildReportesUI({
  required BuildContext context,
  required bool isDesktop,
  required String rolUsuario,
  required DateTime fechaInicio,
  required DateTime fechaFin,
  required Function(DateTime) onFechaInicioChanged,
  required Function(DateTime) onFechaFinChanged,
  required String? filtroEmpresa,
  required String? filtroVendedor,
  required String? filtroMetodo,
  required List<dynamic> empresas,
  required List<dynamic> vendedores,
  required List<String> metodos,
  required Function(String?) onFiltroEmpresaChanged,
  required Function(String?) onFiltroVendedorChanged,
  required Function(String?) onFiltroMetodoChanged,
  required bool cargandoReporte,
  required VoidCallback onGenerarReporte,
  required VoidCallback onNuevaChecada,
  required Map<String, dynamic>? reporteActual,
  required VoidCallback onExportarCSV,
  required VoidCallback onExportarExcel,
  required Function(Map<String, dynamic>) onEditarChecada,
  required Function(Map<String, dynamic>) onEliminarChecada,
  required String Function(DateTime) formatearFechaSimple,
  required String Function(DateTime) formatearFecha,
}) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reportes de Jornada (STPS)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecciona el periodo y descarga el reporte.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              // Fila 1: Fechas
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: formatearFechaSimple(fechaInicio),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Fecha Inicio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fechaInicio,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) onFechaInicioChanged(picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: formatearFechaSimple(fechaFin),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Fecha Fin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fechaFin,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) onFechaFinChanged(picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Fila 2: Filtros
              Row(
                children: [
                  if (rolUsuario == 'SuperAdmin')
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: filtroEmpresa,
                        decoration: const InputDecoration(
                          labelText: 'Empresa',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ...empresas.map(
                            (e) => DropdownMenuItem<String>(
                              value: e['cuentaId'] as String,
                              child: Text(e['nombreComercial'] as String? ?? 'Sin nombre'),
                            ),
                          ),
                        ],
                        onChanged: onFiltroEmpresaChanged,
                      ),
                    ),
                  if (rolUsuario == 'SuperAdmin') const SizedBox(width: 16),
                  if (rolUsuario == 'SuperAdmin')
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: filtroVendedor,
                        decoration: const InputDecoration(
                          labelText: 'Vendedor',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...vendedores.map(
                            (v) => DropdownMenuItem<String>(
                              value: v['usuarioId'] as String,
                              child: Text(v['nombre'] as String? ?? 'Sin nombre'),
                            ),
                          ),
                        ],
                        onChanged: onFiltroVendedorChanged,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: filtroMetodo,
                      decoration: const InputDecoration(
                        labelText: 'Método',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...metodos.map(
                          (m) => DropdownMenuItem<String>(
                            value: m,
                            child: Text(m),
                          ),
                        ),
                      ],
                      onChanged: onFiltroMetodoChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botón Generar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: cargandoReporte ? null : onGenerarReporte,
                      icon: const Icon(Icons.search),
                      label: Text(cargandoReporte ? 'Generando...' : 'Generar Reporte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: cargandoReporte ? null : onNuevaChecada,
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva Checada'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Tabla de resultados
        Expanded(
          child: reporteActual == null
              ? const Center(
                  child: Text(
                    'Selecciona un rango y genera el reporte.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : reporteActual['registros'].isEmpty
                  ? const Center(child: Text('No hay registros.'))
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: ${reporteActual['totalRegistros']} registros',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: onExportarCSV,
                                  icon: const Icon(Icons.download),
                                  tooltip: 'Exportar a CSV',
                                ),
                                IconButton(
                                  onPressed: onExportarExcel,
                                  icon: const Icon(Icons.table_chart),
                                  tooltip: 'Exportar a Excel',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.separated(
                              itemCount: reporteActual['registros'].length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final r = reporteActual['registros'][index];
                                final tipo = (r['tipoChecada'] as String? ?? 'N/A');
                                final empleado = (r['empleado'] as String? ?? 'Sin nombre');
                                final numero = (r['numeroEmpleado'] as String? ?? 'N/A');
                                final timestamp = r['timestampServidor'] as String?;
                                final fechaFormateada = timestamp != null
                                    ? formatearFecha(DateTime.parse(timestamp))
                                    : 'Sin fecha';

                                return ListTile(
                                  leading: Icon(
                                    tipo == 'Entrada' ? Icons.login : Icons.logout,
                                    color: tipo == 'Entrada' ? Colors.green : Colors.orange,
                                  ),
                                  title: Text('$empleado ($numero)'),
                                  subtitle: Text('$tipo • $fechaFormateada'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        tooltip: 'Editar checada',
                                        onPressed: () => onEditarChecada(r),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Eliminar checada',
                                        onPressed: () => onEliminarChecada(r),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    ),
  );
}
