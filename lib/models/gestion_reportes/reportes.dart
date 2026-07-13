import '../gestion_obras/obra.dart';
import '../gestion_obras/actividad.dart';
import '../gestion_incidentes/incidente.dart';
import '../gestion_obras/avance.dart';

/// Modelo de datos consolidado para la generación de informes técnicos y ejecutivos.
class ReporteObraModel {
  final Obra obra;
  final double porcentajeAvance;
  final double avanceSemanal;
  final int totalActividades;
  final List<Actividad> actividades;
  final int totalIncidentes;
  final List<Incidente> incidentes;
  final int riesgosActivos;
  final DateTime fechaGeneracion;
  final String responsable;

  /// Acumulado de horas hombre (HH) registradas en todos los avances de la obra.
  final double totalHorasTrabajadas;

  /// Listado de los registros de avance más recientes para visualización en detalle.
  final List<Avance> ultimosAvances;

  ReporteObraModel({
    required this.obra,
    required this.porcentajeAvance,
    this.avanceSemanal = 0.0,
    required this.totalActividades,
    required this.actividades,
    required this.totalIncidentes,
    required this.incidentes,
    required this.riesgosActivos,
    required this.fechaGeneracion,
    required this.responsable,
    this.totalHorasTrabajadas = 0.0,
    this.ultimosAvances = const [],
  });

  // --- Propiedades Computadas para Resumen ---
  /// Indica si existen incidentes críticos que requieren atención inmediata en el reporte.
  bool get tieneAlertasCriticas =>
      incidentes.any((i) => i.severidad == 'CRITICA' || i.severidad == 'ALTA');

  /// Retorna el conteo de actividades finalizadas para el resumen ejecutivo.
  int get actividadesCompletadas =>
      actividades.where((a) => a.estado == 'COMPLETADA').length;

  /// Formatea la fecha de generación para encabezados de documentos.
  String get fechaFormateada =>
      "${fechaGeneracion.day}/${fechaGeneracion.month}/${fechaGeneracion.year}";
}