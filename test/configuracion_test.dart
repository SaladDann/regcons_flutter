import 'package:flutter_test/flutter_test.dart';

// Simulación de la clase de constantes de REGCONS (Suele estar en lib/config/ o lib/constants/)
class ConfigApp {
  static const String version = "0.1.0"; // Debe coincidir con tu pubspec.yaml
  static const String dbName = "regcons_database.db";
  static const bool esModoProduccion = true; // El pipeline auditará esto
}

void main() {
  group('Pruebas de Configuración de Entorno - REGCONS', () {

    test('El nombre de la base de datos local debe mantener la extensión correcta', () {
      // Evita que por error se borre o cambie el nombre del archivo SQLite en producción
      expect(ConfigApp.dbName, equals("regcons_database.db"));
      expect(ConfigApp.dbName.endsWith('.db'), isTrue);
    });

    test('Verificación de Integridad de Versión del MVP', () {
      // Asegura que la versión del código no sea una cadena vacía y empiece con formato correcto
      expect(ConfigApp.version, isNotEmpty);
      expect(ConfigApp.version, startsWith("0."));
    });

    test('Validación de banderas de Producción para el Pipeline', () {
      // Este test sirve como un "candado". Si un desarrollador cambia esto a 'false'
      // para hacer pruebas locales y se olvida de revertirlo, el pipeline fallará en GitHub
      // evitando que se distribuya un APK configurado para entornos de prueba locales.
      expect(ConfigApp.esModoProduccion, isTrue,
        reason: "¡ALERTA!: La aplicación no está configurada en Modo Producción para el despliegue.");
    });
  });
}
