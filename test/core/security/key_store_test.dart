import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:werewolf_narrator/core/errors/app_exception.dart';
import 'package:werewolf_narrator/core/security/key_store.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// Deterministic stand-in for `Random.secure()` so the generated key is
/// predictable inside the test.
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final int value;

  @override
  int nextInt(int max) => value % max;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  late _MockSecureStorage storage;

  setUp(() {
    storage = _MockSecureStorage();
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
  });

  group('SecureStorageKeyStore', () {
    test('generates and persists a 256-bit key on first launch', () async {
      when(
        () => storage.read(key: SecureStorageKeyStore.storageKeyName),
      ).thenAnswer((_) async => null);

      final keyStore = SecureStorageKeyStore(
        storage: storage,
        random: _FixedRandom(0xab),
      );
      final key = await keyStore.readOrCreateKey();

      expect(key, 'ab' * SecureStorageKeyStore.keyLengthInBytes);
      expect(key.length, 64, reason: '32 bytes rendered as hex');
      verify(
        () => storage.write(
          key: SecureStorageKeyStore.storageKeyName,
          value: key,
        ),
      ).called(1);
    });

    test('returns the stored key without rewriting it', () async {
      final stored = 'cd' * 32;
      when(
        () => storage.read(key: SecureStorageKeyStore.storageKeyName),
      ).thenAnswer((_) async => stored);

      final keyStore = SecureStorageKeyStore(storage: storage);

      expect(await keyStore.readOrCreateKey(), stored);
      verifyNever(
        () => storage.write(key: any(named: 'key'), value: any(named: 'value')),
      );
    });

    test('replaces a corrupted stored value with a fresh key', () async {
      when(
        () => storage.read(key: SecureStorageKeyStore.storageKeyName),
      ).thenAnswer((_) async => 'not-a-valid-hex-key');

      final keyStore = SecureStorageKeyStore(
        storage: storage,
        random: _FixedRandom(0x01),
      );
      final key = await keyStore.readOrCreateKey();

      expect(key, '01' * 32);
      verify(
        () => storage.write(
          key: SecureStorageKeyStore.storageKeyName,
          value: key,
        ),
      ).called(1);
    });

    test('produces a different key on every generation', () async {
      when(
        () => storage.read(key: SecureStorageKeyStore.storageKeyName),
      ).thenAnswer((_) async => null);

      final keyStore = SecureStorageKeyStore(storage: storage);
      final first = await keyStore.readOrCreateKey();
      final second = await keyStore.readOrCreateKey();

      expect(first, isNot(second));
    });

    test('wraps platform failures without leaking the key material', () async {
      when(
        () => storage.read(key: SecureStorageKeyStore.storageKeyName),
      ).thenThrow(Exception('keystore unavailable: secret=abcdef'));

      final keyStore = SecureStorageKeyStore(storage: storage);

      await expectLater(
        keyStore.readOrCreateKey(),
        throwsA(
          isA<KeyStoreException>().having(
            (e) => e.message,
            'message',
            isNot(contains('abcdef')),
          ),
        ),
      );
    });

    test('deleteKey removes the entry', () async {
      final keyStore = SecureStorageKeyStore(storage: storage);
      await keyStore.deleteKey();
      verify(
        () => storage.delete(key: SecureStorageKeyStore.storageKeyName),
      ).called(1);
    });
  });
}
