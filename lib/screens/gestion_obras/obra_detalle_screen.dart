import 'package:flutter/material.dart';
import '../../models/gestion_obras/obra.dart';
import '../../services/gestion_obras/obra_service.dart';
import '../../models/gestion_obras/actividad.dart';
import '../../services/gestion_obras/actividad_service.dart';
import 'avances_actividad_screen.dart';

class ObraDetalleScreen extends StatefulWidget {
  final int idObra;
  const ObraDetalleScreen({super.key, required this.idObra});

  @override
  State<ObraDetalleScreen> createState() => _ObraDetalleScreenState();
}

class _ObraDetalleScreenState extends State<ObraDetalleScreen> with SingleTickerProviderStateMixin {
  // Servicios y Controladores
  final _actividadService = ActividadService();
  final _obraService = ObraService();
  late TabController _tabController;

  // Estado de la UI
  bool _cargando = true;
  Obra? obra;
  Map<String, dynamic>? resumen;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _cargarObra();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Carga principal de datos
  Future<void> _cargarObra() async {
    try {
      if (!mounted) return;
      setState(() => _cargando = true);
      final data = await _obraService.obtenerObraCompleta(widget.idObra);
      if (!mounted) return;
      setState(() {
        obra = data['obra'] as Obra;
        resumen = data;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Notificaciones flotantes para campo
  void _mostrarNotificacion(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(esError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: esError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Gestión de creación y edición
  Future<void> _mostrarModalActividad({Actividad? actividad}) async {
    final _formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: actividad?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: actividad?.descripcion ?? '');
    String estado = actividad?.estado ?? 'PENDIENTE';
    bool guardando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF181B35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(actividad == null ? 'Nueva Actividad' : 'Editar Actividad',
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecor('Nombre', Icons.edit),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descripcionCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecor('Descripción', Icons.description),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: estado,
                    dropdownColor: const Color(0xFF181B35),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecor('Estado', Icons.info_outline),
                    items: actividad == null
                        ? const [DropdownMenuItem(value: 'PENDIENTE', child: Text('PENDIENTE'))]
                        : ['PENDIENTE', 'EN_PROGRESO', 'FINALIZADA'].map((e) =>
                        DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setModalState(() => estado = v ?? 'PENDIENTE'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: guardando ? null : () async {
                if (!_formKey.currentState!.validate()) return;
                setModalState(() => guardando = true);
                try {
                  if (actividad == null) {
                    await _actividadService.crearActividad(
                      idObra: widget.idObra,
                      nombre: nombreCtrl.text.trim(),
                      descripcion: descripcionCtrl.text.trim(),
                      estado: estado,
                    );
                  } else {
                    await _actividadService.actualizarActividad(actividad.copyWith(
                      nombre: nombreCtrl.text.trim(),
                      descripcion: descripcionCtrl.text.trim(),
                      estado: estado,
                    ));
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _cargarObra();
                    _mostrarNotificacion('Operación exitosa');
                  }
                } catch (e) {
                  setModalState(() => guardando = false);
                  _mostrarNotificacion('Error: $e', esError: true);
                }
              },
              child: guardando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('GUARDAR', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Borrado de registros
  void _confirmarEliminar(Actividad actividad) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF181B35),
        title: const Text('¿Eliminar actividad?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción eliminará todos los avances asociados.', style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NO')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SÍ, ELIMINAR'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await _actividadService.eliminarActividad(actividad.idActividad!);
        _mostrarNotificacion('Actividad eliminada');
        _cargarObra();
      } catch (e) {
        _mostrarNotificacion('Error al eliminar', esError: true);
      }
    }
  }

  InputDecoration _inputDecor(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white60),
    prefixIcon: Icon(icon, color: Colors.orange, size: 20),
    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF181B35).withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(obra?.nombre ?? 'Detalle'),
        titleTextStyle: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold, fontSize: 18),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarObra)],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'RESUMEN', icon: Icon(Icons.analytics_outlined)),
            Tab(text: 'ACTIVIDADES', icon: Icon(Icons.list_alt_outlined)),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ACTIVIDAD', style: TextStyle(color: Colors.white)),
        onPressed: () => _mostrarModalActividad(),
      )
          : null,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7))),
          _cargando && obra == null
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : SafeArea(
            child: RefreshIndicator(
              onRefresh: _cargarObra,
              color: Colors.orange,
              child: TabBarView(
                controller: _tabController,
                children: [_tabResumen(), _tabActividades()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabResumen() {
    if (obra == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _headerObra(),
        const SizedBox(height: 16),
        _itemResumen('Total actividades', resumen?['total_actividades']?.toString() ?? '0', Icons.assignment),
        _itemResumen('Cliente', obra?.cliente ?? 'N/A', Icons.person),
        _itemResumen('Ubicación', obra?.direccion ?? 'No especificada', Icons.location_on),
        _itemResumen('Inicio', obra!.fechaInicioFormatted, Icons.event_available),
        _itemResumen('Fin Previsto', obra!.fechaFinFormatted, Icons.event_busy),
      ],
    );
  }

  Widget _tabActividades() {
    final actividades = (resumen?['actividades'] as List<Actividad>? ?? []);
    if (actividades.isEmpty) {
      return const Center(child: Text('Sin actividades', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: actividades.length,
      itemBuilder: (_, i) => _cardActividad(actividades[i]),
    );
  }

  Widget _cardActividad(Actividad actividad) {
    return Card(
      color: const Color(0xFF181B35).withOpacity(0.7),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        iconColor: Colors.orange,
        collapsedIconColor: Colors.white70,
        title: Text(actividad.nombre, style: const TextStyle(color: Colors.white)),
        subtitle: Text('Estado: ${actividad.estado}',
            style: TextStyle(color: actividad.estadoColor == 'FINALIZADA' ? Colors.greenAccent : Colors.white70, fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _btnAccion(Icons.add_chart, 'AVANCES', Colors.greenAccent, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AvancesActividadScreen(
                    idActividad: actividad.idActividad!,
                    idObra: actividad.idObra,
                    nombreActividad: actividad.nombre,
                  ))).then((_) => _cargarObra());
                }),
                _btnAccion(Icons.edit, 'EDITAR', Colors.orange, () => _mostrarModalActividad(actividad: actividad)),
                _btnAccion(Icons.delete, 'BORRAR', Colors.redAccent, () => _confirmarEliminar(actividad)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btnAccion(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _headerObra() {
    final progreso = (obra!.porcentajeAvance ?? 0.0) / 100;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181B35).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(obra!.nombre, style: const TextStyle(color: Colors.white, fontSize: 20))),
              _chipEstado(obra!.estado, obra!.estadoColor),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(value: progreso.clamp(0.0, 1.0), color: Colors.orange, backgroundColor: Colors.white12),
          const SizedBox(height: 8),
          Text('${obra!.porcentajeAvance?.toStringAsFixed(1) ?? '0.0'}% Completado',
              style: const TextStyle(color: Colors.orange, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _chipEstado(String texto, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
    child: Text(texto, style: TextStyle(color: color, fontSize: 10)),
  );

  Widget _itemResumen(String label, String value, IconData icon) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: const Color(0xFF181B35).withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}