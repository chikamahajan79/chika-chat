import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class MediaCipherService {
  final AesGcm _algorithm = AesGcm.with256Bits();

  /// Generates a random 256-bit symmetric key for media encryption
  Future<SecretKey> generateMediaKey() async {
    return await _algorithm.newSecretKey();
  }

  /// Encrypts raw media bytes using AES-256-GCM
  /// Returns a map with ciphertext, nonce (IV), and MAC tag
  Future<Map<String, dynamic>> encryptMedia(Uint8List plainBytes, SecretKey key) async {
    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(
      plainBytes,
      secretKey: key,
      nonce: nonce,
    );

    final keyBytes = await key.extractBytes();

    return {
      'cipherText': secretBox.cipherText,
      'nonce': nonce,
      'mac': secretBox.mac.bytes,
      'keyHex': base64Encode(keyBytes),
      'nonceHex': base64Encode(nonce),
      'macHex': base64Encode(secretBox.mac.bytes),
    };
  }

  /// Decrypts encrypted media bytes using the provided key, nonce, and MAC tag
  Future<Uint8List> decryptMedia({
    required Uint8List cipherText,
    required String keyHex,
    required String nonceHex,
    required String macHex,
  }) async {
    final keyBytes = base64Decode(keyHex);
    final nonceBytes = base64Decode(nonceHex);
    final macBytes = base64Decode(macHex);

    final secretKey = SecretKey(keyBytes);
    final secretBox = SecretBox(
      cipherText,
      nonce: nonceBytes,
      mac: Mac(macBytes),
    );

    final decryptedBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return Uint8List.fromList(decryptedBytes);
  }
}
