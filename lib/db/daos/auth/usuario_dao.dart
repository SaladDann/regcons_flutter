import 'package:sqflite/sqflite.dart';
import '../../../models/auth/usuario.dart';

class UsuarioDao {
  final Database db;

  UsuarioDao(this.db);

  /// Registra un nuevo usuario en la base de datos local
  Future<int> insert(Usuario usuario) async {
    return await db.insert('usuarios', usuario.toMap());
  }

  /// Busca un usuario por su nombre de cuenta único
  Future<Usuario?> getByUsername(String username) async {
    final maps = await db.query(
      'usuarios',
      where: 'username = ?',
      whereArgs: [username],
    );

    return maps.isNotEmpty ? Usuario.fromMap(maps.first) : null;
  }

  /// Recupera un usuario mediante su dirección de correo electrónico
  Future<Usuario?> getByEmail(String email) async {
    final maps = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
    );

    return maps.isNotEmpty ? Usuario.fromMap(maps.first) : null;
  }

  /// Verifica la existencia de un nombre de usuario para validaciones de registro
  Future<bool> exists(String username) async {
    final count = await db.rawQuery(
      'SELECT COUNT(*) FROM usuarios WHERE username = ?',
      [username],
    );
    return Sqflite.firstIntValue(count) != 0;
  }

  /// Actualiza la marca de tiempo del último cambio de credenciales
  Future<void> updateLastPasswordChange(int userId, DateTime fecha) async {
    await db.update(
      'usuarios',
      {'fecha_ultimo_cambio_password': fecha.millisecondsSinceEpoch},
      where: 'id_usuario = ?',
      whereArgs: [userId],
    );
  }

  /// Obtiene el listado completo de usuarios registrados
  Future<List<Usuario>> getAll() async {
    final maps = await db.query('usuarios');
    return List.generate(maps.length, (i) => Usuario.fromMap(maps[i]));
  }
}