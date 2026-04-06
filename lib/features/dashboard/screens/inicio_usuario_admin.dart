import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_header.dart';
import '../../../data/services/mantenimiento_service.dart' as mant_svc;
import '../widgets/admin_models.dart';
import '../widgets/admin_data.dart';
import '../widgets/admin_helpers.dart';
import '../widgets/admin_tab_btn.dart';
import '../widgets/usuario_tile.dart';
import '../widgets/admin_tile.dart';
import '../widgets/especialista_tile.dart';
import 'nuevo_admin_screen.dart';
import 'editar_admin_screen.dart';
import 'editar_especialista.dart';

// ---------------------------------------------------------------------------
// PANTALLA PRINCIPAL
// ---------------------------------------------------------------------------
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _activeTab = 0; // 0=Usuarios  1=Admins  2=Especialistas

  // -- Usuarios --
  late List<UsuarioAdmin> _usuarios;
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';

  // -- Admins --
  late List<Admin> _admins;
  final _searchAdminCtrl = TextEditingController();
  String _searchAdminTerm = '';

  // -- Especialistas --
  late List<Especialista> _especialistas;
  bool _isAddingProvider = false;
  final _formKey       = GlobalKey<FormState>();
  final _nombreEspCtrl = TextEditingController();
  final _telEspCtrl    = TextEditingController();
  final _emailEspCtrl  = TextEditingController();
  final _ciudadEspCtrl = TextEditingController();
  final _estadoGeoCtrl = TextEditingController();
  final _aniosExpCtrl  = TextEditingController();
  final _searchEspCtrl = TextEditingController();
  String _searchEspTerm = '';
  String _tipoSel   = 'Fontanero';
  bool   _disponible = true;

  // Loading state
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _usuarios      = [];
    _admins        = [];
    _especialistas = [];
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Cargar propietarios (usuarios)
      final propData = await ApiClient.get('/propietarios/');
      final propResults = propData['results'] as List;

      final List<UsuarioAdmin> usuarios = [];
      for (final json in propResults) {
        usuarios.add(UsuarioAdmin.fromJson(json));
      }

      // Cargar administradores desde su propio endpoint
      final adminData = await ApiClient.get('/administradores/');
      final adminResults = adminData['results'] as List;
      final List<Admin> admins = [];
      for (final json in adminResults) {
        admins.add(Admin.fromJson(json));
      }

      // Cargar especialistas
      final List<Especialista> esps = [];
      try {
        final espItems = await mant_svc.EspecialistasService.listar();
        for (final item in espItems) {
          try {
            final det = await mant_svc.EspecialistasService.detalle(item.id);
            esps.add(Especialista(
              id: det.id,
              nombre: det.nombre,
              especialidad: det.especialidad,
              telefono: det.telefono,
              email: det.email,
              ciudad: det.ciudad,
              estadoGeografico: det.estadoGeografico,
              calificacion: det.calificacion,
              aniosExperiencia: det.aniosExperiencia,
              disponible: det.disponible,
              createdAt: DateTime.now(),
            ));
          } catch (_) {}
        }
      } catch (_) {}

      setState(() {
        _usuarios = usuarios;
        _admins = admins;
        _especialistas = esps;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Error de conexión'; _loading = false; });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchAdminCtrl.dispose();
    _searchEspCtrl.dispose();
    _nombreEspCtrl.dispose(); _telEspCtrl.dispose();
    _emailEspCtrl.dispose();  _ciudadEspCtrl.dispose();
    _estadoGeoCtrl.dispose(); _aniosExpCtrl.dispose();
    super.dispose();
  }

  // -- Filtros ---------------------------------------------------------------
  List<UsuarioAdmin> get _filtradosUsuarios {
    if (_searchTerm.isEmpty) return _usuarios;
    final t = _searchTerm.toLowerCase();
    return _usuarios.where((u) =>
        u.nombre.toLowerCase().contains(t) ||
        u.apellidos.toLowerCase().contains(t) ||
        u.rol.toLowerCase().contains(t) ||
        u.propiedad.toLowerCase().contains(t)).toList();
  }

  List<Admin> get _filtradosAdmins {
    if (_searchAdminTerm.isEmpty) return _admins;
    final t = _searchAdminTerm.toLowerCase();
    return _admins.where((a) =>
        a.nombre.toLowerCase().contains(t) ||
        a.apellidos.toLowerCase().contains(t) ||
        a.email.toLowerCase().contains(t) ||
        a.rol.toLowerCase().contains(t)).toList();
  }

  List<Especialista> get _filtradosEsp {
    if (_searchEspTerm.isEmpty) return _especialistas;
    final t = _searchEspTerm.toLowerCase();
    return _especialistas.where((e) =>
        e.nombre.toLowerCase().contains(t) ||
        e.especialidad.toLowerCase().contains(t) ||
        e.ciudad.toLowerCase().contains(t)).toList();
  }

  // -- Acciones --------------------------------------------------------------
  void _eliminarUsuario(int id) => _confirmarEliminar(
    titulo: '¿Eliminar usuario?',
    cuerpo: '¿Estas seguro de eliminar este usuario permanentemente?',
    onConfirm: () async {
      try {
        await ApiClient.delete('/propietarios/$id/');
        setState(() => _usuarios.removeWhere((u) => u.id == id));
        _snack('Usuario eliminado del sistema', Colors.red.shade400);
      } on ApiException catch (e) {
        _snack(e.message, Colors.red);
      } catch (_) {
        _snack('Error al eliminar', Colors.red);
      }
    },
  );

  void _eliminarAdmin(int id) => _confirmarEliminar(
    titulo: '¿Eliminar administrador?',
    cuerpo: 'Esta accion revocara el acceso del administrador permanentemente.',
    onConfirm: () async {
      try {
        await ApiClient.delete('/administradores/$id/');
        setState(() => _admins.removeWhere((a) => a.id == id));
        _snack('Administrador eliminado', Colors.red.shade400);
      } on ApiException catch (e) {
        _snack(e.message, Colors.red);
      } catch (_) {
        _snack('Error al eliminar', Colors.red);
      }
    },
  );

  void _confirmarEliminar({
    required String titulo,
    required String cuerpo,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 26),
            ),
            const SizedBox(height: 14),
            Text(titulo, style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(cuerpo, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); onConfirm(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _nuevoAdmin() async {
    final result = await Navigator.push<Admin>(
      context,
      MaterialPageRoute(builder: (_) => const NuevoAdminScreen()),
    );
    if (result != null) {
      setState(() => _admins.add(result));
      _snack('Administrador registrado correctamente', const Color(0xFF1695A3));
    }
  }

  Future<void> _editarAdmin(Admin admin) async {
    final result = await Navigator.push<Admin>(
      context,
      MaterialPageRoute(builder: (_) => EditarAdminScreen(admin: admin)),
    );
    if (result != null) {
      setState(() {
        final idx = _admins.indexWhere((a) => a.id == result.id);
        if (idx != -1) _admins[idx] = result;
      });
      _snack('Administrador actualizado correctamente', const Color(0xFF1695A3));
    }
  }

  void _guardarEspecialista() async {
    if (_formKey.currentState!.validate()) {
      final body = {
        'nombre': _nombreEspCtrl.text.trim(),
        'especialidad': _tipoSel,
        'telefono': _telEspCtrl.text.trim(),
        'email': _emailEspCtrl.text.trim(),
        'ciudad': _ciudadEspCtrl.text.trim(),
        'estado_geografico': _estadoGeoCtrl.text.trim(),
        'anios_experiencia': int.tryParse(_aniosExpCtrl.text.trim()) ?? 0,
        'disponible': _disponible,
      };

      try {
        final det = await mant_svc.EspecialistasService.crear(body);
        setState(() {
          _especialistas.add(Especialista(
            id: det.id,
            nombre: det.nombre,
            especialidad: det.especialidad,
            telefono: det.telefono,
            email: det.email,
            ciudad: det.ciudad,
            estadoGeografico: det.estadoGeografico,
            calificacion: det.calificacion,
            aniosExperiencia: det.aniosExperiencia,
            disponible: det.disponible,
            createdAt: DateTime.now(),
          ));
          _isAddingProvider = false;
          for (final c in [_nombreEspCtrl, _telEspCtrl, _emailEspCtrl,
                _ciudadEspCtrl, _estadoGeoCtrl, _aniosExpCtrl]) {
            c.clear();
          }
          _tipoSel = 'Fontanero'; _disponible = true;
        });
        _snack('Especialista registrado correctamente', const Color(0xFF1695A3));
      } on ApiException catch (e) {
        _snack(e.message, Colors.red);
      } catch (_) {
        _snack('Error de conexión', Colors.red);
      }
    }
  }

  Future<void> _editarEspecialista(Especialista esp) async {
    final result = await Navigator.push<Especialista>(
      context,
      MaterialPageRoute(builder: (_) => EditarEspecialistaScreen(especialista: esp)),
    );
    if (result != null) {
      setState(() {
        final idx = _especialistas.indexWhere((e) => e.id == result.id);
        if (idx != -1) _especialistas[idx] = result;
      });
      _snack('Especialista actualizado correctamente', const Color(0xFF1695A3));
    }
  }

  void _eliminarEspecialista(int id) => _confirmarEliminar(
    titulo: '¿Eliminar especialista?',
    cuerpo: 'Esta acción eliminará al especialista permanentemente.',
    onConfirm: () async {
      try {
        await mant_svc.EspecialistasService.eliminar(id);
        setState(() => _especialistas.removeWhere((e) => e.id == id));
        _snack('Especialista eliminado', Colors.red.shade400);
      } on ApiException catch (e) {
        _snack(e.message, Colors.red);
      } catch (_) {
        _snack('Error al eliminar', Colors.red);
      }
    },
  );

  // -- Bottom sheets ---------------------------------------------------------
  void _mostrarDetalleUsuario(UsuarioAdmin u) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.60, maxChildSize: 0.92, minChildSize: 0.4, expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            adminHandle(), const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: u.activo ? const Color(0xFFACF0F2) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(u.inicial,
                    style: TextStyle(color: u.activo ? const Color(0xFF1695A3) : Colors.grey,
                        fontWeight: FontWeight.bold, fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.nombreCompleto, style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Row(children: [
                  adminChip(u.rol.toUpperCase(), const Color(0xFFACF0F2), const Color(0xFF1695A3)),
                  const SizedBox(width: 6),
                  adminChip(u.estado,
                    u.activo ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    u.activo ? Colors.green.shade700 : Colors.grey),
                ]),
              ])),
            ]),
            const SizedBox(height: 20), Divider(color: Colors.grey.shade100), const SizedBox(height: 12),
            adminSeccion('Informacion Personal'), const SizedBox(height: 10),
            adminFila('Nombre', u.nombre), adminFila('Apellidos', u.apellidos),
            if (u.fechaNacimiento != null) adminFila('Nacimiento', adminFmtDate(u.fechaNacimiento!)),
            adminFila('Folio INE', u.folioIne), const SizedBox(height: 14),
            adminSeccion('Contacto'), const SizedBox(height: 10),
            adminFila('Telefono', u.telefono), adminFila('Email', u.email), const SizedBox(height: 14),
            adminSeccion('Cuenta'), const SizedBox(height: 10),
            adminFila('Propiedad', u.propiedad), adminFila('Creado', adminFmtDate(u.createdAt)),
          ]),
        ),
      ),
    );
  }

  void _mostrarDetalleAdmin(Admin a) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65, maxChildSize: 0.92, minChildSize: 0.4, expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            adminHandle(), const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: a.activo
                        ? [const Color(0xFF225378), const Color(0xFF1695A3)]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(a.inicial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.nombreCompleto, style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 6),
                Row(children: [
                  adminChip(a.rol.toUpperCase(), const Color(0xFFE8F4FD), const Color(0xFF225378)),
                  const SizedBox(width: 6),
                  adminChip(
                    a.estado,
                    a.estado == 'activo' ? const Color(0xFFDCFCE7) :
                    a.estado == 'suspendido' ? const Color(0xFFFFF3CD) :
                    const Color(0xFFF1F5F9),
                    a.estado == 'activo' ? Colors.green.shade700 :
                    a.estado == 'suspendido' ? Colors.orange.shade700 :
                    Colors.grey,
                  ),
                ]),
              ])),
            ]),
            const SizedBox(height: 20), Divider(color: Colors.grey.shade100), const SizedBox(height: 12),
            adminSeccion('Informacion Personal'), const SizedBox(height: 10),
            adminFila('Nombre', a.nombre), adminFila('Apellidos', a.apellidos),
            if (a.fechaNacimiento != null) adminFila('Nacimiento', adminFmtDate(a.fechaNacimiento!)),
            adminFila('Folio INE', a.folioIne), const SizedBox(height: 14),
            adminSeccion('Contacto'), const SizedBox(height: 10),
            adminFila('Telefono', a.telefono), adminFila('Email', a.email), const SizedBox(height: 14),
            adminSeccion('Cuenta'), const SizedBox(height: 10),
            adminFila('Rol', a.rol), adminFila('Estado', a.estado),
            adminFila('Creado', adminFmtDate(a.createdAt)), adminFila('Actualizado', adminFmtDate(a.updatedAt)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _editarAdmin(a); },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar Administrador',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB7F00), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _mostrarDetalleEspecialista(Especialista e) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.60, maxChildSize: 0.92, minChildSize: 0.4, expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            adminHandle(), const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(color: Color(0xFFACF0F2), shape: BoxShape.circle),
                child: Center(child: Text(e.inicial,
                    style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.nombre, style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Row(children: [
                  adminChip(e.especialidad, const Color(0xFFACF0F2), const Color(0xFF1695A3)),
                  const SizedBox(width: 6),
                  adminChip(e.disponible ? 'Disponible' : 'Ocupado',
                    e.disponible ? const Color(0xFFDCFCE7) : Colors.grey.shade100,
                    e.disponible ? Colors.green.shade700 : Colors.grey),
                ]),
              ])),
              Column(children: [
                const Icon(Icons.star, color: Color(0xFFEB7F00), size: 18),
                Text(e.calificacion.toStringAsFixed(1),
                    style: const TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ]),
            const SizedBox(height: 20), Divider(color: Colors.grey.shade100), const SizedBox(height: 12),
            adminSeccion('Informacion Profesional'), const SizedBox(height: 10),
            adminFila('Especialidad', e.especialidad),
            adminFila('Años de Experiencia', '${e.aniosExperiencia} anios'),
            adminFila('Calificacion', e.calificacion.toStringAsFixed(2)),
            const SizedBox(height: 14),
            adminSeccion('Contacto y Ubicacion'), const SizedBox(height: 10),
            adminFila('Telefono', e.telefono), adminFila('Email', e.email),
            adminFila('Ciudad', e.ciudad), adminFila('Estado', e.estadoGeografico),
            const SizedBox(height: 14),
            adminSeccion('Cuenta'), const SizedBox(height: 10),
            adminFila('Registrado', adminFmtDate(e.createdAt)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(context); _eliminarEspecialista(e.id); },
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                  label: Text('Eliminar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red.shade400)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(context); _editarEspecialista(e); },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar Especialista',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEB7F00), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // -- Helpers ---------------------------------------------------------------
  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // -- BUILD -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Panel Admin'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1695A3)))
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _cargarDatos, child: const Text('Reintentar')),
                  ],
                ))
              : Column(children: [
        // Tabs
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Row(children: [
              AdminTabBtn(label: 'Usuarios', icon: Icons.people_outline,
                active: _activeTab == 0, activeColor: const Color(0xFF225378),
                onTap: () => setState(() { _activeTab = 0; _isAddingProvider = false; })),
              AdminTabBtn(label: 'Admins', icon: Icons.shield_outlined,
                active: _activeTab == 1, activeColor: const Color(0xFFEB7F00),
                onTap: () => setState(() { _activeTab = 1; _isAddingProvider = false; })),
              AdminTabBtn(label: 'Servicios', icon: Icons.handyman_outlined,
                active: _activeTab == 2, activeColor: const Color(0xFF1695A3),
                onTap: () => setState(() => _activeTab = 2)),
            ]),
          ),
        ),

        // Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            layoutBuilder: (cur, prev) => Stack(
              alignment: Alignment.topCenter,
              children: [...prev, ?cur],
            ),
            child: _activeTab == 0 ? _buildTabUsuarios()
                : _activeTab == 1 ? _buildTabAdmins()
                : _buildTabEspecialistas(),
          ),
        ),
      ]),
    );
  }

  // -- TAB USUARIOS ----------------------------------------------------------
  Widget _buildTabUsuarios() {
    return Column(key: const ValueKey('tab_usuarios'), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: adminSearchBar(_searchCtrl, 'Buscar usuario...',
            (v) => setState(() => _searchTerm = v),
            onClear: () { _searchCtrl.clear(); setState(() => _searchTerm = ''); },
            showClear: _searchTerm.isNotEmpty),
      ),
      Expanded(
        child: _filtradosUsuarios.isEmpty
            ? adminEmptyState('No se encontraron usuarios.')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: _filtradosUsuarios.length,
                itemBuilder: (_, i) {
                  final u = _filtradosUsuarios[i];
                  return UsuarioTile(
                    usuario: u,
                    onDelete: () => _eliminarUsuario(u.id),
                    onTap: () => _mostrarDetalleUsuario(u),
                  );
                }),
      ),
    ]);
  }

  // -- TAB ADMINS ------------------------------------------------------------
  Widget _buildTabAdmins() {
    return Column(key: const ValueKey('tab_admins'), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Column(children: [
          adminSearchBar(_searchAdminCtrl, 'Buscar administrador...',
              (v) => setState(() => _searchAdminTerm = v),
              onClear: () { _searchAdminCtrl.clear(); setState(() => _searchAdminTerm = ''); },
              showClear: _searchAdminTerm.isNotEmpty),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _nuevoAdmin,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Nuevo Administrador',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB7F00), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ),

      // Contador
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(children: [
          Text('${_filtradosAdmins.length} administrador(es)',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Spacer(),
          adminChip(
            '${_admins.where((a) => a.estado == 'activo').length} activos',
            const Color(0xFFDCFCE7), Colors.green.shade700,
          ),
        ]),
      ),

      Expanded(
        child: _filtradosAdmins.isEmpty
            ? adminEmptyState('No se encontraron administradores.')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: _filtradosAdmins.length,
                itemBuilder: (_, i) {
                  final a = _filtradosAdmins[i];
                  return AdminTile(
                    admin: a,
                    onTap: () => _mostrarDetalleAdmin(a),
                    onEdit: () => _editarAdmin(a),
                    onDelete: () => _eliminarAdmin(a.id),
                  );
                }),
      ),
    ]);
  }

  // -- TAB ESPECIALISTAS -----------------------------------------------------
  Widget _buildTabEspecialistas() {
    return SingleChildScrollView(
      key: const ValueKey('tab_esp'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        adminSearchBar(_searchEspCtrl, 'Buscar especialista...',
            (v) => setState(() => _searchEspTerm = v),
            onClear: () { _searchEspCtrl.clear(); setState(() => _searchEspTerm = ''); },
            showClear: _searchEspTerm.isNotEmpty),
        const SizedBox(height: 12),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
              child: child)),
          child: _isAddingProvider
              ? _buildFormEspecialista()
              : SizedBox(
                  key: const ValueKey('btn_nuevo_esp'),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isAddingProvider = true),
                    icon: const Icon(Icons.person_add_outlined, size: 20),
                    label: const Text('Nuevo Especialista',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1695A3), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3, shadowColor: const Color(0xFF1695A3).withOpacity(0.4),
                    ),
                  ),
                ),
        ),

        if (!_isAddingProvider) ...[
          const SizedBox(height: 20),
          const Text('Directorio Activo',
              style: TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          if (_filtradosEsp.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text(
                  _searchEspTerm.isNotEmpty ? 'No se encontraron especialistas.' : 'No hay especialistas registrados.',
                  style: const TextStyle(color: Colors.grey, fontSize: 13))),
            )
          else
            ...(_filtradosEsp.map((e) => EspecialistaTile(
              especialista: e,
              onTap: () => _mostrarDetalleEspecialista(e),
              onEdit: () => _editarEspecialista(e),
              onDelete: () => _eliminarEspecialista(e.id),
          ))),
        ],
      ]),
    );
  }

  Widget _buildFormEspecialista() {
    return Container(
      key: const ValueKey('form_esp'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFACF0F2), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Registrar Especialista',
                style: TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 15)),
            GestureDetector(
              onTap: () => setState(() => _isAddingProvider = false),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.grey, size: 18),
              ),
            ),
          ]),
          const SizedBox(height: 18),

          adminEspLabel('Nombre / Empresa'), const SizedBox(height: 5),
          TextFormField(controller: _nombreEspCtrl,
            validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
            style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
            decoration: adminEspDeco('Ej. Plomeria Express', Icons.person_outline)),
          const SizedBox(height: 14),

          adminEspLabel('Especialidad'), const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: _tipoSel, isExpanded: true,
              style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1695A3)),
              onChanged: (v) => setState(() => _tipoSel = v!),
              items: tiposEspecialista.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            )),
          ),
          const SizedBox(height: 14),

          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              adminEspLabel('Telefono'), const SizedBox(height: 5),
              TextFormField(controller: _telEspCtrl, keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')), LengthLimitingTextInputFormatter(15)],
                validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
                decoration: adminEspDeco('55 0000 0000', Icons.phone_outlined)),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              adminEspLabel('Email'), const SizedBox(height: 5),
              TextFormField(controller: _emailEspCtrl, keyboardType: TextInputType.emailAddress,
                validator: (v) { if (v!.trim().isEmpty) return 'Requerido'; if (!v.contains('@')) return 'Invalido'; return null; },
                style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
                decoration: adminEspDeco('correo@mail.mx', Icons.mail_outline)),
            ])),
          ]),
          const SizedBox(height: 14),

          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              adminEspLabel('Ciudad'), const SizedBox(height: 5),
              TextFormField(controller: _ciudadEspCtrl,
                validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
                decoration: adminEspDeco('Ej. CDMX', Icons.location_city_outlined)),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              adminEspLabel('Estado'), const SizedBox(height: 5),
              TextFormField(controller: _estadoGeoCtrl,
                validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
                decoration: adminEspDeco('Ej. Jalisco', Icons.map_outlined)),
            ])),
          ]),
          const SizedBox(height: 14),

          adminEspLabel('Años de Experiencia'), const SizedBox(height: 5),
          TextFormField(controller: _aniosExpCtrl, keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
            style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
            decoration: adminEspDeco('0', Icons.workspace_premium_outlined)),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF1695A3), size: 18),
              const SizedBox(width: 10),
              const Expanded(child: Text('Disponible actualmente',
                  style: TextStyle(fontSize: 13, color: Color(0xFF225378), fontWeight: FontWeight.w500))),
              Switch.adaptive(value: _disponible, onChanged: (v) => setState(() => _disponible = v),
                  activeColor: const Color(0xFF1695A3)),
            ]),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _guardarEspecialista,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Guardar Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1695A3), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
