import 'package:flutter/material.dart';
import 'package:regcons/screens/gestion_obras/widgets/loading_widget.dart';
import 'package:regcons/screens/gestion_obras/widgets/obra_card.dart';
import 'package:regcons/screens/gestion_obras/widgets/search_bar.dart';
import '../../services/gestion_obras/obra_service.dart';
import '../../models/gestion_obras/obra.dart';
import 'obra_detalle_screen.dart';
import 'obras_form_screen.dart';

class ObrasScreen extends StatefulWidget {
  // 1. Recibimos el ID por parámetro para asegurar que siempre esté disponible
  final int idUsuarioActual;

  const ObrasScreen({super.key, required this.idUsuarioActual});

  @override
  State<ObrasScreen> createState() => _ObrasScreenState();
}

class _ObrasScreenState extends State<ObrasScreen> {
  final ObraService _obraService = ObraService();
  List<Obra> _todasObras = [];
  List<Obra> _obrasFiltradas = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    _cargarObras();
  }

  // --- LÓGICA DE DATOS ---

  Future<void> _cargarObras() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 2. Usamos directamente el ID que viene del widget
      final obras = await _obraService.obtenerObrasPorUsuario(widget.idUsuarioActual);

      if (!mounted) return;
      setState(() {
        _todasObras = obras;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _notificarMensaje('Error: ${e.toString()}', esError: true);
    }
  }

  void _aplicarFiltros() {
    List<Obra> filtradas = List.from(_todasObras);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtradas = filtradas.where((o) =>
      o.nombre.toLowerCase().contains(query) ||
          (o.descripcion?.toLowerCase().contains(query) ?? false) ||
          (o.cliente?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    if (_showOnlyActive) {
      filtradas = filtradas.where((o) => o.estado == 'ACTIVA').toList();
    }

    setState(() => _obrasFiltradas = filtradas);
  }

  // --- ACCIONES DE USUARIO ---

  Future<void> _eliminarObra(Obra obra) async {
    if (obra.idObra == null) return;
    try {
      await _obraService.eliminarObraCompleta(obra.idObra!);
      setState(() {
        _todasObras.removeWhere((o) => o.idObra == obra.idObra);
        _aplicarFiltros();
      });
      _notificarMensaje('"${obra.nombre}" eliminada correctamente');
    } catch (e) {
      _notificarMensaje('Error al eliminar: $e', esError: true);
    }
  }

  Future<void> _finalizarObra(Obra obra) async {
    if (obra.idObra == null) return;
    try {
      final obraActualizada = Obra(
        idObra: obra.idObra,
        nombre: obra.nombre,
        descripcion: obra.descripcion,
        direccion: obra.direccion,
        cliente: obra.cliente,
        fechaInicio: obra.fechaInicio,
        fechaFin: obra.fechaFin,
        presupuesto: obra.presupuesto,
        estado: 'FINALIZADA',
        porcentajeAvance: 100.0,
      );
      await _obraService.actualizarObra(obraActualizada);
      _cargarObras();
      _notificarMensaje('Obra finalizada con éxito');
    } catch (e) {
      _notificarMensaje('Error al finalizar: $e', esError: true);
    }
  }

  // --- NAVEGACIÓN ---

  void _navegarAFormulario({Obra? obra}) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ObraFormScreen(
          obra: obra,
          idUsuarioActual: widget.idUsuarioActual,
        ))
    ).then((_) => _cargarObras());
  }

  void _verDetalles(Obra obra) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ObraDetalleScreen(idObra: obra.idObra!)))
        .then((_) => _cargarObras());
  }

  // --- INTERFAZ ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10121D),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTopSearchArea(),
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              color: Colors.orange,
              backgroundColor: const Color(0xFF181B35),
              onRefresh: _cargarObras,
              child: _buildMainList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarAFormulario(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('NUEVA OBRA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: const Color(0xFF181B35),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.orange, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Gestión de Obras',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      actions: [
        _buildCounterIndicator(),
      ],
    );
  }

  Widget _buildTopSearchArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: const Color(0xFF181B35),
      child: SearchBarWidget(
        hintText: 'Buscar nombre o cliente...',
        onSearch: (q) { setState(() => _searchQuery = q); _aplicarFiltros(); },
        onClear: () { setState(() => _searchQuery = ''); _aplicarFiltros(); },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          FilterChip(
            label: const Text('SOLO ACTIVAS'),
            selected: _showOnlyActive,
            onSelected: (_) { setState(() => _showOnlyActive = !_showOnlyActive); _aplicarFiltros(); },
            backgroundColor: const Color(0xFF1E2130),
            selectedColor: Colors.orange.withOpacity(0.2),
            checkmarkColor: Colors.orange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _showOnlyActive ? Colors.orange : Colors.white60),
          ),
          const Spacer(),
          IconButton(onPressed: _cargarObras, icon: const Icon(Icons.sync, color: Colors.blueAccent)),
        ],
      ),
    );
  }

  Widget _buildMainList() {
    if (_isLoading && _todasObras.isEmpty) {
      return const LoadingWidget(message: 'Cargando proyectos...');
    }

    if (_obrasFiltradas.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
      itemCount: _obrasFiltradas.length,
      itemBuilder: (context, index) {
        final obra = _obrasFiltradas[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: ObraCard(
            obra: obra,
            onEditar: () => _navegarAFormulario(obra: obra),
            onFinalizar: obra.estado == 'FINALIZADA' ? null : () => _finalizarObra(obra),
            onEliminar: () => _mostrarConfirmacion(obra),
            onTap: () => _verDetalles(obra),
          ),
        );
      },
    );
  }

  Widget _buildCounterIndicator() {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withAlpha(80))
      ),
      child: Center(
        child: Text('${_obrasFiltradas.length}',
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: _InternalEmptyState(
          title: _searchQuery.isEmpty ? 'Sin obras registradas' : 'Sin coincidencias',
          message: _searchQuery.isEmpty
              ? 'Inicia registrando tu primer proyecto en el botón inferior.'
              : 'No hay resultados para "$_searchQuery".',
          icon: _searchQuery.isEmpty ? Icons.inventory_2_outlined : Icons.search_off_rounded,
        ),
      ),
    );
  }

  void _notificarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarConfirmacion(Obra obra) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF181B35),
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
        content: Text('¿Deseas eliminar permanentemente "${obra.nombre}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () { Navigator.pop(context); _eliminarObra(obra); },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _InternalEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _InternalEmptyState({required this.title, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.orange.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }
}
