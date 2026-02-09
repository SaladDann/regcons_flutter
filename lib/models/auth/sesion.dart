/// Representa una sesión de usuario activa en el dispositivo local.
/// Utilizada para gestionar el acceso persistente y la expiración de tokens.
class Sesion {
  int? idSesion;
  int idUsuario;
  String token;
  DateTime fechaCreacion;
  DateTime fechaExpiracion;
  bool activa;

  Sesion({
    this.idSesion,
    required this.idUsuario,
    required this.token,
    required this.fechaCreacion,
    required this.fechaExpiracion,
    required this.activa,
  });

  /// Crea una instancia de Sesion a partir de un mapa de datos
  factory Sesion.fromMap(Map<String, dynamic> map) {
    return Sesion(
      idSesion: map['id_sesion'] as int?,
      idUsuario: map['id_usuario'] as int,
      token: map['token'] as String,
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['fecha_creacion'] as int),
      fechaExpiracion: DateTime.fromMillisecondsSinceEpoch(map['fecha_expiracion'] as int),
      activa: (map['activa'] as int) == 1,
    );
  }

  /// Convierte la instancia actual en un mapa para persistencia
  Map<String, dynamic> toMap() {
    return {
      'id_sesion': idSesion,
      'id_usuario': idUsuario,
      'token': token,
      'fecha_creacion': fechaCreacion.millisecondsSinceEpoch,
      'fecha_expiracion': fechaExpiracion.millisecondsSinceEpoch,
      'activa': activa ? 1 : 0,
    };
  }

  /// Verifica si la sesión ha superado su fecha de validez
  bool estaExpirada() => DateTime.now().isAfter(fechaExpiracion);
}