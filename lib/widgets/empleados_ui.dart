import 'package:flutter/material.dart';

/// Construye la pantalla de gestión de empleados.
Widget buildEmpleadosUI({
  required BuildContext context,
  required bool isDesktop,
  required List<dynamic> empleados,
  required bool cargandoEmpleados,
  required String filtroEmpleados,
  required String filtroEstadoEmpleados,
  required String filtroEmpresaEmpleados,
  required String filtroVendedorEmpleados,
  required Function(String) onFiltroEmpleadosChanged,
  required Function(String) onFiltroEstadoChanged,
  required Function(String) onFiltroEmpresaChanged,
  required Function(String) onFiltroVendedorChanged,
  required VoidCallback onAltaEmpleado,
  required Function(Map<String, dynamic>) onEditarEmpleado,
  required Function(String) onEliminarEmpleado,
  required Widget Function(String) chipEstado,
}) {
  final empresas = empleados.map((e) => e['empresa'] ?? 'N/A').toSet().toList();
  final vendedores = empleados.map((e) => e['vendedor'] ?? 'Sin vendedor').toSet().toList();

  final empleadosFiltrados = empleados.where((e) {
    final nombre = (e['nombreCompleto'] ?? '').toString().toLowerCase();
    final numero = (e['numeroEmpleado'] ?? '').toString().toLowerCase();
    final coincideTexto = nombre.contains(filtroEmpleados.toLowerCase()) || numero.contains(filtroEmpleados.toLowerCase());

    final estado = e['estado'] ?? 'Activo';
    final coincideEstado = filtroEstadoEmpleados == 'Todos' || estado == filtroEstadoEmpleados;

    final empresa = e['empresa'] ?? 'N/A';
    final coincideEmpresa = filtroEmpresaEmpleados == 'Todas' || empresa == filtroEmpresaEmpleados;

    final vendedor = e['vendedor'] ?? 'Sin vendedor';
    final coincideVendedor = filtroVendedorEmpleados == 'Todos' || vendedor == filtroVendedorEmpleados;

    return coincideTexto && coincideEstado && coincideEmpresa && coincideVendedor;
  }).toList();

  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Empleados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: onAltaEmpleado,
              icon: const Icon(Icons.person_add),
              label: const Text('Dar de Alta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 250,
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre o número...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: onFiltroEmpleadosChanged,
              ),
            ),
            DropdownButton<String>(
              value: filtroEstadoEmpleados,
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos (Estado)')),
                DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo')),
              ],
              onChanged: (value) { if (value != null) onFiltroEstadoChanged(value); },
            ),
            DropdownButton<String>(
              value: filtroEmpresaEmpleados,
              items: [
                const DropdownMenuItem(value: 'Todas', child: Text('Todas (Empresa)')),
                ...empresas.map((e) => DropdownMenuItem(value: e, child: Text(e))),
              ],
              onChanged: (value) { if (value != null) onFiltroEmpresaChanged(value); },
            ),
            DropdownButton<String>(
              value: filtroVendedorEmpleados,
              items: [
                const DropdownMenuItem(value: 'Todos', child: Text('Todos (Vendedor)')),
                ...vendedores.map((v) => DropdownMenuItem(value: v, child: Text(v))),
              ],
              onChanged: (value) { if (value != null) onFiltroVendedorChanged(value); },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: cargandoEmpleados
              ? const Center(child: CircularProgressIndicator())
              : empleadosFiltrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay empleados que coincidan con los filtros.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                      ),
                      child: ListView.separated(
                        itemCount: empleadosFiltrados.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final empleado = empleadosFiltrados[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                              child: Text(
                                (empleado['nombreCompleto'] as String? ?? 'E').substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(empleado['nombreCompleto'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nómina: ${empleado['numeroEmpleado']} • Método: ${empleado['metodoLecturaPreferido']}'),
                                Text('Empresa: ${empleado['empresa'] ?? 'N/A'} • Vendedor: ${empleado['vendedor'] ?? 'Sin vendedor'}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isDesktop) chipEstado(empleado['estado'] ?? 'Activo'),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => onEditarEmpleado(empleado),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                                  onPressed: () => onEliminarEmpleado(empleado['empleadoId']),
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
  );
}
