import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/ui_feedback.dart';
import '../../games/domain/game_entities.dart';
import 'controllers/export_providers.dart';
import 'password_dialog.dart';

/// Exports [game] as a password-protected file and opens the share sheet.
///
/// The archive is only ever written to disk encrypted, so the temporary file
/// left behind by the share sheet is useless without the password.
Future<void> exportGameFlow(
  BuildContext context,
  WidgetRef ref,
  Game game,
) async {
  final password = await PasswordDialog.show(
    context,
    title: 'Exporter « ${game.name} »',
    message:
        'Le fichier sera chiffré avec ce mot de passe (AES-256-GCM). '
        'Sans lui, la partie est définitivement illisible — '
        'il n\'existe aucun moyen de le récupérer.',
    confirm: true,
  );
  if (password == null || !context.mounted) return;

  final service = ref.read(exportServiceProvider);
  String? path;
  String? fileName;

  await _withBlockingProgress(context, 'Chiffrement en cours…', () async {
    final exported = await service.exportGame(
      gameId: game.id,
      password: password,
    );
    path = exported.file.path;
    fileName = exported.fileName;
  });

  if (path == null || !context.mounted) return;

  await runGuarded(context, () async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path!, mimeType: 'application/json')],
        fileNameOverrides: [fileName!],
        subject: 'Partie « ${game.name} » (chiffrée)',
        text:
            'Export chiffré de la partie « ${game.name} ». '
            'Un mot de passe est nécessaire pour l\'ouvrir.',
      ),
    );
  });
}

/// Picks an encrypted export, asks for its password and restores it.
///
/// Returns the restored game, or `null` if the user backed out.
Future<Game?> importGameFlow(BuildContext context, WidgetRef ref) async {
  final picked = await FilePicker.pickFile(
    dialogTitle: 'Choisir un export Werewolf Narrator',
  );
  if (picked == null || !context.mounted) return null;

  final String envelopeJson;
  try {
    envelopeJson = utf8.decode(await picked.readAsBytes());
  } on Object {
    if (context.mounted) {
      showMessage(context, 'Ce fichier ne peut pas être lu.');
    }
    return null;
  }
  if (!context.mounted) return null;

  final password = await PasswordDialog.show(
    context,
    title: 'Importer une partie',
    message: 'Saisissez le mot de passe utilisé lors de l\'export.',
    confirm: false,
  );
  if (password == null || !context.mounted) return null;

  Game? imported;
  await _withBlockingProgress(context, 'Déchiffrement en cours…', () async {
    imported = await ref
        .read(exportServiceProvider)
        .importGame(envelopeJson: envelopeJson, password: password);
  });

  if (imported != null && context.mounted) {
    showMessage(context, 'Partie « ${imported!.name} » importée.');
  }
  return imported;
}

/// Shows a modal spinner while [action] runs, and reports failures as usual.
///
/// Key derivation deliberately takes a moment, so the narrator needs to see
/// that something is happening.
Future<void> _withBlockingProgress(
  BuildContext context,
  String label,
  Future<void> Function() action,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    ),
  );

  AppException? failure;
  try {
    await action();
  } on AppException catch (error) {
    failure = error;
  } on Object catch (error) {
    failure = ExportException('Opération impossible.', cause: error);
  } finally {
    if (navigator.canPop()) navigator.pop();
  }

  if (failure != null && context.mounted) {
    showMessage(context, failure.message);
  }
}
