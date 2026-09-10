import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The debate stopwatch: set it, start it, and let the table argue.
///
/// Uses only the SDK — `Timer.periodic` for the countdown, haptics and the
/// system alert sound when the time runs out. No package, therefore no extra
/// permission in the manifest.
class DebateTimerCard extends StatefulWidget {
  const DebateTimerCard({this.initialDuration = defaultDuration, super.key});

  static const Duration defaultDuration = Duration(minutes: 5);

  final Duration initialDuration;

  @override
  State<DebateTimerCard> createState() => _DebateTimerCardState();
}

class _DebateTimerCardState extends State<DebateTimerCard> {
  static const List<int> _presetMinutes = [2, 3, 5, 10];

  Timer? _ticker;
  late Duration _configured = widget.initialDuration;
  late Duration _remaining = widget.initialDuration;
  bool _running = false;
  bool _rang = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _setDuration(Duration duration) {
    if (duration.inSeconds < 30) return;
    setState(() {
      _configured = duration;
      _remaining = duration;
      _rang = false;
    });
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_remaining.inSeconds == 0) _remaining = _configured;
    setState(() {
      _running = true;
      _rang = false;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _running = false;
      _remaining = _configured;
      _rang = false;
    });
  }

  void _tick() {
    if (!mounted) return;
    final next = _remaining - const Duration(seconds: 1);
    if (next.inSeconds <= 0) {
      _ticker?.cancel();
      setState(() {
        _remaining = Duration.zero;
        _running = false;
        _rang = true;
      });
      unawaited(HapticFeedback.vibrate());
      unawaited(SystemSound.play(SystemSoundType.alert));
      return;
    }
    setState(() => _remaining = next);
  }

  String get _label {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _configured.inSeconds == 0
        ? 0.0
        : _remaining.inSeconds / _configured.inSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 168,
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                Text(
                  _label,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: _rang ? theme.colorScheme.error : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_rang)
          Center(
            child: Text(
              'Temps écoulé — au vote !',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final minutes in _presetMinutes)
              ChoiceChip(
                selected: _configured.inMinutes == minutes && !_running,
                onSelected: _running
                    ? null
                    : (_) => _setDuration(Duration(minutes: minutes)),
                label: Text('$minutes min'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _running
                  ? null
                  : () => _setDuration(
                      _configured - const Duration(seconds: 30),
                    ),
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: '30 secondes de moins',
            ),
            Text('${_configured.inMinutes} min ${_configured.inSeconds % 60}s'),
            IconButton(
              onPressed: _running
                  ? null
                  : () => _setDuration(
                      _configured + const Duration(seconds: 30),
                    ),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: '30 secondes de plus',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _toggle,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'Pause' : 'Démarrer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Remettre à zéro'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
