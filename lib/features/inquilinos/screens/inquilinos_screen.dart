import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_navbar.dart';

// ─── HELPERS DE CONTACTO ──────────────────────────────────────────────────────
Future<void> _llamar(BuildContext context, String telefono) async {
  final numero = telefono.replaceAll(RegExp(r'\s+'), '');
  final uri = Uri.parse('tel:$numero');
  try {
    // En web canLaunchUrl falla, usamos launchUrl directo
    await launchUrl(uri);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Llama al $numero'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1695A3),
        ),
      );
    }
  }
}

Future<void> _abrirWhatsApp(BuildContext context, String telefono) async {
  var numero = telefono.replaceAll(RegExp(r'\s+'), '');
  if (!numero.startsWith('+')) numero = '+52$numero';

  final uri = Uri.parse(
      'https://wa.me/$numero?text=${Uri.encodeComponent("Hola, te contactamos por tu renta.")}');
  try {
    // LaunchMode.externalApplication en móvil, platformDefault en web
    await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─── ENUM ─────────────────────────────────────────────────────────────────────
enum ArrendatarioEstado { activo, inactivo }
enum PagoStatus { al_corriente, pendiente, atrasado }

extension PagoStatusExt on PagoStatus {
  String get label {
    switch (this) {
      case PagoStatus.al_corriente: return 'Al corriente';
      case PagoStatus.pendiente:    return 'Pendiente';
      case PagoStatus.atrasado:     return 'Atrasado';
    }
  }

  Color get bgColor {
    switch (this) {
      case PagoStatus.al_corriente: return const Color(0xFFDCFCE7);
      case PagoStatus.pendiente:    return const Color(0xFFFEF9C3);
      case PagoStatus.atrasado:     return const Color(0xFFFFE4E6);
    }
  }

  Color get textColor {
    switch (this) {
      case PagoStatus.al_corriente: return const Color(0xFF15803D);
      case PagoStatus.pendiente:    return const Color(0xFFA16207);
      case PagoStatus.atrasado:     return const Color(0xFFBE123C);
    }
  }
}

// ─── MODELO según Django ──────────────────────────────────────────────────────
class Arrendatario {
  final int id;
  final String nombre;
  final String apellidos;
  final String telefono;
  final String email;
  final DateTime? fechaNacimiento;
  final String folioIne;
  final String? fotoUrl;
  final bool mascotas;
  final bool hijos;
  final ArrendatarioEstado estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos relacionales (para vista de lista)
  final String? propiedadAsignada; // nombre de la propiedad del contrato activo
  final PagoStatus? statusPago;    // calculado desde contratos/pagos

  const Arrendatario({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.telefono,
    required this.email,
    this.fechaNacimiento,
    required this.folioIne,
    this.fotoUrl,
    required this.mascotas,
    required this.hijos,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
    this.propiedadAsignada,
    this.statusPago,
  });

  String get nombreCompleto => '$nombre $apellidos';
  String get inicial => nombre[0].toUpperCase();

  // TODO: usar al conectar Django → GET /api/arrendatarios/
  factory Arrendatario.fromJson(Map<String, dynamic> json) {
    return Arrendatario(
      id:               json['id'],
      nombre:           json['nombre'],
      apellidos:        json['apellidos'],
      telefono:         json['telefono'],
      email:            json['email'],
      fechaNacimiento:  json['fecha_nacimiento'] != null
                          ? DateTime.parse(json['fecha_nacimiento'])
                          : null,
      folioIne:         json['folio_ine'],
      fotoUrl:          json['foto'],
      mascotas:         json['mascotas'],
      hijos:            json['hijos'],
      estado:           json['estado'] == 'activo'
                          ? ArrendatarioEstado.activo
                          : ArrendatarioEstado.inactivo,
      createdAt:        DateTime.parse(json['created_at']),
      updatedAt:        DateTime.parse(json['updated_at']),
    );
  }
}

// ─── DATOS EJEMPLO ────────────────────────────────────────────────────────────
final List<Arrendatario> _arrendatariosEjemplo = [
  Arrendatario(
    id: 1,
    nombre: 'Juan', apellidos: 'Pérez López',
    telefono: '55 1234 5678', email: 'juan.perez@email.com',
    folioIne: 'PELJ901012HDFRZN01',
    mascotas: false, hijos: true,
    estado: ArrendatarioEstado.activo,
    createdAt: DateTime(2023, 1, 1), updatedAt: DateTime(2025, 1, 1),
    propiedadAsignada: 'Depto 302 - Reforma',
    statusPago: PagoStatus.al_corriente,
  ),
  Arrendatario(
    id: 2,
    nombre: 'Maria', apellidos: 'González Ruiz',
    telefono: '55 8765 4321', email: 'maria.gz@email.com',
    folioIne: 'GORM850320MDFNZR02',
    mascotas: true, hijos: false,
    estado: ArrendatarioEstado.activo,
    createdAt: DateTime(2023, 3, 15), updatedAt: DateTime(2025, 2, 1),
    propiedadAsignada: 'Casa Jardines',
    statusPago: PagoStatus.pendiente,
  ),
  Arrendatario(
    id: 3,
    nombre: 'Carlos', apellidos: 'Ruiz Mendoza',
    telefono: '55 1122 3344', email: 'carlos.rm@email.com',
    folioIne: 'RUMC780915HDFZND03',
    mascotas: false, hijos: true,
    estado: ArrendatarioEstado.activo,
    createdAt: DateTime(2023, 6, 1), updatedAt: DateTime(2025, 1, 15),
    propiedadAsignada: 'Loft Centro',
    statusPago: PagoStatus.al_corriente,
  ),
  Arrendatario(
    id: 4,
    nombre: 'Ana', apellidos: 'López Torres',
    telefono: '55 9988 7766', email: 'ana.lt@email.com',
    folioIne: 'LOTA920610MDFPRN04',
    mascotas: true, hijos: true,
    estado: ArrendatarioEstado.activo,
    createdAt: DateTime(2022, 11, 20), updatedAt: DateTime(2025, 3, 1),
    propiedadAsignada: 'Local 5',
    statusPago: PagoStatus.atrasado,
  ),
];

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class InquilinosScreen extends StatefulWidget {
  const InquilinosScreen({super.key});

  @override
  State<InquilinosScreen> createState() => _InquilinosScreenState();
}

class _InquilinosScreenState extends State<InquilinosScreen> {
  final int _navIndex = 2;
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
      '/propiedades',
      '',
      '/pagos',
      '/mantenimiento',
    ];
    if (index != _navIndex) {
      Navigator.pushNamed(context, routes[index]);
    }
  }

  List<Arrendatario> get _filtrados {
    if (_searchTerm.isEmpty) return _arrendatariosEjemplo;
    final term = _searchTerm.toLowerCase();
    return _arrendatariosEjemplo.where((a) =>
        a.nombreCompleto.toLowerCase().contains(term) ||
        (a.propiedadAsignada?.toLowerCase().contains(term) ?? false) ||
        a.telefono.contains(term) ||
        a.email.toLowerCase().contains(term)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Inquilinos'),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/inquilinos/nuevo'),
        backgroundColor: const Color(0xFFEB7F00),
        elevation: 4,
        child: const Icon(Icons.person_add_outlined,
            color: Colors.white, size: 26),
      ),
      body: Column(
        children: [
          // ── Buscador ──────────────────────────────────────────────────────
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchTerm = v),
              style: const TextStyle(
                  color: Color(0xFF225378), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar inquilino...',
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
            child: _filtrados.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No se encontraron inquilinos.',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: _filtrados.length,
                    itemBuilder: (context, index) => _InquilinoCard(
                      arrendatario: _filtrados[index],
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/inquilinos/info',
                        arguments: _filtrados[index].id,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── TARJETA INQUILINO ────────────────────────────────────────────────────────
class _InquilinoCard extends StatelessWidget {
  final Arrendatario arrendatario;
  final VoidCallback onTap;

  const _InquilinoCard({
    required this.arrendatario,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = arrendatario;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────────────
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFACF0F2),
                shape: BoxShape.circle,
                image: a.fotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(a.fotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: a.fotoUrl == null
                  ? Center(
                      child: Text(
                        a.inicial,
                        style: const TextStyle(
                          color: Color(0xFF1695A3),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // ── Info ─────────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.nombreCompleto,
                      style: const TextStyle(
                          color: Color(0xFF225378),
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    a.propiedadAsignada ?? 'Sin propiedad asignada',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 5),

                  // Badges: status pago + extras
                  Row(
                    children: [
                      if (a.statusPago != null)
                        _Badge(
                          label: a.statusPago!.label,
                          bgColor: a.statusPago!.bgColor,
                          textColor: a.statusPago!.textColor,
                        ),
                      if (a.mascotas) ...[
                        const SizedBox(width: 5),
                        _Badge(
                          label: '🐾 Mascotas',
                          bgColor: const Color(0xFFF3FFE2),
                          textColor: Colors.green.shade700,
                        ),
                      ],
                      if (a.hijos) ...[
                        const SizedBox(width: 5),
                        _Badge(
                          label: '👶 Hijos',
                          bgColor: const Color(0xFFEFF6FF),
                          textColor: Colors.blue.shade700,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Acciones ────────────────────────────────────────────────────
            Column(
              children: [
                _ActionBtn(
                  icon: Icons.phone_outlined,
                  color: const Color(0xFF1695A3),
                  tooltip: 'Llamar',
                  onTap: () => _llamar(context, a.telefono),
                ),
                const SizedBox(height: 6),
                _ActionBtn(
                  icon: Icons.chat_outlined,
                  color: const Color(0xFF25D366), // verde WhatsApp
                  tooltip: 'WhatsApp',
                  onTap: () => _abrirWhatsApp(context, a.telefono),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS AUXILIARES ───────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: textColor)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }
}