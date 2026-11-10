import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  bool _cargando = true;
  String? _error;
  Map<String, dynamic>? _dashboard;

  @override
  void initState() {
    super.initState();
    _cargarDashboard();
  }

  Future<void> _cargarDashboard() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await ApiService.obtenerDashboard();
      if (mounted) {
        setState(() {
          _dashboard = data;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarDashboard,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final kpis = _dashboard!['kpis'] as Map<String, dynamic>;
    final graficos = _dashboard!['graficos'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumen General',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
                onPressed: _cargarDashboard,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Período: ${_dashboard!['periodo']['inicio']} al ${_dashboard!['periodo']['fin']}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          // KPIs grid
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _kpiCard('Total Checadas', '${kpis['totalChecadas']}', Icons.fingerprint, Colors.blue),
              _kpiCard('Empleados', '${kpis['totalEmpleados']}', Icons.people, Colors.orange),
              _kpiCard('Puntuales', '${kpis['porcentajePuntuales']}%', Icons.check_circle, Colors.green),
              _kpiCard('Retardos', '${kpis['porcentajeRetardos']}%', Icons.warning, Colors.red),
              _kpiCard('Horas Extra', '${kpis['horasExtra']}h', Icons.access_time, Colors.purple),
              _kpiCard('Ausencias', '${kpis['ausencias']}', Icons.person_off, Colors.brown),
              _kpiCard('Sucursales', '${kpis['totalSucursales']}', Icons.business, Colors.teal),
              _kpiCard('Kioskos', '${kpis['totalKioskos']}', Icons.devices, Colors.indigo),
            ],
          ),
          const SizedBox(height: 32),

          // Gráficos
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gráfico de checadas por día
              Expanded(
                flex: 2,
                child: _card(
                  'Checadas por Día',
                  SizedBox(
                    height: 300,
                    child: _graficoChecadasPorDia(graficos['checadasPorDia'] as List),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Gráfico de métodos usados
              Expanded(
                flex: 1,
                child: _card(
                  'Métodos Usados',
                  SizedBox(
                    height: 300,
                    child: _graficoMetodosUsados(graficos['metodosUsados'] as List),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String titulo, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _graficoChecadasPorDia(List data) {
    if (data.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }

    final spots = <FlSpot>[];
    final labels = <String>[];
    final valores = <double>[];
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final total = (item['total'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), total));
      valores.add(total);
      labels.add((item['fecha'] as String).substring(5)); // MM-DD
    }

    // Encontrar el valor máximo para escalar el eje Y
    final maxY = valores.reduce((a, b) => a > b ? a : b);
    final maxYEscalado = (maxY * 1.2).ceilToDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxYEscalado,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[idx],
                      style: const TextStyle(fontSize: 10, color: Colors.black87),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        // 🆕 Tooltip al pasar el mouse/tocar
        lineTouchData: LineTouchData(
        enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => const Color(0xFF0F766E),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final fecha = (idx >= 0 && idx < data.length)
                    ? data[idx]['fecha'] as String
                    : '';
                return LineTooltipItem(
                  '$fecha\n${spot.y.toInt()} checadas',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF0F766E),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: const Color(0xFF0F766E),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF0F766E).withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _graficoMetodosUsados(List data) {
    if (data.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }

    final colores = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.brown,
      Colors.teal,
    ];

    final total = data.fold<int>(0, (sum, item) => sum + (item['total'] as int));

    // 🆕 Layout: pastel + leyenda
    return Row(
      children: [
        // Gráfico de pastel
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: data.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final porcentaje = (item['total'] as int) / total * 100;
                return PieChartSectionData(
                  value: (item['total'] as num).toDouble(),
                  title: '${porcentaje.toStringAsFixed(0)}%',
                  color: colores[idx % colores.length],
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              // 🆕 Tooltip al pasar el mouse
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  // Tooltip opcional (se puede dejar sin acción)
                },
              ),
            ),
          ),
        ),
        // 🆕 Leyenda
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: data.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colores[idx % colores.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item['metodo']} (${item['total']})',
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
