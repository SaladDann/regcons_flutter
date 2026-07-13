import 'package:sqflite/sqflite.dart';
import '../../../models/gestion_obras/obra.dart';

/// Data Access Object para la gestión de proyectos de construcción (Obras).
/// Controla el ciclo de vida de los proyectos y calcula métricas de progreso global.
class ObraDao {
  final Database db;

  ObraDao(this.db);

  /// Registra una nueva obra en el sistema
  Future<int> insert(Obra obra) async {
    return await db.insert('obras', obra.toMap());
  }

  /// Actualiza la información técnica y administrativa de una obra
  Future<int> update(Obra obra) async {
    return await db.update(
      'obras',
      obra.toMap(),
      where: 'id_obra = ?',
      whereArgs: [obra.idObra],
    );
  }

  /// Elimina una obra de la base de datos local
  Future<int> delete(int idObra) async {
    return await db.delete('obras', where: 'id_obra = ?', whereArgs: [idObra]);
  }

  /// Recupera el listado completo de obras, ordenadas por fecha de inicio
  Future<List<Obra>> getAll() async {
    final maps = await db.query('obras', orderBy: 'fecha_inicio DESC');
    return maps.map((m) => Obra.fromMap(m)).toList();
  }

  /// Filtra proyectos por su estado operativo actual
  Future<List<Obra>> getByEstado(String estado) async {
    final maps = await db.query(
      'obras',
      where: 'estado = ?',
      whereArgs: [estado],
      orderBy: 'fecha_inicio DESC',
    );
    return maps.map((m) => Obra.fromMap(m)).toList();
  }

  /// Acceso rápido a las obras en ejecución
  Future<List<Obra>> getActivas() => getByEstado('ACTIVA');

  /// Busca una obra específica mediante su identificador único
  Future<Obra?> getById(int idObra) async {
    final maps = await db.query(
      'obras',
      where: 'id_obra = ?',
      whereArgs: [idObra],
    );
    return maps.isNotEmpty ? Obra.fromMap(maps.first) : null;
  }

  /// Calcula el porcentaje de avance real basado en el estado de las tareas vinculadas.
  Future<double> calcularPorcentajeAvance(int idObra) async {
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN estado = 'COMPLETADA' OR estado = 'FINALIZADA' THEN 1 ELSE 0 END) as completadas
      FROM actividades 
      WHERE id_obra = ?
    ''', [idObra]);

    if (result.isEmpty || (result.first['total'] as int) == 0) return 0.0;

    final total = result.first['total'] as int;
    final completadas = (result.first['completadas'] as int?) ?? 0;

    return (completadas / total) * 100.0;
  }

  /// Conteo total de proyectos registrados
  Future<int> count() async {
    final result = await db.rawQuery('SELECT COUNT(*) FROM obras');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Búsqueda avanzada por múltiples criterios (nombre, cliente, dirección)
  Future<List<Obra>> search(String query) async {
    final searchTerm = '%${query.trim()}%';
    final maps = await db.query(
      'obras',
      where: 'nombre LIKE ? OR descripcion LIKE ? OR cliente LIKE ? OR direccion LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm, searchTerm],
      orderBy: 'fecha_inicio DESC',
    );

    return maps.map((m) => Obra.fromMap(m)).toList();
  }
}