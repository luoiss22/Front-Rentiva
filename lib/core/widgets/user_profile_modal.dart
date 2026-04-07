import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../providers/auth_provider.dart';
import '../utils/upper_case_formatter.dart';

// ─── MODELO DATOS FISCALES según Django ──────────────────────────────────────
class DatosFiscales {
  final int? id;
  final String nombreORazonSocial;
  final String rfc;
  final String regimenFiscal;
  final String usoCfdi;
  final String codigoPostal;
  final String correoFacturacion;

  const DatosFiscales({
    this.id,
    required this.nombreORazonSocial,
    required this.rfc,
    required this.regimenFiscal,
    required this.usoCfdi,
    required this.codigoPostal,
    required this.correoFacturacion,
  });
}

// ─── MODELO DATOS BANCARIOS ───────────────────────────────────────────────────
class DatosBancarios {
  final int? id;
  final String clabe;
  final String banco;

  const DatosBancarios({
    this.id,
    required this.clabe,
    required this.banco,
  });
}

// Catálogos SAT simplificados
const List<String> _regimenesFiscales = [
  '601 - General de Ley Personas Morales',
  '603 - Personas Morales con Fines No Lucrativos',
  '605 - Sueldos y Salarios',
  '606 - Arrendamiento',
  '607 - Régimen de Enajenación o Adquisición de Bienes',
  '608 - Demás ingresos',
  '612 - Personas Físicas con Actividades Empresariales',
  '616 - Sin obligaciones fiscales',
  '621 - Incorporación Fiscal',
  '625 - Régimen de las Actividades Empresariales con ingresos',
  '626 - Régimen Simplificado de Confianza',
];

const List<Map<String, String>> _usosCfdi = [
  {'value': 'G01', 'label': 'G01 - Adquisición de mercancias'},
  {'value': 'G02', 'label': 'G02 - Devoluciones, descuentos o bonificaciones'},
  {'value': 'G03', 'label': 'G03 - Gastos en general'},
  {'value': 'I01', 'label': 'I01 - Construcciones'},
  {'value': 'I03', 'label': 'I03 - Equipo de transporte'},
  {'value': 'D01', 'label': 'D01 - Honorarios médicos'},
  {'value': 'D10', 'label': 'D10 - Pagos por servicios educativos'},
  {'value': 'P01', 'label': 'P01 - Por definir'},
  {'value': 'S01', 'label': 'S01 - Sin efectos fiscales'},
];

// Catálogo de bancos mexicanos
const List<String> _bancos = [
  'BBVA',
  'Banorte',
  'HSBC',
  'Santander',
  'Citibanamex',
  'Scotiabank',
  'Inbursa',
  'Banbajío',
  'Afirme',
  'Banco del Ejército',
  'Otro',
];

class UserProfileModal extends StatefulWidget {
  const UserProfileModal({super.key});

  @override
  State<UserProfileModal> createState() => _UserProfileModalState();
}

class _UserProfileModalState extends State<UserProfileModal> {
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  final bool _obscurePassword = true;
  bool _loadingProfile = true;
  File? _imageFile;
  Uint8List? _webImage;
  bool _imagenCambiada = false;
  String? _fotoUrl;

  Map<String, String> _userData = {
    'nombre': '', 'apellidos': '', 'fechaNac': '',
    'telefono': '', 'email': '', 'claveElector': '', 'cargo': '',
  };

  DatosFiscales? _fiscal;
  DatosBancarios? _bancario;

  int? _userId;

  // ── Controladores ───────────────────────────────────────────────────────────
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidosCtrl;
  late TextEditingController _fechaNacCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _claveElectorCtrl;
  late TextEditingController _passwordCtrl;

  // ── Controladores — DatosFiscales ─────────────────────────────────────────
  late TextEditingController _razonSocialCtrl;
  late TextEditingController _rfcCtrl;
  late TextEditingController _cpCtrl;
  late TextEditingController _correoFiscalCtrl;
  String _regimenFiscal = '606 - Arrendamiento';
  String _usoCfdi       = 'G03';
  bool _showFiscal      = false;

  // ── Controladores — DatosBancarios ────────────────────────────────────────
  late TextEditingController _clabeCtrl;
  String _banco      = 'BBVA';
  bool _showBancario = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final rawData = await ApiClient.get('/auth/me/');
      final data = rawData['usuario'] as Map<String, dynamic>? ?? rawData;
      final userType = rawData['user_type'] as String? ?? 'propietario';
      if (mounted) setState(() => _userId = data['id']);
      final nombre    = data['nombre']    ?? '';
      final apellidos = data['apellidos'] ?? '';
      final fechaNac  = data['fecha_nacimiento'] != null
          ? _isoADisplay(data['fecha_nacimiento'])
          : '';
      setState(() {
        _fotoUrl = ApiClient.resolveMediaUrl(data['foto'] as String?);
        _userData = {
          'nombre':       nombre,
          'apellidos':    apellidos,
          'fechaNac':     fechaNac,
          'telefono':     data['telefono']  ?? '',
          'email':        data['email']     ?? '',
          'claveElector': data['folio_ine'] ?? '',
          'banco':        data['banco']     ?? '',
          'clabe':        data['clabe_interbancaria'] ?? '',
          'cargo':        userType,
        };
        if ((data['clabe_interbancaria'] ?? '').isNotEmpty) {
          _bancario = DatosBancarios(
            banco: data['banco']?.isNotEmpty == true ? data['banco'] : 'BBVA',
            clabe: data['clabe_interbancaria'],
          );
          _clabeCtrl.text = _bancario!.clabe;
          _banco = _bancario!.banco;
        }
        _loadingProfile = false;
      });
      _nombreCtrl.text       = nombre;
      _apellidosCtrl.text    = apellidos;
      _fechaNacCtrl.text     = fechaNac;
      _telefonoCtrl.text     = data['telefono']  ?? '';
      _emailCtrl.text        = data['email']     ?? '';
      _claveElectorCtrl.text = data['folio_ine'] ?? '';

      if (_userId != null) {
        try {
          final res = await ApiClient.get('/datos-fiscales/?tipo_entidad=propietario&entidad_id=$_userId');
          if (res['results'] != null && res['results'].isNotEmpty) {
            final f = res['results'][0];
            setState(() {
              _fiscal = DatosFiscales(
                id: f['id'],
                nombreORazonSocial: f['nombre_o_razon_social'] ?? '',
                rfc: f['rfc'] ?? '',
                regimenFiscal: f['regimen_fiscal'] ?? '',
                usoCfdi: f['uso_cfdi'] ?? '',
                codigoPostal: f['codigo_postal'] ?? '',
                correoFacturacion: f['correo_facturacion'] ?? '',
              );
              _razonSocialCtrl.text = _fiscal!.nombreORazonSocial;
              _rfcCtrl.text = _fiscal!.rfc;
              _cpCtrl.text = _fiscal!.codigoPostal;
              _correoFiscalCtrl.text = _fiscal!.correoFacturacion;
              
              if (_fiscal!.regimenFiscal.isNotEmpty) {
                if (_regimenesFiscales.contains(_fiscal!.regimenFiscal)) {
                  _regimenFiscal = _fiscal!.regimenFiscal;
                } else {
                  final match = _regimenesFiscales.where((r) => r.startsWith(_fiscal!.regimenFiscal)).firstOrNull;
                  if (match != null) _regimenFiscal = match;
                }
              }
              
              if (_fiscal!.usoCfdi.isNotEmpty) {
                final exists = _usosCfdi.any((u) => u['value'] == _fiscal!.usoCfdi);
                if (exists) {
                  _usoCfdi = _fiscal!.usoCfdi;
                }
              }
            });
          }
        } catch (_) {}
      }
    } catch (_) {
      final user = await StorageService.getUser();
      if (user != null && mounted) {
        final parts = (user['nombre'] as String? ?? '').split(' ');
        final fechaRaw = user['fecha_nacimiento'] as String?;
        final fechaDisplay = (fechaRaw != null && fechaRaw.isNotEmpty)
            ? _isoADisplay(fechaRaw)
            : '';
        setState(() {
          _userData['nombre']       = parts.isNotEmpty ? parts.first : '';
          _userData['apellidos']    = parts.length > 1 ? parts.skip(1).join(' ') : '';
          _userData['fechaNac']     = fechaDisplay;
          _userData['claveElector'] = user['folio_ine'] as String? ?? '';
          _userData['telefono']     = user['telefono']  as String? ?? '';
          _userData['email']        = user['email']     as String? ?? '';
          _userData['cargo']        = user['rol'] ?? 'propietario';
          _loadingProfile = false;
        });
        _fechaNacCtrl.text     = fechaDisplay;
        _claveElectorCtrl.text = user['folio_ine'] as String? ?? '';
        _telefonoCtrl.text     = user['telefono']  as String? ?? '';
        _emailCtrl.text        = user['email']     as String? ?? '';
      } else if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _webImage = bytes;
        _imageFile = null;
        _imagenCambiada = true;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _imageFile = File(image.path);
        _webImage = null;
        _imagenCambiada = true;
      });
    }
  }

  String _isoADisplay(String iso) {
    final partes = iso.split('-');
    if (partes.length != 3) return iso;
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  String _displayAIso(String display) {
    final partes = display.split('/');
    if (partes.length != 3) return display;
    return '${partes[2]}-${partes[1]}-${partes[0]}';
  }

  void _initControllers() {
    _nombreCtrl       = TextEditingController(text: _userData['nombre']);
    _apellidosCtrl    = TextEditingController(text: _userData['apellidos']);
    _fechaNacCtrl     = TextEditingController(text: _userData['fechaNac']);
    _telefonoCtrl     = TextEditingController(text: _userData['telefono']);
    _emailCtrl        = TextEditingController(text: _userData['email']);
    _claveElectorCtrl = TextEditingController(text: _userData['claveElector']);
    _passwordCtrl     = TextEditingController();
    _razonSocialCtrl  = TextEditingController(text: '');
    _rfcCtrl          = TextEditingController(text: '');
    _cpCtrl           = TextEditingController(text: '');
    _correoFiscalCtrl = TextEditingController(text: '');
    _clabeCtrl        = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _fechaNacCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _claveElectorCtrl.dispose();
    _passwordCtrl.dispose();
    _razonSocialCtrl.dispose();
    _rfcCtrl.dispose();
    _cpCtrl.dispose();
    _correoFiscalCtrl.dispose();
    _clabeCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1695A3),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF225378),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _fechaNacCtrl.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  void _handleSave() async {
    try {
      final body = <String, dynamic>{
        'nombre':    _nombreCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'telefono':  _telefonoCtrl.text.trim(),
        'email':     _emailCtrl.text.trim(),
        'folio_ine': _claveElectorCtrl.text.trim(),
        'banco':     _banco,
        'clabe_interbancaria': _clabeCtrl.text.trim(),
        if (_fechaNacCtrl.text.isNotEmpty)
          'fecha_nacimiento': _displayAIso(_fechaNacCtrl.text),
      };
      // ignore: avoid_print
      print('[Profile] _handleSave body: $body');
      // ignore: avoid_print
      print('[Profile] _userId: $_userId');
      final profileRes = await ApiClient.patch('/auth/me/', body);

      if (_imagenCambiada && (_imageFile != null || _webImage != null)) {
        final fotoRes = await ApiClient.multipart(
          'PATCH',
          '/auth/me/',
          file: _imageFile,
          webFileBytes: _webImage,
          webFileName: 'perfil.jpg',
          fileField: 'foto',
        );
        final fotoData = fotoRes['usuario'] as Map<String, dynamic>? ?? fotoRes;
        final resolved = ApiClient.resolveMediaUrl(fotoData['foto'] as String?);
        if (resolved != null) {
          _fotoUrl = '$resolved?t=${DateTime.now().millisecondsSinceEpoch}';
        } else {
          _fotoUrl = null;
        }
      } else {
        final data = profileRes['usuario'] as Map<String, dynamic>? ?? profileRes;
        _fotoUrl = ApiClient.resolveMediaUrl(data['foto'] as String?);
      }

      // Guardar Datos Fiscales
      if (_userId != null) {
        final bodyFiscal = {
          'tipo_entidad': 'propietario',
          'entidad_id': _userId,
          'nombre_o_razon_social': _razonSocialCtrl.text.trim(),
          'rfc': _rfcCtrl.text.trim().toUpperCase(),
          'regimen_fiscal': _regimenFiscal,
          'uso_cfdi': _usoCfdi,
          'codigo_postal': _cpCtrl.text.trim(),
          'correo_facturacion': _correoFiscalCtrl.text.trim(),
        };

        if (_fiscal != null && _fiscal!.id != null) {
          await ApiClient.patch('/datos-fiscales/${_fiscal!.id}/', bodyFiscal);
        } else {
          final nf = await ApiClient.post('/datos-fiscales/', bodyFiscal);
          _fiscal = DatosFiscales(
            id: nf['id'],
            nombreORazonSocial: nf['nombre_o_razon_social'] ?? '',
            rfc: nf['rfc'] ?? '',
            regimenFiscal: nf['regimen_fiscal'] ?? '',
            usoCfdi: nf['uso_cfdi'] ?? '',
            codigoPostal: nf['codigo_postal'] ?? '',
            correoFacturacion: nf['correo_facturacion'] ?? '',
          );
        }
      }

      setState(() {
        final clabe = _clabeCtrl.text.trim();
        _bancario = clabe.isNotEmpty
            ? DatosBancarios(clabe: clabe, banco: _banco)
            : null;

        _userData = {
          'nombre':       _nombreCtrl.text,
          'apellidos':    _apellidosCtrl.text,
          'fechaNac':     _fechaNacCtrl.text,
          'telefono':     _telefonoCtrl.text,
          'email':        _emailCtrl.text,
          'claveElector': _claveElectorCtrl.text,
          'banco':        _banco,
          'clabe':        clabe,
          'cargo':        _userData['cargo']!,
        };
        _isEditing = false;
        _imagenCambiada = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado'), backgroundColor: Color(0xFF1695A3), behavior: SnackBarBehavior.floating),
        );
      }
    } on ApiException catch (e) {
      // ignore: avoid_print
      print('[Profile] ApiException ${e.statusCode}: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[Profile] catch generico: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _handleCancel() {
    setState(() {
      _nombreCtrl.text       = _userData['nombre']!;
      _apellidosCtrl.text    = _userData['apellidos']!;
      _fechaNacCtrl.text     = _userData['fechaNac']!;
      _telefonoCtrl.text     = _userData['telefono']!;
      _emailCtrl.text        = _userData['email']!;
      _claveElectorCtrl.text = _userData['claveElector']!;
      _passwordCtrl.clear();
      _razonSocialCtrl.text  = _fiscal?.nombreORazonSocial ?? '';
      _rfcCtrl.text          = _fiscal?.rfc ?? '';
      _cpCtrl.text           = _fiscal?.codigoPostal ?? '';
      _correoFiscalCtrl.text = _fiscal?.correoFacturacion ?? '';
      
      String rf = _fiscal?.regimenFiscal ?? '';
      if (rf.isNotEmpty && !_regimenesFiscales.contains(rf)) {
        rf = _regimenesFiscales.where((r) => r.startsWith(rf)).firstOrNull ?? '606 - Arrendamiento';
      } else if (rf.isEmpty) {
        rf = '606 - Arrendamiento';
      }
      _regimenFiscal = rf;

      String uc = _fiscal?.usoCfdi ?? '';
      if (uc.isNotEmpty && !_usosCfdi.any((u) => u['value'] == uc)) {
        uc = 'G03';
      } else if (uc.isEmpty) {
        uc = 'G03';
      }
      _usoCfdi = uc;
      
      _clabeCtrl.text        = _bancario?.clabe ?? '';
      _banco                 = _bancario?.banco ?? 'BBVA';
      _imageFile             = null;
      _webImage              = null;
      _imagenCambiada        = false;
      _isEditing = false;
    });
  }

  Future<void> _mostrarCambioPassword() async {
    final actualCtrl = TextEditingController();
    final nuevoCtrl  = TextEditingController();
    final confirCtrl = TextEditingController();
    bool obscureActual = true;
    bool obscureNuevo  = true;
    bool obscureConfir = true;
    bool enviando      = false;
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cambiar contraseña',
              style: TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                _pwField('Contraseña actual', actualCtrl, obscureActual,
                    () => setD(() => obscureActual = !obscureActual)),
                const SizedBox(height: 10),
                _pwField('Nueva contraseña (mín. 8)', nuevoCtrl, obscureNuevo,
                    () => setD(() => obscureNuevo = !obscureNuevo)),
                const SizedBox(height: 10),
                _pwField('Confirmar nueva contraseña', confirCtrl, obscureConfir,
                    () => setD(() => obscureConfir = !obscureConfir)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: enviando ? null : () async {
                final actual = actualCtrl.text.trim();
                final nuevo  = nuevoCtrl.text.trim();
                final confir = confirCtrl.text.trim();
                if (actual.isEmpty || nuevo.isEmpty || confir.isEmpty) {
                  setD(() => errorMsg = 'Completa todos los campos');
                  return;
                }
                if (nuevo.length < 8) {
                  setD(() => errorMsg = 'La nueva contraseña debe tener al menos 8 caracteres');
                  return;
                }
                if (nuevo != confir) {
                  setD(() => errorMsg = 'Las contraseñas no coinciden');
                  return;
                }
                setD(() { enviando = true; errorMsg = null; });
                try {
                  await ApiClient.post('/auth/cambio-password/', {
                    'password_actual': actual,
                    'password_nuevo':  nuevo,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Contraseña actualizada correctamente'),
                      backgroundColor: Color(0xFF1695A3),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                } on ApiException catch (e) {
                  setD(() { enviando = false; errorMsg = e.message; });
                } catch (_) {
                  setD(() { enviando = false; errorMsg = 'Error de conexión'; });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1695A3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: enviando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    actualCtrl.dispose();
    nuevoCtrl.dispose();
    confirCtrl.dispose();
  }

  static Widget _pwField(String label, TextEditingController ctrl, bool obscure, VoidCallback onToggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              size: 18, color: Colors.grey),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1695A3), width: 2)),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    // Capturamos el navigator y el provider ANTES de mostrar el diálogo,
    // porque después del pop el context del modal puede estar desmontado.
    final navigator = Navigator.of(context, rootNavigator: true);
    final authProvider = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            '¿Cerrar sesión?',
            style: TextStyle(
              color: Color(0xFF225378),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(fontSize: 15),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await authProvider.logout();
                } catch (_) {}
                navigator.pushNamedAndRemoveUntil('/', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB7F00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  String get _initials {
    final n = _userData['nombre'] ?? '';
    final a = _userData['apellidos'] ?? '';
    return '${n.isNotEmpty ? n[0] : '?'}${a.isNotEmpty ? a[0] : '?'}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
          color: Colors.white,
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: const Color(0xFF225378),
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
                child: Row(
                  children: [
                    const Text(
                      'Mi Perfil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Avatar ────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: const Color(0xFFF3FFE2),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1695A3),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFACF0F2), width: 3),
                          ),
                          child: ClipOval(
                            child: _webImage != null
                                ? Image.memory(_webImage!, fit: BoxFit.cover)
                                : _imageFile != null
                                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                                    : (_fotoUrl != null
                                        ? Image.network(
                                            _fotoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(
                                                _initials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              _initials,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEB7F00),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_userData['nombre']} ${_userData['apellidos']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF225378),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userData['cargo']!,
                      style: const TextStyle(
                          color: Color(0xFF1695A3), fontSize: 12),
                    ),
                  ],
                ),
              ),

              // ── Contenido scrollable ──────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child:
                      _isEditing ? _buildEditMode() : _buildViewMode(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODO VISTA
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildViewMode() {
    return Column(
      children: [
        _InfoRow(icon: Icons.person_outline,    label: 'Nombre',           value: _userData['nombre']!),
        _InfoRow(icon: Icons.people_outline,     label: 'Apellidos',        value: _userData['apellidos']!),
        _InfoRow(icon: Icons.calendar_today,     label: 'Fecha de Nac.',    value: _userData['fechaNac']!),
        _InfoRow(icon: Icons.phone_outlined,     label: 'Teléfono',         value: _userData['telefono']!),
        _InfoRow(icon: Icons.mail_outline,       label: 'Email',            value: _userData['email']!),
        _InfoRow(icon: Icons.badge_outlined,     label: 'Clave de Elector', value: _userData['claveElector']!),
        GestureDetector(
          onTap: _mostrarCambioPassword,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.grey, size: 17),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contraseña', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      SizedBox(height: 2),
                      Text('••••••••', style: TextStyle(color: Color(0xFF225378),
                          fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, color: Color(0xFF1695A3), size: 15),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Datos Bancarios (collapsible) ─────────────────────────────────
        _CollapsibleSection(
          icon: Icons.account_balance_outlined,
          label: 'Datos Bancarios',
          expanded: _showBancario,
          onToggle: () =>
              setState(() => _showBancario = !_showBancario),
        ),
        if (_showBancario) ...[
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.numbers_outlined,          label: 'CLABE Interbancaria', value: _bancario?.clabe ?? '—'),
          _InfoRow(icon: Icons.account_balance_outlined,  label: 'Banco',               value: _bancario?.banco ?? '—'),
        ],
        const SizedBox(height: 12),

        // ── Datos Fiscales (collapsible) ──────────────────────────────────
        _CollapsibleSection(
          icon: Icons.receipt_long_outlined,
          label: 'Datos Fiscales (SAT)',
          expanded: _showFiscal,
          onToggle: () =>
              setState(() => _showFiscal = !_showFiscal),
        ),
        if (_showFiscal) ...[
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.business_outlined,        label: 'Razón Social',       value: _fiscal?.nombreORazonSocial ?? '—'),
          _InfoRow(icon: Icons.fingerprint,               label: 'RFC',                value: _fiscal?.rfc ?? '—'),
          _InfoRow(icon: Icons.account_balance_outlined,  label: 'Régimen Fiscal',     value: _fiscal?.regimenFiscal ?? '—'),
          _InfoRow(icon: Icons.description_outlined,      label: 'Uso CFDI',           value: _fiscal?.usoCfdi ?? '—'),
          _InfoRow(icon: Icons.location_on_outlined,      label: 'Código Postal',      value: _fiscal?.codigoPostal ?? '—'),
          _InfoRow(icon: Icons.mail_outline,              label: 'Correo Facturación', value: _fiscal?.correoFacturacion ?? '—'),
        ],
        const SizedBox(height: 20),

        // ── Botón editar ──────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _isEditing = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF225378),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Editar Información',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Botón cerrar sesión ───────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text(
              'Cerrar Sesión',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEB7F00),
              side: const BorderSide(color: Color(0xFFEB7F00), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODO EDICIÓN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre
        _EditField(label: 'Nombre', controller: _nombreCtrl),
        const SizedBox(height: 12),

        // Apellidos
        _EditField(label: 'Apellidos', controller: _apellidosCtrl),
        const SizedBox(height: 12),

        // Fecha de Nacimiento
        _EditField(
          label: 'Fecha de Nacimiento',
          controller: _fechaNacCtrl,
          readOnly: true,
          onTap: _selectDate,
          suffixIcon: const Icon(Icons.calendar_today,
              color: Color(0xFF1695A3), size: 18),
        ),
        const SizedBox(height: 12),

        // Teléfono
        _EditField(
          label: 'Teléfono',
          controller: _telefonoCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        const SizedBox(height: 12),

        // Email
        _EditField(
          label: 'Email',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),

        // Clave de elector
        _EditField(
          label: 'Clave de Elector (INE)',
          controller: _claveElectorCtrl,
          inputFormatters: [
            LengthLimitingTextInputFormatter(18),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            UpperCaseTextFormatter(),
          ],
        ),
        const SizedBox(height: 20),

        // ── Sección Datos Bancarios ───────────────────────────────────────
        _SectionHeader(
          icon: Icons.account_balance_outlined,
          label: 'Datos Bancarios',
          color: const Color(0xFFEB7F00),
          bgColor: const Color(0xFFFFF7ED),
          borderColor: const Color(0xFFEB7F00),
        ),
        const SizedBox(height: 12),

        // CLABE
        _EditField(
          label: 'CLABE Interbancaria',
          controller: _clabeCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(18),
          ],
          helperText: '18 dígitos',
        ),
        const SizedBox(height: 12),

        // Banco dropdown
        _buildBancoDropdown(),
        const SizedBox(height: 20),

        // ── Sección Datos Fiscales ────────────────────────────────────────
        _SectionHeader(
          icon: Icons.receipt_long_outlined,
          label: 'Datos Fiscales (SAT)',
          color: const Color(0xFF1695A3),
          bgColor: const Color(0xFFF3FFE2),
          borderColor: const Color(0xFF1695A3),
        ),
        const SizedBox(height: 12),

        // Razón Social
        _EditField(
          label: 'Nombre o Razón Social',
          controller: _razonSocialCtrl,
        ),
        const SizedBox(height: 12),

        // RFC
        _EditField(
          label: 'RFC',
          controller: _rfcCtrl,
          inputFormatters: [
            LengthLimitingTextInputFormatter(13),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9&Ññ]')),
            UpperCaseTextFormatter(),
          ],
        ),
        const SizedBox(height: 12),

        // Régimen Fiscal
        _buildRegimenDropdown(),
        const SizedBox(height: 12),

        // Uso CFDI
        _buildUsoCfdiDropdown(),
        const SizedBox(height: 12),

        // CP + Correo en fila
        Row(
          children: [
            Expanded(
              child: _EditField(
                label: 'Código Postal',
                controller: _cpCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EditField(
                label: 'Correo Facturación',
                controller: _correoFiscalCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Botones ───────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleSave,
                icon: const Icon(Icons.save_outlined,
                    size: 18, color: Colors.white),
                label: const Text('Guardar',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1695A3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── BANCO DROPDOWN ────────────────────────────────────────────────────────
  Widget _buildBancoDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Banco',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _banco,
              isExpanded: true,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF225378)),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFFEB7F00)),
              onChanged: (v) => setState(() => _banco = v!),
              items: _bancos
                  .map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── RÉGIMEN FISCAL DROPDOWN ───────────────────────────────────────────────
  Widget _buildRegimenDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Régimen Fiscal',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _regimenFiscal,
              isExpanded: true,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF225378)),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF1695A3)),
              onChanged: (v) =>
                  setState(() => _regimenFiscal = v!),
              items: _regimenesFiscales
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── USO CFDI DROPDOWN ─────────────────────────────────────────────────────
  Widget _buildUsoCfdiDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Uso CFDI',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _usoCfdi,
              isExpanded: true,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF225378)),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF1695A3)),
              onChanged: (v) => setState(() => _usoCfdi = v!),
              items: _usosCfdi
                  .map((u) => DropdownMenuItem(
                        value: u['value'],
                        child: Text(u['label']!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── COLLAPSIBLE SECTION HEADER (modo vista) ──────────────────────────────────
class _CollapsibleSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool expanded;
  final VoidCallback onToggle;

  const _CollapsibleSection({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF3FFE2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF1695A3).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1695A3), size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF225378),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const Spacer(),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: const Color(0xFF1695A3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SECTION HEADER (modo edición) ───────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: const Color(0xFF225378),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── INFO ROW ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFACF0F2).withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1695A3), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF225378),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EDIT FIELD ───────────────────────────────────────────────────────────────
class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final String? helperText;

  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.inputFormatters,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            suffixIcon: suffixIcon,
            helperText: helperText,
            helperStyle: const TextStyle(
                color: Colors.grey, fontSize: 10),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF1695A3), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── PASSWORD FIELD ───────────────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nueva Contraseña',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
          decoration: InputDecoration(
            hintText: 'Dejar vacío para no cambiar',
            hintStyle:
                const TextStyle(color: Colors.grey, fontSize: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF1695A3),
                size: 18,
              ),
              onPressed: onToggle,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF1695A3), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}