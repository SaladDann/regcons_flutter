import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth/auth_service.dart';
import '../services/user_service.dart';

class ConfiguracionesScreen extends StatefulWidget {
  final VoidCallback? onAccountChanged;
  const ConfiguracionesScreen({super.key, this.onAccountChanged});

  @override
  State<ConfiguracionesScreen> createState() => _ConfiguracionesScreenState();
}

class _ConfiguracionesScreenState extends State<ConfiguracionesScreen> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  String _nombreCompleto = 'Cargando...';
  String _correoUsuario = '...';
  String _rolUsuario = '...';
  String? _rutaImagen;
  int _idUsuario = 0;
  List<Map<String, dynamic>> _otrasCuentas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    _idUsuario = prefs.getInt('id_usuario') ?? 0;
    List<String> idsStr = prefs.getStringList('cuentas_recordadas') ?? [_idUsuario.toString()];

    if (_idUsuario != 0) {
      final perfil = await _userService.obtenerPerfilCompleto(_idUsuario);
      List<int> otrosIds = idsStr.map(int.parse).where((id) => id != _idUsuario).toList();
      List<Map<String, dynamic>> perfilesOtros = [];
      if (otrosIds.isNotEmpty) {
        perfilesOtros = await _userService.obtenerMultiplesPerfiles(otrosIds);
      }

      if (mounted) {
        setState(() {
          _nombreCompleto = perfil?['nombre_completo'] ?? 'Usuario';
          _correoUsuario = perfil?['email'] ?? 'Sin correo';
          _rolUsuario = perfil?['rol_nombre'] ?? 'Sin Rol';
          _rutaImagen = perfil?['ruta_foto'];
          _otrasCuentas = perfilesOtros;
        });
      }
    }
  }

  // --- VENTANAS MODALES ---

  void _mostrarPerfil() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181B35),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('DATOS DE PERFIL', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white10, height: 30),
            _infoRow(Icons.badge, 'Nombre', _nombreCompleto),
            _infoRow(Icons.email, 'Correo', _correoUsuario),
            _infoRow(Icons.admin_panel_settings, 'Rol', _rolUsuario),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('CERRAR'),
            )
          ],
        ),
      ),
    );
  }

  void _mostrarSeguridad() {
    final TextEditingController passActualController = TextEditingController();
    final TextEditingController passNuevaController = TextEditingController();
    final AuthService authService = AuthService();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181B35),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 24, left: 24, right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_reset_rounded, color: Colors.orange, size: 40),
            const SizedBox(height: 10),
            const Text('SEGURIDAD', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: passActualController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _modalInputStyle('Contraseña actual'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passNuevaController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _modalInputStyle('Nueva contraseña'),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (passNuevaController.text.length < 6) {
                    _mostrarSnackBar('La nueva contraseña debe tener al menos 6 caracteres');
                    return;
                  }

                  // --- DIÁLOGO DE CONFIRMACIÓN ---
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF181B35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      title: const Text('¿Confirmar cambio?', style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'Al actualizar la contraseña se cerrará la sesión actual por seguridad. Deberás ingresar de nuevo.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCELAR', style: TextStyle(color: Colors.white30)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: () async {
                            bool exito = await authService.actualizarPassword(
                                _idUsuario,
                                passNuevaController.text.trim()
                            );

                            if (mounted) {
                              if (exito) {
                                // Cerramos todo y mandamos al Login
                                _ejecutarCierreSesion(soloEstaCuenta: false);
                              } else {
                                Navigator.pop(context);
                                _mostrarSnackBar('Error al actualizar');
                              }
                            }
                          },
                          child: const Text('SÍ, ACTUALIZAR', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('ACTUALIZAR CREDENCIALES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAcercaDe() {
    showAboutDialog(
      context: context,
      applicationName: 'REGCONS',
      applicationVersion: '1.0.2',
      applicationIcon: const Icon(Icons.construction, color: Colors.orange, size: 40),
      children: [
        const Text('Sistema integral para la gestión y seguimiento de obras de construcción.'),
        const SizedBox(height: 10),
        const Text('Desarrollado para optimizar el control operativo y seguridad.'),
      ],
    );
  }

  void _mostrarDialogoCierreSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181B35),
        title: const Text('¿Cerrar sesión?', style: TextStyle(color: Colors.white)),
        content: const Text('Se limpiarán los datos de acceso de esta cuenta.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _ejecutarCierreSesion(soloEstaCuenta: false);
            },
            child: const Text('SALIR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // --- LÓGICA DE NEGOCIO ---

  Future<void> _cambiarDeCuenta(int nuevoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('id_usuario', nuevoId);
    if (widget.onAccountChanged != null) widget.onAccountChanged!();
    _cargarDatosUsuario();
    _mostrarSnackBar('Cambiado a cuenta: $nuevoId');
  }

  Future<void> _ejecutarCierreSesion({bool soloEstaCuenta = true}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!soloEstaCuenta) {
      await prefs.clear();
    } else {
      List<String> actuales = prefs.getStringList('cuentas_recordadas') ?? [];
      actuales.remove(_idUsuario.toString());
      await prefs.setStringList('cuentas_recordadas', actuales);
      if (actuales.isNotEmpty) {
        await _cambiarDeCuenta(int.parse(actuales.first));
        return;
      }
      await prefs.clear();
    }
    if (mounted) Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/', (route) => false);
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10121D),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildPerfilHeader(),
          if (_otrasCuentas.isNotEmpty) _buildSelectorCuentas(),
          const SizedBox(height: 25),
          _buildSeccion('MI CUENTA', [
            _buildTile(Icons.person_add_alt_1_outlined, 'Añadir cuenta', 'Usar otro perfil',
                    () => _ejecutarCierreSesion(soloEstaCuenta: false), color: Colors.orange),
            _buildTile(Icons.person_outline, 'Perfil', 'Datos personales', _mostrarPerfil),
            _buildTile(Icons.security, 'Seguridad', 'Contraseña y acceso', _mostrarSeguridad),
          ]),
          const SizedBox(height: 25),
          _buildSeccion('SISTEMA', [
            _buildTile(Icons.info_outline, 'Acerca de', 'Versión 1.0.2', _mostrarAcercaDe),
            _buildTile(Icons.power_settings_new, 'Cerrar Sesión', 'Salir de la app',
                _mostrarDialogoCierreSesion, color: Colors.redAccent),
          ]),
        ],
      ),
    );
  }

  Widget _buildPerfilHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _cambiarImagen,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF181B35),
                backgroundImage: (_rutaImagen != null && File(_rutaImagen!).existsSync()) ? FileImage(File(_rutaImagen!)) : null,
                child: (_rutaImagen == null) ? const Icon(Icons.person, size: 50, color: Colors.orange) : null,
              ),
              const CircleAvatar(radius: 15, backgroundColor: Colors.orange, child: Icon(Icons.camera_alt, size: 14, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(_nombreCompleto, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(_rolUsuario.toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 10, letterSpacing: 1)),
        Text(_correoUsuario, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
      ],
    );
  }

  Widget _buildSelectorCuentas() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF181B35).withOpacity(0.5), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OTRAS CUENTAS', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
          ..._otrasCuentas.map((cuenta) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 18, backgroundImage: (cuenta['ruta_foto'] != null) ? FileImage(File(cuenta['ruta_foto'])) : null, child: (cuenta['ruta_foto'] == null) ? const Icon(Icons.person, size: 20) : null),
            title: Text(cuenta['nombre_completo'], style: const TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () => _cambiarDeCuenta(cuenta['id_usuario']),
          )),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(titulo, style: const TextStyle(color: Colors.orange, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Container(decoration: BoxDecoration(color: const Color(0xFF181B35), borderRadius: BorderRadius.circular(15)), child: Column(children: items)),
    ],
  );

  Widget _buildTile(IconData icon, String title, String sub, VoidCallback onTap, {Color color = Colors.white}) => ListTile(
    leading: Icon(icon, color: color.withOpacity(0.7)),
    title: Text(title, style: TextStyle(color: color, fontSize: 15)),
    subtitle: Text(sub, style: const TextStyle(color: Colors.white30, fontSize: 12)),
    trailing: const Icon(Icons.chevron_right, color: Colors.white10),
    onTap: onTap,
  );

  InputDecoration _modalInputStyle(String label) => InputDecoration(
    labelText: label, labelStyle: const TextStyle(color: Colors.white54),
    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(children: [
      Icon(icon, color: Colors.white30, size: 20),
      const SizedBox(width: 15),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ])
    ]),
  );

  Future<void> _cambiarImagen() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null && _idUsuario != 0) {
      await _userService.actualizarFotoPerfil(_idUsuario, image.path);
      setState(() => _rutaImagen = image.path);
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.orange));
  }
}