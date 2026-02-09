import 'package:flutter/material.dart';
import 'package:regcons/screens/home_page.dart';
import 'package:regcons/screens/auth/login_page.dart';
import 'package:regcons/screens/auth/registro_form_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

/// Configura el tema global, navegación y rutas del sistema.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RegCons',

      // Configuración estética global de la aplicación
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF10121D),

        // Personalización de componentes comunes
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF10121D),
          elevation: 0,
          centerTitle: true,
        ),
      ),

      // Definición de la rutas
      initialRoute: '/',
      routes: _buildRoutes(),
    );
  }

  /// Rutas para una navegación centralizada
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => const LoginPage(),
      '/register': (context) => const RegistroFormPage(),
      '/home': (context) => const HomePage(nombreUsuario: 'Usuario'),
    };
  }
}
