import 'package:sqflite/sqflite.dart';
import '../../../models/auth/sesion.dart';

class SesionDao {
  final Database db;

  SesionDao(this.db);

  /// Registra una nueva sesión en el dispositivo
  Future<int> insert(Sesion sesion) async {
    return await db.insert('sesiones', sesion.toMap());
  }

  /// Recupera una sesión activa validando su token único
  Future<Sesion?> getActiveByToken(String token) async {
    final maps = await db.query(
      'sesiones',
      where: 'token = ? AND activa = 1',
      whereArgs: [token],
    );

    return maps.isNotEmpty ? Sesion.fromMap(maps.first) : null;
  }

  /// Obtiene la sesión más reciente del usuario que aún esté marcada como activa
  Future<Sesion?> getLastActiveByUser(int userId) async {
    final maps = await db.query(
      'sesiones',
      where: 'id_usuario = ? AND activa = 1',
      whereArgs: [userId],
      orderBy: 'fecha_creacion DESC',
      limit: 1,
    );

    return maps.isNotEmpty ? Sesion.fromMap(maps.first) : null;
  }

  /// Desactiva todas las sesiones abiertas de un usuario específico
  Future<void> invalidateAllUserSessions(int userId) async {
    await db.update(
      'sesiones',
      {'activa': 0},
      where: 'id_usuario = ? AND activa = 1',
      whereArgs: [userId],
    );
  }

  /// Invalida una sesión puntual mediante su identificador primario
  Future<void> invalidateSession(int sessionId) async {
    await db.update(
      'sesiones',
      {'activa': 0},
      where: 'id_sesion = ?',
      whereArgs: [sessionId],
    );
  }

  /// Elimina físicamente de la base de datos los registros cuya fecha de validez haya expirado
  Future<void> cleanExpiredSessions() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.delete(
      'sesiones',
      where: 'fecha_expiracion < ?',
      whereArgs: [now],
    );
  }

  /// Lista todas las sesiones activas en el sistema para auditoría o sincronización
  Future<List<Sesion>> getActiveSessions() async {
    final maps = await db.query(
      'sesiones',
      where: 'activa = 1',
    );
    return List.generate(maps.length, (i) => Sesion.fromMap(maps[i]));
  }
}