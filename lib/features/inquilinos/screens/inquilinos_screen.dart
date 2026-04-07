import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/bottom_navbar.dart';
import '../../../data/services/arrendatarios_service.dart';

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
  Timer? _debounceTimer;
  late Future<List<ArrendatarioItem>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ArrendatariosService.listar();
  }

  void _recargar() {
    setState(() {
      _futuro = ArrendatariosService.listar(
        busqueda: _searchTerm.isEmpty ? null : _searchTerm,
      );
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    const routes = [
      '/inicio-usuario', '/propiedades', '', '/pagos', '/mantenimiento',
    ];
    if (index != _navIndex) Navigator.pushNamed(context, routes[index]);
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
        onPressed: () => Navigator.pushNamed(context, '/inquilinos/nuevo')
            .then((_) => _recargar()),
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
              onSubmitted: (_) {
                _debounceTimer?.cancel();
                _recargar();
              },
              onChanged: (v) {
                _debounceTimer?.cancel();
                setState(() => _searchTerm = v);
                _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                  _recargar();
                });
              },
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
                          _recargar();
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

          // ── Lista con datos reales ─────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<ArrendatarioItem>>(
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
                        Text(snapshot.error.toString(),
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center),
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
                        Icon(Icons.people_outline, size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No se encontraron inquilinos.',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: lista.length,
                  itemBuilder: (context, index) => _InquilinoCard(
                    arrendatario: lista[index],
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/inquilinos/info',
                      arguments: lista[index].id,
                    ).then((_) => _recargar()),
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

// ─── TARJETA INQUILINO ────────────────────────────────────────────────────────
class _InquilinoCard extends StatelessWidget {
  final ArrendatarioItem arrendatario;
  final VoidCallback onTap;

  const _InquilinoCard({required this.arrendatario, required this.onTap});

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
              width: 50, height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFACF0F2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  a.inicial,
                  style: const TextStyle(
                    color: Color(0xFF1695A3),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
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
                  Text(a.propiedadActual,
                      style: const TextStyle(color: Color(0xFF1695A3), fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(a.email,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  _Badge(
                    label: a.estado == 'activo' ? 'Activo' : 'Inactivo',
                    bgColor: a.estado == 'activo'
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    textColor: a.estado == 'activo'
                        ? const Color(0xFF15803D)
                        : Colors.grey,
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