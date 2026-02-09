import 'dart:convert';

/// Representa un registro de seguridad en obra.
/// Gestiona la severidad, evidencias fotográficas y el estado de resolución.
class Incidente {
  int? idReporte;
  int idObra;
  int idUsuario;
  String tipo;
  String severidad;
  String descripcion;
  DateTime fechaEvento;
  List<String> evidenciasFoto;
  String estado;
  int sincronizado;

  Incidente({
    this.idReporte,
    required this.idObra,
    required this.idUsuario,
    required this.tipo,
    required this.severidad,
    required this.descripcion,
    required this.fechaEvento,
    this.evidenciasFoto = const [],
    this.estado = 'REPORTADO',
    this.sincronizado = 0,
  });

  /// Convierte el objeto a un mapa compatible con SQLite, serializando la lista de fotos.
  Map<String, dynamic> toMap() {
    return {
      'id_reporte': idReporte,
      'id_obra': idObra,
      'id_usuario': idUsuario,
      'tipo': tipo,
      'severidad': severidad,
      'descripcion': descripcion,
      'fecha_evento': fechaEvento.millisecondsSinceEpoch,
      'evidencias_foto': evidenciasFoto.isNotEmpty ? jsonEncode(evidenciasFoto) : null,
      'estado': estado,
      'sincronizado': sincronizado,
    };
  }

  /// Reconstruye el incidente desde los datos de la BD, deserializando evidencias.
  factory Incidente.fromMap(Map<String, dynamic> map) {
    return Incidente(
      idReporte: map['id_reporte'] as int?,
      idObra: map['id_obra'] as int,
      idUsuario: map['id_usuario'] as int,
      tipo: map['tipo'] as String,
      severidad: map['severidad'] as String,
      descripcion: (map['descripcion'] as String?) ?? '',
      fechaEvento: DateTime.fromMillisecondsSinceEpoch(map['fecha_evento'] as int),
      evidenciasFoto: map['evidencias_foto'] != null
          ? List<String>.from(jsonDecode(map['evidencias_foto'] as String))
          : [],
      estado: (map['estado'] as String?) ?? 'REPORTADO',
      sincronizado: (map['sincronizado'] as int?) ?? 0,
    );
  }

  // --- Propiedades ---
  bool get esCritico => severidad == 'CRITICA' || severidad == 'ALTA';
  bool get tieneEvidencias => evidenciasFoto.isNotEmpty;

  /// Retorna la fecha del evento en formato legible (DD/MM/AAAA).
  String get fechaEventoFormatted {
    final d = fechaEvento.day.toString().padLeft(2, '0');
    final m = fechaEvento.month.toString().padLeft(2, '0');
    return '$d/$m/${fechaEvento.year}';
  }
}
