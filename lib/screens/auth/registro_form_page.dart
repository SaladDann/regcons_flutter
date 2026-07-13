import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';

class RegistroFormPage extends StatefulWidget {
  final VoidCallback? onCancelar;
  const RegistroFormPage({super.key, this.onCancelar});

  @override
  State<RegistroFormPage> createState() => _RegistroFormPageState();
}

class _RegistroFormPageState extends State<RegistroFormPage> {
  final _formKey = GlobalKey<FormState>();

  // CONTROLADORES
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // VARIABLES DE ESTADO
  String _rolSeleccionado = 'Supervisor';
  String _genero = 'M';
  DateTime? _fechaNacimiento;
  bool _aceptaCondiciones = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _usuarioController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // Decoración de inputs
  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.orange, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Future<void> _onAceptarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaNacimiento == null) {
      _notificar('Seleccione su fecha de nacimiento', Colors.redAccent);
      return;
    }

    if (_fechaNacimiento!.isAfter(DateTime.now())) {
      _notificar('La fecha no puede ser futura', Colors.redAccent);
      return;
    }

    if (_passController.text != _confirmPassController.text) {
      _notificar('Las contraseñas no coinciden', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nuevoUsuario = await _authService.registrarUsuario(
        username: _usuarioController.text.trim(),
        email: _correoController.text.trim(),
        nombreCompleto: _nombreController.text.trim(),
        password: _passController.text,
        aceptaTerminos: _aceptaCondiciones,
        genero: _genero,
        fechaNacimiento: _fechaNacimiento,
        rol: _rolSeleccionado,
      );

      if (nuevoUsuario != null) {
        _notificar(
          '¡Usuario "${nuevoUsuario.username}" creado con éxito!',
          Colors.green,
        );

        // Esperar y volver al login
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      _notificar('Error: ${e.toString()}', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _notificar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final DateTime hoy = DateTime.now();
    final DateTime inicial = DateTime(hoy.year - 18, hoy.month, hoy.day);

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? inicial,
      firstDate: DateTime(1940),
      lastDate: hoy,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.orange,
            onPrimary: Colors.white,
            surface: Color(0xFF1E2130),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (fecha != null) setState(() => _fechaNacimiento = fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10121D),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/tapiz_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, e, s) =>
                  Container(color: const Color(0xFF10121D)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(key: _formKey, child: _buildFormCard()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      color: const Color(0xDD1E2130),
      elevation: 15,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'REGISTRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 25),

            TextFormField(
              controller: _nombreController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                'Nombre Completo',
                Icons.badge_outlined,
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                'Correo Electrónico',
                Icons.email_outlined,
              ),
              validator: (v) => v!.contains('@') ? null : 'Correo inválido',
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _rolSeleccionado,
                    dropdownColor: const Color(0xFF1E2130),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration('Rol', Icons.work_outline),
                    items: ['Supervisor', 'Operario']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _rolSeleccionado = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: InkWell(
                    onTap: _seleccionarFecha,
                    child: InputDecorator(
                      decoration: _inputDecoration('Nacimiento', Icons.event),
                      child: Text(
                        _fechaNacimiento == null
                            ? 'DD/MM/AA'
                            : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _usuarioController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                'Usuario',
                Icons.account_circle_outlined,
              ),
              validator: (v) => v!.length < 4 ? 'Mínimo 4 caracteres' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passController,
              obscureText: _obscurePass,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                'Contraseña',
                Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePass ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _confirmPassController,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                'Repetir Contraseña',
                Icons.lock_reset,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Confirme contraseña' : null,
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniRadio('Masculino', 'M'),
                _miniRadio('Femenino', 'F'),
              ],
            ),

            CheckboxListTile(
              value: _aceptaCondiciones,
              onChanged: (v) => setState(() => _aceptaCondiciones = v ?? false),
              title: const Text(
                'Acepto términos y condiciones',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.orange,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 20),

            // Solo se activa si acepta condiciones y no está cargando
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isLoading || !_aceptaCondiciones)
                    ? null
                    : _onAceptarRegistro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.orange.withOpacity(0.12),
                  disabledForegroundColor: Colors.white24,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'REGISTRAR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text(
                '¿Ya tienes cuenta? Inicia Sesión',
                style: TextStyle(color: Colors.orange, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniRadio(String texto, String valor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: valor,
          groupValue: _genero,
          activeColor: Colors.orange,
          onChanged: (v) => setState(() => _genero = v!),
        ),
        Text(
          texto,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
