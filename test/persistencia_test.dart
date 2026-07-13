import 'package:flutter_test/flutter_test.dart';

// Simulación de un Modelo de Datos para REGCONS (Control de Incidentes en Obra)
class ReporteIncidente {
  final int? id;
  final String descripcion;
  final String nivelSeveridad; // Alta, Media, Baja
  final String rutaFotografia;

  ReporteIncidente({
    this.id,
    required this.descripcion,
    required this.nivelSeveridad,
    required this.rutaFotografia,
  });

  // Convierte el objeto a un Mapa (formato requerido por sqflite para guardar en el celular)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'descripcion': descripcion,
      'nivel_severidad': nivelSeveridad,
      'ruta_fotografia': rutaFotografia,
    };
  }

  // Reconstruye el objeto desde los datos guardados en SQLite
  factory ReporteIncidente.fromMap(Map<String, dynamic> map) {
    return ReporteIncidente(
      id: map['id'] as int?,
      descripcion: map['descripcion'] as String,
      nivelSeveridad: map['nivel_severidad'] as String,
      rutaFotografia: map['ruta_fotografia'] as String,
    );
  }
}

void main() {
  group('Pruebas de Persistencia y Modelos SQLite - REGCONS', () {

    test('El modelo de incidente debe convertirse a un Mapa correctamente para SQLite', () {
      final incidente = ReporteIncidente(
        id: 1,
        descripcion: "Falta de arnés en zona de andamios",
        nivelSeveridad: "ALTA",
        rutaFotografia: "/storage/emulated/0/DCIM/evidencia_01.jpg",
      );

      final mapaResultado = incidente.toMap();

      // Verificaciones de estructura
      expect(mapaResultado['id'], equals(1));
      expect(mapaResultado['descripcion'], equals("Falta de arnés en zona de andamios"));
      expect(mapaResultado['nivel_severidad'], equals("ALTA"));
      expect(mapaResultado['ruta_fotografia'], contains("evidencia_01.jpg"));
    });

    test('El modelo debe reconstruirse fielmente desde un registro de la Base de Datos', () {
      // Simulamos lo que nos devolvería una consulta SQLite de la tabla de REGCONS
      final Map<String, dynamic> registroBaseDatos = {
        'id': 25,
        'descripcion': 'Escombro obstruyendo salida de emergencia',
        'nivel_severidad': 'MEDIA',
        'ruta_fotografia': '/data/user/0/regcons/files/img_db_25.png'
      };

      final incidenteReconstruido = ReporteIncidente.fromMap(registroBaseDatos);

      expect(incidenteReconstruido.id, equals(25));
      expect(incidenteReconstruido.nivelSeveridad, equals("MEDIA"));
      expect(incidenteReconstruido.descripcion, isNotEmpty);
    });
  });
}
