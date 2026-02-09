import 'package:flutter/material.dart';

/// Representa un proyecto de construcción (Obra) en el sistema.
/// Centraliza la información contractual, cronológica y de presupuesto.
class Obra {
  int? idObra;
  String nombre;
  String? descripcion;
  String? direccion;
  String? cliente;
  DateTime? fechaInicio;
  DateTime? fechaFin;
  double? presupuesto;
  String estado;
  double? porcentajeAvance;

  Obra({
    this.idObra,
    required this.nombre,
    this.descripcion,
    this.direccion,
    this.cliente,
    this.fechaInicio,
    this.fechaFin,
    this.presupuesto,
    required this.estado,
    this.porcentajeAvance = 0.0,
  });

  /// Reconstruye la Obra desde la base de datos con casting de tipos seguro.
  factory Obra.fromMap(Map<String, dynamic> map) {
    return Obra(
      idObra: map['id_obra'] as int?,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      direccion: map['direccion'] as String?,
      cliente: map['cliente'] as String?,
      fechaInicio: map['fecha_inicio'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fecha_inicio'] as int)
          : null,
      fechaFin: map['fecha_fin'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fecha_fin'] as int)
          : null,
      presupuesto: (map['presupuesto'] as num?)?.toDouble(),
      estado: (map['estado'] as String?) ?? 'PLANIFICADA',
    );
  }

  /// Serializa la Obra para persistencia en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id_obra': idObra,
      'nombre': nombre,
      'descripcion': descripcion,
      'direccion': direccion,
      'cliente': cliente,
      'fecha_inicio': fechaInicio?.millisecondsSinceEpoch,
      'fecha_fin': fechaFin?.millisecondsSinceEpoch,
      'presupuesto': presupuesto,
      'estado': estado,
    };
  }

  // --- Getters de Formato ---

  /// Retorna la fecha de inicio formateada para etiquetas de UI.
  String get fechaInicioFormatted {
    if (fechaInicio == null) return 'No definida';
    return '${fechaInicio!.day.toString().padLeft(2, '0')}/${fechaInicio!.month.toString().padLeft(2, '0')}/${fechaInicio!.year}';
  }

  /// Retorna la fecha estimada de finalización formateada.
  String get fechaFinFormatted {
    if (fechaFin == null) return 'No definida';
    return '${fechaFin!.day.toString().padLeft(2, '0')}/${fechaFin!.month.toString().padLeft(2, '0')}/${fechaFin!.year}';
  }

  /// Formatea el presupuesto en una cadena de moneda simple.
  String get presupuestoFormatted {
    if (presupuesto == null) return '\$0.00';
    return '\$${presupuesto!.toStringAsFixed(2)}';
  }

  // --- Estética de Interfaz ---

  /// Color semántico según el estado operativo de la obra.
  Color get estadoColor {
    switch (estado) {
      case 'ACTIVA':
        return Colors.green;
      case 'PLANIFICADA':
        return Colors.blueGrey;
      case 'SUSPENDIDA':
        return Colors.orange;
      case 'FINALIZADA':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  /// Icono representativo para el estado actual.
  IconData get estadoIcon {
    switch (estado) {
      case 'ACTIVA':
        return Icons.rocket_launch_outlined;
      case 'PLANIFICADA':
        return Icons.event_note_outlined;
      case 'SUSPENDIDA':
        return Icons.pause_circle_outline;
      case 'FINALIZADA':
        return Icons.verified_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
