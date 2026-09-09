import 'package:flutter/material.dart';

/// Asks for the password protecting an export.
///
/// In [confirm] mode the password is typed twice, because a typo here would
/// produce a file nobody can ever open again.
class PasswordDialog extends StatefulWidget {
  const PasswordDialog({
    required this.title,
    required this.message,
    required this.confirm,
    super.key,
  });

  final String title;
  final String message;
  final bool confirm;

  static const int minimumLength = 6;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String message,
    required bool confirm,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => PasswordDialog(
        title: title,
        message: message,
        confirm: confirm,
      ),
    );
  }

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _repeat = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  String? get _error {
    final value = _password.text;
    if (value.isEmpty) return null;
    if (value.length < PasswordDialog.minimumLength) {
      return 'Au moins ${PasswordDialog.minimumLength} caractères.';
    }
    if (widget.confirm && _repeat.text.isNotEmpty && _repeat.text != value) {
      return 'Les deux mots de passe diffèrent.';
    }
    return null;
  }

  bool get _isValid {
    final value = _password.text;
    if (value.length < PasswordDialog.minimumLength) return false;
    if (widget.confirm && _repeat.text != value) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: _obscure,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              errorText: _error,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (widget.confirm) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _repeat,
              obscureText: _obscure,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(_password.text)
              : null,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
