import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/app_exception.dart';

/// Provides the 256-bit key used to encrypt the local SQLCipher database.
///
/// The key never leaves the device and is never written anywhere except the
/// platform keystore.
abstract interface class DatabaseKeyStore {
  /// Returns the database key as a lowercase hex string (64 characters).
  ///
  /// Generates and persists a new random key on first launch.
  Future<String> readOrCreateKey();

  /// Removes the stored key. The database becomes permanently unreadable.
  Future<void> deleteKey();
}

/// [DatabaseKeyStore] backed by Android Keystore / iOS Keychain.
class SecureStorageKeyStore implements DatabaseKeyStore {
  SecureStorageKeyStore({FlutterSecureStorage? storage, Random? random})
    : _storage = storage ?? const FlutterSecureStorage(),
      _random = random ?? Random.secure();

  /// Versioned so a future key-rotation scheme can coexist with this one.
  static const String storageKeyName = 'wn_database_key_v1';

  /// 32 bytes = AES-256, the key size SQLCipher derives its page keys from.
  static const int keyLengthInBytes = 32;

  final FlutterSecureStorage _storage;
  final Random _random;

  @override
  Future<String> readOrCreateKey() async {
    try {
      final existing = await _storage.read(key: storageKeyName);
      if (existing != null && _isValidKey(existing)) {
        return existing;
      }
      final generated = _generateKey();
      await _storage.write(key: storageKeyName, value: generated);
      return generated;
    } on Object catch (error) {
      // Deliberately does not include `error` in the message: platform
      // exceptions from secure storage can echo back the value being written.
      throw KeyStoreException(
        "Impossible d'accéder au coffre-fort sécurisé de l'appareil.",
        cause: error,
      );
    }
  }

  @override
  Future<void> deleteKey() async {
    try {
      await _storage.delete(key: storageKeyName);
    } on Object catch (error) {
      throw KeyStoreException(
        'Impossible de supprimer la clé de chiffrement.',
        cause: error,
      );
    }
  }

  String _generateKey() {
    final buffer = StringBuffer();
    for (var i = 0; i < keyLengthInBytes; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static bool _isValidKey(String value) =>
      value.length == keyLengthInBytes * 2 &&
      RegExp(r'^[0-9a-f]+$').hasMatch(value);
}
