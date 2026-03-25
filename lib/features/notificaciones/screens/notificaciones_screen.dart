import 'package:flutter/material.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_header.dart';
import '../../../data/services/notificaciones_service.dart';

// ─── MODELOS según backend Django ─────────────────────────────────────────────
enum NotifTipo { pago_proximo, pago_vencido, contrato_por_vencer, general }
enum NotifMedio { email, sms, push, whatsapp }

class Notificacion {
  final int id;
  final NotifTipo tipo;
  final String titulo;
  final String mensaje;
  final DateTime fechaProgramada;
  final NotifMedio medio;
  final DateTime createdAt;
  bool read;

  Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.fechaProgramada,
    required this.medio,
    required this.createdAt,
    this.read = false,
  });

  // TODO: usar cuando conectes Django → GET /api/notificaciones/
  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      tipo: NotifTipo.values.firstWhere((e) => e.name == json['tipo']),
      titulo: json['titulo'],
      mensaje: json['mensaje'],
      fechaProgramada: DateTime.parse(json['fecha_programada']),
      medio: NotifMedio.values.firstWhere((e) => e.name == json['medio']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// (datos mock eliminados — ahora se cargan desde el API)

// ─── PANTALLA ─────────────────────────────────────────────────────────────────
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<Notificacion> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await NotificacionesService.listar();
      setState(() {
        _notifications = items.map((item) {
          return Notificacion(
            id: item.id,
            tipo: NotifTipo.values.firstWhere(
              (e) => e.name == item.tipo,
              orElse: () => NotifTipo.general,
            ),
            titulo: item.titulo,
            mensaje: '',
            fechaProgramada: DateTime.tryParse(item.fechaProgramada) ?? DateTime.now(),
            medio: NotifMedio.values.firstWhere(
              (e) => e.name == item.medio,
              orElse: () => NotifMedio.email,
            ),
            createdAt: DateTime.tryParse(item.fechaProgramada) ?? DateTime.now(),
            read: item.leida,
          );
        }).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Error de conexión'; _loading = false; });
    }
  }

  Future<void> _remove(int id) async {
    try {
      await NotificacionesService.eliminar(id);
      setState(() => _notifications.removeWhere((n) => n.id == id));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      // Si falla la API, igual removemos de la UI
      setState(() => _notifications.removeWhere((n) => n.id == id));
    }
  }

  Future<void> _markAllRead() async {
    try {
      await NotificacionesService.marcarTodasComoLeidas();
      setState(() {
        for (final n in _notifications) {
          n.read = true;
        }
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al marcar todas como leídas'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _tiempoRelativo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Notificaciones', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1695A3)))
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _cargarNotificaciones, child: const Text('Reintentar')),
                  ],
                ))
              : Column(
        children: [
          // ── Barra superior ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'RECIENTES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEB7F00),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                GestureDetector(
                  onTap: _markAllRead,
                  child: const Text(
                    'Marcar todo como leído',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1695A3),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Lista ────────────────────────────────────────────────────────
          Expanded(
            child: _notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No tienes notificaciones nuevas.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return _NotifCard(
                        key: ValueKey(notif.id),
                        notif: notif,
                        tiempo: _tiempoRelativo(notif.createdAt),
                        onDismiss: () => _remove(notif.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── TARJETA ──────────────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final Notificacion notif;
  final String tiempo;
  final VoidCallback onDismiss;

  const _NotifCard({
    super.key,
    required this.notif,
    required this.tiempo,
    required this.onDismiss,
  });

  IconData get _icon {
    switch (notif.tipo) {
      case NotifTipo.pago_proximo:        return Icons.calendar_today;
      case NotifTipo.pago_vencido:        return Icons.warning_amber_rounded;
      case NotifTipo.contrato_por_vencer: return Icons.description_outlined;
      case NotifTipo.general:             return Icons.notifications_outlined;
    }
  }

  Color get _color {
    switch (notif.tipo) {
      case NotifTipo.pago_proximo:        return const Color(0xFF1695A3);
      case NotifTipo.pago_vencido:        return Colors.red;
      case NotifTipo.contrato_por_vencer: return const Color(0xFFEB7F00);
      case NotifTipo.general:             return const Color(0xFF225378);
    }
  }

  String get _medioLabel {
    switch (notif.medio) {
      case NotifMedio.email:    return '✉ Email';
      case NotifMedio.sms:      return '💬 SMS';
      case NotifMedio.push:     return '🔔 Push';
      case NotifMedio.whatsapp: return '📱 WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
      ),
      child: Opacity(
        opacity: notif.read ? 0.7 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),  // uniform ✓
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ← Colored left accent bar
                  Container(
                    width: 4,
                    color: notif.read ? Colors.grey.shade200 : _color,
                  ),
                  // ← Original content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notif.titulo,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: notif.read
                                    ? Colors.grey.shade600
                                    : const Color(0xFF225378),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tiempo,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}