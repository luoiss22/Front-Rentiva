import 'package:flutter/material.dart';

// ─── PANTALLA TUTORIAL / ONBOARDING ─────────────────────────────────────────
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  static const _teal = Color(0xFF1695A3);
  static const _dark = Color(0xFF225378);
  static const _orange = Color(0xFFEB7F00);
  static const _lightTeal = Color(0xFFACF0F2);

  static final List<_TutorialPage> _pages = [
    // 0 ─ Bienvenida
    _TutorialPage(
      icon: Icons.home_rounded,
      iconBg: _dark,
      title: 'Bienvenido a Rentiva',
      subtitle: 'Tu asistente integral para la\nadministración de rentas',
      body:
          'Gestiona propiedades, inquilinos, pagos, mantenimiento y más desde un solo lugar. '
          'Desliza para conocer cada sección.',
      tips: [],
    ),
    // 1 ─ Dashboard
    _TutorialPage(
      icon: Icons.dashboard_rounded,
      iconBg: _teal,
      title: 'Panel de Inicio',
      subtitle: 'Tu resumen en una vista',
      body:
          'Al iniciar sesión llegarás al panel principal donde encontrarás:',
      tips: [
        _Tip(Icons.bar_chart_rounded, 'Resumen de ingresos y pagos pendientes del mes.'),
        _Tip(Icons.notifications_active_outlined, 'Acceso rápido a notificaciones importantes.'),
        _Tip(Icons.person_outline, 'Tu perfil y ajustes desde el avatar superior.'),
        _Tip(Icons.menu_rounded, 'Barra de navegación inferior para moverte entre secciones.'),
      ],
    ),
    // 2 ─ Propiedades
    _TutorialPage(
      icon: Icons.apartment_rounded,
      iconBg: _dark,
      title: 'Propiedades',
      subtitle: 'Controla todos tus inmuebles',
      body:
          'Registra y administra cada propiedad con información completa:',
      tips: [
        _Tip(Icons.add_home_outlined, 'Agrega casas, departamentos, locales u oficinas.'),
        _Tip(Icons.photo_library_outlined, 'Sube fotos y detalles de cada propiedad.'),
        _Tip(Icons.chair_outlined, 'Lleva un inventario del mobiliario incluido.'),
        _Tip(Icons.edit_location_outlined, 'Dirección, ciudad, estado y código postal.'),
      ],
    ),
    // 3 ─ Inquilinos
    _TutorialPage(
      icon: Icons.people_rounded,
      iconBg: _teal,
      title: 'Inquilinos',
      subtitle: 'Gestión de arrendatarios',
      body:
          'Mantén un directorio completo de tus inquilinos:',
      tips: [
        _Tip(Icons.person_add_outlined, 'Registra nombre, contacto, INE y foto.'),
        _Tip(Icons.pets_outlined, 'Indica si tienen mascotas o hijos.'),
        _Tip(Icons.assignment_outlined, 'Vincula contratos con fechas y montos.'),
        _Tip(Icons.search_rounded, 'Busca rápidamente por nombre o propiedad.'),
      ],
    ),
    // 4 ─ Pagos
    _TutorialPage(
      icon: Icons.receipt_long_rounded,
      iconBg: _orange,
      title: 'Pagos y Facturas',
      subtitle: 'Control financiero completo',
      body:
          'Lleva el registro de todos los movimientos económicos:',
      tips: [
        _Tip(Icons.attach_money_rounded, 'Ve ingresos recibidos y saldos pendientes.'),
        _Tip(Icons.filter_list_rounded, 'Filtra por pagados, pendientes o vencidos.'),
        _Tip(Icons.picture_as_pdf_outlined, 'Genera facturas CFDI en PDF con un toque.'),
        _Tip(Icons.download_rounded, 'Descarga fichas de pago con datos bancarios.'),
      ],
    ),
    // 5 ─ Mantenimiento
    _TutorialPage(
      icon: Icons.build_rounded,
      iconBg: _dark,
      title: 'Mantenimiento',
      subtitle: 'Reportes y especialistas',
      body:
          'Gestiona las solicitudes de mantenimiento de tus propiedades:',
      tips: [
        _Tip(Icons.report_problem_outlined, 'Crea reportes con prioridad: baja, media, alta o urgente.'),
        _Tip(Icons.handyman_outlined, 'Asigna especialistas (fontaneros, electricistas, etc.).'),
        _Tip(Icons.star_outline_rounded, 'Califica el servicio con reseñas.'),
        _Tip(Icons.track_changes_rounded, 'Sigue el estado: abierto, en proceso o resuelto.'),
      ],
    ),
    // 6 ─ Notificaciones
    _TutorialPage(
      icon: Icons.notifications_rounded,
      iconBg: _teal,
      title: 'Notificaciones',
      subtitle: 'Nunca pierdas un aviso',
      body:
          'Mantente al día con alertas automáticas:',
      tips: [
        _Tip(Icons.schedule_outlined, 'Aviso de pagos próximos a vencer.'),
        _Tip(Icons.warning_amber_rounded, 'Alerta de pagos vencidos.'),
        _Tip(Icons.event_outlined, 'Contratos por vencer.'),
        _Tip(Icons.campaign_outlined, 'Avisos generales del sistema.'),
      ],
    ),
    // 7 ─ Listo
    _TutorialPage(
      icon: Icons.rocket_launch_rounded,
      iconBg: _orange,
      title: '¡Listo para empezar!',
      subtitle: 'Ya conoces Rentiva',
      body:
          'Ahora tienes todo el conocimiento para aprovechar al máximo la plataforma. '
          'Puedes volver a consultar este tutorial desde la pantalla principal.',
      tips: [],
    ),
  ];

  void _next() {
    if (_current < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _skip() => Navigator.pop(context);

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _current == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Contador de página
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _lightTeal.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_current + 1} / ${_pages.length}',
                      style: const TextStyle(
                          color: _teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  if (!isLast)
                    TextButton(
                      onPressed: _skip,
                      child: const Text('Omitir',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    )
                  else
                    const SizedBox(width: 60),
                ],
              ),
            ),

            // ── Progress bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_current + 1) / _pages.length,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(_teal),
                ),
              ),
            ),

            // ── Pages ───────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            // ── Dots + Button ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _current ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _current ? _teal : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast ? _orange : _dark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                        shadowColor: (isLast ? _orange : _dark).withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? 'Comenzar a usar Rentiva' : 'Siguiente',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLast
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_forward_ios_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Builder de cada página ──────────────────────────────────────────────
  Widget _buildPage(_TutorialPage page) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          // Ícono grande
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: page.iconBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: page.iconBg.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(page.icon, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _dark,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtítulo
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _teal,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Descripción
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // Tips (si hay)
          if (page.tips.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: page.tips
                    .asMap()
                    .entries
                    .map((entry) => _buildTip(
                          entry.value,
                          isLast: entry.key == page.tips.length - 1,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTip(_Tip tip, {required bool isLast}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _lightTeal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tip.icon, color: _teal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                tip.text,
                style: const TextStyle(
                  color: _dark,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DATA CLASSES ────────────────────────────────────────────────────────────
class _TutorialPage {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String body;
  final List<_Tip> tips;

  const _TutorialPage({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.tips,
  });
}

class _Tip {
  final IconData icon;
  final String text;
  const _Tip(this.icon, this.text);
}
