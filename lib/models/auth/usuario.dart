/// Representa a un usuario dentro del sistema.
/// Gestiona la información de perfil, credenciales de seguridad y roles.
class Usuario {
  int? idUsuario;
  String username;
  String email;
  String nombreCompleto;
  String? genero;
  DateTime? fechaNacimiento;
  String passwordHash;
  String passwordSalt;
  DateTime? fechaUltimoCambioPassword;
  bool aceptaTerminos;
  String estado;
  DateTime fechaCreacion;
  int idRol;

  Usuario({
    this.idUsuario,
    required this.username,
    required this.email,
    required this.nombreCompleto,
    this.genero,
    this.fechaNacimiento,
    required this.passwordHash,
    required this.passwordSalt,
    this.fechaUltimoCambioPassword,
    required this.aceptaTerminos,
    required this.estado,
    required this.fechaCreacion,
    required this.idRol,
  });

  /// Construye un Usuario desde un mapa de base de datos con casting de tipos.
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      idUsuario: map['id_usuario'] as int?,
      username: map['username'] as String,
      email: map['email'] as String,
      nombreCompleto: map['nombre_completo'] as String,
      genero: map['genero'] as String?,
      fechaNacimiento: map['fecha_nacimiento'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fecha_nacimiento'] as int)
          : null,
      passwordHash: map['password_hash'] as String,
      passwordSalt: map['password_salt'] as String,
      fechaUltimoCambioPassword: map['fecha_ultimo_cambio_password'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fecha_ultimo_cambio_password'] as int)
          : null,
      aceptaTerminos: (map['acepta_terminos'] as int) == 1,
      estado: map['estado'] as String,
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['fecha_creacion'] as int),
      idRol: map['id_rol'] as int,
    );
  }

  /// Serializa la instancia a un mapa compatible con SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'username': username,
      'email': email,
      'nombre_completo': nombreCompleto,
      'genero': genero,
      'fecha_nacimiento': fechaNacimiento?.millisecondsSinceEpoch,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'fecha_ultimo_cambio_password': fechaUltimoCambioPassword?.millisecondsSinceEpoch,
      'acepta_terminos': aceptaTerminos ? 1 : 0,
      'estado': estado,
      'fecha_creacion': fechaCreacion.millisecondsSinceEpoch,
      'id_rol': idRol,
    };
  }

  /// Retorna las iniciales del usuario para avatares o perfiles rápidos.
  String get iniciales {
    if (nombreCompleto.isEmpty) return '??';
    final partes = nombreCompleto.trim().split(' ');
    if (partes.length < 2) return partes[0][0].toUpperCase();
    return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase();
  }
}