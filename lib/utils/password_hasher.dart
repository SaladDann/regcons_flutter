import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Proveedor de utilidades criptográficas para el manejo de credenciales y tokens de sesión
class PasswordHasher {

  /// Genera una sal (salt) aleatoria de 32 bytes codificada en Base64
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Crea un hash SHA-256 combinando la contraseña en texto plano con su sal respectiva
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  /// Compara una contraseña ingresada contra un hash almacenado utilizando la sal original
  static bool verifyPassword(
      String inputPassword,
      String storedHash,
      String storedSalt,
      ) {
    final hash = hashPassword(inputPassword, storedSalt);
    return hash == storedHash;
  }

  /// Genera un token de sesión seguro de 64 bytes utilizando codificación Base64 URL-safe
  static String generateSessionToken() {
    final random = Random.secure();
    final tokenBytes = List<int>.generate(64, (_) => random.nextInt(256));
    return base64UrlEncode(tokenBytes);
  }
}