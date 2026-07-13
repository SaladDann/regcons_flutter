import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // Flutter procesará esto para validar cadenas

// Función que emula el comportamiento criptográfico de REGCONS
String generarHashSeguro(String password, String salt) {
  final bytes = utf8.encode(password + salt);
  return sha256.convert(bytes).toString();
}

void main() {
  group('Pruebas de Blindaje Criptográfico - REGCONS', () {
    test('Validación de consistencia en Hash SHA-256', () {
      const contrasenaObra = "ClaveInspector2026";
      const saltDinamico = "regcons_salt_xyz";

      final hashUno = generarHashSeguro(contrasenaObra, saltDinamico);
      final hashDos = generarHashSeguro(contrasenaObra, saltDinamico);

      // Verificaciones estrictas
      expect(hashUno, equals(hashDos)); // El resultado debe ser idéntico
      expect(hashUno.length, 64);       // Debe cumplir con los 64 caracteres de SHA-256
    });

    test('Validación de alteración por Salt Dinámico', () {
      const contrasenaObra = "ClaveInspector2026";

      final hashAlfa = generarHashSeguro(contrasenaObra, "salt_A");
      final hashBeta = generarHashSeguro(contrasenaObra, "salt_B");

      expect(hashAlfa, isNot(equals(hashBeta))); // Salts distintos deben dar hashes distintos
    });
  });
}
