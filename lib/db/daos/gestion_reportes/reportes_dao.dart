import 'package:sqflite/sqflite.dart';

/// Data Access Object especializado en la extracción de métricas consolidadas.
/// Provee la inteligencia de datos necesaria para alimentar el ReporteObraModel.
class ReporteDao {
  final Database db;
  ReporteDao(this.db);

  /// Cuantifica los incidentes registrados en un intervalo de tiempo específico.
  Future<int> contarIncidentes(int idObra, int inicio, int fin) async {
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM reportes_seguridad 
      WHERE id_obra = ? AND fecha_evento BETWEEN ? AND ?
    ''', [idObra, inicio, fin]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Identifica el volumen de riesgos críticos o altos que aún no han sido mitigados.
  Future<int> contarRiesgosActivos(int idObra) async {
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM reportes_seguridad 
      WHERE id_obra = ? AND severidad IN ('ALTA', 'CRITICA') AND estado != 'RESUELTO'
    ''', [idObra]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Calcula el porcentaje de avance físico real.
  /// Implementa validación para evitar divisiones por cero si la obra no tiene tareas.
  Future<double> obtenerAvanceGlobal(int idObra) async {
    final result = await db.rawQuery('''
      SELECT 
        CASE 
          WHEN COUNT(*) = 0 THEN 0.0
          ELSE (CAST(SUM(CASE WHEN estado = 'FINALIZADA' OR estado = 'COMPLETADA' THEN 1 ELSE 0 END) AS REAL) / COUNT(*)) * 100 
        END as progreso
      FROM actividades WHERE id_obra = ?
    ''', [idObra]);

    return (result.first['progreso'] as num?)?.toDouble() ?? 0.0;
  }

  /// Obtiene la sumatoria total de horas hombre (HH) acumuladas en una obra específica.
  Future<double> obtenerTotalHorasObra(int idObra) async {
    final result = await db.rawQuery('''
      SELECT SUM(horas_trabajadas) as total 
      FROM avances 
      WHERE id_obra = ?
    ''', [idObra]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}