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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: navigatorKey,
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
      onGenerateRoute: (settings) {
        // Rutas públicas — no requieren sesión
        const publicRoutes = {'/', '/tutorial', '/login', '/register'};

        if (!publicRoutes.contains(settings.name)) {
          final auth = Provider.of<AuthProvider>(
            navigatorKey.currentContext!,
            listen: false,
          );
          // Si todavía está inicializando, esperar antes de decidir
          if (auth.cargando) {
            return MaterialPageRoute(
              builder: (_) => Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.cargando) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(color: Color(0xFF1695A3)),
                      ),
                    );
                  }
                  if (!auth.estaAutenticado) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    });
                    return const Scaffold(body: SizedBox());
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacementNamed(settings.name ?? '/');
                  });
                  return const Scaffold(body: SizedBox());
                },
              ),
            );
          }
          if (!auth.estaAutenticado) {
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: const RouteSettings(name: '/login'),
            );
          }
        }

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LandingScreen());
          case '/tutorial':
            return MaterialPageRoute(builder: (_) => const TutorialScreen());
          case '/admin':
            return MaterialPageRoute(builder: (_) => const AdminPanelScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/inicio-usuario':
            return MaterialPageRoute(builder: (_) => const InicioUsuarioScreen());
          case '/notificaciones':
            return MaterialPageRoute(builder: (_) => const NotificacionesScreen());
          case '/propiedades':
            return MaterialPageRoute(builder: (_) => const PropiedadesScreen());
          case '/propiedades/nueva':
            return MaterialPageRoute(builder: (_) => const NuevaPropiedadScreen());
          case '/propiedades/info': {
            final id = settings.arguments as int?;
            return MaterialPageRoute(builder: (_) => InformacionPropiedadScreen(propiedadId: id));
          }
          case '/propiedades/editar': {
            final id = settings.arguments as int?;
            return MaterialPageRoute(builder: (_) => EditarPropiedadScreen(propiedadId: id));
          }
          case '/mobiliario/nuevo': {
            final id = settings.arguments as int?;
            return MaterialPageRoute(builder: (_) => NuevoMobiliarioScreen(propiedadId: id));
          }
          case '/mobiliario/editar': {
            final id = settings.arguments as int?;
            return MaterialPageRoute(builder: (_) => EditarMobiliarioScreen(propiedadMobiliarioId: id));
          }
          case '/inquilinos':
            return MaterialPageRoute(builder: (_) => const InquilinosScreen());
          case '/inquilinos/nuevo':
            return MaterialPageRoute(builder: (_) => const NuevoInquilinoScreen());
          case '/inquilinos/info': {
            final id = settings.arguments as int?;
            return MaterialPageRoute(builder: (_) => InformacionInquilinoScreen(arrendatarioId: id));
          }
          case '/inquilinos/editar': {
            final id = settings.arguments as int?;
            return MaterialPageRoute(builder: (_) => EditarInquilinoScreen(arrendatarioId: id));
          }
          case '/pagos':
            return MaterialPageRoute(builder: (_) => const PagosScreen());
          case '/contratos':
            return MaterialPageRoute(builder: (_) => const ContratosScreen());
          case '/contratos/nuevo':
            return MaterialPageRoute(builder: (_) => const NuevoContratoScreen());
          case '/contratos/detalle': {
            final id = settings.arguments as int?;
            return MaterialPageRoute(builder: (_) => DetalleContratoScreen(contratoId: id));
          }
          case '/mantenimiento':
            return MaterialPageRoute(builder: (_) => const MantenimientoScreen());
          case '/mantenimiento/nuevo':
            return MaterialPageRoute(builder: (_) => const NuevoReporteScreen());
          case '/mantenimiento/editar': {
            final id = settings.arguments as int?;
            return MaterialPageRoute(builder: (_) => EditarReporteScreen(reporteId: id));
          }
          case '/documentos':
            return MaterialPageRoute(builder: (_) => const DocumentosScreen());
          case '/fiscal':
            return MaterialPageRoute(builder: (_) => const FiscalScreen());
          case '/fiscal/nuevo':
            return MaterialPageRoute(builder: (_) => const NuevoFiscalScreen());
          case '/fiscal/detalle': {
            final id = settings.arguments as int?;
            return MaterialPageRoute(builder: (_) => DetalleFiscalScreen(fiscalId: id));
          }
          default:
            return MaterialPageRoute(builder: (_) => const LandingScreen());
        }
      },
    );
  }
}
