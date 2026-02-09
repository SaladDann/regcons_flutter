import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../db/daos/gestion_obras/obra_dao.dart';
import '../../models/gestion_obras/obra.dart';
import '../../models/gestion_reportes/reportes.dart';
import '../../services/gestion_reportes/reporte_pdf_service.dart';
import '../../services/gestion_reportes/reportes_service.dart';

class ReportesScreen extends StatefulWidget {
  final Obra? obraSeleccionada;

  const ReportesScreen({super.key, this.obraSeleccionada});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final AppDatabase _db = AppDatabase();
  final ReporteService _reporteService = ReporteService();
  final ReportePdfService _pdfService = ReportePdfService();

  List<Obra> _obrasDisponibles = [];
  Obra? _obraSeleccionada;
  ReporteObraModel? _reporteActual;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarObras();
  }

  /// Recupera las obras activas de la base de datos
  Future<void> _cargarObras() async {
    setState(() => _cargando = true);
    try {
      final dbClient = await _db.database;
      final obraDao = ObraDao(dbClient);
      final lista = await obraDao.getActivas();

      if (lista.isNotEmpty) {
        setState(() {
          _obrasDisponibles = lista;

          // Si recibimos una obra desde HomePage, usarla
          if (widget.obraSeleccionada != null && widget.obraSeleccionada!.idObra != null) {
            // Buscar si la obra recibida está en la lista
            final obraEncontrada = lista.firstWhere(
                  (o) => o.idObra == widget.obraSeleccionada!.idObra,
              orElse: () => lista.first,
            );
            _obraSeleccionada = obraEncontrada;
          } else {
            // Si no hay obra recibida, usar la primera
            _obraSeleccionada = lista.first;
          }
        });
        await _generarDataReporte();
      }
    } catch (e) {
      _showError("Error al cargar obras: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Procesa los datos de la obra para generar métricas
  Future<void> _generarDataReporte() async {
    if (_obraSeleccionada == null) return;

    setState(() => _cargando = true);
    try {
      final data = await _reporteService.generarDataReporte(
        _obraSeleccionada!.idObra!,
        "Admin RegCons",
      );
      setState(() => _reporteActual = data);
    } catch (e) {
      _showError("Error al procesar datos: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Exporta el reporte a PDF
  void _exportarPDF() async {
    if (_reporteActual == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generando documento PDF..."), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
    );
    try {
      await _pdfService.exportarPdf(_reporteActual!);
    } catch (e) {
      _showError("Error al exportar PDF: $e");
    }
  }

  /// Notifica errores en pantalla
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text("Reportes de Control", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.orange),
            onPressed: _reporteActual == null ? null : _exportarPDF,
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Cuerpo principal con scroll
  Widget _buildBody() {
    if (_cargando && _obrasDisponibles.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (_obrasDisponibles.isEmpty) {
      return const Center(child: Text("No hay obras activas", style: TextStyle(color: Colors.white54)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("OBRA BAJO ANÁLISIS"),
          _buildFiltroObra(),
          const SizedBox(height: 20),
          if (_reporteActual != null) ...[
            _buildHeaderInfo(),
            const SizedBox(height: 20),
            _buildMetricasClave(),
            const SizedBox(height: 12),
            _buildSeccionProgreso(),
            const SizedBox(height: 12),
            _buildSeccionSeguridad(),
            const SizedBox(height: 25),
            _buildLabel("DETALLE DE ACTIVIDADES"),
            _buildResumenActividades(),
            const SizedBox(height: 20),
          ]
        ],
      ),
    );
  }

  /// Títulos de sección
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text, style: const TextStyle(color: Colors.orange, fontSize: 10, letterSpacing: 1.2)),
  );

  /// Selector de obra
  Widget _buildFiltroObra() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Obra>(
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1D2E),
          style: const TextStyle(color: Colors.white),
          value: _obraSeleccionada,
          items: _obrasDisponibles.map((o) => DropdownMenuItem(value: o, child: Text(o.nombre))).toList(),
          onChanged: (val) {
            setState(() { _obraSeleccionada = val; _reporteActual = null; });
            _generarDataReporte();
          },
        ),
      ),
    );
  }

  /// Info de cabecera
  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.15))),
      child: Row(
        children: [
          const CircleAvatar(radius: 22, backgroundColor: Colors.orange, child: Icon(Icons.business_center, color: Colors.black, size: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_reporteActual!.obra.nombre, style: const TextStyle(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 2),
                Text("Cliente: ${_reporteActual!.obra.cliente ?? 'No registrado'}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grid de métricas principales
  Widget _buildMetricasClave() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.35,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _kpiCard("Actividades", "${_reporteActual!.totalActividades}", Icons.checklist, Colors.blueAccent),
        _kpiCard("Horas Hombre", "${_reporteActual!.totalHorasTrabajadas}h", Icons.timer, Colors.cyanAccent),
        _kpiCard("Incidentes", "${_reporteActual!.totalIncidentes}", Icons.warning_amber, Colors.redAccent),
        _kpiCard("Riesgos Altas", "${_reporteActual!.riesgosActivos}", Icons.gpp_maybe, Colors.orangeAccent),
      ],
    );
  }

  /// Tarjeta KPI individual
  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  /// Sección de progreso acumulado
  Widget _buildSeccionProgreso() {
    double progreso = (_reporteActual!.porcentajeAvance / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("AVANCE DE OBRA", style: TextStyle(fontSize: 11, color: Colors.white, letterSpacing: 0.5)),
              Text("${_reporteActual!.porcentajeAvance.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.orange, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(progreso > 0.7 ? Colors.greenAccent : Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de seguridad
  Widget _buildSeccionSeguridad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.1))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.shield, color: Colors.redAccent, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("SEGURIDAD", style: TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(height: 2),
              Text("${_reporteActual!.totalIncidentes} Incidentes registrados", style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  /// Listado de actividades detalladas
  Widget _buildResumenActividades() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reporteActual!.actividades.length,
      itemBuilder: (context, index) {
        final act = _reporteActual!.actividades[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            title: Text(act.nombre, style: const TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text(act.estado, style: const TextStyle(color: Colors.orange, fontSize: 11)),
            trailing: Text("${act.porcentajeCompletado}%", style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        );
      },
    );
  }
}