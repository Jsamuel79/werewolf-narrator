import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the promise that the shipped app cannot talk to the network.
///
/// This is checked against the source tree rather than at runtime, because the
/// only reliable way to prevent network access on Android is to not ask for the
/// permission in the first place.
void main() {
  test('the release Android manifest declares no INTERNET permission', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      isNot(contains('android.permission.INTERNET')),
      reason: 'the app must stay offline-only',
    );
  });

  test('debug tooling keeps its own manifest, separate from release', () {
    // Hot reload needs the permission, but only in debug/profile builds.
    for (final flavour in ['debug', 'profile']) {
      final file = File('android/app/src/$flavour/AndroidManifest.xml');
      expect(file.existsSync(), isTrue, reason: flavour);
      expect(
        file.readAsStringSync(),
        contains('android.permission.INTERNET'),
        reason: flavour,
      );
    }
  });

  test('no source file opens a socket or an HTTP client', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      final source = entity.readAsStringSync();
      final hasNetworkCall =
          source.contains('HttpClient(') ||
          source.contains('Socket.connect') ||
          source.contains('WebSocket.connect') ||
          source.contains("import 'package:http/");
      if (hasNetworkCall) offenders.add(entity.path);
    }

    expect(offenders, isEmpty);
  });
}
