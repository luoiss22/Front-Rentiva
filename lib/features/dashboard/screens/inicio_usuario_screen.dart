import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rentiva/core/widgets/app_header.dart';
import '../../../core/widgets/bottom_navbar.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_client.dart';

class InicioUsuarioScreen extends StatefulWidget {
  const InicioUsuarioScreen({super.key});

  @override
  State<InicioUsuarioScreen> createState() => _InicioUsuarioScreenState();
}

class _InicioUsuarioScreenState extends State<InicioUsuarioScreen> {
  final int _navIndex = 0;

  String _nombre = '';
  bool _loadingStats = true;
  List<_StatData> _stats = [];
  final List<_ChartData> _chartData = [];
  List<Map<String, dynamic>> _actividad = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _onNavTap(int index) {
    const routes = ['', '/propiedades', '/inquilinos', '/pagos', '/mantenimiento'];
    if (index != _navIndex) Navigator.pushNamed(context, routes[index]);
  }

  Future<void> _cargarDatos() async {
    final user = await StorageService.getUser();
    if (mounted) setState(() => _nombre = user?['nombre'] ?? '');

    try {
      final propiedades = await ApiClient.get('/propiedades/');
      final totalPropiedades = propiedades is List
          ? propiedades.length
          : (propiedades['count'] ?? 0);

      final arrendatarios = await ApiClient.get('/arrendatarios/?estado=activo');
      final totalArrendatarios = arrendatarios is List
          ? arrendatarios.length
          : (arrendatarios['count'] ?? 0);

      final pagos = await ApiClient.get('/pagos/?estado=pendiente');
      final listaPagos = pagos is List ? pagos : (pagos['results'] ?? []);
      final totalPendiente = (listaPagos as List).fold<double>(
        0,
        (sum, p) => sum + (double.tryParse(p['monto'].toString()) ?? 0),
      );

      // El back ordena por fecha_limite desc y devuelve resultados paginados
      final pagosRecientes = await ApiClient.get('/pagos/?ordering=-fecha_limite&page_size=3');
      final listaReciente = pagosRecientes is List
          ? pagosRecientes
          : (pagosRecientes['results'] ?? []);

      if (!mounted) return;
      setState(() {
        _stats = [
          _StatData(name: 'Propiedades', value: '$totalPropiedades', icon: Icons.home_outlined, isIncrease: true),
          _StatData(name: 'Inquilinos',  value: '$totalArrendatarios', icon: Icons.people_outline, isIncrease: true),
          _StatData(name: 'Pendientes',  value: '\$${totalPendiente.toStringAsFixed(0)}', icon: Icons.access_time, isIncrease: false),
        ];
        _actividad = List<Map<String, dynamic>>.from(listaReciente);
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: 'Rentiva'),
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: BottomNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeCard(nombre: _nombre),
              const SizedBox(height: 20),
              _loadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : _StatsGrid(stats: _stats),
              const SizedBox(height: 20),
              _chartData.isEmpty
                  ? const SizedBox()
                  : _RevenueChart(chartData: _chartData),
              const SizedBox(height: 20),
              _RecentActivity(actividad: _actividad),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── WELCOME CARD ─────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String nombre;
  const _WelcomeCard({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFACF0F2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre.isNotEmpty ? 'Hola, $nombre' : 'Hola',
            style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text('Aqui tienes el resumen de tus propiedades.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── STATS GRID ───────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final List<_StatData> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ...stats.map((s) => _StatCard(data: s)),
        _QuickActionButton(
          color: const Color(0xFF225378),
          icon: Icons.home_outlined,
          label: '+ Propiedad',
          onTap: () => Navigator.pushNamed(context, '/propiedades/nueva'),
        ),
        _QuickActionButton(
          color: const Color(0xFFEB7F00),
          icon: Icons.build_outlined,
          label: '+ Reporte',
          onTap: () => Navigator.pushNamed(context, '/mantenimiento/nuevo'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isIncrease = data.isIncrease;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isIncrease
                      ? const Color(0xFFACF0F2).withOpacity(0.3)
                      : const Color(0xFFEB7F00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 30,
                    color: isIncrease ? const Color(0xFF1695A3) : const Color(0xFFEB7F00)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.name.toUpperCase(),
                  style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Text(data.value,
                  style: const TextStyle(color: Color(0xFF225378), fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({required this.color, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── REVENUE CHART ────────────────────────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final List<_ChartData> chartData;
  const _RevenueChart({required this.chartData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFACF0F2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ingresos Mensuales',
                  style: TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                child: const Text('Este Año',
                    style: TextStyle(color: Color(0xFF1695A3), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= chartData.length) return const SizedBox();
                      return Text(chartData[index].name, style: const TextStyle(fontSize: 10, color: Colors.grey));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: chartData.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.value / 1000))
                      .toList(),
                  isCurved: true,
                  color: const Color(0xFF1695A3),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [const Color(0xFF1695A3).withOpacity(0.3), const Color(0xFF1695A3).withOpacity(0.0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

// ─── RECENT ACTIVITY ──────────────────────────────────────────────────────────
class _RecentActivity extends StatelessWidget {
  final List<Map<String, dynamic>> actividad;
  const _RecentActivity({required this.actividad});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Actividad Reciente',
              style: TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        if (actividad.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('Sin actividad reciente.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          )
        else
          ...actividad.map((pago) {
            final monto = pago['monto']?.toString() ?? '0';
            // El serializer devuelve: periodo, inquilino_nombre, fecha_pago, fecha_limite
            final concepto = pago['inquilino_nombre'] != null && pago['inquilino_nombre'].toString().isNotEmpty
                ? '${pago['inquilino_nombre']} — ${pago['periodo'] ?? ''}'
                : (pago['periodo'] ?? 'Pago');
            final fecha = pago['fecha_pago'] ?? pago['fecha_limite'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: const BorderSide(color: Color(0xFFEB7F00), width: 4),
                    top: BorderSide(color: Colors.grey.shade100),
                    right: BorderSide(color: Colors.grey.shade100),
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.receipt_outlined, size: 18, color: Color(0xFFEB7F00)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(concepto,
                              style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 13)),
                          if (fecha.isNotEmpty)
                            Text(fecha, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('\$$monto',
                        style: const TextStyle(color: Color(0xFF1695A3), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ─── DATA MODELS ─────────────────────────────────────────────────────────────
class _StatData {
  final String name;
  final String value;
  final bool isIncrease;
  final IconData icon;

  const _StatData({required this.name, required this.value, required this.isIncrease, required this.icon});
}

class _ChartData {
  final String name;
  final double value;
  const _ChartData(this.name, this.value);
}
