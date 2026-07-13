import 'package:flutter/material.dart';

/// Representa una tarea específica dentro de un proyecto de construcción.
/// Gestiona el ciclo de vida de la actividad y su representación visual en la UI.
class Actividad {
  int? idActividad;
  int idObra;
  String nombre;
  String? descripcion;
  String estado;
  double porcentajeCompletado;

  Actividad({
    this.idActividad,
    required this.idObra,
    required this.nombre,
    this.descripcion,
    this.estado = 'PENDIENTE',
    this.porcentajeCompletado = 0,
  });

  /// Reconstruye la actividad desde un mapa de BD asegurando tipos de datos correctos.
  factory Actividad.fromMap(Map<String, dynamic> map) {
    return Actividad(
      idActividad: map['id_actividad'] as int?,
      idObra: map['id_obra'] as int,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      estado: (map['estado'] as String?) ?? 'PENDIENTE',
    );
  }

  /// Serializa los datos reales de la entidad para almacenamiento local.
  Map<String, dynamic> toMap() {
    return {
      'id_actividad': idActividad,
      'id_obra': idObra,
      'nombre': nombre,
      'descripcion': descripcion,
      'estado': estado,
    };
  }

  // --- Atributos Dinámicos para UI ---

  /// Retorna el color temático según el estado actual de la tarea.
  Color get estadoColor {
    switch (estado) {
      case 'COMPLETADA':
        return Colors.green;
      case 'EN_PROGRESO':
        return Colors.orange;
      case 'PENDIENTE':
        return Colors.blueGrey;
      case 'ATRASADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Retorna el icono representativo para indicadores visuales.
  IconData get estadoIcon {
    switch (estado) {
      case 'COMPLETADA':
        return Icons.check_circle_outline;
      case 'EN_PROGRESO':
        return Icons.pending_actions;
      case 'PENDIENTE':
        return Icons.hourglass_empty;
      case 'ATRASADA':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  /// Versión amigable para el usuario del estado técnico.
  String get estadoTexto {
    switch (estado) {
      case 'COMPLETADA':
        return 'Finalizada';
      case 'EN_PROGRESO':
        return 'En ejecución';
      case 'PENDIENTE':
        return 'Por iniciar';
      case 'ATRASADA':
        return 'Con retraso';
      default:
        return estado;
    }
  }

  /// Formatea el progreso numérico para etiquetas de texto.
  String get progresoLabel => '${porcentajeCompletado.toStringAsFixed(0)}%';

  // --- Lógica de Negocio y Validación ---
  /// Permite crear copias del objeto con modificaciones específicas (Inmutabilidad parcial).
  Actividad copyWith({
    int? idActividad,
    int? idObra,
    String? nombre,
    String? descripcion,
    String? estado,
    double? porcentajeCompletado,
  }) {
    return Actividad(
      idActividad: idActividad ?? this.idActividad,
      idObra: idObra ?? this.idObra,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      porcentajeCompletado: porcentajeCompletado ?? this.porcentajeCompletado,
    );
  }

  /// Realiza una verificación de integridad antes de intentar la persistencia.
  List<String> validar() {
    final errores = <String>[];
    if (nombre.trim().isEmpty) errores.add('El nombre no puede estar vacío');
    if (idObra <= 0) errores.add('Vínculo de obra inválido');
    return errores;
  }
}
