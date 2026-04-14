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
  List<_ChartData> _chartData = [];
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

  Future<List<dynamic>> _cargarTodosPagados() async {
    final List<dynamic> todos = [];
    int page = 1;
    while (true) {
      final data = await ApiClient.get('/pagos/?estado=pagado&page=$page&page_size=100');
      final results = data is List ? data : (data['results'] ?? []);
      todos.addAll(results as List);
      if (data is List || data['next'] == null) break;
      page++;
    }
    return todos;
  }

  Future<void> _cargarDatos() async {
    final user = await StorageService.getUser();
    if (mounted) setState(() => _nombre = user?['nombre'] ?? '');

    try {
      final anioActual = DateTime.now().year;

      // Todas las llamadas en paralelo
      final resultados = await Future.wait([
        ApiClient.get('/propiedades/'),
        ApiClient.get('/arrendatarios/?estado=activo'),
        ApiClient.get('/pagos/?estado=pendiente'),
        ApiClient.get('/pagos/?ordering=-created_at&page_size=5'),
        _cargarTodosPagados(),
      ]);

      final propiedades       = resultados[0];
      final arrendatarios     = resultados[1];
      final pagosP            = resultados[2];
      final pagosRecientes    = resultados[3];
      final pagadosData       = resultados[4];

      final totalPropiedades   = propiedades is List  ? propiedades.length  : (propiedades['count']  ?? 0);
      final totalArrendatarios = arrendatarios is List ? arrendatarios.length : (arrendatarios['count'] ?? 0);

      final listaPagos = pagosP is List ? pagosP : (pagosP['results'] ?? []);
      final totalPendiente = (listaPagos as List).fold<double>(
        0, (s, p) => s + (double.tryParse(p['monto'].toString()) ?? 0),
      );

      final listaReciente = pagosRecientes is List
          ? pagosRecientes
          : (pagosRecientes['results'] ?? []);

      // Agrupar pagos pagados por mes del año actual
      final listaPagados = pagadosData is List
          ? pagadosData
          : (pagadosData['results'] as List? ?? []);

      final mesesLabel = ['Ene','Feb','Mar','Abr','May','Jun',
                          'Jul','Ago','Sep','Oct','Nov','Dic'];
      final totalesMes = List<double>.filled(12, 0);

      for (final p in listaPagados) {
        final fechaStr = p['fecha_pago'] as String?;
        if (fechaStr == null || fechaStr.isEmpty) continue;
        final fecha = DateTime.tryParse(fechaStr);
        if (fecha == null || fecha.year != anioActual) continue;
        totalesMes[fecha.month - 1] += double.tryParse(p['monto'].toString()) ?? 0;
      }

      // Solo mostrar gráfica si hay al menos un mes con ingresos reales
      final mesActual = DateTime.now().month;
      final hayIngresos = totalesMes.any((v) => v > 0);
      final chart = <_ChartData>[];
      if (hayIngresos) {
        for (int i = 0; i < mesActual; i++) {
          chart.add(_ChartData(mesesLabel[i], totalesMes[i]));
        }
      }

      if (!mounted) return;
      setState(() {
        _stats = [
          _StatData(name: 'Propiedades', value: '$totalPropiedades',  icon: Icons.home_outlined,  isIncrease: true),
          _StatData(name: 'Inquilinos',  value: '$totalArrendatarios', icon: Icons.people_outline, isIncrease: true),
          _StatData(name: 'Pendientes',  value: '\$${totalPendiente.toStringAsFixed(0)}', icon: Icons.access_time, isIncrease: false),
        ];
        _chartData = chart;
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
              if (_chartData.isNotEmpty) ...[
                _RevenueChart(chartData: _chartData),
                const SizedBox(height: 20),
              ],
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
    final s = stats;
    const rowHeight = 110.0;
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: s.length > 0 ? _StatCard(data: s[0]) : const SizedBox()),
              const SizedBox(width: 12),
              Expanded(child: s.length > 1 ? _StatCard(data: s[1]) : const SizedBox()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: rowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: s.length > 2 ? _StatCard(data: s[2]) : const SizedBox()),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  color: const Color(0xFF225378),
                  icon: Icons.home_outlined,
                  label: '+ Propiedad',
                  onTap: () => Navigator.pushNamed(context, '/propiedades/nueva'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 70,
          child: _QuickActionButton(
            color: const Color(0xFFEB7F00),
            icon: Icons.build_outlined,
            label: '+ Reporte',
            onTap: () => Navigator.pushNamed(context, '/mantenimiento/nuevo'),
          ),
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
    // Escala dinámica: dividir entre un divisor que haga los valores manejables
    final maxVal = chartData.fold<double>(0, (m, d) => d.value > m ? d.value : m);
    final divisor = maxVal > 100000 ? 1000.0 : maxVal > 1000 ? 100.0 : 1.0;
    final sufijo  = divisor == 1000.0 ? 'k' : divisor == 100.0 ? 'c' : '';
    final yMax    = maxVal > 0 ? (maxVal / divisor) * 1.2 : 1.0;

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
                child: Text(
                  '${DateTime.now().year}',
                  style: const TextStyle(color: Color(0xFF1695A3), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              minY: 0,
              maxY: yMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toStringAsFixed(0)}$sufijo',
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ),
                ),
                rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= chartData.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(chartData[index].name,
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: chartData.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.value / divisor))
                      .toList(),
                  isCurved: true,
                  color: const Color(0xFF1695A3),
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 3,
                      color: const Color(0xFF1695A3),
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1695A3).withOpacity(0.25),
                        const Color(0xFF1695A3).withOpacity(0.0),
                      ],
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

  // Íconos y colores según estado del pago
  static _EstadoVisual _visualEstado(String? estado) {
    switch (estado) {
      case 'pagado':
        return _EstadoVisual(
          icon: Icons.check_circle_outline,
          color: const Color(0xFF15803D),
          bg: const Color(0xFFDCFCE7),
          label: 'Pagado',
        );
      case 'vencido':
        return _EstadoVisual(
          icon: Icons.warning_amber_outlined,
          color: const Color(0xFFBE123C),
          bg: const Color(0xFFFFE4E6),
          label: 'Vencido',
        );
      case 'parcial':
        return _EstadoVisual(
          icon: Icons.incomplete_circle_outlined,
          color: const Color(0xFFEA580C),
          bg: const Color(0xFFFFEDD5),
          label: 'Parcial',
        );
      case 'cancelado':
        return _EstadoVisual(
          icon: Icons.cancel_outlined,
          color: Colors.grey,
          bg: const Color(0xFFF1F5F9),
          label: 'Cancelado',
        );
      default: // pendiente
        return _EstadoVisual(
          icon: Icons.schedule_outlined,
          color: const Color(0xFFA16207),
          bg: const Color(0xFFFEF9C3),
          label: 'Pendiente',
        );
    }
  }

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
            final estado = pago['estado'] as String?;
            final vis = _visualEstado(estado);

            final inquilino = pago['inquilino_nombre']?.toString() ?? '';
            final propiedad = pago['propiedad_nombre']?.toString() ?? '';
            final periodo = pago['periodo']?.toString() ?? '';

            // Línea principal: nombre del inquilino — periodo
            final titulo = inquilino.isNotEmpty
                ? '$inquilino — $periodo'
                : periodo.isNotEmpty ? periodo : 'Pago';

            // Subtítulo: propiedad + fecha
            final fecha = pago['fecha_pago'] ?? pago['fecha_limite'] ?? '';
            final subtitulo = [
              if (propiedad.isNotEmpty) propiedad,
              if (fecha.toString().isNotEmpty) fecha.toString(),
            ].join(' · ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(color: vis.color, width: 4),
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
                      decoration: BoxDecoration(color: vis.bg, borderRadius: BorderRadius.circular(20)),
                      child: Icon(vis.icon, size: 18, color: vis.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titulo,
                              style: const TextStyle(
                                  color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 13)),
                          if (subtitulo.isNotEmpty)
                            Text(subtitulo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$$monto',
                            style: const TextStyle(
                                color: Color(0xFF1695A3), fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: vis.bg, borderRadius: BorderRadius.circular(8)),
                          child: Text(vis.label,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: vis.color)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _EstadoVisual {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  const _EstadoVisual({required this.icon, required this.color, required this.bg, required this.label});
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
