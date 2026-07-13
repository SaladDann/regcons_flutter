import 'package:sqflite/sqflite.dart';
import '../../../models/gestion_obras/usuario_obra.dart';

/// Data Access Object para gestionar la tabla pivot entre Usuarios y Obras.
/// Controla los permisos de acceso y la asignación de personal a proyectos específicos.
class UsuarioObraDao {
  final Database db;

  UsuarioObraDao(this.db);

  // --- ASIGNACIONES (ESCRITURA) ---
  /// Vincula un usuario a una obra específica.
  Future<int> insert(UsuarioObra usuarioObra) async {
    return await db.insert(
      'usuario_obra',
      usuarioObra.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore, // Evita duplicados de relación
    );
  }

  /// Revoca el acceso de un usuario a una obra puntual.
  Future<int> delete(int idUsuario, int idObra) async {
    return await db.delete(
      'usuario_obra',
      where: 'id_usuario = ? AND id_obra = ?',
      whereArgs: [idUsuario, idObra],
    );
  }

  // --- CONSULTAS (LECTURA) ---
  /// Obtiene los identificadores de todas las obras asignadas a un usuario.
  Future<List<int>> getObrasByUsuario(int idUsuario) async {
    final maps = await db.query(
      'usuario_obra',
      columns: ['id_obra'],
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );

    return maps.map((m) => m['id_obra'] as int).toList();
  }

  /// Obtiene los identificadores de todos los usuarios vinculados a una obra.
  Future<List<int>> getUsuariosByObra(int idObra) async {
    final maps = await db.query(
      'usuario_obra',
      columns: ['id_usuario'],
      where: 'id_obra = ?',
      whereArgs: [idObra],
    );

    return maps.map((m) => m['id_usuario'] as int).toList();
  }

  /// Valida rápidamente si un usuario posee permisos para interactuar con una obra.
  Future<bool> tieneAcceso(int idUsuario, int idObra) async {
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM usuario_obra 
      WHERE id_usuario = ? AND id_obra = ?
    ''', [idUsuario, idObra]);

    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  /// Elimina todas las vinculaciones de personal para una obra.
  Future<int> deleteByObra(int idObra) async {
    return await db.delete(
      'usuario_obra',
      where: 'id_obra = ?',
      whereArgs: [idObra],
    );
  }

  /// Remueve todos los permisos de obra para un usuario específico.
  Future<int> deleteByUsuario(int idUsuario) async {
    return await db.delete(
      'usuario_obra',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }
}