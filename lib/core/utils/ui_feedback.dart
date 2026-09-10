import 'package:flutter/material.dart';

import '../errors/app_exception.dart';

/// Runs [action], turning an expected [AppException] into a snack bar instead
/// of an unhandled error, and returns whether it succeeded.
///
/// Keeps every call site in the UI free of try/catch boilerplate while making
/// sure a failure is never swallowed silently.
Future<bool> runGuarded(
  BuildContext context,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    return true;
  } on AppException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
    return false;
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text('Une erreur inattendue est survenue.')),
    );
    return false;
  }
}

/// Same contract as [runGuarded], for an action that produces a value.
///
/// Returns `null` when the action failed — the snack bar has already told the
/// narrator why.
Future<T?> runGuardedValue<T extends Object>(
  BuildContext context,
  Future<T> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    return await action();
  } on AppException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
    return null;
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text('Une erreur inattendue est survenue.')),
    );
    return null;
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
