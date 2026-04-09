// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/widgets/app_header.dart';
import '../../../core/services/api_client.dart';
import '../../../data/services/arrendatarios_service.dart';
// ignore_for_file: use_build_context_synchronously
import '../../propiedades/widgets/contrato_pdf.dart';
import '../../pagos/widgets/pago_models.dart';
import '../../pagos/widgets/pago_tile.dart';
import '../../pagos/widgets/detalle_pago_sheet.dart';

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

  ArrendatarioDetalle? _inquilino;
  bool _cargando = true;
  String? _error;

  static const _tabs = ['General', 'Pagos', 'Documentos'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (widget.arrendatarioId == null) {
      setState(() { _cargando = false; _error = 'ID no válido'; });
      return;
    }
    try {
      final d = await ArrendatariosService.detalle(widget.arrendatarioId!);
      if (mounted) setState(() { _inquilino = d; _cargando = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _cargando = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _cargando = false; _error = 'Sin conexión'; });
    }
  }

  Future<void> _eliminar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar inquilino',
            style: TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold)),
        content: const Text(
          'Esta acción no se puede deshacer. Se eliminará el inquilino y todos sus datos.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ArrendatariosService.eliminar(widget.arrendatarioId!);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message),
            backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el inquilino'),
            backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _llamar() async {
    final numero = (_inquilino?.telefono ?? '').replaceAll(RegExp(r'\s+'), '');
    if (numero.isEmpty) return;
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
    var numero = (_inquilino?.telefono ?? '').replaceAll(RegExp(r'\s+'), '');
    if (numero.isEmpty) return;
    if (!numero.startsWith('+')) numero = '+52$numero';
    final uri = Uri.parse(
        'https://wa.me/$numero?text=${Uri.encodeComponent("Hola, te contactamos por tu renta.")}');
    try {
      await launchUrl(uri,
          mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication);
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
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1695A3))),
      );
    }
    if (_error != null || _inquilino == null) {
      return Scaffold(
        appBar: const AppHeader(title: 'Detalle Inquilino', showBack: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.grey, size: 48),
              const SizedBox(height: 12),
              Text(_error ?? 'Inquilino no encontrado',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    final inq = _inquilino!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Detalle Inquilino',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Eliminar inquilino',
            onPressed: _eliminar,
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _ProfileHeader(
                  inquilino: inq,
                  onEdit: () => Navigator.pushNamed(
                    context, '/inquilinos/editar', arguments: inq.id,
                  ).then((_) => _cargarDatos()),
                ),
                const SizedBox(height: 52),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                      unselectedLabelStyle: const TextStyle(fontSize: 12),
                      indicator: BoxDecoration(
                        color: const Color(0xFF1695A3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: _tabs.map((t) => Tab(text: t, height: 36)).toList(),
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
            _TabGeneral(inquilino: inq, onLlamar: _llamar, onWhatsApp: _abrirWhatsApp, onEditar: _cargarDatos),
            _TabPagos(inquilinoId: inq.id),
            _TabDocumentos(inquilino: inq),
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
                            color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Inquilino desde ${inquilino.desdeAnio}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEB7F00), shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -44,
          child: Container(
            width: 88, height: 88,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: ClipOval(
              child: inquilino.fotoUrl != null && inquilino.fotoUrl!.isNotEmpty
                  ? Image.network(
                      inquilino.fotoUrl!,
                      width: 82, height: 82,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 82, height: 82,
                        color: const Color(0xFFACF0F2),
                        child: Center(child: _inicial(inquilino.inicial)),
                      ),
                    )
                  : Container(
                      width: 82, height: 82,
                      color: const Color(0xFFACF0F2),
                      child: Center(child: _inicial(inquilino.inicial)),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _inicial(String i) => Center(
    child: Text(i, style: const TextStyle(
        color: Color(0xFF1695A3), fontSize: 32, fontWeight: FontWeight.bold)),
  );
}


// ─── TAB: GENERAL ─────────────────────────────────────────────────────────────
class _TabGeneral extends StatelessWidget {
  final ArrendatarioDetalle inquilino;
  final VoidCallback onLlamar;
  final VoidCallback onWhatsApp;
  final VoidCallback onEditar;
  const _TabGeneral({required this.inquilino, required this.onLlamar, required this.onWhatsApp, required this.onEditar});

  @override
  Widget build(BuildContext context) {
    final inq = inquilino;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          // ── Información Personal ──────────────────────────────────────────
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardTitle(Icons.person_outline, 'Información Personal'),
                const SizedBox(height: 12),
                _contactRow(
                  icon: Icons.phone_outlined, label: 'Teléfono', value: inq.telefono,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    _miniBtn(Icons.phone_outlined, const Color(0xFF1695A3), onLlamar),
                    const SizedBox(width: 6),
                    _miniBtn(Icons.chat_outlined, const Color(0xFF25D366), onWhatsApp),
                  ]),
                ),
                const SizedBox(height: 8),
                _contactRow(icon: Icons.mail_outline, label: 'Email', value: inq.email),
                if (inq.folioIne.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _contactRow(
                      icon: Icons.credit_card_outlined,
                      label: 'Folio INE', value: inq.folioIne),
                ],
                if (inq.mascotas || inq.hijos) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (inq.mascotas) _badge('Mascotas',
                          const Color(0xFFF3FFE2), Colors.green.shade700),
                      if (inq.mascotas && inq.hijos) const SizedBox(width: 8),
                      if (inq.hijos) _badge('Hijos',
                          const Color(0xFFEFF6FF), Colors.blue.shade700),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Estado ───────────────────────────────────────────────────────
          _InfoCard(
            child: Row(
              children: [
                const Icon(Icons.toggle_on_outlined,
                    color: Color(0xFF1695A3), size: 18),
                const SizedBox(width: 8),
                const Text('Estado',
                    style: TextStyle(
                        color: Color(0xFF225378),
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: inq.estado == 'activo'
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    inq.estado == 'activo' ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: inq.estado == 'activo'
                          ? const Color(0xFF15803D) : Colors.grey,
                      fontSize: 12, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Acción editar ─────────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/inquilinos/editar',
                arguments: inq.id).then((_) => onEditar()),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3FFE2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1695A3).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, color: Color(0xFF1695A3), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Toca para editar datos del inquilino, contrato o información fiscal.',
                      style: TextStyle(color: Color(0xFF225378), fontSize: 12, height: 1.4),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Color(0xFF1695A3), size: 18),
                ],
              ),
            ),
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
        Text(title, style: const TextStyle(
            color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 14)),
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
        color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(
                    color: Color(0xFF225378), fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  static Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12), shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }

  static Widget _badge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.bold, color: text)),
    );
  }
}


class _TabPagos extends StatefulWidget {
  final int inquilinoId;
  const _TabPagos({required this.inquilinoId});

  @override
  State<_TabPagos> createState() => _TabPagosState();
}

class _TabPagosState extends State<_TabPagos> {
  List<Pago> _pagos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPagos();
  }

  Future<void> _cargarPagos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.get('/pagos/?contrato__arrendatario=${widget.inquilinoId}');
      final results = res['results'] as List;
      setState(() {
        _pagos = results.map((e) => Pago.fromJson(e)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  void _mostrarDetallePago(BuildContext context, Pago pago) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DetallePagoSheet(pago: pago),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_pagos.isEmpty) return const Center(child: Text('No hay pagos registrados', style: TextStyle(color: Colors.grey)));
    return RefreshIndicator(
      onRefresh: _cargarPagos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _pagos.length,
        itemBuilder: (context, i) => PagoTile(
          pago: _pagos[i],
          isLast: i == _pagos.length - 1,
          onTap: () => _mostrarDetallePago(context, _pagos[i]),
        ),
      ),
    );
  }
}

// ─── TAB: DOCUMENTOS ─────────────────────────────────────────────────────────
class _TabDocumentos extends StatefulWidget {
  final ArrendatarioDetalle inquilino;
  const _TabDocumentos({required this.inquilino});

  @override
  State<_TabDocumentos> createState() => _TabDocumentosState();
}

class _TabDocumentosState extends State<_TabDocumentos> {
  int? _contratoActivoId;
  bool _cancelando = false;

  Future<void> _generarContratoPdf(BuildContext context) async {
    try {
      // Cargar contrato activo del arrendatario
      final data = await ApiClient.get('/contratos/?arrendatario=${widget.inquilino.id}&estado=activo');
      final lista = data is List ? data : (data['results'] ?? []);

      String direccion = 'Ver contrato para dirección';
      String renta = 'Ver contrato para monto';
      String ciudad = 'México';
      String? fechaInicio;
      String? fechaFin;
      String? deposito;

      if ((lista as List).isNotEmpty) {
        final contrato = lista.first;
        fechaInicio = contrato['fecha_inicio'];
        fechaFin    = contrato['fecha_fin'];
        renta       = '\$${contrato['renta_acordada'] ?? 0}';
        deposito    = contrato['deposito']?.toString();

        // Cargar datos de la propiedad
        final propiedadId = contrato['propiedad'];
        if (propiedadId != null) {
          try {
            final prop = await ApiClient.get('/propiedades/$propiedadId/');
            direccion = '${prop['direccion'] ?? ''}, ${prop['ciudad'] ?? ''}, ${prop['estado_geografico'] ?? ''}';
            ciudad    = prop['ciudad'] ?? 'México';
          } catch (_) {}
        }
      }

      // Cargar nombre del propietario autenticado
      String arrendador = 'El Propietario';
      try {
        final me = await ApiClient.get('/auth/me/');
        arrendador = '${me['nombre'] ?? ''} ${me['apellidos'] ?? ''}'.trim();
      } catch (_) {}

      ContratoPdf.generarConDatos(
        arrendatario:       widget.inquilino.nombreCompleto,
        inmuebleDireccion:  direccion,
        renta:              renta,
        ciudad:             ciudad,
        arrendador:         arrendador,
        fechaInicio:        fechaInicio,
        fechaFin:           fechaFin,
        deposito:           deposito,
      );
    } catch (_) {
      // Si falla la carga, genera con lo que se tiene
      ContratoPdf.generarConDatos(
        arrendatario:      widget.inquilino.nombreCompleto,
        inmuebleDireccion: 'Ver contrato para dirección',
        renta:             'Ver contrato para monto',
        ciudad:            'México',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarContratoActivo();
  }

  Future<void> _cargarContratoActivo() async {
    try {
      final data = await ApiClient.get(
          '/contratos/?arrendatario=${widget.inquilino.id}&estado=activo');
      final lista = data is List ? data : (data['results'] ?? []);
      if ((lista as List).isNotEmpty && mounted) {
        setState(() => _contratoActivoId = lista.first['id'] as int?);
      }
    } catch (_) {}
  }

  Future<void> _cancelarContrato(BuildContext ctx) async {
    if (_contratoActivoId == null) return;
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar contrato',
            style: TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold)),
        content: const Text(
          'Esta acción cancelará el contrato activo y liberará la propiedad. ¿Deseas continuar?',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlg, false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlg, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancelar contrato',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _cancelando = true);
    try {
      await ApiClient.patch('/contratos/$_contratoActivoId/', {'estado': 'cancelado'});
      if (!mounted) return;
      setState(() => _contratoActivoId = null);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Contrato cancelado'),
          backgroundColor: Color(0xFF1695A3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Error al cancelar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
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
                  color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _generarContratoPdf(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.03), blurRadius: 6)],
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contrato de Arrendamiento',
                            style: TextStyle(
                                color: Color(0xFF225378),
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('Genera el PDF del contrato',
                            style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1695A3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_outlined, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('PDF', style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_contratoActivoId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelando ? null : () => _cancelarContrato(context),
                icon: _cancelando
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.red),
                      )
                    : const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                label: Text(
                  _cancelando ? 'Cancelando...' : 'Cancelar Contrato',
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ─── WIDGETS REUTILIZABLES ────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
