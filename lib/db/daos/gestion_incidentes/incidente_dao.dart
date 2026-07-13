import 'package:sqflite/sqflite.dart';
import '../../../models/gestion_incidentes/incidente.dart';
import '../../app_db.dart';

/// Data Access Object para la gestión de incidentes y condiciones inseguras.
/// Maneja la persistencia local y el filtrado avanzado de reportes de seguridad.
class IncidenteDao {
  final AppDatabase _appDatabase = AppDatabase();

  /// Registra un nuevo reporte de seguridad. Usa ConflictAlgorithm.replace para actualizaciones.
  Future<int> insertarIncidente(Incidente incidente) async {
    final db = await _appDatabase.database;
    return await db.insert(
      'reportes_seguridad',
      incidente.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualiza los datos de un incidente existente mediante su ID primario.
  Future<int> actualizarIncidente(Incidente incidente) async {
    final db = await _appDatabase.database;
    return await db.update(
      'reportes_seguridad',
      incidente.toMap(),
      where: 'id_reporte = ?',
      whereArgs: [incidente.idReporte],
    );
  }

  /// Remueve un registro de la base de datos local.
  Future<int> eliminarIncidente(int idReporte) async {
    final db = await _appDatabase.database;
    return await db.delete(
      'reportes_seguridad',
      where: 'id_reporte = ?',
      whereArgs: [idReporte],
    );
  }

  /// Busca un reporte específico por su identificador único.
  Future<Incidente?> obtenerPorId(int idReporte) async {
    final db = await _appDatabase.database;
    final result = await db.query(
      'reportes_seguridad',
      where: 'id_reporte = ?',
      whereArgs: [idReporte],
      limit: 1,
    );

    return result.isNotEmpty ? Incidente.fromMap(result.first) : null;
  }

  /// Recupera todos los incidentes asociados a una obra específica.
  Future<List<Incidente>> listarPorObra(int idObra) async {
    final db = await _appDatabase.database;
    final result = await db.query(
      'reportes_seguridad',
      where: 'id_obra = ?',
      whereArgs: [idObra],
      orderBy: 'fecha_evento DESC',
    );

    return result.map((e) => Incidente.fromMap(e)).toList();
  }

  /// Consulta avanzada con múltiples criterios de filtrado para auditorías de seguridad.
  Future<List<Incidente>> listarConFiltros({
    required int idObra,
    String? tipo,
    String? severidad,
    String? estado,
    String? textoBusqueda,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final db = await _appDatabase.database;
    final List<String> where = ['id_obra = ?'];
    final List<dynamic> args = [idObra];

    if (tipo != null) {
      where.add('tipo = ?');
      args.add(tipo);
    }
    if (severidad != null) {
      where.add('severidad = ?');
      args.add(severidad);
    }
    if (estado != null) {
      where.add('estado = ?');
      args.add(estado);
    }
    if (textoBusqueda != null && textoBusqueda.trim().isNotEmpty) {
      where.add('descripcion LIKE ?');
      args.add('%$textoBusqueda%');
    }
    if (fechaInicio != null) {
      where.add('fecha_evento >= ?');
      args.add(fechaInicio.millisecondsSinceEpoch);
    }
    if (fechaFin != null) {
      where.add('fecha_evento <= ?');
      args.add(fechaFin.millisecondsSinceEpoch);
    }

    final result = await db.query(
      'reportes_seguridad',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'fecha_evento DESC',
    );

    return result.map((e) => Incidente.fromMap(e)).toList();
  }

  /// Cambia exclusivamente el flujo de resolución de un reporte.
  Future<int> actualizarEstado(int idReporte, String nuevoEstado) async {
    final db = await _appDatabase.database;
    return await db.update(
      'reportes_seguridad',
      {'estado': nuevoEstado},
      where: 'id_reporte = ?',
      whereArgs: [idReporte],
    );
  }
}
