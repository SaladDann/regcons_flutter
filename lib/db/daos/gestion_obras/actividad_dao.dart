import 'package:sqflite/sqflite.dart';
import '../../../models/gestion_obras/actividad.dart';

/// Data Access Object para la gestión de tareas y cronogramas de obra.
/// Centraliza la persistencia de actividades y el cálculo de métricas de progreso.
class ActividadDao {
  final Database db;

  ActividadDao(this.db);

  /// Registra una nueva actividad en el cronograma
  Future<int> insert(Actividad actividad) async {
    return await db.insert('actividades', actividad.toMap());
  }

  /// Actualiza los metadatos de una actividad existente
  Future<int> update(Actividad actividad) async {
    return await db.update(
      'actividades',
      actividad.toMap(),
      where: 'id_actividad = ?',
      whereArgs: [actividad.idActividad],
    );
  }

  /// Elimina una actividad del registro local
  Future<int> delete(int idActividad) async {
    return await db.delete(
      'actividades',
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
    );
  }

  /// Recupera el listado completo de actividades registradas
  Future<List<Actividad>> getAll() async {
    final maps = await db.query('actividades');
    return maps.map((m) => Actividad.fromMap(m)).toList();
  }

  /// Busca una actividad específica por su ID primario
  Future<Actividad?> getById(int idActividad) async {
    final maps = await db.query(
      'actividades',
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
    );
    return maps.isNotEmpty ? Actividad.fromMap(maps.first) : null;
  }

  /// Obtiene las actividades vinculadas a un proyecto de obra específico
  Future<List<Actividad>> getByObra(int idObra) async {
    final maps = await db.query(
      'actividades',
      where: 'id_obra = ?',
      whereArgs: [idObra],
    );
    return maps.map((m) => Actividad.fromMap(m)).toList();
  }

  /// Filtra actividades por su estado operativo (PENDIENTE, EN_PROGRESO, etc.)
  Future<List<Actividad>> getByEstado(String estado) async {
    final maps = await db.query(
      'actividades',
      where: 'estado = ?',
      whereArgs: [estado],
      orderBy: 'id_obra',
    );
    return maps.map((m) => Actividad.fromMap(m)).toList();
  }

  /// Conteo rápido de actividades asociadas a una obra
  Future<int> countByObra(int idObra) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM actividades WHERE id_obra = ?',
      [idObra],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Actualiza exclusivamente el flujo de estado de una tarea
  Future<int> updateEstado(int idActividad, String estado) async {
    return await db.update(
      'actividades',
      {'estado': estado},
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
    );
  }

  /// Búsqueda inteligente por coincidencias en nombre o descripción dentro de una obra
  Future<List<Actividad>> searchByObra(int idObra, String query) async {
    final searchTerm = '%${query.trim()}%';
    final maps = await db.query(
      'actividades',
      where: 'id_obra = ? AND (nombre LIKE ? OR descripcion LIKE ?)',
      whereArgs: [idObra, searchTerm, searchTerm],
      orderBy: 'id_actividad',
    );
    return maps.map((m) => Actividad.fromMap(m)).toList();
  }

  /// Genera un resumen estadístico del estado de las tareas para reportes de obra
  Future<Map<String, int>> getEstadisticasByObra(int idObra) async {
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN estado = 'COMPLETADA' THEN 1 ELSE 0 END) as finalizados,
        SUM(CASE WHEN estado = 'EN_PROGRESO' THEN 1 ELSE 0 END) as en_proceso
      FROM actividades 
      WHERE id_obra = ?
    ''', [idObra]);

    if (result.isEmpty) return {'total': 0, 'finalizados': 0, 'en_proceso': 0};

    return {
      'total': (result.first['total'] as int?) ?? 0,
      'finalizados': (result.first['finalizados'] as int?) ?? 0,
      'en_proceso': (result.first['en_proceso'] as int?) ?? 0,
    };
  }
}

