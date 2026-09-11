import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart'
    show HMac, InvalidCipherTextException, PBKDF2KeyDerivator, Pbkdf2Parameters,
        SHA256Digest;

import '../errors/app_exception.dart';

/// Password-based encryption for anything that leaves the device.
///
/// A user password is not a key, so it is stretched with PBKDF2-HMAC-SHA256
/// over a random salt before being used with AES-256-GCM. GCM authenticates the
/// ciphertext, so a wrong password or a tampered file fails loudly instead of
/// producing garbage.
class CryptoService {
  CryptoService({Random? random, int? iterations})
    : _random = random ?? Random.secure(),
      _iterations = iterations ?? defaultIterations;

  /// Identifies our own files so an unrelated JSON is rejected early.
  static const String formatMarker = 'werewolf-narrator-export';
  static const int formatVersion = 1;
  static const int defaultIterations = 150000;
  static const String kdfAlgorithm = 'PBKDF2-HMAC-SHA256';

  /// Marks an envelope sealed with the device key itself, with nothing to
  /// stretch: the automatic snapshots never involve a password.
  static const String deviceKeyAlgorithm = 'device-key';
  static const String cipherAlgorithm = 'AES-256-GCM';
  static const int saltLength = 16;

  /// 96 bits: the nonce size GCM is specified for.
  static const int nonceLength = 12;
  static const int keyLength = 32;

  final Random _random;
  final int _iterations;

  /// Encrypts [plaintext] and returns the self-describing envelope, as JSON.
  String encrypt({required String plaintext, required String password}) {
    if (password.isEmpty) {
      throw const ValidationException('Le mot de passe est obligatoire.');
    }
    try {
      final salt = _randomBytes(saltLength);
      final nonce = _randomBytes(nonceLength);
      final key = deriveKey(
        password: password,
        salt: salt,
        iterations: _iterations,
      );

      final encrypter = Encrypter(AES(Key(key), mode: AESMode.gcm));
      final encrypted = encrypter.encryptBytes(
        utf8.encode(plaintext),
        iv: IV(nonce),
        associatedData: _associatedData(
          version: formatVersion,
          kdfAlgorithm: kdfAlgorithm,
          iterations: _iterations,
          salt: base64Encode(salt),
          cipherAlgorithm: cipherAlgorithm,
          nonce: base64Encode(nonce),
        ),
      );

      return jsonEncode({
        'format': formatMarker,
        'version': formatVersion,
        'kdf': {
          'algorithm': kdfAlgorithm,
          'iterations': _iterations,
          'salt': base64Encode(salt),
        },
        'cipher': {
          'algorithm': cipherAlgorithm,
          'nonce': base64Encode(nonce),
        },
        'payload': encrypted.base64,
      });
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw ExportException(
        'Le chiffrement de la partie a échoué.',
        cause: error,
      );
    }
  }

  /// Encrypts [plaintext] under a key the app already holds — the database key
  /// from the platform keystore.
  ///
  /// Used for the automatic snapshots, which must be written without asking
  /// the narrator for anything. There is no password to stretch, so the
  /// envelope declares [deviceKeyAlgorithm] and carries no salt: it can only
  /// be opened on this device, by this install.
  String encryptWithKey({
    required String plaintext,
    required Uint8List key,
  }) {
    if (key.length != keyLength) {
      throw const ExportException('La clé de chiffrement est invalide.');
    }
    try {
      final nonce = _randomBytes(nonceLength);
      final encrypter = Encrypter(AES(Key(key), mode: AESMode.gcm));
      final encrypted = encrypter.encryptBytes(
        utf8.encode(plaintext),
        iv: IV(nonce),
        associatedData: _associatedData(
          version: formatVersion,
          kdfAlgorithm: deviceKeyAlgorithm,
          iterations: 0,
          salt: '',
          cipherAlgorithm: cipherAlgorithm,
          nonce: base64Encode(nonce),
        ),
      );

      return jsonEncode({
        'format': formatMarker,
        'version': formatVersion,
        'kdf': {'algorithm': deviceKeyAlgorithm, 'iterations': 0, 'salt': ''},
        'cipher': {'algorithm': cipherAlgorithm, 'nonce': base64Encode(nonce)},
        'payload': encrypted.base64,
      });
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw ExportException(
        'Le chiffrement de la sauvegarde a échoué.',
        cause: error,
      );
    }
  }

  /// Reverses [encryptWithKey].
  String decryptWithKey({
    required String envelopeJson,
    required Uint8List key,
  }) {
    final envelope = _readEnvelope(envelopeJson);
    final kdf = envelope['kdf'] as Map<String, dynamic>?;
    if (kdf == null || kdf['algorithm'] != deviceKeyAlgorithm) {
      throw const ImportException(
        'Cette sauvegarde attend un mot de passe : ouvrez-la par l\'import.',
      );
    }

    try {
      final cipher = envelope['cipher'] as Map<String, dynamic>;
      final nonce = cipher['nonce'] as String;
      final encrypter = Encrypter(AES(Key(key), mode: AESMode.gcm));
      final plain = encrypter.decryptBytes(
        Encrypted.fromBase64(envelope['payload'] as String),
        iv: IV(base64Decode(nonce)),
        associatedData: _associatedData(
          version: envelope['version'] as int,
          kdfAlgorithm: deviceKeyAlgorithm,
          iterations: 0,
          salt: '',
          cipherAlgorithm: cipher['algorithm'] as String,
          nonce: nonce,
        ),
      );
      return utf8.decode(plain);
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw ImportException(
        'Cette sauvegarde est illisible sur cet appareil.',
        cause: error,
      );
    }
  }

  /// Reverses [encrypt]. Throws [ImportException] on a wrong password, a
  /// tampered payload or a file that is not one of ours.
  String decrypt({required String envelopeJson, required String password}) {
    if (password.isEmpty) {
      throw const ValidationException('Le mot de passe est obligatoire.');
    }

    final envelope = _readEnvelope(envelopeJson);
    final kdfAlgorithmUsed =
        (envelope['kdf'] as Map<String, dynamic>?)?['algorithm'];
    if (kdfAlgorithmUsed == deviceKeyAlgorithm) {
      throw const ImportException(
        'Cette sauvegarde automatique n\'a pas de mot de passe : '
        'restaurez-la depuis les instantanés de secours.',
      );
    }

    try {
      final kdf = envelope['kdf'] as Map<String, dynamic>;
      final cipher = envelope['cipher'] as Map<String, dynamic>;
      final salt = kdf['salt'] as String;
      final nonce = cipher['nonce'] as String;
      final key = deriveKey(
        password: password,
        salt: base64Decode(salt),
        iterations: kdf['iterations'] as int,
      );

      final encrypter = Encrypter(AES(Key(key), mode: AESMode.gcm));
      final plain = encrypter.decryptBytes(
        Encrypted.fromBase64(envelope['payload'] as String),
        iv: IV(base64Decode(nonce)),
        associatedData: _associatedData(
          version: envelope['version'] as int,
          kdfAlgorithm: kdf['algorithm'] as String,
          iterations: kdf['iterations'] as int,
          salt: salt,
          cipherAlgorithm: cipher['algorithm'] as String,
          nonce: nonce,
        ),
      );
      return utf8.decode(plain);
    } on InvalidCipherTextException catch (error) {
      throw ImportException(
        'Mot de passe incorrect, ou fichier abîmé.',
        cause: error,
      );
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw ImportException(
        'Mot de passe incorrect, ou fichier abîmé.',
        cause: error,
      );
    }
  }

  /// Parses the envelope and checks it is one of ours, before any key is
  /// derived — shared by both ways of opening a file.
  Map<String, dynamic> _readEnvelope(String envelopeJson) {
    final Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(envelopeJson);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      envelope = decoded;
    } on FormatException catch (error) {
      throw ImportException(
        "Ce fichier n'est pas un export Werewolf Narrator.",
        cause: error,
      );
    }

    if (envelope['format'] != formatMarker) {
      throw const ImportException(
        "Ce fichier n'est pas un export Werewolf Narrator.",
      );
    }
    if (envelope['version'] is! int ||
        (envelope['version'] as int) > formatVersion) {
      throw const ImportException(
        'Cet export vient d\'une version plus récente de l\'application.',
      );
    }
    return envelope;
  }

  /// Canonical rendering of the header, fed to GCM as additional authenticated
  /// data. The tag then covers the whole envelope, so weakening a field — the
  /// iteration count, say — makes decryption fail instead of silently
  /// downgrading the protection.
  ///
  /// Built from the fields themselves rather than from the JSON text, so
  /// reformatting or reordering the file does not break a legitimate import.
  static Uint8List _associatedData({
    required int version,
    required String kdfAlgorithm,
    required int iterations,
    required String salt,
    required String cipherAlgorithm,
    required String nonce,
  }) {
    return Uint8List.fromList(
      utf8.encode(
        [
          formatMarker,
          version,
          kdfAlgorithm,
          iterations,
          salt,
          cipherAlgorithm,
          nonce,
        ].join('|'),
      ),
    );
  }

  static Uint8List deriveKey({
    required String password,
    required Uint8List salt,
    required int iterations,
  }) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, keyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }
}
