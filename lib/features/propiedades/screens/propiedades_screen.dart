import 'package:flutter/material.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_navbar.dart';
import '../../../data/services/propiedades_service.dart';

// ─── ENUMS según backend Django ───────────────────────────────────────────────
enum PropiedadTipo { casa, departamento, local, oficina, terreno, otro }
enum PropiedadEstado { disponible, rentada, mantenimiento, inactiva }

extension PropiedadTipoExt on PropiedadTipo {
  String get label {
    switch (this) {
      case PropiedadTipo.casa:         return 'Casa';
      case PropiedadTipo.departamento: return 'Departamento';
      case PropiedadTipo.local:        return 'Local';
      case PropiedadTipo.oficina:      return 'Oficina';
      case PropiedadTipo.terreno:      return 'Terreno';
      case PropiedadTipo.otro:         return 'Otro';
    }
  }
}

extension PropiedadEstadoExt on PropiedadEstado {
  String get label {
    switch (this) {
      case PropiedadEstado.disponible:    return 'Disponible';
      case PropiedadEstado.rentada:       return 'Rentada';
      case PropiedadEstado.mantenimiento: return 'Mantenimiento';
      case PropiedadEstado.inactiva:      return 'Inactiva';
    }
  }

  Color get color {
    switch (this) {
      case PropiedadEstado.disponible:    return const Color(0xFF1695A3);
      case PropiedadEstado.rentada:       return const Color(0xFFEB7F00);
      case PropiedadEstado.mantenimiento: return Colors.orange;
      case PropiedadEstado.inactiva:      return Colors.grey;
    }
  }
}

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class PropiedadesScreen extends StatefulWidget {
  const PropiedadesScreen({super.key});

  @override
  State<PropiedadesScreen> createState() => _PropiedadesScreenState();
}

class _PropiedadesScreenState extends State<PropiedadesScreen> {
  final int _navIndex = 1;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchTerm = '';
  late Future<List<PropiedadItem>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = PropiedadesService.listar();
  }

  void _recargar() {
    setState(() {
      _futuro = PropiedadesService.listar(busqueda: _searchTerm.isEmpty ? null : _searchTerm);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    const routes = [
      '/inicio-usuario', '', '/inquilinos', '/pagos', '/mantenimiento',
    ];
    if (index != _navIndex) Navigator.pushNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Propiedades'),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),

      // ── Botón flotante ─────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/propiedades/nueva');
          _recargar();
        },
        backgroundColor: const Color(0xFFEB7F00),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

      body: Column(
        children: [
          // ── Barra de búsqueda ─────────────────────────────────────────────
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _recargar(),
              onChanged: (v) {
                setState(() => _searchTerm = v);
                if (v.isEmpty) _recargar();
              },
              style: const TextStyle(color: Color(0xFF225378), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o dirección...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchTerm = '');
                          _recargar();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF1695A3), width: 2),
                ),
              ),
            ),
          ),

          // ── Lista con datos reales ─────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<PropiedadItem>>(
              future: _futuro,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1695A3)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _recargar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final lista = snapshot.data ?? [];
                if (lista.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_work_outlined, size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No se encontraron propiedades.',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: lista.length,
                  itemBuilder: (context, index) => _PropiedadCard(
                    propiedad: lista[index],
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        '/propiedades/info',
                        arguments: lista[index].id,
                      );
                      PaintingBinding.instance.imageCache.clear();
                      _recargar();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────
String _formatPrice(double price) {
  final parts = price.toStringAsFixed(0).split('');
  final result = <String>[];
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) result.add(',');
    result.add(parts[i]);
  }
  return result.join();
}

Color _estadoColor(String estado) {
  switch (estado) {
    case 'disponible':    return const Color(0xFF1695A3);
    case 'rentada':       return const Color(0xFFEB7F00);
    case 'mantenimiento': return Colors.orange;
    default:              return Colors.grey;
  }
}

String _estadoLabel(String estado) {
  const labels = {
    'disponible':    'Disponible',
    'rentada':       'Rentada',
    'mantenimiento': 'Mantenimiento',
    'inactiva':      'Inactiva',
  };
  return labels[estado] ?? estado;
}

String _tipoLabel(String tipo) {
  const labels = {
    'casa':         'Casa',
    'departamento': 'Departamento',
    'local':        'Local',
    'oficina':      'Oficina',
    'terreno':      'Terreno',
    'otro':         'Otro',
  };
  return labels[tipo] ?? tipo;
}

// ─── TARJETA DE PROPIEDAD ─────────────────────────────────────────────────────
class _PropiedadCard extends StatelessWidget {
  final PropiedadItem propiedad;
  final VoidCallback onTap;

  const _PropiedadCard({required this.propiedad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Imagen ──────────────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen con fallback
                    Image.network(
                      propiedad.fotoPrincipal ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFACF0F2).withOpacity(0.3),
                        child: const Icon(Icons.home_outlined,
                            size: 60, color: Color(0xFF1695A3)),
                      ),
                    ),

                    // Badge status
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          _estadoLabel(propiedad.estado),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _estadoColor(propiedad.estado),
                          ),
                        ),
                      ),
                    ),

                    // Overlay degradado + título + dirección
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              propiedad.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 12,
                                    color: Colors.white70),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    '${propiedad.ciudad}, ${propiedad.estadoGeografico}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Info inferior ────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: Características
                  Row(
                    children: [
                      _Feature(
                          icon: Icons.home_outlined,
                          label: _tipoLabel(propiedad.tipo)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Feature(
                            icon: Icons.location_city_outlined,
                            label: propiedad.ciudad),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Fila 2: Precio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '\$${_formatPrice(propiedad.costoRenta)}',
                              style: const TextStyle(
                                color: Color(0xFF225378),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const TextSpan(
                              text: ' /mes',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _estadoColor(propiedad.estado).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _estadoColor(propiedad.estado).withOpacity(0.4)),
                        ),
                        child: Text(
                          _estadoLabel(propiedad.estado),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _estadoColor(propiedad.estado),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Feature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}