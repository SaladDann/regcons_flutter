import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:regcons/screens/gestion_reportes/reportes_screen.dart';
import '../models/gestion_obras/obra.dart';
import '../services/gestion_obras/obra_service.dart';
import 'gestion_incidentes/reportes_incidentes_screen.dart';
import 'gestion_obras/obra_detalle_screen.dart';
import 'gestion_obras/obras_screen.dart';
import 'news_page.dart';
import 'configuraciones_screen.dart';

class HomePage extends StatefulWidget {
  final String nombreUsuario;
  const HomePage({super.key, required this.nombreUsuario});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- ESTADO Y SERVICIOS ---
  int _selectedIndex = 2;
  bool _isLoading = true;
  String? _rutaImagen;
  Obra? _obraSeleccionada;
  List<Obra> _obrasActivas = [];
  int? _idUsuarioActual;

  final ObraService _obraService = ObraService();

  static const List<String> _titles = [
    'Ajustes', 'Noticias', 'Inicio', 'Incidentes', 'Reportes'
  ];

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  // --- LÓGICA DE DATOS ---

  Future<void> _inicializarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _idUsuarioActual = prefs.getInt('id_usuario') ?? 0;
      _rutaImagen = prefs.getString('user_profile_path');
    });

    if (_idUsuarioActual != 0) {
      await _cargarObrasActivas();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarObrasActivas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Usamos el ID recuperado en la inicialización
      if (_idUsuarioActual == null || _idUsuarioActual == 0) {
        final prefs = await SharedPreferences.getInstance();
        _idUsuarioActual = prefs.getInt('id_usuario') ?? 0;
      }

      final obras = await _obraService.obtenerObrasActivasPorUsuario(_idUsuarioActual!);

      if (!mounted) return;
      setState(() {
        _obrasActivas = obras;
        if (_obrasActivas.isNotEmpty) {
          _obraSeleccionada = _obraSeleccionada != null
              ? _obrasActivas.firstWhere(
                  (o) => o.idObra == _obraSeleccionada!.idObra,
              orElse: () => _obrasActivas.first
          )
              : _obrasActivas.first;
        } else {
          _obraSeleccionada = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NAVEGACIÓN ---

  void _irADetalleObra() {
    if (_obraSeleccionada?.idObra != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ObraDetalleScreen(idObra: _obraSeleccionada!.idObra!),
        ),
      ).then((_) => _cargarObrasActivas());
    }
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10121D),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(bottom: false, child: _buildContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final bool esInicio = _selectedIndex == 2;
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: const Color(0xFF181B35).withOpacity(0.9),
      leading: esInicio ? null : IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.orange, size: 20),
        onPressed: () => setState(() => _selectedIndex = 2),
      ),
      title: Text(_titles[_selectedIndex], style: const TextStyle(color: Colors.white, fontSize: 18)),
      actions: esInicio ? [
        IconButton(onPressed: _cargarObrasActivas, icon: const Icon(Icons.sync, color: Colors.orange))
      ] : null,
    );
  }

  Widget _buildBackground() => Positioned.fill(
      child: Image.asset('assets/images/tapiz_bg.png', fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.15))
  );

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return ConfiguracionesScreen(
        onAccountChanged: () => _inicializarDatos(),
      );
      case 1: return const NewsPage();
      case 2: return _buildHomeContent();
      case 3:
        return _obraSeleccionada == null
            ? _buildEmptyState('Seleccione una obra activa')
            : IncidentesScreen(obra: _obraSeleccionada!);
      case 4:
        return (_obraSeleccionada == null || _obraSeleccionada!.idObra == null)
            ? _buildEmptyState('Seleccione una obra para generar reportes')
            : ReportesScreen(obraSeleccionada: _obraSeleccionada!);
      default: return const SizedBox();
    }
  }

  Widget _buildEmptyState(String message) => Center(child: Text(message, style: const TextStyle(color: Colors.white70)));

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildActiveWorkCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('CONTROL OPERATIVO'),
          const SizedBox(height: 12),
          _buildGridAcciones(),
          const SizedBox(height: 24),
          _buildSectionTitle('RESUMEN DE PROYECTOS'),
          const SizedBox(height: 16),
          _buildResumenEstadistico(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedIndex = 0),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.orange.withOpacity(0.2),
            backgroundImage: (_rutaImagen != null && _rutaImagen!.isNotEmpty) ? FileImage(File(_rutaImagen!)) : null,
            child: (_rutaImagen == null || _rutaImagen!.isEmpty) ? const Icon(Icons.person, color: Colors.orange, size: 28) : null,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PANEL DE CONTROL', style: TextStyle(color: Colors.orange.withAlpha(200), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text(widget.nombreUsuario, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveWorkCard() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF181B35), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.construction, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text('OBRA EN SEGUIMIENTO', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoading ? const LinearProgressIndicator(color: Colors.orange) : _buildDropdownObras(),
                if (_obraSeleccionada != null) ...[
                  const SizedBox(height: 20),
                  _buildProgresoVisual(),
                ],
              ],
            ),
          ),
          if (_obraSeleccionada != null) _buildFooterCard(),
        ],
      ),
    );
  }

  Widget _buildDropdownObras() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Obra>(
          value: _obraSeleccionada,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E2130),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.orange),
          items: _obrasActivas.map((o) => DropdownMenuItem(
              value: o,
              child: Text(o.nombre, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))
          )).toList(),
          onChanged: (v) => setState(() => _obraSeleccionada = v),
        ),
      ),
    );
  }

  Widget _buildProgresoVisual() {
    final porc = _obraSeleccionada!.porcentajeAvance ?? 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nivel de Avance', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            Text('${porc.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (porc / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            color: Colors.orange,
            minHeight: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterCard() => InkWell(
    onTap: _irADetalleObra,
    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility, color: Colors.orange, size: 18),
          SizedBox(width: 8),
          Text('DETALLES Y ACTIVIDADES', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    ),
  );

  Widget _buildGridAcciones() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _buildActionCard(
            icon: Icons.business_center_outlined,
            label: 'Gestionar\nObras',
            color: Colors.blueAccent,
            // CORRECCIÓN AQUÍ: Pasamos el ID del usuario actual
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ObrasScreen(idUsuarioActual: _idUsuarioActual ?? 0))
            ).then((_) => _cargarObrasActivas())
        ),
        _buildActionCard(
            icon: Icons.report_problem_outlined,
            label: 'Nuevo\nIncidente',
            color: Colors.redAccent,
            onTap: () {
              if (_obraSeleccionada != null) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => IncidentesScreen(obra: _obraSeleccionada!)));
              } else {
                setState(() => _selectedIndex = 3);
              }
            }
        ),
        _buildActionCard(
            icon: Icons.analytics_outlined,
            label: 'Reportes\nPDF',
            color: Colors.purpleAccent,
            onTap: () {
              if (_obraSeleccionada != null) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ReportesScreen(obraSeleccionada: _obraSeleccionada!)));
              } else {
                setState(() => _selectedIndex = 4);
              }
            }
        ),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF181B35), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 24)),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenEstadistico() {
    return FutureBuilder<Map<String, int>>(
      future: (_idUsuarioActual != null && _idUsuarioActual != 0)
          ? _obraService.getEstadisticasPorUsuario(_idUsuarioActual!)
          : Future.value({'total': 0, 'activas': 0, 'finalizadas': 0}),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0, 'activas': 0, 'finalizadas': 0};
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(color: const Color(0xFF181B35), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Total', stats['total'].toString(), Colors.blue),
              _statItem('Activas', stats['activas'].toString(), Colors.orange),
              _statItem('Finalizadas', stats['finalizadas'].toString(), Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String val, Color color) => Column(
    children: [
      Text(val, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2));

  Widget _buildBottomNav() => BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: (i) => setState(() => _selectedIndex = i),
    type: BottomNavigationBarType.fixed,
    backgroundColor: const Color(0xFF181B35),
    selectedItemColor: Colors.orange,
    unselectedItemColor: Colors.white30,
    elevation: 10,
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Ajustes'),
      BottomNavigationBarItem(icon: Icon(Icons.newspaper_outlined), activeIcon: Icon(Icons.newspaper), label: 'Noticias'),
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_filled), label: 'Inicio'),
      BottomNavigationBarItem(icon: Icon(Icons.report_outlined), activeIcon: Icon(Icons.report), label: 'Incidentes'),
      BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assessment), label: 'Reportes'),
    ],
  );

  //Cambio de sesion
  Future<void> cambiarCuenta(int nuevoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('id_usuario', nuevoId); // Actualizamos el ID activo

    // Limpiamos la obra seleccionada para evitar errores de pertenencia
    setState(() {
      _obraSeleccionada = null;
      _idUsuarioActual = nuevoId;
    });

    await _inicializarDatos();
  }
}