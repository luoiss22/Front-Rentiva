import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Widgets reutilizables desde core/
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_password_field.dart';
import '../../../core/widgets/app_image_picker.dart';
import '../../../core/utils/upper_case_formatter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _INEController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _INEController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1695A3),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF225378),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  bool _isLoading = false;

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? fechaBackend;
      final fechaTexto = _birthDateController.text.trim();
      if (fechaTexto.isNotEmpty) {
        final partes = fechaTexto.split('/');
        fechaBackend = '${partes[2]}-${partes[1]}-${partes[0]}';
      }

      final body = {
        'nombre': _nameController.text.trim(),
        'apellidos': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'password': _passwordController.text,
        if (fechaBackend != null) 'fecha_nacimiento': fechaBackend,
        if (_INEController.text.isNotEmpty)
          'folio_ine': _INEController.text.trim(),
      };

      await ApiClient.post('/auth/registro/', body, auth: false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada exitosamente!'),
          backgroundColor: Color(0xFF1695A3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamed(context, '/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo conectar al servidor'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Círculo decorativo superior izquierdo
          Positioned(
            top: -200,
            left: -200,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFACF0F2).withOpacity(0.3),
              ),
            ),
          ),
          // Círculo decorativo inferior derecho
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEB7F00).withOpacity(0.1),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFACF0F2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header ───────────────────────────────────
                            Center(
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Crear Cuenta',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF225378),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Gestiona tus propiedades de forma profesional',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Nombre y Apellidos ────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Nombre',
                                    controller: _nameController,
                                    hint: 'Juan',
                                    icon: Icons.person_outline,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Apellidos',
                                    controller: _lastNameController,
                                    hint: 'Pérez',
                                    icon: Icons.person_outline,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Fecha de Nacimiento ───────────────────────
                            AppTextField(
                              label: 'Fecha de Nacimiento',
                              controller: _birthDateController,
                              hint: 'DD/MM/AAAA',
                              icon: Icons.calendar_today,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              validator: (v) =>
                                  v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),

                            // ── Teléfono ──────────────────────────────────
                            AppTextField(
                              label: 'Teléfono',
                              controller: _phoneController,
                              hint: '5512345678',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (v.length != 10) return 'Debe tener 10 dígitos';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // ── Clave de elector (INE) ────────────────────
                            AppTextField(
                              label: 'Clave de elector (INE)',
                              controller: _INEController,
                              hint: 'ABCDE123456XYZ',
                              icon: Icons.badge_outlined,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(18),
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]')),
                                UpperCaseTextFormatter(),
                              ],
                              validator: (v) {
                                if (v != null && v.isNotEmpty && v.length != 18) {
                                  return 'Debe tener 18 caracteres';
                                }
                                if (v != null && v.isNotEmpty &&
                                    !RegExp(r'^[A-Z]{5}\d{6}[A-Z0-9]{7}$').hasMatch(v)) {
                                  return 'Folio INE inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // ── Foto / Identificación ─────────────────────
                            AppImagePicker(
                              label: 'Subir Foto de Perfil',
                              onImageSelected: (file) {
                                // TODO: guardar referencia al archivo
                              },
                            ),
                            const SizedBox(height: 16),

                            // ── Email ─────────────────────────────────────
                            AppTextField(
                              label: 'Correo Electrónico',
                              controller: _emailController,
                              hint: 'ejemplo@correo.com',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(v)) {
                                  return 'Correo inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // ── Contraseña ────────────────────────────────
                            AppPasswordField(
                              label: 'Contraseña',
                              controller: _passwordController,
                              obscure: _obscurePassword,
                              onToggle: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (v.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // ── Confirmar Contraseña ──────────────────────
                            AppPasswordField(
                              label: 'Confirmar Contraseña',
                              controller: _confirmPasswordController,
                              obscure: _obscureConfirm,
                              onToggle: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // ── Botón submit ──────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _onSubmit,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined, size: 20),
                                label: const Text(
                                  'Registrarse',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1695A3),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Link a Login ──────────────────────────────
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  const Text(
                                    '¿Ya tienes una cuenta? ',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, '/login'),
                                    child: const Text(
                                      'Inicia sesión aquí',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF225378),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}