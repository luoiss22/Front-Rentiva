import 'package:flutter/material.dart';
import '../../../core/widgets/app_header.dart';
import '../../../data/services/fiscal_service.dart';

class DetalleFiscalScreen extends StatefulWidget {
  final int? fiscalId;
  const DetalleFiscalScreen({super.key, this.fiscalId});

  @override
  State<DetalleFiscalScreen> createState() => _DetalleFiscalScreenState();
}

class _DetalleFiscalScreenState extends State<DetalleFiscalScreen> {
  bool _cargando = true;
  DatosFiscalesDetalle? _datos;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await DatosFiscalesService.detalle(
          widget.fiscalId!);
      if (!mounted) return;
      setState(() { _datos = data; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(
          title: 'Detalle Fiscal', showBack: true),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF1695A3)))
          : _error.isNotEmpty
              ? Center(child: Text(_error,
                  style: const TextStyle(color: Colors.red)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _datos!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            _row(Icons.badge_outlined, 'RFC', d.rfc),
            _row(Icons.business_outlined, 'Razón Social',
                d.nombreORazonSocial),
            _row(Icons.account_balance_outlined, 'Régimen',
                d.regimenFiscal),
            _row(Icons.receipt_outlined, 'Uso CFDI',
                d.usoCfdi),
            _row(Icons.location_on_outlined, 'C.P.',
                d.codigoPostal),
            _row(Icons.email_outlined, 'Correo',
                d.correoFacturacion.isEmpty
                    ? 'No registrado'
                    : d.correoFacturacion),
            _row(Icons.category_outlined, 'Tipo entidad',
                d.tipoEntidad),
            _row(Icons.tag, 'ID entidad',
                d.entidadId.toString()),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1695A3)),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF225378),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
