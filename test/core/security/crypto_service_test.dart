import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/core/errors/app_exception.dart';
import 'package:werewolf_narrator/core/security/crypto_service.dart';

void main() {
  // Fewer rounds keeps the suite fast; the production default is exercised by
  // the dedicated test at the bottom.
  final service = CryptoService(iterations: 1000);

  group('round trip', () {
    test('decrypts back to the original text', () {
      const plaintext = 'Alice est Voyante, Bob est Loup-Garou.';
      final envelope = service.encrypt(
        plaintext: plaintext,
        password: 'motdepasse',
      );

      expect(
        service.decrypt(envelopeJson: envelope, password: 'motdepasse'),
        plaintext,
      );
    });

    test('survives accents and emoji', () {
      const plaintext = 'Chloé 🐺 — « dévorée » à la nuit 2';
      final envelope = service.encrypt(plaintext: plaintext, password: 'pw123');
      expect(
        service.decrypt(envelopeJson: envelope, password: 'pw123'),
        plaintext,
      );
    });

    test('never leaks the plaintext into the envelope', () {
      final envelope = service.encrypt(
        plaintext: 'CONFIDENTIAL_MARKER',
        password: 'motdepasse',
      );
      expect(envelope, isNot(contains('CONFIDENTIAL_MARKER')));
      expect(envelope, isNot(contains('motdepasse')));
    });

    test('two exports of the same text differ', () {
      final first = service.encrypt(plaintext: 'x', password: 'pw');
      final second = service.encrypt(plaintext: 'x', password: 'pw');
      expect(first, isNot(second), reason: 'salt and nonce must be random');
    });
  });

  group('envelope shape', () {
    test('declares its format, KDF and cipher', () {
      final envelope =
          jsonDecode(service.encrypt(plaintext: 'x', password: 'pw'))
              as Map<String, dynamic>;

      expect(envelope['format'], CryptoService.formatMarker);
      expect(envelope['version'], CryptoService.formatVersion);
      expect(envelope['kdf']['algorithm'], 'PBKDF2-HMAC-SHA256');
      expect(envelope['kdf']['iterations'], 1000);
      expect(envelope['cipher']['algorithm'], 'AES-256-GCM');
      expect(
        base64Decode(envelope['kdf']['salt'] as String),
        hasLength(CryptoService.saltLength),
      );
      expect(
        base64Decode(envelope['cipher']['nonce'] as String),
        hasLength(CryptoService.nonceLength),
      );
    });
  });

  group('failures', () {
    test('a wrong password is rejected, not silently mangled', () {
      final envelope = service.encrypt(plaintext: 'secret', password: 'good');
      expect(
        () => service.decrypt(envelopeJson: envelope, password: 'bad'),
        throwsA(isA<ImportException>()),
      );
    });

    test('a tampered payload is rejected by the GCM tag', () {
      final envelope =
          jsonDecode(service.encrypt(plaintext: 'secret', password: 'pw'))
              as Map<String, dynamic>;
      final payload = base64Decode(envelope['payload'] as String);
      payload[0] = payload[0] ^ 0xff;
      envelope['payload'] = base64Encode(payload);

      expect(
        () => service.decrypt(
          envelopeJson: jsonEncode(envelope),
          password: 'pw',
        ),
        throwsA(isA<ImportException>()),
      );
    });

    test('a downgraded KDF header is rejected', () {
      final envelope =
          jsonDecode(service.encrypt(plaintext: 'secret', password: 'pw'))
              as Map<String, dynamic>;
      // The header is bound into the tag, so weakening it breaks decryption.
      envelope['version'] = 0;

      expect(
        () => service.decrypt(
          envelopeJson: jsonEncode(envelope),
          password: 'pw',
        ),
        throwsA(isA<ImportException>()),
      );
    });

    test('a foreign JSON file is rejected with a clear message', () {
      expect(
        () => service.decrypt(
          envelopeJson: '{"hello": "world"}',
          password: 'pw',
        ),
        throwsA(
          isA<ImportException>().having(
            (e) => e.message,
            'message',
            contains('Werewolf Narrator'),
          ),
        ),
      );
    });

    test('a file from a newer format version is rejected', () {
      final envelope =
          jsonDecode(service.encrypt(plaintext: 'x', password: 'pw'))
              as Map<String, dynamic>;
      envelope['version'] = CryptoService.formatVersion + 1;

      expect(
        () => service.decrypt(
          envelopeJson: jsonEncode(envelope),
          password: 'pw',
        ),
        throwsA(
          isA<ImportException>().having(
            (e) => e.message,
            'message',
            contains('plus récente'),
          ),
        ),
      );
    });

    test('garbage input is rejected', () {
      expect(
        () => service.decrypt(envelopeJson: 'not json', password: 'pw'),
        throwsA(isA<ImportException>()),
      );
    });

    test('an empty password is refused on both sides', () {
      expect(
        () => service.encrypt(plaintext: 'x', password: ''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => service.decrypt(envelopeJson: '{}', password: ''),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  test('the production KDF setting round-trips', () {
    final strong = CryptoService();
    final envelope = strong.encrypt(plaintext: 'x', password: 'motdepasse');
    expect(
      jsonDecode(envelope)['kdf']['iterations'],
      CryptoService.defaultIterations,
    );
    expect(
      strong.decrypt(envelopeJson: envelope, password: 'motdepasse'),
      'x',
    );
  });
}
