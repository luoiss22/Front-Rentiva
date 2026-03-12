import 'package:flutter/material.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_navbar.dart';

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

// ─── MODELO según backend Django ──────────────────────────────────────────────
class Propiedad {
  final int id;
  final String nombre;
  final String direccion;
  final String ciudad;
  final String estadoGeografico;
  final String codigoPostal;
  final PropiedadTipo tipo;
  final String descripcion;
  final double costoRenta;
  final double? superficieM2;
  final PropiedadEstado estado;
  final String imagen;           // campo local para UI
  final DateTime createdAt;
  final DateTime updatedAt;

  const Propiedad({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.ciudad,
    required this.estadoGeografico,
    required this.codigoPostal,
    required this.tipo,
    required this.descripcion,
    required this.costoRenta,
    this.superficieM2,
    required this.estado,
    required this.imagen,
    required this.createdAt,
    required this.updatedAt,
  });

  // TODO: usar cuando conectes Django → GET /api/propiedades/
  factory Propiedad.fromJson(Map<String, dynamic> json) {
    return Propiedad(
      id:                json['id'],
      nombre:            json['nombre'],
      direccion:         json['direccion'],
      ciudad:            json['ciudad'],
      estadoGeografico:  json['estado_geografico'],
      codigoPostal:      json['codigo_postal'],
      tipo:              PropiedadTipo.values.firstWhere((e) => e.name == json['tipo']),
      descripcion:       json['descripcion'],
      costoRenta:        double.parse(json['costo_renta'].toString()),
      superficieM2:      json['superficie_m2'] != null ? double.parse(json['superficie_m2'].toString()) : null,
      estado:            PropiedadEstado.values.firstWhere((e) => e.name == json['estado']),
      imagen:            json['imagen'] ?? '',
      createdAt:         DateTime.parse(json['created_at']),
      updatedAt:         DateTime.parse(json['updated_at']),
    );
  }
}

// ─── DATOS DE EJEMPLO (reemplazar con API Django) ─────────────────────────────
final List<Propiedad> _propiedadesEjemplo = [
  Propiedad(
    id: 1,
    nombre: 'Apartamento Moderno Centro',
    direccion: 'Av. Reforma 222',
    ciudad: 'Ciudad de México',
    estadoGeografico: 'CDMX',
    codigoPostal: '06600',
    tipo: PropiedadTipo.departamento,
    descripcion: 'Departamento moderno en el corazón de la ciudad con vista panorámica.',
    costoRenta: 12500,
    superficieM2: 85,
    estado: PropiedadEstado.rentada,
    imagen: 'https://images.unsplash.com/photo-1594873604892-b599f847e859?w=600',
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2025, 3, 1),
  ),
  Propiedad(
    id: 2,
    nombre: 'Casa Familiar Jardines',
    direccion: 'Calle Roble 45',
    ciudad: 'Guadalajara',
    estadoGeografico: 'Jalisco',
    codigoPostal: '44100',
    tipo: PropiedadTipo.casa,
    descripcion: 'Amplia casa familiar con jardín y garage para dos autos.',
    costoRenta: 28000,
    superficieM2: 150,
    estado: PropiedadEstado.disponible,
    imagen: 'https://images.unsplash.com/photo-1646877419384-98cbdde02d3a?w=600',
    createdAt: DateTime(2024, 3, 10),
    updatedAt: DateTime(2025, 2, 20),
  ),
  Propiedad(
    id: 3,
    nombre: 'Loft Industrial',
    direccion: 'Calle 10 #200',
    ciudad: 'Monterrey',
    estadoGeografico: 'Nuevo León',
    codigoPostal: '64000',
    tipo: PropiedadTipo.local,
    descripcion: 'Espacio abierto estilo industrial, ideal para oficinas creativas.',
    costoRenta: 15000,
    superficieM2: 60,
    estado: PropiedadEstado.rentada,
    imagen: 'https://images.unsplash.com/photo-1605610973140-02080d1905ec?w=600',
    createdAt: DateTime(2024, 6, 5),
    updatedAt: DateTime(2025, 1, 10),
  ),
  Propiedad(
    id: 4,
    nombre: 'Oficina Torre Norte',
    direccion: 'Blvd. Manuel Ávila Camacho 88',
    ciudad: 'Ciudad de México',
    estadoGeografico: 'CDMX',
    codigoPostal: '11560',
    tipo: PropiedadTipo.oficina,
    descripcion: 'Oficina corporativa en edificio de primer nivel con estacionamiento.',
    costoRenta: 35000,
    superficieM2: 120,
    estado: PropiedadEstado.mantenimiento,
    imagen: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=600',
    createdAt: DateTime(2024, 8, 20),
    updatedAt: DateTime(2025, 3, 5),
  ),
];

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class PropiedadesScreen extends StatefulWidget {
  const PropiedadesScreen({super.key});

  @override
  State<PropiedadesScreen> createState() => _PropiedadesScreenState();
}

class _PropiedadesScreenState extends State<PropiedadesScreen> {
  final int _navIndex = 1; // Propiedades = índice 1
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    const routes = [
      '/inicio-usuario',
      '',
      '/inquilinos',
      '/pagos',
      '/mantenimiento',
    ];
    if (index != _navIndex) {
      Navigator.pushNamed(context, routes[index]);
    }
  }

  List<Propiedad> get _filtradas {
    if (_searchTerm.isEmpty) return _propiedadesEjemplo;
    final term = _searchTerm.toLowerCase();
    return _propiedadesEjemplo
        .where((p) =>
            p.nombre.toLowerCase().contains(term) ||
            p.direccion.toLowerCase().contains(term) ||
            p.ciudad.toLowerCase().contains(term))
        .toList();
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
        onPressed: () => Navigator.pushNamed(context, '/propiedades/nueva'),
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
              onChanged: (v) => setState(() => _searchTerm = v),
              style: const TextStyle(
                  color: Color(0xFF225378), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o dirección...',
                hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: Colors.grey, size: 20),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchTerm = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
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
                  borderSide: const BorderSide(
                      color: Color(0xFF1695A3), width: 2),
                ),
              ),
            ),
          ),

          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: _filtradas.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_work_outlined,
                            size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No se encontraron propiedades.',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: _filtradas.length,
                    itemBuilder: (context, index) => _PropiedadCard(
                      propiedad: _filtradas[index],
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/propiedades/info',
                        arguments: _filtradas[index].id,
                      ),
                    ),
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

// ─── TARJETA DE PROPIEDAD ─────────────────────────────────────────────────────
class _PropiedadCard extends StatelessWidget {
  final Propiedad propiedad;
  final VoidCallback onTap;

  const _PropiedadCard({
    required this.propiedad,
    required this.onTap,
  });

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
                    // Imagen de red
                    Image.network(
                      propiedad.imagen,
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
                          propiedad.estado.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: propiedad.estado.color,
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
                                    propiedad.direccion,
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
                          label: propiedad.tipo.label),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Feature(
                            icon: Icons.location_city_outlined,
                            label: propiedad.ciudad),
                      ),
                      if (propiedad.superficieM2 != null)
                        _Feature(
                            icon: Icons.straighten,
                            label: '${propiedad.superficieM2!.toStringAsFixed(0)} m²'),
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
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: propiedad.estado.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: propiedad.estado.color.withOpacity(0.4)),
                        ),
                        child: Text(
                          propiedad.estado.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: propiedad.estado.color,
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