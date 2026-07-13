import '../db/app_db.dart';

class UserService {
  final AppDatabase _db = AppDatabase();

  /// Obtiene la información completa del usuario (Datos básicos + Rol + Perfil)
  Future<Map<String, dynamic>?> obtenerPerfilCompleto(int idUsuario) async {
    final db = await _db.database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        u.id_usuario, 
        u.username, 
        u.email, 
        u.nombre_completo, 
        u.estado,
        r.nombre as rol_nombre,
        p.ruta_foto,
        p.ultimo_cambio
      FROM usuarios u
      INNER JOIN roles r ON u.id_rol = r.id_rol
      LEFT JOIN perfil_usuario p ON u.id_usuario = p.id_usuario
      WHERE u.id_usuario = ?
    ''', [idUsuario]);

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  /// NUEVO: Obtiene info básica de una lista de IDs para el selector de cuentas
  /// Se usa para mostrar el listado tipo "Google" en la pantalla de Ajustes.
  Future<List<Map<String, dynamic>>> obtenerMultiplesPerfiles(List<int> ids) async {
    if (ids.isEmpty) return [];

    final db = await _db.database;
    // Creamos los placeholders (?,?,?) según la cantidad de IDs
    final placeholders = List.filled(ids.length, '?').join(',');

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        u.id_usuario, 
        u.nombre_completo, 
        u.email, 
        p.ruta_foto 
      FROM usuarios u 
      LEFT JOIN perfil_usuario p ON u.id_usuario = p.id_usuario
      WHERE u.id_usuario IN ($placeholders)
    ''', ids);

    return result;
  }

  /// Guarda o actualiza la foto de perfil del usuario.
  Future<bool> actualizarFotoPerfil(int idUsuario, String ruta) async {
    try {
      final db = await _db.database;

      await db.rawInsert('''
        INSERT INTO perfil_usuario (id_usuario, ruta_foto, ultimo_cambio)
        VALUES (?, ?, ?)
        ON CONFLICT(id_usuario) DO UPDATE SET 
          ruta_foto = excluded.ruta_foto,
          ultimo_cambio = excluded.ultimo_cambio
      ''', [
        idUsuario,
        ruta,
        DateTime.now().millisecondsSinceEpoch
      ]);

      return true;
    } catch (e) {
      print("Error en UserService.actualizarFotoPerfil: $e");
      return false;
    }
  }

  /// Verifica si el usuario está activo antes de operaciones críticas
  Future<bool> esUsuarioActivo(int idUsuario) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> res = await db.query(
      'usuarios',
      columns: ['estado'],
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );

    if (res.isNotEmpty) {
      return res.first['estado'] == AppDatabase.estadoActivo;
    }
    return false;
  }
}