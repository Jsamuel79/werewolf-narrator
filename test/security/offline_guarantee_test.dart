import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the promise that the shipped app cannot talk to the network.
///
/// This is checked against the source tree rather than at runtime, because the
/// only reliable way to prevent network access on Android is to not ask for the
/// permission in the first place.
/// Every package the app is allowed to ship with.
///
/// The V2 added a swipeable card deck, a debate stopwatch and a haptic/audio
/// cue, all of them built on the SDK: this list must therefore be exactly the
/// one 1.0.0 shipped. Adding a package is a deliberate act that has to update
/// this test — and justify itself against the offline promise.
const Set<String> allowedRuntimeDependencies = {
  'flutter',
  'flutter_localizations',
  'cupertino_icons',
  'flutter_riverpod',
  'drift',
  'sqlite3',
  'flutter_secure_storage',
  'encrypt',
  'pointycastle',
  'crypto',
  'share_plus',
  'file_picker',
  'uuid',
  'path_provider',
  'path',
  'intl',
};

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

  test('the app ships no runtime dependency outside the audited list', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final declared = <String>{};
    var inDependencies = false;

    for (final line in pubspec) {
      if (line.startsWith('dependencies:')) {
        inDependencies = true;
        continue;
      }
      // Any other top-level key ends the block.
      if (inDependencies &&
          line.isNotEmpty &&
          !line.startsWith(' ') &&
          !line.startsWith('#')) {
        break;
      }
      if (!inDependencies) continue;
      final match = RegExp(r'^  ([a-z0-9_]+):').firstMatch(line);
      if (match != null) declared.add(match.group(1)!);
    }

    expect(declared, isNotEmpty, reason: 'the block was not parsed');
    expect(
      declared.difference(allowedRuntimeDependencies),
      isEmpty,
      reason: 'a new package must be audited against the offline promise',
    );
  });

  test('the card deck and the stopwatch are built on the SDK alone', () {
    // The two V2 widgets that could have justified a package.
    for (final path in [
      'lib/core/widgets/swipe_card_stack.dart',
      'lib/features/day/presentation/widgets/debate_timer_card.dart',
    ]) {
      final source = File(path).readAsStringSync();
      final imports = RegExp(
        r"^import 'package:([a-z0-9_]+)/",
        multiLine: true,
      ).allMatches(source).map((m) => m.group(1)!).toSet();

      expect(
        imports.difference({'flutter'}),
        isEmpty,
        reason: '$path pulls something other than the SDK',
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
