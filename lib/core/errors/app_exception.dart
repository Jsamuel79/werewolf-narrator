/// Base class for every error the application raises on purpose.
///
/// Anything thrown outside of this hierarchy is a bug, not an expected failure.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// Human readable, French, safe to show in the UI.
  final String message;

  /// Underlying error, kept for debugging. Never rendered to the user.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// The encryption key could not be created, read or stored.
class KeyStoreException extends AppException {
  const KeyStoreException(super.message, {super.cause});
}

/// The encrypted database could not be opened or a query failed.
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

/// User input is not acceptable (empty name, duplicate player, ...).
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// The requested operation is forbidden by the rules of the game.
class GameRuleException extends AppException {
  const GameRuleException(super.message);
}

/// Building or writing an encrypted export failed.
class ExportException extends AppException {
  const ExportException(super.message, {super.cause});
}

/// Reading an encrypted export failed: wrong password, corrupted or foreign file.
class ImportException extends AppException {
  const ImportException(super.message, {super.cause});
}
