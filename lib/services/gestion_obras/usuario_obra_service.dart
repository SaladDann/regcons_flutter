import '../../db/app_db.dart';
import '../../db/daos/gestion_obras/usuario_obra_dao.dart';
import '../../models/gestion_obras/usuario_obra.dart';

class UsuarioObraService {
  late UsuarioObraDao _usuarioObraDao;
  bool _inicializado = false;

  /// Inicializa el DAO de relación Usuario-Obra asegurando la conexión a la base de datos
  Future<void> _initialize() async {
    if (!_inicializado) {
      final db = await AppDatabase().database;
      _usuarioObraDao = UsuarioObraDao(db);
      _inicializado = true;
    }
  }

  /// Crea un vínculo de acceso entre un usuario específico y una obra
  Future<void> asignarUsuarioAObra(int idUsuario, int idObra) async {
    await _initialize();
    await _usuarioObraDao.insert(UsuarioObra(
      idUsuario: idUsuario,
      idObra: idObra,
    ));
  }

  /// Remueve el permiso de acceso de un usuario a una obra determinada
  Future<void> eliminarAsignacionUsuarioObra(int idUsuario, int idObra) async {
    await _initialize();
    await _usuarioObraDao.delete(idUsuario, idObra);
  }

  /// Recupera los identificadores de todas las obras a las que el usuario tiene acceso
  Future<List<int>> obtenerObrasDeUsuario(int idUsuario) async {
    await _initialize();
    return await _usuarioObraDao.getObrasByUsuario(idUsuario);
  }

  /// Recupera los identificadores de todos los usuarios asignados a una obra
  Future<List<int>> obtenerUsuariosDeObra(int idObra) async {
    await _initialize();
    return await _usuarioObraDao.getUsuariosByObra(idObra);
  }

  /// Verifica de forma rápida si un usuario posee permisos de entrada en una obra
  Future<bool> tieneAccesoAObra(int idUsuario, int idObra) async {
    await _initialize();
    return await _usuarioObraDao.tieneAcceso(idUsuario, idObra);
  }

  /// Registra masivamente el acceso de múltiples usuarios a una sola obra
  Future<void> asignarUsuariosAObra(List<int> idsUsuarios, int idObra) async {
    await _initialize();
    for (var idUsuario in idsUsuarios) {
      await _usuarioObraDao.insert(UsuarioObra(
        idUsuario: idUsuario,
        idObra: idObra,
      ));
    }
  }

  /// Limpia todos los registros de acceso vinculados a una obra (borrado masivo)
  Future<void> eliminarTodosUsuariosDeObra(int idObra) async {
    await _initialize();
    await _usuarioObraDao.deleteByObra(idObra);
  }

  /// Revoca el acceso de un usuario a todos los proyectos en los que estaba asignado
  Future<void> eliminarTodasObrasDeUsuario(int idUsuario) async {
    await _initialize();
    await _usuarioObraDao.deleteByUsuario(idUsuario);
  }

  /// Obtiene obras permitidas para un usuario con posibilidad de excluir IDs específicos
  Future<List<int>> obtenerObrasAccesibles(
      int idUsuario, {
        List<int>? excludeObras,
      }) async {
    await _initialize();
    final todasObras = await _usuarioObraDao.getObrasByUsuario(idUsuario);

    if (excludeObras != null) {
      return todasObras.where((id) => !excludeObras.contains(id)).toList();
    }
    return todasObras;
  }
}