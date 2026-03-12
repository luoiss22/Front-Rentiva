import 'package:flutter/material.dart';
import '../../../core/widgets/app_header.dart';
import '../widgets/contrato_pdf.dart';

// ─── MODELOS ──────────────────────────────────────────────────────────────────
class PropiedadDetalle {
  final int id;
  final String nombre;
  final String precio;
  final String direccion;
  final String ciudad;
  final String estadoGeografico;
  final String descripcion;
  final String imagen;
  final String estado;
  final String tipo;
  final double? superficieM2;
  final InquilinoResumen? inquilino;
  final List<PropiedadMobiliario> mobiliario;
  final List<PagoResumen> pagos;

  const PropiedadDetalle({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.direccion,
    required this.ciudad,
    required this.estadoGeografico,
    required this.descripcion,
    required this.imagen,
    required this.estado,
    required this.tipo,
    this.superficieM2,
    this.inquilino,
    required this.mobiliario,
    required this.pagos,
  });
}

class InquilinoResumen {
  final String nombre;
  final String telefono;
  final String email;
  final String iniciales;
  final String estadoPago;
  final String desde;

  const InquilinoResumen({
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.iniciales,
    required this.estadoPago,
    required this.desde,
  });
}

// Catálogo de mobiliario (tabla Mobiliario en Django)
class Mobiliario {
  final int id;
  final String nombre;
  final String tipo;
  final String descripcion;
  final String? fotoUrl;

  const Mobiliario({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    this.fotoUrl,
  });
}

// Relación propiedad-mobiliario (tabla PropiedadMobiliario en Django)
enum MobiliarioEstado { bueno, regular, malo, reparacion }

extension MobiliarioEstadoExt on MobiliarioEstado {
  String get label {
    switch (this) {
      case MobiliarioEstado.bueno:      return 'Bueno';
      case MobiliarioEstado.regular:    return 'Regular';
      case MobiliarioEstado.malo:       return 'Malo';
      case MobiliarioEstado.reparacion: return 'En Reparación';
    }
  }

  Color get color {
    switch (this) {
      case MobiliarioEstado.bueno:      return const Color(0xFF1695A3);
      case MobiliarioEstado.regular:    return const Color(0xFFEB7F00);
      case MobiliarioEstado.malo:       return Colors.red;
      case MobiliarioEstado.reparacion: return Colors.orange;
    }
  }
}

class PropiedadMobiliario {
  final int id;
  final Mobiliario mobiliario;
  final int cantidad;
  final double? valorEstimado;
  final MobiliarioEstado estado;

  const PropiedadMobiliario({
    required this.id,
    required this.mobiliario,
    required this.cantidad,
    this.valorEstimado,
    required this.estado,
  });
}

class PagoResumen {
  final int id;
  final String fecha;
  final String monto;
  final String status;

  const PagoResumen({
    required this.id,
    required this.fecha,
    required this.monto,
    required this.status,
  });
}

// ─── DATOS EJEMPLO ────────────────────────────────────────────────────────────
final _propiedadEjemplo = PropiedadDetalle(
  id: 1,
  nombre: 'Apartamento Moderno Centro',
  precio: '\$12,500',
  direccion: 'Av. Reforma 222',
  ciudad: 'Ciudad de México',
  estadoGeografico: 'CDMX',
  descripcion:
      'Hermoso apartamento recién remodelado con vista a la ciudad. Cuenta con acabados de lujo, cocina integral y seguridad 24/7.',
  imagen:
      'https://images.unsplash.com/photo-1594873604892-b599f847e859?w=800',
  estado: 'Rentada',
  tipo: 'Departamento',
  superficieM2: 85,
  inquilino: const InquilinoResumen(
    nombre: 'Juan Pérez',
    telefono: '55 1234 5678',
    email: 'juan.perez@email.com',
    iniciales: 'JP',
    estadoPago: 'Al corriente',
    desde: 'Enero 2023',
  ),
  mobiliario: const [
    PropiedadMobiliario(
      id: 1,
      mobiliario: Mobiliario(id: 1, nombre: 'Sofá cama gris', tipo: 'Mueble', descripcion: 'Sofá cama de 3 plazas color gris'),
      cantidad: 1,
      valorEstimado: 4500,
      estado: MobiliarioEstado.bueno,
    ),
    PropiedadMobiliario(
      id: 2,
      mobiliario: Mobiliario(id: 2, nombre: 'Mesa de centro', tipo: 'Mueble', descripcion: 'Mesa de centro de cristal templado'),
      cantidad: 1,
      valorEstimado: 1800,
      estado: MobiliarioEstado.regular,
    ),
    PropiedadMobiliario(
      id: 3,
      mobiliario: Mobiliario(id: 3, nombre: 'Refrigerador Samsung', tipo: 'Electrodoméstico', descripcion: 'Refrigerador Samsung 14 pies No Frost'),
      cantidad: 1,
      valorEstimado: 12000,
      estado: MobiliarioEstado.bueno,
    ),
    PropiedadMobiliario(
      id: 4,
      mobiliario: Mobiliario(id: 4, nombre: 'Lavadora LG', tipo: 'Electrodoméstico', descripcion: 'Lavadora LG 18kg carga frontal'),
      cantidad: 1,
      valorEstimado: 9500,
      estado: MobiliarioEstado.bueno,
    ),
  ],
  pagos: const [
    PagoResumen(id: 1, fecha: '01/05/2023', monto: '\$12,500', status: 'Pagado'),
    PagoResumen(id: 2, fecha: '01/04/2023', monto: '\$12,500', status: 'Pagado'),
    PagoResumen(id: 3, fecha: '01/03/2023', monto: '\$12,500', status: 'Pagado'),
  ],
);

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class InformacionPropiedadScreen extends StatefulWidget {
  final int? propiedadId;
  const InformacionPropiedadScreen({super.key, this.propiedadId});

  @override
  State<InformacionPropiedadScreen> createState() =>
      _InformacionPropiedadScreenState();
}

class _InformacionPropiedadScreenState
    extends State<InformacionPropiedadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // TODO: cargar desde Django → GET /api/propiedades/{id}/
  final PropiedadDetalle _propiedad = _propiedadEjemplo;

  final List<_TabItem> _tabs = const [
    _TabItem(key: 'detalles',   label: 'Detalles'),
    _TabItem(key: 'mobiliario', label: 'Mobiliario'),
    _TabItem(key: 'inquilino',  label: 'Inquilino'),
    _TabItem(key: 'pagos',      label: 'Pagos'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Detalle', showBack: true),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Hero imagen ────────────────────────────────────────────
                _HeroImage(propiedad: _propiedad),
                // ── Tabs ───────────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                      unselectedLabelStyle:
                          const TextStyle(fontSize: 12),
                      indicator: BoxDecoration(
                        color: const Color(0xFF225378),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: _tabs
                          .map((t) => Tab(text: t.label, height: 36))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _TabDetalles(propiedad: _propiedad),
            _TabMobiliario(
              propiedadId: _propiedad.id,
              mobiliario: _propiedad.mobiliario,
            ),
            _TabInquilino(propiedad: _propiedad),
            _TabPagos(pagos: _propiedad.pagos),
          ],
        ),
      ),
    );
  }
}

// ─── HERO IMAGE ───────────────────────────────────────────────────────────────
class _HeroImage extends StatelessWidget {
  final PropiedadDetalle propiedad;
  const _HeroImage({required this.propiedad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            propiedad.imagen,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFACF0F2).withOpacity(0.3),
              child: const Icon(Icons.home_outlined,
                  size: 80, color: Color(0xFF1695A3)),
            ),
          ),
          // Overlay superior
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Overlay inferior
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFF8FAFC),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Botón editar
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(
                context, '/propiedades/editar',
                arguments: propiedad.id,
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEB7F00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          // Nombre y dirección
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  propiedad.nombre,
                  style: const TextStyle(
                    color: Color(0xFF225378),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${propiedad.direccion}, ${propiedad.ciudad}',
                  style: const TextStyle(
                      color: Color(0xFF1695A3),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB: DETALLES ────────────────────────────────────────────────────────────
class _TabDetalles extends StatelessWidget {
  final PropiedadDetalle propiedad;
  const _TabDetalles({required this.propiedad});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          // Descripción
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Descripción',
                    style: TextStyle(
                        color: Color(0xFF225378),
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 8),
                Text(
                  propiedad.descripcion,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats: tipo, superficie, estado, precio
          _Card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.category_outlined,
                  label: 'Tipo',
                  value: propiedad.tipo,
                ),
                _Divider(),
                _StatItem(
                  icon: Icons.straighten,
                  label: 'Área',
                  value: propiedad.superficieM2 != null
                      ? '${propiedad.superficieM2!.toStringAsFixed(0)}m²'
                      : '-',
                ),
                _Divider(),
                _StatItem(
                  icon: Icons.toggle_on_outlined,
                  label: 'Estado',
                  value: propiedad.estado,
                ),
                _Divider(),
                _StatItem(
                  icon: Icons.attach_money,
                  label: 'Renta',
                  value: propiedad.precio,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ubicación completa
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ubicación',
                    style: TextStyle(
                        color: Color(0xFF225378),
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 10),
                _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Dirección',
                    value: propiedad.direccion),
                _InfoRow(
                    icon: Icons.location_city_outlined,
                    label: 'Ciudad',
                    value: propiedad.ciudad),
                _InfoRow(
                    icon: Icons.map_outlined,
                    label: 'Estado',
                    value: propiedad.estadoGeografico),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB: MOBILIARIO ──────────────────────────────────────────────────────────
class _TabMobiliario extends StatelessWidget {
  final int propiedadId;
  final List<PropiedadMobiliario> mobiliario;
  const _TabMobiliario(
      {required this.propiedadId, required this.mobiliario});

  Color _condicionColor(String condicion) {
    switch (condicion.toLowerCase()) {
      case 'excelente': return const Color(0xFF1695A3);
      case 'bueno':     return Colors.green;
      case 'regular':   return const Color(0xFFEB7F00);
      default:          return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Inventario',
                  style: TextStyle(
                      color: Color(0xFF225378),
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                    context, '/mobiliario/nuevo',
                    arguments: propiedadId),
                child: const Row(
                  children: [
                    Icon(Icons.add,
                        color: Color(0xFF1695A3), size: 16),
                    SizedBox(width: 4),
                    Text('Agregar',
                        style: TextStyle(
                            color: Color(0xFF1695A3),
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...mobiliario.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFACF0F2).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: Color(0xFF1695A3), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.mobiliario.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF225378))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text('Estado: ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                            Text(item.estado.label,
                                style: TextStyle(
                                    color: item.estado.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, '/mobiliario/editar',
                        arguments: item.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          size: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB: INQUILINO ───────────────────────────────────────────────────────────
class _TabInquilino extends StatelessWidget {
  final PropiedadDetalle propiedad;
  const _TabInquilino({required this.propiedad});

  InquilinoResumen? get inquilino => propiedad.inquilino;

  @override
  Widget build(BuildContext context) {
    if (inquilino == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 52, color: Colors.grey),
            SizedBox(height: 12),
            Text('Sin inquilino asignado',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: _Card(
        child: Column(
          children: [
            // Avatar
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFACF0F2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8)
                ],
              ),
              child: Center(
                child: Text(inquilino!.iniciales,
                    style: const TextStyle(
                        color: Color(0xFF1695A3),
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Text(inquilino!.nombre,
                style: const TextStyle(
                    color: Color(0xFF225378),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('Inquilino desde ${inquilino!.desde}',
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),

            // Info grid
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                      label: 'Teléfono', value: inquilino!.telefono),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                      label: 'Email', value: inquilino!.email),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Estado de pago
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estado de Pago',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 14),
                            const SizedBox(width: 4),
                            Text(inquilino!.estadoPago,
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => ContratoPdf.generar(propiedad),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1695A3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Ver Contrato',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
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

// ─── TAB: PAGOS ───────────────────────────────────────────────────────────────
class _TabPagos extends StatelessWidget {
  final List<PagoResumen> pagos;
  const _TabPagos({required this.pagos});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Historial',
                  style: TextStyle(
                      color: Color(0xFF225378),
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Icon(Icons.notifications_outlined,
                        color: Color(0xFFEB7F00), size: 16),
                    SizedBox(width: 4),
                    Text('Recordar Pago',
                        style: TextStyle(
                            color: Color(0xFFEB7F00),
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...pagos.map(
            (pago) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: const BorderSide(
                      color: Color(0xFF1695A3), width: 4),
                  top: BorderSide(color: Colors.grey.shade100),
                  right: BorderSide(color: Colors.grey.shade100),
                  bottom: BorderSide(color: Colors.grey.shade100),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pago.monto,
                          style: const TextStyle(
                              color: Color(0xFF225378),
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 11, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(pago.fecha,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFACF0F2)),
                    ),
                    child: Text(pago.status,
                        style: const TextStyle(
                            color: Color(0xFF1695A3),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WIDGETS REUTILIZABLES ────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1695A3), size: 18),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.grey, fontSize: 9, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF225378),
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: Colors.grey.shade200);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1695A3), size: 16),
          const SizedBox(width: 8),
          Text('$label: ',
              style:
                  const TextStyle(color: Colors.grey, fontSize: 12)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF225378),
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF225378),
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _TabItem {
  final String key;
  final String label;
  const _TabItem({required this.key, required this.label});
}