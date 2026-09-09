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

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
