import 'package:flutter/material.dart';
import '../../../core/widgets/app_header.dart';
import '../../../data/services/fiscal_service.dart';

class NuevoFiscalScreen extends StatefulWidget {
  const NuevoFiscalScreen({super.key});

  @override
  State<NuevoFiscalScreen> createState() => _NuevoFiscalScreenState();
}

class _NuevoFiscalScreenState extends State<NuevoFiscalScreen> {
  final _formKey = GlobalKey<FormState>();

  String _tipoEntidad = 'propietario';
  final _entidadIdCtrl    = TextEditingController();
  final _rfcCtrl           = TextEditingController();
  final _razonSocialCtrl   = TextEditingController();
  final _regimenCtrl       = TextEditingController();
  final _usoCfdiCtrl       = TextEditingController();
  final _cpCtrl            = TextEditingController();
  final _correoCtrl        = TextEditingController();

  @override
  void dispose() {
    _entidadIdCtrl.dispose();
    _rfcCtrl.dispose();
    _razonSocialCtrl.dispose();
    _regimenCtrl.dispose();
    _usoCfdiCtrl.dispose();
    _cpCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await DatosFiscalesService.crear({
        'tipo_entidad':          _tipoEntidad,
        'entidad_id':            int.parse(_entidadIdCtrl.text),
        'rfc':                   _rfcCtrl.text.toUpperCase(),
        'nombre_o_razon_social': _razonSocialCtrl.text,
        'regimen_fiscal':        _regimenCtrl.text,
        'uso_cfdi':              _usoCfdiCtrl.text.toUpperCase(),
        'codigo_postal':         _cpCtrl.text,
        if (_correoCtrl.text.isNotEmpty)
          'correo_facturacion': _correoCtrl.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos fiscales guardados'),
          backgroundColor: Color(0xFF1695A3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(
          title: 'Nuevo Dato Fiscal', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Entidad'),
              const SizedBox(height: 12),

              // Tipo entidad
              DropdownButtonFormField<String>(
                initialValue: _tipoEntidad,
                decoration: _deco('Tipo de entidad',
                    Icons.business_outlined),
                items: const [
                  DropdownMenuItem(value: 'propietario',
                      child: Text('Propietario',
                          style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'arrendatario',
                      child: Text('Arrendatario',
                          style: TextStyle(fontSize: 13))),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _tipoEntidad = v);
                },
              ),
              const SizedBox(height: 12),

              // ID entidad
              TextFormField(
                controller: _entidadIdCtrl,
                keyboardType: TextInputType.number,
                decoration: _deco('ID de la entidad',
                    Icons.tag),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),

              _sectionTitle('Datos del SAT'),
              const SizedBox(height: 12),

              // RFC
              TextFormField(
                controller: _rfcCtrl,
                decoration: _deco('RFC', Icons.badge_outlined),
                maxLength: 13,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // Razon social
              TextFormField(
                controller: _razonSocialCtrl,
                decoration: _deco('Nombre o Razón Social',
                    Icons.business_outlined),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // Regimen fiscal
              TextFormField(
                controller: _regimenCtrl,
                decoration: _deco('Régimen Fiscal',
                    Icons.account_balance_outlined),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // Uso CFDI
              TextFormField(
                controller: _usoCfdiCtrl,
                decoration: _deco('Uso CFDI', Icons.receipt_outlined),
                maxLength: 10,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // Codigo postal
              TextFormField(
                controller: _cpCtrl,
                keyboardType: TextInputType.number,
                decoration: _deco('Código Postal',
                    Icons.location_on_outlined),
                maxLength: 5,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // Correo facturación (opcional)
              TextFormField(
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _deco('Correo facturación (opcional)',
                    Icons.email_outlined),
              ),
              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save_outlined, size: 20),
                  label: const Text('Guardar Datos Fiscales',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
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

  // ── Helpers ─────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF1695A3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF225378),
                letterSpacing: 0.3)),
      ],
    );
  }

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF1695A3), size: 18),
      counterText: '',
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
    );
  }
}
