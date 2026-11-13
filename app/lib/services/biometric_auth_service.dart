import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Check if device supports biometric hardware
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate user via fingerprint or facial recognition
  Future<bool> authenticate({String reason = 'Please authenticate to unlock chats'}) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        // If device has no biometrics, allow PIN fallback or pass
        return true;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Fallback to device PIN/Pattern
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Store master database key in secure enclave
  Future<void> saveDatabaseKey(String key) async {
    await _secureStorage.write(key: 'db_master_key', value: key);
  }

  /// Retrieve master database key
  Future<String?> getDatabaseKey() async {
    return await _secureStorage.read(key: 'db_master_key');
  }
}
