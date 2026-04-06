import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/widgets/app_header.dart';
import '../../../core/utils/upper_case_formatter.dart';
import '../../../core/services/api_client.dart';
import '../../../data/services/arrendatarios_service.dart';
import '../../../data/services/propiedades_service.dart';

class EditarInquilinoScreen extends StatefulWidget {
  final int? arrendatarioId;
  const EditarInquilinoScreen({super.key, this.arrendatarioId});

  @override
  State<EditarInquilinoScreen> createState() => _EditarInquilinoScreenState();
}




class _EditarInquilinoScreenState extends State<EditarInquilinoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Foto
  File? _imageFile;
  Uint8List? _webImage;
  bool _imagenCambiada = false;
  ArrendatarioDetalle? _data;
  bool _isLoading = false;
  bool _cargando = true;
  String? _errorCarga;

  // ── Controladores — Modelo Arrendatario ───────────────────────────────────
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidosCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _folioIneCtrl;
  DateTime? _fechaNacimiento;

  // Booleans
  bool _mascotas = false;
  bool _hijos    = false;

  // Estado
  String _estado = 'activo';

  // ── Controladores — Modelo Contrato ───────────────────────────────────────
  int?   _contratoId;          // ID del contrato activo (para PATCH vs POST)
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  late TextEditingController _rentaCtrl;
  late TextEditingController _depositoCtrl;
  late TextEditingController _diaPagoCtrl;
  late TextEditingController _incrementoAnualCtrl;
  late TextEditingController _penalizacionCtrl;
  late TextEditingController _observacionesCtrl;
  String _periodoPago        = 'mensual';
  String _estadoContrato     = 'activo';
  int?   _propiedadId;

  // ── Controladores — DatosFiscales Arrendatario ────────────────────────────
  int? _fiscalId;
  late TextEditingController _fiscalRazonSocialCtrl;
  late TextEditingController _fiscalRfcCtrl;
  late TextEditingController _fiscalCpCtrl;
  late TextEditingController _fiscalCorreoCtrl;
  String _fiscalRegimen  = '606 - Arrendamiento';
  String _fiscalUsoCfdi  = 'G03';

  // TODO: cargar desde → GET /api/propiedades/?estado=disponible
  List<Map<String, dynamic>> _propiedades = [];

  static const List<Map<String, String>> _periodosPago = [
    {'value': 'diario',  'label': 'Diario'},
    {'value': 'mensual', 'label': 'Mensual'},
    {'value': 'anual',   'label': 'Anual'},
  ];

  String _mensajeErrorContrato(String raw) {
    final m = raw.toLowerCase();
    if (m.contains('propiedad no está disponible') || m.contains('propiedad no esta disponible')) {
      return 'La propiedad seleccionada ya no esta disponible.';
    }
    if (m.contains('ya tiene un contrato activo')) {
      return 'La propiedad ya tiene un contrato activo.';
    }
    if (m.contains('fecha de fin debe ser posterior')) {
      return 'Revisa las fechas del contrato: la fecha fin debe ser posterior al inicio.';
    }
    return raw;
  }

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con strings vacíos hasta que cargue
    _nombreCtrl          = TextEditingController();
    _apellidosCtrl       = TextEditingController();
    _telefonoCtrl        = TextEditingController();
    _emailCtrl           = TextEditingController();
    _folioIneCtrl        = TextEditingController();
    _rentaCtrl           = TextEditingController();
    _depositoCtrl        = TextEditingController();
    _diaPagoCtrl         = TextEditingController(text: '1');
    _incrementoAnualCtrl = TextEditingController(text: '0.00');
    _penalizacionCtrl    = TextEditingController();
    _observacionesCtrl   = TextEditingController();
    _fiscalRazonSocialCtrl = TextEditingController();
    _fiscalRfcCtrl         = TextEditingController();
    _fiscalCpCtrl          = TextEditingController();
    _fiscalCorreoCtrl      = TextEditingController();
    _cargarDatos();
    _cargarPropiedades();
  }

  Future<void> _cargarDatos() async {
    if (widget.arrendatarioId == null) {
      setState(() { _cargando = false; _errorCarga = 'ID no válido'; });
      return;
    }
    try {
      final d = await ArrendatariosService.detalle(widget.arrendatarioId!);
      if (!mounted) return;
      setState(() {
        _data = d;
        _nombreCtrl.text         = d.nombre;
        _apellidosCtrl.text      = d.apellidos;
        _telefonoCtrl.text       = d.telefono;
        _emailCtrl.text          = d.email;
        _folioIneCtrl.text       = d.folioIne;
        _fechaNacimiento         = d.fechaNacimiento != null
            ? DateTime.tryParse(d.fechaNacimiento!)
            : null;
        _mascotas   = d.mascotas;
        _hijos      = d.hijos;
        _estado     = d.estado;
        _cargando   = false;
      });

      // Cargar contrato activo del inquilino para pre-poblar la sección Contrato
      try {
        final contratosData = await ApiClient.get(
          '/contratos/?arrendatario=${widget.arrendatarioId}&estado=activo',
        );
        final lista = contratosData is List
            ? contratosData
            : (contratosData['results'] ?? []) as List;
        if (lista.isNotEmpty) {
          final c = lista.first as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _contratoId    = c['id'] as int?;
              _propiedadId   = c['propiedad'] as int?;
              _estadoContrato = c['estado'] ?? 'activo';
              _periodoPago   = c['periodo_pago'] ?? 'mensual';
              _fechaInicio   = c['fecha_inicio'] != null
                  ? DateTime.tryParse(c['fecha_inicio'])
                  : null;
              _fechaFin      = c['fecha_fin'] != null
                  ? DateTime.tryParse(c['fecha_fin'])
                  : null;
              _rentaCtrl.text          = c['renta_acordada']?.toString() ?? '';
              _depositoCtrl.text       = c['deposito']?.toString() ?? '';
              _diaPagoCtrl.text        = c['dia_pago']?.toString() ?? '1';
              _incrementoAnualCtrl.text = c['incremento_anual']?.toString() ?? '0.00';
              _penalizacionCtrl.text   = c['penalizacion_anticipada']?.toString() ?? '';
              _observacionesCtrl.text  = c['observaciones'] ?? '';
            });
            // Recalcular catálogo de propiedades tras conocer la propiedad actual.
            await _cargarPropiedades();
          }
        }
      } catch (_) {
        // No hay contrato activo — los campos quedan vacíos, el usuario puede crear uno nuevo
      }

      // Cargar datos fiscales
      try {
        final fRes = await ApiClient.get('/datos-fiscales/?tipo_entidad=arrendatario&entidad_id=${widget.arrendatarioId}');
        if (fRes['results'] != null && fRes['results'].isNotEmpty) {
          final f = fRes['results'][0];
          if (mounted) {
            setState(() {
              _fiscalId = f['id'];
              _fiscalRazonSocialCtrl.text = f['nombre_o_razon_social'] ?? '';
              _fiscalRfcCtrl.text = f['rfc'] ?? '';
              _fiscalCpCtrl.text = f['codigo_postal'] ?? '';
              _fiscalCorreoCtrl.text = f['correo_facturacion'] ?? '';
              if (f['regimen_fiscal'] != null && f['regimen_fiscal'].toString().isNotEmpty) {
                // matching logic since backend might save full text
                final rfStr = f['regimen_fiscal'].toString();
                final regimenes = [
                  '601 - General de Ley Personas Morales',
                  '603 - Personas Morales con Fines No Lucrativos',
                  '605 - Sueldos y Salarios',
                  '606 - Arrendamiento',
                  '607 - Enajenación o Adquisición de Bienes',
                  '608 - Demás ingresos',
                  '612 - Personas Físicas con Actividades Empresariales',
                  '616 - Sin obligaciones fiscales',
                  '621 - Incorporación Fiscal',
                  '626 - Régimen Simplificado de Confianza',
                ];
                if (regimenes.contains(rfStr)) {
                  _fiscalRegimen = rfStr;
                } else {
                  final match = regimenes.where((r) => r.startsWith(rfStr)).firstOrNull;
                  if (match != null) _fiscalRegimen = match;
                }
              }
              if (f['uso_cfdi'] != null && f['uso_cfdi'].toString().isNotEmpty) {
                final ucStr = f['uso_cfdi'].toString();
                final usos = ['G01','G02','G03','I01','I03','D01','D10','P01','S01'];
                if (usos.contains(ucStr)) _fiscalUsoCfdi = ucStr;
              }
            });
          }
        }
      } catch (_) {}

    } on ApiException catch (e) {
      if (mounted) setState(() { _cargando = false; _errorCarga = e.message; });
    } catch (_) {
      if (mounted) setState(() { _cargando = false; _errorCarga = 'Sin conexión'; });
    }
  }

  Future<void> _cargarPropiedades() async {
    try {
      // Trae disponibles + la que ya tiene este inquilino (si aplica).
      final lista = await PropiedadesService.listar(estado: 'disponible');
      final opciones = <int, Map<String, dynamic>>{};
      for (final p in lista) {
        opciones[p.id] = {'id': p.id, 'nombre': p.nombre};
      }

      if (_propiedadId != null && !opciones.containsKey(_propiedadId)) {
        try {
          final actual = await PropiedadesService.detalle(_propiedadId!);
          opciones[_propiedadId!] = {
            'id': _propiedadId,
            'nombre': (actual['nombre'] ?? 'Propiedad #$_propiedadId').toString(),
          };
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _propiedades = opciones.values.toList();
          if (_propiedadId != null && !_propiedades.any((p) => p['id'] == _propiedadId)) {
            _propiedadId = null;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _folioIneCtrl.dispose();
    _rentaCtrl.dispose();
    _depositoCtrl.dispose();
    _diaPagoCtrl.dispose();
    _incrementoAnualCtrl.dispose();
    _penalizacionCtrl.dispose();
    _observacionesCtrl.dispose();
    _fiscalRazonSocialCtrl.dispose();
    _fiscalRfcCtrl.dispose();
    _fiscalCpCtrl.dispose();
    _fiscalCorreoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() { _webImage = bytes; _imagenCambiada = true; });
    } else {
      setState(() { _imageFile = File(image.path); _imagenCambiada = true; });
    }
  }

  Future<void> _pickFechaContrato(bool isInicio) async {
    final now = DateTime.now();
    // La fecha de fin no puede ser anterior ni igual a la de inicio
    final firstDate = isInicio
        ? DateTime(2020)
        : (_fechaInicio != null
            ? _fechaInicio!.add(const Duration(days: 1))
            : DateTime(2020));
    final initial = isInicio
        ? (_fechaInicio ?? now)
        : (_fechaFin ?? (firstDate.isAfter(now) ? firstDate : now.add(const Duration(days: 365))));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF225378),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF225378),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = picked;
          // Si el fin ya estaba puesto y ahora es igual o anterior al nuevo inicio, se limpia
          if (_fechaFin != null && !_fechaFin!.isAfter(picked)) {
            _fechaFin = null;
          }
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18), // mínimo 18 años
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF225378),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF225378),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading || widget.arrendatarioId == null) return;

    setState(() => _isLoading = true);
    try {
      // 1. Actualizar datos del arrendatario
      await ArrendatariosService.actualizar(widget.arrendatarioId!, {
        'nombre':           _nombreCtrl.text.trim(),
        'apellidos':        _apellidosCtrl.text.trim(),
        'telefono':         _telefonoCtrl.text.trim(),
        'email':            _emailCtrl.text.trim(),
        'fecha_nacimiento': _fechaNacimiento?.toIso8601String().split('T')[0],
        'folio_ine':        _folioIneCtrl.text.toUpperCase(),
        'mascotas':         _mascotas,
        'hijos':            _hijos,
        'estado':           _estado,
      });

      // 1.1. Subir foto si el usuario la cambió
      if (_imagenCambiada && (_imageFile != null || _webImage != null)) {
        await ApiClient.multipart(
          'PATCH',
          '/arrendatarios/${widget.arrendatarioId}/',
          file: _imageFile,
          webFileBytes: _webImage,
          webFileName: 'inquilino.jpg',
          fileField: 'foto',
        );
      }

      // 1.5. Guardar datos fiscales
      final fiscalBody = {
        'tipo_entidad': 'arrendatario',
        'entidad_id': widget.arrendatarioId,
        'rfc': _fiscalRfcCtrl.text.toUpperCase(),
        'nombre_o_razon_social': _fiscalRazonSocialCtrl.text,
        'regimen_fiscal': _fiscalRegimen,
        'codigo_postal': _fiscalCpCtrl.text,
        'uso_cfdi': _fiscalUsoCfdi,
        'correo_facturacion': _fiscalCorreoCtrl.text.trim(),
      };

      if (_fiscalId != null) {
        await ApiClient.patch('/datos-fiscales/$_fiscalId/', fiscalBody);
      } else {
        await ApiClient.post('/datos-fiscales/', fiscalBody);
      }

      // 2. Guardar contrato si se llenaron los campos mínimos
      if (_propiedadId != null && _fechaInicio != null && _fechaFin != null && _rentaCtrl.text.isNotEmpty) {
        final contratoBody = {
          'arrendatario':            widget.arrendatarioId,
          'propiedad':               _propiedadId,
          'fecha_inicio':            _fechaInicio!.toIso8601String().split('T')[0],
          'fecha_fin':               _fechaFin!.toIso8601String().split('T')[0],
          'renta_acordada':          _rentaCtrl.text,
          'deposito':                _depositoCtrl.text.isNotEmpty ? _depositoCtrl.text : '0',
          'dia_pago':                int.tryParse(_diaPagoCtrl.text) ?? 1,
          'periodo_pago':            _periodoPago,
          'incremento_anual':        _incrementoAnualCtrl.text.isNotEmpty ? _incrementoAnualCtrl.text : '0.00',
          'penalizacion_anticipada': _penalizacionCtrl.text.isNotEmpty ? _penalizacionCtrl.text : '0.00',
          'observaciones':           _observacionesCtrl.text,
          'estado':                  _estadoContrato,
        };

        if (_contratoId != null) {
          // Ya existe contrato activo → actualizar
          await ApiClient.patch('/contratos/$_contratoId/', contratoBody);
        } else {
          // No hay contrato → crear uno nuevo
          await ApiClient.post('/contratos/', contratoBody);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inquilino actualizado correctamente'),
          backgroundColor: Color(0xFF1695A3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      final detalle = _mensajeErrorContrato(e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detalle), backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Sin conexión con el servidor'),
            backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Inquilino',
            style: TextStyle(color: Color(0xFF225378), fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de eliminar a "${_data?.nombreCompleto}"?\nEsta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (widget.arrendatarioId == null) return;
              try {
                await ArrendatariosService.eliminar(widget.arrendatarioId!);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inquilino eliminado'),
                      backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                );
                Navigator.pushNamedAndRemoveUntil(context, '/inquilinos', (r) => false);
              } on ApiException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message), backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF1695A3))),
      );
    }
    if (_errorCarga != null) {
      return Scaffold(
        appBar: const AppHeader(title: 'Editar Inquilino', showBack: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.grey, size: 48),
              const SizedBox(height: 12),
              Text(_errorCarga!, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Editar Inquilino', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // ── Botón eliminar ───────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline,
                            color: Colors.red.shade400, size: 16),
                        const SizedBox(width: 6),
                        Text('Eliminar Inquilino',
                            style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Avatar / Foto ─────────────────────────────────────────────
              _buildAvatarPicker(),
              const SizedBox(height: 28),

              // ── Sección: Datos Personales ─────────────────────────────────
              _sectionTitle(Icons.person_outline, 'Datos Personales'),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Nombre',
                      controller: _nombreCtrl,
                      hint: 'Juan',
                      icon: Icons.badge_outlined,
                      maxLength: 120,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      label: 'Apellidos',
                      controller: _apellidosCtrl,
                      hint: 'Pérez López',
                      icon: Icons.badge_outlined,
                      maxLength: 120,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildField(
                label: 'Teléfono',
                controller: _telefonoCtrl,
                hint: '55 1234 5678',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 20,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              _buildField(
                label: 'Correo Electrónico (opcional)',
                controller: _emailCtrl,
                hint: 'juan@email.com',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v != null && v.isNotEmpty && !v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Fecha de nacimiento
              _buildDateField(),
              const SizedBox(height: 12),

              // Folio INE (opcional)
              _buildField(
                label: 'Folio INE / Clave Electoral (opcional)',
                controller: _folioIneCtrl,
                hint: 'PELJ901012HDFRZN01',
                icon: Icons.credit_card_outlined,
                maxLength: 20,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(20),
                ],
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 18) return 'Mínimo 18 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ── Sección: Características ──────────────────────────────────
              _sectionTitle(Icons.info_outline, 'Características'),
              const SizedBox(height: 14),

              Container(
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
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: '🐾',
                      label: 'Tiene mascotas',
                      sublabel: 'El inquilino tiene animales de compañía',
                      value: _mascotas,
                      onChanged: (v) => setState(() => _mascotas = v),
                    ),
                    Divider(height: 1, color: Colors.grey.shade100),
                    _buildSwitchTile(
                      icon: '👶',
                      label: 'Tiene hijos',
                      sublabel: 'El inquilino tiene menores de edad',
                      value: _hijos,
                      onChanged: (v) => setState(() => _hijos = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Sección: Estado ───────────────────────────────────────────
              _sectionTitle(Icons.toggle_on_outlined, 'Estado'),
              const SizedBox(height: 14),

              Row(
                children: [
                  _buildEstadoBtn(
                    value: 'activo',
                    label: 'Activo',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF1695A3),
                  ),
                  const SizedBox(width: 12),
                  _buildEstadoBtn(
                    value: 'inactivo',
                    label: 'Inactivo',
                    icon: Icons.cancel_outlined,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Sección: Contrato ──────────────────────────────────────────
              _sectionTitle(Icons.description_outlined, 'Contrato'),
              const SizedBox(height: 14),

              // Propiedad
              _buildContratoDropdown(),
              const SizedBox(height: 12),

              // Fechas inicio / fin
              Row(
                children: [
                  Expanded(
                    child: _buildDateContrato(
                      label: 'Inicio',
                      fecha: _fechaInicio,
                      onTap: () => _pickFechaContrato(true),
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateContrato(
                      label: 'Fin',
                      fecha: _fechaFin,
                      onTap: () => _pickFechaContrato(false),
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Periodo de pago
              _buildPeriodoSelector(),
              const SizedBox(height: 12),

              // Renta + Día de pago
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Renta acordada',
                      controller: _rentaCtrl,
                      hint: '12500.00',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d{0,2}'))],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      label: 'Día de pago',
                      controller: _diaPagoCtrl,
                      hint: '1',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null || n < 1 || n > 31) return 'Entre 1 y 31';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Depósito + Penalización
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Depósito en garantía',
                      controller: _depositoCtrl,
                      hint: '12500.00',
                      icon: Icons.credit_card_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d{0,2}'))],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      label: 'Penalización anticipada',
                      controller: _penalizacionCtrl,
                      hint: '0.00 (opcional)',
                      icon: Icons.gavel_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d{0,2}'))],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Incremento anual
              _buildField(
                label: 'Incremento anual (%)',
                controller: _incrementoAnualCtrl,
                hint: '0.00',
                icon: Icons.trending_up_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 12),

              // Observaciones
              _buildField(
                label: 'Observaciones (opcional)',
                controller: _observacionesCtrl,
                hint: 'Condiciones especiales, acuerdos adicionales...',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ── Sección: Datos Fiscales (SAT) ─────────────────────────────
              _sectionTitle(Icons.receipt_long_outlined, 'Datos Fiscales (SAT)'),
              const SizedBox(height: 6),
              _buildFiscalHint(),
              const SizedBox(height: 14),
              _buildField(
                label: 'Nombre o Razón Social',
                controller: _fiscalRazonSocialCtrl,
                hint: 'Juan Pérez López',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 12),
              _buildField(
                label: 'RFC',
                controller: _fiscalRfcCtrl,
                hint: 'PELJ900101ABC',
                icon: Icons.fingerprint,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9&Ññ]')),
                  LengthLimitingTextInputFormatter(13),
                  UpperCaseTextFormatter(),
                ],
              ),
              const SizedBox(height: 12),
              _buildRegimenDropdown(),
              const SizedBox(height: 12),
              _buildUsoCfdiDropdown(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Código Postal',
                      controller: _fiscalCpCtrl,
                      hint: '06600',
                      icon: Icons.location_on_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      label: 'Correo Facturación',
                      controller: _fiscalCorreoCtrl,
                      hint: 'factura@mail.mx',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Botón registrar ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _onSubmit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined, size: 20),
                  label: const Text(
                    'Guardar Cambios',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF225378),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FISCAL HINT ──────────────────────────────────────────────────────────
  Widget _buildFiscalHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FFE2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF1695A3).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFF1695A3), size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Necesario para emitir facturas CFDI al inquilino.',
              style: TextStyle(
                  color: Color(0xFF225378),
                  fontSize: 11,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── RÉGIMEN FISCAL DROPDOWN ───────────────────────────────────────────────
  Widget _buildRegimenDropdown() {
    const regimenes = [
      '601 - General de Ley Personas Morales',
      '603 - Personas Morales con Fines No Lucrativos',
      '605 - Sueldos y Salarios',
      '606 - Arrendamiento',
      '607 - Enajenación o Adquisición de Bienes',
      '608 - Demás ingresos',
      '612 - Personas Físicas con Actividades Empresariales',
      '616 - Sin obligaciones fiscales',
      '621 - Incorporación Fiscal',
      '626 - Régimen Simplificado de Confianza',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Régimen Fiscal',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _fiscalRegimen,
              isExpanded: true,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF225378)),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF1695A3)),
              onChanged: (v) => setState(() => _fiscalRegimen = v!),
              items: regimenes
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
    const usos = [
      {'value': 'G01', 'label': 'G01 - Adquisición de mercancias'},
      {'value': 'G02', 'label': 'G02 - Devoluciones o descuentos'},
      {'value': 'G03', 'label': 'G03 - Gastos en general'},
      {'value': 'I01', 'label': 'I01 - Construcciones'},
      {'value': 'D01', 'label': 'D01 - Honorarios médicos'},
      {'value': 'P01', 'label': 'P01 - Por definir'},
      {'value': 'S01', 'label': 'S01 - Sin efectos fiscales'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Uso CFDI',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _fiscalUsoCfdi,
              isExpanded: true,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF225378)),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF1695A3)),
              onChanged: (v) => setState(() => _fiscalUsoCfdi = v!),
              items: usos
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

  // ── AVATAR PICKER ─────────────────────────────────────────────────────────
  Widget _buildAvatarPicker() {
    final hasNewImage = _webImage != null || _imageFile != null;
    final hasExistingPhoto = !_imagenCambiada && _data?.fotoUrl != null;
    final inicial = _nombreCtrl.text.isNotEmpty
        ? _nombreCtrl.text[0].toUpperCase()
        : '?';

    Widget avatarContent;
    if (hasNewImage) {
      avatarContent = ClipOval(
        child: kIsWeb
            ? Image.memory(_webImage!, fit: BoxFit.cover)
            : Image.file(_imageFile!, fit: BoxFit.cover),
      );
    } else if (hasExistingPhoto) {
      avatarContent = ClipOval(
        child: Image.network(
          _data!.fotoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(inicial,
                style: const TextStyle(
                    color: Color(0xFF1695A3),
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else {
      avatarContent = Center(
        child: Text(inicial,
            style: const TextStyle(
                color: Color(0xFF1695A3),
                fontSize: 32,
                fontWeight: FontWeight.bold)),
      );
    }

    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFACF0F2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10),
                ],
              ),
              child: avatarContent,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFEB7F00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DATE FIELD ────────────────────────────────────────────────────────────
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fecha de Nacimiento',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickFecha,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: Color(0xFF1695A3), size: 18),
                const SizedBox(width: 12),
                Text(
                  _fechaNacimiento != null
                      ? '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/'
                        '${_fechaNacimiento!.month.toString().padLeft(2, '0')}/'
                        '${_fechaNacimiento!.year}'
                      : 'Seleccionar fecha (opcional)',
                  style: TextStyle(
                    color: _fechaNacimiento != null
                        ? const Color(0xFF225378)
                        : Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── SWITCH TILE ───────────────────────────────────────────────────────────
  Widget _buildSwitchTile({
    required String icon,
    required String label,
    required String sublabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF225378),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(sublabel,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF1695A3),
          ),
        ],
      ),
    );
  }

  // ── ESTADO BUTTON ─────────────────────────────────────────────────────────
  Widget _buildEstadoBtn({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _estado == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _estado = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? color : Colors.grey, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? color : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ── SECTION TITLE ─────────────────────────────────────────────────────────
  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF1695A3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: const Color(0xFF1695A3), size: 16),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378),
                letterSpacing: 0.3)),
      ],
    );
  }

  // ── TEXT FIELD ────────────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          onChanged: (_) => setState(() {}), // refresca inicial del avatar
          style: const TextStyle(fontSize: 13, color: Color(0xFF225378)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon:
                Icon(icon, color: const Color(0xFF1695A3), size: 18),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1695A3), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ── PROPIEDAD DROPDOWN ───────────────────────────────────────────────────
  Widget _buildContratoDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Propiedad a rentar',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _propiedadId,
              isExpanded: true,
              hint: Row(
                children: [
                  const Icon(Icons.home_outlined,
                      color: Color(0xFF1695A3), size: 18),
                  const SizedBox(width: 8),
                  Text('Seleccionar propiedad',
                      style: TextStyle(color: Colors.grey.shade500,
                          fontSize: 13)),
                ],
              ),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF1695A3), size: 20),
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF225378)),
              onChanged: (v) => setState(() => _propiedadId = v),
              items: _propiedades.map((p) => DropdownMenuItem<int>(
                    value: p['id'] as int,
                    child: Row(
                      children: [
                        const Icon(Icons.home_outlined,
                            color: Color(0xFF1695A3), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p['nombre'] as String,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── DATE FIELD CONTRATO ───────────────────────────────────────────────────
  Widget _buildDateContrato({
    required String label,
    required DateTime? fecha,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: Color(0xFF225378))),
            if (required)
              const Text(' *',
                  style: TextStyle(color: Colors.red, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: fecha == null && required
                    ? Colors.grey.shade200
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    color: fecha != null
                        ? const Color(0xFF1695A3)
                        : Colors.grey,
                    size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fecha != null
                        ? '${fecha.day.toString().padLeft(2, '0')}/'
                          '${fecha.month.toString().padLeft(2, '0')}/'
                          '${fecha.year}'
                        : 'DD/MM/AAAA',
                    style: TextStyle(
                      color: fecha != null
                          ? const Color(0xFF225378)
                          : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── PERIODO DE PAGO ───────────────────────────────────────────────────────
  Widget _buildPeriodoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Periodo de pago',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold,
                color: Color(0xFF225378))),
        const SizedBox(height: 8),
        Row(
          children: _periodosPago.map((p) {
            final isSelected = _periodoPago == p['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _periodoPago = p['value']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF225378).withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF225378)
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    p['label']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF225378)
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

}

// ─── FORMATTER INE MAYÚSCULAS ─────────────────────────────────────────────────
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}