import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/widgets/app_header.dart';
import '../../propiedades/widgets/contrato_pdf.dart';

// ─── MODELOS ──────────────────────────────────────────────────────────────────
class ArrendatarioDetalle {
  final int id;
  final String nombre;
  final String apellidos;
  final String telefono;
  final String email;
  final String? folioIne;
  final String? fotoUrl;
  final bool mascotas;
  final bool hijos;
  final String estado; // activo | inactivo
  final String desde;  // texto libre "desde 2023"
  final ContratoResumen? contrato;
  final List<PagoInquilino> pagos;
  final List<DocumentoInquilino> documentos;
  // DatosFiscales (SAT)
  final String? fiscalRazonSocial;
  final String? fiscalRfc;
  final String? fiscalRegimen;
  final String? fiscalUsoCfdi;
  final String? fiscalCp;
  final String? fiscalCorreo;

  const ArrendatarioDetalle({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.telefono,
    required this.email,
    this.folioIne,
    this.fotoUrl,
    required this.mascotas,
    required this.hijos,
    required this.estado,
    required this.desde,
    this.contrato,
    required this.pagos,
    required this.documentos,
    this.fiscalRazonSocial,
    this.fiscalRfc,
    this.fiscalRegimen,
    this.fiscalUsoCfdi,
    this.fiscalCp,
    this.fiscalCorreo,
  });

  String get nombreCompleto => '$nombre $apellidos';
  String get inicial => nombre[0].toUpperCase();
}

class ContratoResumen {
  final int propiedadId;
  final String propiedadNombre;
  final String propiedadDireccion;
  final String renta;
  final String deposito;
  final String fechaInicio;
  final String fechaFin;

  const ContratoResumen({
    required this.propiedadId,
    required this.propiedadNombre,
    required this.propiedadDireccion,
    required this.renta,
    required this.deposito,
    required this.fechaInicio,
    required this.fechaFin,
  });
}

class PagoInquilino {
  final int id;
  final String periodo;
  final String fecha;
  final String monto;
  final String status; // Pagado | Pendiente | Atrasado

  const PagoInquilino({
    required this.id,
    required this.periodo,
    required this.fecha,
    required this.monto,
    required this.status,
  });

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pagado':    return const Color(0xFF15803D);
      case 'pendiente': return const Color(0xFFA16207);
      default:          return const Color(0xFFBE123C);
    }
  }

  Color get statusBg {
    switch (status.toLowerCase()) {
      case 'pagado':    return const Color(0xFFDCFCE7);
      case 'pendiente': return const Color(0xFFFEF9C3);
      default:          return const Color(0xFFFFE4E6);
    }
  }
}

class DocumentoInquilino {
  final int id;
  final String nombre;
  final String tipo; // pdf | img
  final String fecha;
  final String? url;

  const DocumentoInquilino({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.fecha,
    this.url,
  });
}

// ─── DATOS EJEMPLO ────────────────────────────────────────────────────────────
final _inquilinoEjemplo = ArrendatarioDetalle(
  id: 1,
  nombre: 'Juan', apellidos: 'Pérez López',
  telefono: '55 1234 5678',
  email: 'juan.perez@email.com',
  folioIne: 'PELJ901012HDFRZN01',
  mascotas: false, hijos: true,
  estado: 'activo',
  desde: '2023',
  contrato: const ContratoResumen(
    propiedadId: 1,
    propiedadNombre: 'Apartamento Moderno Centro',
    propiedadDireccion: 'Av. Reforma 222, CDMX',
    renta: '\$12,500',
    deposito: '\$12,500',
    fechaInicio: '01/01/2023',
    fechaFin: '31/12/2023',
  ),
  pagos: const [
    PagoInquilino(id: 1, periodo: 'Mayo 2023',  fecha: '01/05/2023', monto: '\$12,500', status: 'Pagado'),
    PagoInquilino(id: 2, periodo: 'Abril 2023', fecha: '01/04/2023', monto: '\$12,500', status: 'Pagado'),
    PagoInquilino(id: 3, periodo: 'Marzo 2023', fecha: '01/03/2023', monto: '\$12,500', status: 'Pagado'),
  ],
  documentos: const [
    DocumentoInquilino(id: 1, nombre: 'Contrato de Arrendamiento', tipo: 'pdf', fecha: '01/01/2023'),
    DocumentoInquilino(id: 2, nombre: 'Identificación Oficial',    tipo: 'img', fecha: '15/12/2022'),
    DocumentoInquilino(id: 3, nombre: 'Comprobante de Ingresos',   tipo: 'pdf', fecha: '15/12/2022'),
  ],
  fiscalRazonSocial: 'Juan Pérez López',
  fiscalRfc: 'PELJ901012ABC',
  fiscalRegimen: '606 - Arrendamiento',
  fiscalUsoCfdi: 'G03',
  fiscalCp: '06600',
  fiscalCorreo: 'factura@juanperez.com',
);

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class InformacionInquilinoScreen extends StatefulWidget {
  final int? arrendatarioId;
  const InformacionInquilinoScreen({super.key, this.arrendatarioId});

  @override
  State<InformacionInquilinoScreen> createState() =>
      _InformacionInquilinoScreenState();
}

class _InformacionInquilinoScreenState
    extends State<InformacionInquilinoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // TODO: cargar desde Django → GET /api/arrendatarios/{id}/
  final ArrendatarioDetalle _inquilino = _inquilinoEjemplo;

  final List<_TabItem> _tabs = const [
    _TabItem(key: 'general',    label: 'General'),
    _TabItem(key: 'pagos',      label: 'Pagos'),
    _TabItem(key: 'documentos', label: 'Documentos'),
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

  // ── Contacto ─────────────────────────────────────────────────────────────
  Future<void> _llamar() async {
    final numero = _inquilino.telefono.replaceAll(RegExp(r'\s+'), '');
    try {
      await launchUrl(Uri.parse('tel:$numero'));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Llama al $numero'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _abrirWhatsApp() async {
    var numero = _inquilino.telefono.replaceAll(RegExp(r'\s+'), '');
    if (!numero.startsWith('+')) numero = '+52$numero';
    final uri = Uri.parse(
        'https://wa.me/$numero?text=${Uri.encodeComponent("Hola, te contactamos por tu renta.")}');
    try {
      await launchUrl(uri,
          mode: kIsWeb
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Detalle Inquilino', showBack: true),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Header azul + avatar ────────────────────────────────────
                _ProfileHeader(
                  inquilino: _inquilino,
                  onEdit: () => Navigator.pushNamed(
                    context, '/inquilinos/editar',
                    arguments: _inquilino.id,
                  ),
                ),
                const SizedBox(height: 52), // espacio para el avatar flotante

                // ── Tabs ────────────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6),
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
                        color: const Color(0xFF1695A3),
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
            _TabGeneral(
                inquilino: _inquilino,
                onLlamar: _llamar,
                onWhatsApp: _abrirWhatsApp),
            _TabPagos(pagos: _inquilino.pagos),
            _TabDocumentos(inquilino: _inquilino),
          ],
        ),
      ),
    );
  }
}

// ─── PROFILE HEADER ───────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final ArrendatarioDetalle inquilino;
  final VoidCallback onEdit;
  const _ProfileHeader({required this.inquilino, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Fondo azul
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          decoration: const BoxDecoration(
            color: Color(0xFF225378),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inquilino.nombreCompleto,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Inquilino desde ${inquilino.desde}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Botón editar
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Color(0xFFEB7F00),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),

        // Avatar flotante
        Positioned(
          bottom: -44,
          child: Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFACF0F2),
                shape: BoxShape.circle,
              ),
              child: inquilino.fotoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        inquilino.fotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _inicialWidget(inquilino.inicial),
                      ),
                    )
                  : _inicialWidget(inquilino.inicial),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _inicialWidget(String inicial) {
    return Center(
      child: Text(inicial,
          style: const TextStyle(
              color: Color(0xFF1695A3),
              fontSize: 32,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ─── TAB: GENERAL ─────────────────────────────────────────────────────────────
class _TabGeneral extends StatelessWidget {
  final ArrendatarioDetalle inquilino;
  final VoidCallback onLlamar;
  final VoidCallback onWhatsApp;
  const _TabGeneral({
    required this.inquilino,
    required this.onLlamar,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          // ── Información Personal ────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardTitle(Icons.person_outline, 'Información Personal'),
                const SizedBox(height: 12),

                _contactRow(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: inquilino.telefono,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _miniBtn(Icons.phone_outlined,
                          const Color(0xFF1695A3), onLlamar),
                      const SizedBox(width: 6),
                      _miniBtn(Icons.chat_outlined,
                          const Color(0xFF25D366), onWhatsApp),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _contactRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: inquilino.email),
                if (inquilino.folioIne != null) ...[
                  const SizedBox(height: 8),
                  _contactRow(
                      icon: Icons.credit_card_outlined,
                      label: 'Folio INE',
                      value: inquilino.folioIne!),
                ],

                // Badges mascotas/hijos
                if (inquilino.mascotas || inquilino.hijos) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (inquilino.mascotas)
                        _badge('🐾 Mascotas',
                            const Color(0xFFF3FFE2),
                            Colors.green.shade700),
                      if (inquilino.mascotas && inquilino.hijos)
                        const SizedBox(width: 8),
                      if (inquilino.hijos)
                        _badge('👶 Hijos',
                            const Color(0xFFEFF6FF),
                            Colors.blue.shade700),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Propiedad / Contrato ────────────────────────────────────────
          if (inquilino.contrato != null)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _cardTitle(Icons.home_outlined, 'Propiedad Actual',
                          color: const Color(0xFFEB7F00)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context, '/propiedades/info',
                          arguments: inquilino.contrato!.propiedadId,
                        ),
                        child: const Text('Ver Propiedad',
                            style: TextStyle(
                                color: Color(0xFF1695A3),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Nombre y dirección
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inquilino.contrato!.propiedadNombre,
                            style: const TextStyle(
                                color: Color(0xFF225378),
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(inquilino.contrato!.propiedadDireccion,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Grid de datos del contrato
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.8,
                    children: [
                      _gridTile('Inicio',  inquilino.contrato!.fechaInicio),
                      _gridTile('Fin',     inquilino.contrato!.fechaFin),
                      _gridTile('Renta',   inquilino.contrato!.renta,
                          valueColor: const Color(0xFF1695A3)),
                      _gridTile('Depósito', inquilino.contrato!.deposito),
                    ],
                  ),
                ],
              ),
            )
          else
            _Card(
              child: Column(
                children: [
                  const Icon(Icons.home_outlined,
                      size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Sin propiedad asignada',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // ── Datos Fiscales ─────────────────────────────────────────────
          if (inquilino.fiscalRfc != null && inquilino.fiscalRfc!.isNotEmpty)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TabGeneral._cardTitle(
                      Icons.receipt_long_outlined, 'Datos Fiscales (SAT)',
                      color: const Color(0xFF225378)),
                  const SizedBox(height: 10),
                  _fiscalRow(Icons.business_outlined,    'Razón Social',    inquilino.fiscalRazonSocial ?? '-'),
                  _fiscalRow(Icons.fingerprint,           'RFC',             inquilino.fiscalRfc ?? '-'),
                  _fiscalRow(Icons.account_balance_outlined, 'Régimen Fiscal', inquilino.fiscalRegimen ?? '-'),
                  _fiscalRow(Icons.description_outlined, 'Uso CFDI',        inquilino.fiscalUsoCfdi ?? '-'),
                  _fiscalRow(Icons.location_on_outlined, 'C.P.',            inquilino.fiscalCp ?? '-'),
                  _fiscalRow(Icons.mail_outline,          'Correo Fact.',    inquilino.fiscalCorreo ?? '-'),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context, '/inquilinos/editar',
                arguments: inquilino.id,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3FFE2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF1695A3).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: Color(0xFF1695A3), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Sin datos fiscales registrados Toca para agregar datos SAT.',
                        style: TextStyle(
                            color: Color(0xFF225378),
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: Color(0xFF1695A3), size: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _fiscalRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 15),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Color(0xFF225378),
                    fontWeight: FontWeight.w600,
                    fontSize: 11)),
          ),
        ],
      ),
    );
  }

  static Widget _cardTitle(IconData icon, String title,
      {Color color = const Color(0xFF1695A3)}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                color: Color(0xFF225378),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }

  static Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Color(0xFF225378),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  static Widget _miniBtn(
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }

  static Widget _badge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: text)),
    );
  }

  static Widget _gridTile(String label, String value,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 9)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? const Color(0xFF225378),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── TAB: PAGOS ───────────────────────────────────────────────────────────────
class _TabPagos extends StatelessWidget {
  final List<PagoInquilino> pagos;
  const _TabPagos({required this.pagos});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Historial de Pagos',
                  style: TextStyle(
                      color: Color(0xFF225378),
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Al corriente',
                    style: TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pagos.map((pago) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
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
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.attach_money,
                          color: Color(0xFF15803D), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pago.periodo,
                              style: const TextStyle(
                                  color: Color(0xFF225378),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
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
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(pago.monto,
                            style: const TextStyle(
                                color: Color(0xFF225378),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pago.statusBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(pago.status,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: pago.statusColor)),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── TAB: DOCUMENTOS ──────────────────────────────────────────────────────────
class _TabDocumentos extends StatelessWidget {
  final ArrendatarioDetalle inquilino;
  const _TabDocumentos({required this.inquilino});

  void _generarContratoPdf() {
    final contrato = inquilino.contrato;
    ContratoPdf.generarConDatos(
      arrendatario: inquilino.nombreCompleto,
      inmuebleDireccion: contrato?.propiedadDireccion ?? 'Sin dirección registrada',
      renta: contrato?.renta ?? '\$0',
      ciudad: contrato?.propiedadDireccion.split(',').last.trim() ?? 'México',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Expediente Digital',
              style: TextStyle(
                  color: Color(0xFF225378),
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),

          // ── Contrato de Arrendamiento ──────────────────────────────
          GestureDetector(
            onTap: _generarContratoPdf,
            child: Container(
              padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFACF0F2).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined,
                        color: Color(0xFF1695A3), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contrato de Arrendamiento',
                            style: TextStyle(
                                color: Color(0xFF225378),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          inquilino.contrato != null
                              ? 'Vigencia: ${inquilino.contrato!.fechaInicio} — ${inquilino.contrato!.fechaFin}'
                              : 'Sin contrato activo',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1695A3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_outlined,
                            color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('PDF',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
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

class _TabItem {
  final String key;
  final String label;
  const _TabItem({required this.key, required this.label});
}