import 'package:flutter/material.dart';

/// Representa un registro de progreso diario o específico para una actividad en obra.
/// Incluye el control de horas hombre (HH), evidencias fotográficas y estado de sincronización.
class Avance {
  int? idAvance;
  int idObra;
  int idActividad;
  DateTime fecha;
  double? horasTrabajadas;
  String? descripcion;
  String? evidenciaFoto;
  String estado;
  int sincronizado;

  /// Porcentaje de ejecución de la actividad en este registro puntual (Solo UI).
  double porcentajeEjecutado;

  /// Nombre de la actividad asociada para facilitar la visualización en reportes.
  String? nombreActividad;

  Avance({
    this.idAvance,
    required this.idObra,
    required this.idActividad,
    required this.fecha,
    this.horasTrabajadas = 0.0,
    this.descripcion,
    this.evidenciaFoto,
    this.estado = 'REGISTRADO',
    this.sincronizado = 0,
    this.porcentajeEjecutado = 0.0,
    this.nombreActividad,
  });

  /// Reconstruye el Avance desde un mapa de base de datos con manejo seguro de tipos numéricos.
  factory Avance.fromMap(Map<String, dynamic> map) {
    return Avance(
      idAvance: map['id_avance'] as int?,
      idObra: map['id_obra'] as int,
      idActividad: map['id_actividad'] as int,
      fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha'] as int),
      horasTrabajadas: (map['horas_trabajadas'] as num?)?.toDouble() ?? 0.0,
      descripcion: map['descripcion'] as String?,
      evidenciaFoto: map['evidencia_foto'] as String?,
      estado: (map['estado'] as String?) ?? 'REGISTRADO',
      sincronizado: (map['sincronizado'] as int?) ?? 0,
    );
  }

  /// Serializa el modelo para persistencia local en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id_avance': idAvance,
      'id_obra': idObra,
      'id_actividad': idActividad,
      'fecha': fecha.millisecondsSinceEpoch,
      'horas_trabajadas': horasTrabajadas,
      'descripcion': descripcion,
      'evidencia_foto': evidenciaFoto,
      'estado': estado,
      'sincronizado': sincronizado,
    };
  }

  // --- Utilidades de Formato y UI ---

  /// Retorna la fecha en formato legible (DD/MM/AAAA).
  String get fechaFormateada => '${fecha.day}/${fecha.month}/${fecha.year}';

  /// Retorna la hora del registro (HH:MM).
  String get horaFormateada =>
      '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

  /// Combinación de fecha y hora para encabezados de detalle.
  String get fechaHoraCompleta => '$fechaFormateada $horaFormateada';

  /// Color semántico basado en el estado del registro.
  Color get estadoColor {
    switch (estado) {
      case 'FINALIZADO':
        return Colors.green;
      case 'EN_PROCESO':
        return Colors.orange;
      case 'PENDIENTE':
        return Colors.blueGrey;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  /// Iconografía representativa para listas de avances.
  IconData get estadoIcon {
    switch (estado) {
      case 'FINALIZADO':
        return Icons.task_alt;
      case 'EN_PROCESO':
        return Icons.history_edu;
      case 'PENDIENTE':
        return Icons.more_time;
      case 'CANCELADO':
        return Icons.block;
      default:
        return Icons.edit_note;
    }
  }

  /// Texto descriptivo del estado para la interfaz.
  String get estadoTexto {
    switch (estado) {
      case 'FINALIZADO':
        return 'Finalizado';
      case 'EN_PROCESO':
        return 'En proceso';
      case 'PENDIENTE':
        return 'Pendiente';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return 'Registrado';
    }
  }

  // --- Validaciones y Etiquetas ---
  bool get tieneEvidencia => evidenciaFoto != null && evidenciaFoto!.isNotEmpty;

  bool get tieneDescripcion => descripcion != null && descripcion!.trim().isNotEmpty;

  bool get tieneHorasTrabajadas => (horasTrabajadas ?? 0) > 0;

  String get porcentajeTexto => '${porcentajeEjecutado.toStringAsFixed(1)}%';

  String? get horasTexto => (horasTrabajadas ?? 0) > 0
      ? '${horasTrabajadas!.toStringAsFixed(1)} h'
      : null;

  // --- Operaciones de Modelo ---
  /// Genera una copia del objeto para cambios inmutables.
  Avance copyWith({
    int? idAvance,
    int? idObra,
    int? idActividad,
    DateTime? fecha,
    double? horasTrabajadas,
    String? descripcion,
    String? evidenciaFoto,
    String? estado,
    int? sincronizado,
    double? porcentajeEjecutado,
    String? nombreActividad,
  }) {
    return Avance(
      idAvance: idAvance ?? this.idAvance,
      idObra: idObra ?? this.idObra,
      idActividad: idActividad ?? this.idActividad,
      fecha: fecha ?? this.fecha,
      horasTrabajadas: horasTrabajadas ?? this.horasTrabajadas,
      descripcion: descripcion ?? this.descripcion,
      evidenciaFoto: evidenciaFoto ?? this.evidenciaFoto,
      estado: estado ?? this.estado,
      sincronizado: sincronizado ?? this.sincronizado,
      porcentajeEjecutado: porcentajeEjecutado ?? this.porcentajeEjecutado,
      nombreActividad: nombreActividad ?? this.nombreActividad,
    );
  }
}
