import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:rentiva/core/providers/auth_provider.dart';
import 'package:rentiva/features/auth/screens/login_screen.dart';
import 'package:rentiva/features/auth/screens/register_screen.dart';
import 'package:rentiva/features/dashboard/screens/inicio_usuario_admin.dart';
import 'package:rentiva/features/dashboard/screens/inicio_usuario_screen.dart';
import 'package:rentiva/features/home/screens/landing_screen.dart';
import 'package:rentiva/features/home/screens/tutorial_screen.dart';
import 'package:rentiva/features/contratos/screens/contratos_screen.dart';
import 'package:rentiva/features/contratos/screens/nuevo_contrato_screen.dart';
import 'package:rentiva/features/contratos/screens/detalle_contrato_screen.dart';
import 'package:rentiva/features/documentos/screens/documentos_screen.dart';
import 'package:rentiva/features/fiscal/screens/fiscal_screen.dart';
import 'package:rentiva/features/fiscal/screens/nuevo_fiscal_screen.dart';
import 'package:rentiva/features/fiscal/screens/detalle_fiscal_screen.dart';
import 'package:rentiva/features/inquilinos/screens/editar_inquilino_screen.dart';
import 'package:rentiva/features/inquilinos/screens/informacion_inquilino_screen.dart';
import 'package:rentiva/features/inquilinos/screens/inquilinos_screen.dart';
import 'package:rentiva/features/inquilinos/screens/nuevo_inquilino_screen.dart';
import 'package:rentiva/features/mantenimiento/screens/editar_reporte_screen.dart';
import 'package:rentiva/features/mantenimiento/screens/mantenimiento_screen.dart';
import 'package:rentiva/features/mantenimiento/screens/nuevo_reporte_screen.dart';
import 'package:rentiva/features/notificaciones/screens/notificaciones_screen.dart';
import 'package:rentiva/features/pagos/screens/pagos_screen.dart';
import 'package:rentiva/features/propiedades/screens/editar_mobiliario_screen.dart';
import 'package:rentiva/features/propiedades/screens/editar_propiedad_screen.dart';
import 'package:rentiva/features/propiedades/screens/informacion_propiedad_screen.dart';
import 'package:rentiva/features/propiedades/screens/nueva_propiedad_screen.dart';
import 'package:rentiva/features/propiedades/screens/nuevo_mobiliario_screen.dart';
import 'package:rentiva/features/propiedades/screens/propiedades_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..inicializar(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentiva',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Sans',
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/tutorial': (context) => const TutorialScreen(),
        '/admin': (context) => const AdminPanelScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/inicio-usuario': (context) => const InicioUsuarioScreen(),
        '/notificaciones': (context) => const NotificacionesScreen(),
        '/propiedades': (context) => const PropiedadesScreen(),
        '/propiedades/nueva': (context) => const NuevaPropiedadScreen(),
        '/propiedades/info': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int?;
          return InformacionPropiedadScreen(propiedadId: id);
        },
        '/mobiliario/nuevo': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int?;
          return NuevoMobiliarioScreen(propiedadId: id);
        },
        '/mobiliario/editar': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int?;
          return EditarMobiliarioScreen(propiedadMobiliarioId: id);
        },
        '/propiedades/editar': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int?;
          return EditarPropiedadScreen(propiedadId: id);
        },
        '/inquilinos': (context) => const InquilinosScreen(),
        '/inquilinos/nuevo': (context) => const NuevoInquilinoScreen(),
        '/inquilinos/info': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int?;
          return InformacionInquilinoScreen(arrendatarioId: id);
        },
        '/inquilinos/editar': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int?;
          return EditarInquilinoScreen(arrendatarioId: id);
        },
        '/pagos': (context) => const PagosScreen(),
        '/contratos': (context) => const ContratosScreen(),
        '/contratos/nuevo': (context) => const NuevoContratoScreen(),
        '/contratos/detalle': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int?;
          return DetalleContratoScreen(contratoId: id);
        },
        '/mantenimiento': (context) => const MantenimientoScreen(),
        '/mantenimiento/nuevo': (context) => const NuevoReporteScreen(),
        '/mantenimiento/editar': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int?;
          return EditarReporteScreen(reporteId: id);
        },
        '/documentos': (context) => const DocumentosScreen(),
        '/fiscal': (context) => const FiscalScreen(),
        '/fiscal/nuevo': (context) => const NuevoFiscalScreen(),
        '/fiscal/detalle': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int?;
          return DetalleFiscalScreen(fiscalId: id);
        },
      },
    );
  }
}
