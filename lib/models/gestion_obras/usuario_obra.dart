/// Clase de relación para la gestión de permisos entre Usuarios y Obras.
/// Representa la tabla intermedia que vincula el acceso de personal a proyectos específicos.
class UsuarioObra {
  final int idUsuario;
  final int idObra;

  UsuarioObra({
    required this.idUsuario,
    required this.idObra,
  });

  /// Crea una instancia de vinculación desde un mapa de base de datos.
  factory UsuarioObra.fromMap(Map<String, dynamic> map) {
    return UsuarioObra(
      idUsuario: map['id_usuario'] as int,
      idObra: map['id_obra'] as int,
    );
  }

  /// Serializa la relación para inserciones o eliminaciones en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'id_obra': idObra,
    };
  }

  /// Compara si dos objetos representan la misma vinculación.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UsuarioObra &&
              runtimeType == other.runtimeType &&
              idUsuario == other.idUsuario &&
              idObra == other.idObra;

  @override
  int get hashCode => idUsuario.hashCode ^ idObra.hashCode;
}