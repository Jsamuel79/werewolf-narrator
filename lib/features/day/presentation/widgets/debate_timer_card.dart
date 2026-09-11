import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../games/domain/game_entities.dart';

/// The debate stopwatch: set it, start it, and let the table argue.
///
/// Uses only the SDK — `Timer.periodic` for the countdown, haptics and the
/// system alert sound when the time runs out. No package, therefore no extra
/// permission in the manifest.
/// How the table is timed.
enum DebateMode {
  /// One countdown for the whole debate.
  free('Débat libre'),

  /// Each player in turn gets the same short slot to speak.
  speakingTurns('Tour de parole');

  const DebateMode(this.label);

  final String label;
}

class DebateTimerCard extends StatefulWidget {
  const DebateTimerCard({
    this.initialDuration = defaultDuration,
    this.speakers = const [],
    super.key,
  });

  static const Duration defaultDuration = Duration(minutes: 5);
  static const Duration defaultTurnDuration = Duration(seconds: 30);

  final Duration initialDuration;

  /// Living players, in seating order — who speaks, and in which order.
  final List<Player> speakers;

  @override
  State<DebateTimerCard> createState() => _DebateTimerCardState();
}

class _DebateTimerCardState extends State<DebateTimerCard> {
  static const List<int> _presetMinutes = [2, 3, 5, 10];
  static const List<int> _presetSeconds = [20, 30, 45, 60];

  Timer? _ticker;
  late Duration _configured = widget.initialDuration;
  late Duration _remaining = widget.initialDuration;
  bool _running = false;
  bool _rang = false;
  DebateMode _mode = DebateMode.free;
  int _speaker = 0;

  bool get _byTurns =>
      _mode == DebateMode.speakingTurns && widget.speakers.isNotEmpty;

  Player? get _currentSpeaker =>
      _byTurns ? widget.speakers[_speaker % widget.speakers.length] : null;

  void _setMode(DebateMode mode) {
    _ticker?.cancel();
    setState(() {
      _mode = mode;
      _running = false;
      _rang = false;
      _speaker = 0;
      _configured = mode == DebateMode.speakingTurns
          ? DebateTimerCard.defaultTurnDuration
          : widget.initialDuration;
      _remaining = _configured;
    });
  }

  /// Hands the floor to the next player, timer reset and ready to start.
  void _nextSpeaker() {
    _ticker?.cancel();
    setState(() {
      _speaker = (_speaker + 1) % widget.speakers.length;
      _running = false;
      _rang = false;
      _remaining = _configured;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _setDuration(Duration duration) {
    if (duration.inSeconds < (_byTurns ? 10 : 30)) return;
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
        if (widget.speakers.isNotEmpty) ...[
          SegmentedButton<DebateMode>(
            segments: [
              for (final mode in DebateMode.values)
                ButtonSegment(value: mode, label: Text(mode.label)),
            ],
            selected: {_mode},
            onSelectionChanged: (values) => _setMode(values.first),
          ),
          const SizedBox(height: 16),
        ],
        if (_currentSpeaker != null)
          Center(
            child: Text(
              'C\'est à ${_currentSpeaker!.name}',
              style: theme.textTheme.titleMedium,
            ),
          ),
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
              _byTurns
                  ? 'Temps écoulé — au suivant !'
                  : 'Temps écoulé — au vote !',
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
            if (_byTurns)
              for (final seconds in _presetSeconds)
                ChoiceChip(
                  selected: _configured.inSeconds == seconds && !_running,
                  onSelected: _running
                      ? null
                      : (_) => _setDuration(Duration(seconds: seconds)),
                  label: Text('$seconds s'),
                )
            else
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
                onPressed: _byTurns ? _nextSpeaker : _reset,
                icon: Icon(_byTurns ? Icons.skip_next : Icons.restart_alt),
                label: Text(_byTurns ? 'Joueur suivant' : 'Remettre à zéro'),
              ),
            ),
          ],
        ),
        if (_byTurns)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Chaque joueur parle à son tour, ${_configured.inSeconds} '
              'secondes chacun.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}
