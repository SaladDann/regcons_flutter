import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth/auth_service.dart';
import '../home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores
  final _usuarioController = TextEditingController();
  final _passController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _mantenerSesion = false;
  bool _isLoading = false;

  // DECORACIÓN INPUTS
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 1.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarSesion();
  }

  // CARGAR SESIÓN DESDE SHARED PREFERENCES
  Future<void> _cargarSesion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuario = prefs.getString('usuario');
      final idUsuario = prefs.getInt('id_usuario');
      final mantener = prefs.getBool('mantener_sesion') ?? false;

      // Verificamos que existan datos de sesión válidos
      if (mantener && usuario != null && idUsuario != null && idUsuario != 0) {
        _usuarioController.text = usuario;
        _mantenerSesion = true;

        final sesionActiva = await _authService.verificarSesionActiva();

        if (sesionActiva && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePage(nombreUsuario: usuario)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al cargar sesión: $e');
    }
  }

  // MÉTODO LOGIN PARA MULTI-CUENTA
  Future<void> _login() async {
    final username = _usuarioController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _mostrarError('Ingrese sus credenciales completas');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuario = await _authService.login(username, password);

      if (usuario != null) {
        final prefs = await SharedPreferences.getInstance();
        final int idNuevo = usuario.idUsuario ?? 0;

        // 1. GUARDADO DEL ID ACTUAL
        await prefs.setInt('id_usuario', idNuevo);

        // 2. LÓGICA DE MULTI-CUENTA (Bóveda de IDs)
        // Recuperamos la lista actual de IDs recordados
        List<String> recordadas = prefs.getStringList('cuentas_recordadas') ?? [];

        // Si el ID del usuario que acaba de entrar no está en la lista, lo añadimos
        if (!recordadas.contains(idNuevo.toString())) {
          recordadas.add(idNuevo.toString());
          await prefs.setStringList('cuentas_recordadas', recordadas);
        }

        // 3. Persistencia de sesión individual
        await prefs.setBool('mantener_sesion', _mantenerSesion);

        if (_mantenerSesion) {
          await prefs.setString('usuario', username);
        } else {
          await prefs.remove('usuario');
        }

        if (!mounted) return;

        // Navegación limpia al Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(nombreUsuario: username)),
        );
      } else {
        _mostrarError('Usuario o contraseña incorrectos');
      }
    } catch (e) {
      _mostrarError('Error de conexión: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/tapiz_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 10,
                  color: const Color.fromARGB(66, 24, 27, 53),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 12),
                        const Text('Lidera tu construcción', style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 28),
                        _buildUserField(),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 12),
                        _buildSessionCheckbox(),
                        const SizedBox(height: 24),
                        _buildLoginButton(),
                        const SizedBox(height: 12),
                        _buildRegisterButton(),
                        const SizedBox(height: 16),
                        _buildForgotPasswordLink(),
                      ],
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

  // --- WIDGETS AUXILIARES (Refactorizados para limpieza) ---

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icon/icon_regcons.png',
          height: 50,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.construction, size: 50, color: Colors.orange),
        ),
        const SizedBox(width: 10),
        const Text('REGCONS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.white)),
      ],
    );
  }

  Widget _buildUserField() {
    return TextField(
      controller: _usuarioController,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label: 'Usuario', icon: Icons.person_outline),
      enabled: !_isLoading,
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Contraseña',
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      enabled: !_isLoading,
      onSubmitted: (_) => _login(),
    );
  }

  Widget _buildSessionCheckbox() {
    return CheckboxListTile(
      value: _mantenerSesion,
      onChanged: _isLoading ? null : (v) => setState(() => _mantenerSesion = v ?? false),
      title: const Text('Mantener sesión activa', style: TextStyle(color: Colors.white)),
      activeColor: Colors.orange,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/register'),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: const Text('Registrarse', style: TextStyle(color: Colors.orange)),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return TextButton(
      onPressed: _isLoading ? null : () => _mostrarError('Función en desarrollo.'),
      child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.blueGrey)),
    );
  }
}