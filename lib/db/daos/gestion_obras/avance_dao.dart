import 'package:sqflite/sqflite.dart';
import '../../../models/gestion_obras/avance.dart';

/// Data Access Object para la gestión de registros de avance diario.
/// Controla la persistencia de horas trabajadas, evidencias y estados de ejecución.
class AvanceDao {
  final Database db;

  AvanceDao(this.db);

  // --- MÉTODOS DE ESCRITURA (CUD) ---

  /// Registra un nuevo avance en la base de datos
  Future<int> insert(Avance avance) async {
    return await db.insert('avances', avance.toMap());
  }

  /// Actualiza un registro de avance existente
  Future<int> update(Avance avance) async {
    return await db.update(
      'avances',
      avance.toMap(),
      where: 'id_avance = ?',
      whereArgs: [avance.idAvance],
    );
  }

  /// Actualiza exclusivamente el estado de un avance
  Future<int> updateEstado(int idAvance, String estado) async {
    return await db.update(
      'avances',
      {'estado': estado},
      where: 'id_avance = ?',
      whereArgs: [idAvance],
    );
  }

  /// Elimina un avance específico por su ID
  Future<int> delete(int idAvance) async {
    return await db.delete(
      'avances',
      where: 'id_avance = ?',
      whereArgs: [idAvance],
    );
  }

  /// Elimina todos los avances vinculados a una actividad
  Future<int> deleteByActividad(int idActividad) async {
    return await db.delete(
      'avances',
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
    );
  }

  // --- MÉTODOS DE LECTURA (READ) ---

  /// Recupera un avance por su identificador único
  Future<Avance?> getById(int idAvance) async {
    final maps = await db.query(
      'avances',
      where: 'id_avance = ?',
      whereArgs: [idAvance],
    );
    return maps.isNotEmpty ? Avance.fromMap(maps.first) : null;
  }

  /// Obtiene el último avance registrado para una actividad específica
  Future<Avance?> getUltimoByActividad(int idActividad) async {
    final maps = await db.query(
      'avances',
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
      orderBy: 'fecha DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? Avance.fromMap(maps.first) : null;
  }

  /// Lista todos los avances ordenados por fecha descendente
  Future<List<Avance>> getAll() async {
    final maps = await db.query('avances', orderBy: 'fecha DESC');
    return maps.map((m) => Avance.fromMap(m)).toList();
  }

  /// Filtra avances por actividad
  Future<List<Avance>> getByActividad(int idActividad) async {
    final maps = await db.query(
      'avances',
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Avance.fromMap(m)).toList();
  }

  /// Filtra avances por obra
  Future<List<Avance>> getByObra(int idObra) async {
    final maps = await db.query(
      'avances',
      where: 'id_obra = ?',
      whereArgs: [idObra],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Avance.fromMap(m)).toList();
  }

  /// Filtra avances por estado operativo
  Future<List<Avance>> getByEstado(String estado) async {
    final maps = await db.query(
      'avances',
      where: 'estado = ?',
      whereArgs: [estado],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Avance.fromMap(m)).toList();
  }

  /// Filtra avances dentro de un rango de fechas
  Future<List<Avance>> getByFechaRange(DateTime start, DateTime end) async {
    final maps = await db.query(
      'avances',
      where: 'fecha >= ? AND fecha <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Avance.fromMap(m)).toList();
  }

  /// Búsqueda por texto en descripción o estado
  Future<List<Avance>> search(String query) async {
    final searchTerm = '%${query.trim()}%';
    final maps = await db.query(
      'avances',
      where: 'descripcion LIKE ? OR estado LIKE ?',
      whereArgs: [searchTerm, searchTerm],
      orderBy: 'fecha DESC',
    );
    return maps.map((m) => Avance.fromMap(m)).toList();
  }

  // --- CONSULTAS AGREGADAS Y ESTADÍSTICAS ---

  /// Conteo de avances por actividad
  Future<int> countByActividad(int idActividad) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM avances WHERE id_actividad = ?',
      [idActividad],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Conteo de avances por obra
  Future<int> countByObra(int idObra) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM avances WHERE id_obra = ?',
      [idObra],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Suma total de horas hombre (HH) para una actividad
  Future<double> sumHorasByActividad(int idActividad) async {
    final result = await db.rawQuery('''
      SELECT SUM(horas_trabajadas) as total_horas
      FROM avances
      WHERE id_actividad = ? AND horas_trabajadas IS NOT NULL
    ''', [idActividad]);

    final total = result.first['total_horas'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  /// Genera un resumen estadístico global de los avances
  Future<Map<String, int>> getEstadisticas() async {
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN estado = 'FINALIZADO' THEN 1 ELSE 0 END) as finalizados,
        SUM(CASE WHEN estado = 'EN_PROCESO' THEN 1 ELSE 0 END) as en_proceso,
        SUM(CASE WHEN estado = 'PENDIENTE' THEN 1 ELSE 0 END) as pendientes
      FROM avances
    ''');

    if (result.isEmpty) return {'total': 0, 'finalizados': 0, 'en_proceso': 0, 'pendientes': 0};

    final row = result.first;
    return {
      'total': (row['total'] as int?) ?? 0,
      'finalizados': (row['finalizados'] as int?) ?? 0,
      'en_proceso': (row['en_proceso'] as int?) ?? 0,
      'pendientes': (row['pendientes'] as int?) ?? 0,
    };
  }
}