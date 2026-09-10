import 'package:flutter/material.dart';

/// A deck of full-screen cards the narrator flicks through.
///
/// Home-made on purpose: a `PageView` cannot show the next card peeking behind
/// the current one, and pulling a swipe-card package in would add a dependency
/// to an app that guarantees it has none touching the network. Everything here
/// is `GestureDetector` + `Transform` + one `AnimationController`.
///
/// The widget is **controlled**: the parent owns [index] and reacts to
/// [onNext] / [onPrevious]. Swiping is never the only way through — the caller
/// is expected to offer buttons as well, and does.
class SwipeCardStack extends StatefulWidget {
  const SwipeCardStack({
    required this.itemCount,
    required this.index,
    required this.itemBuilder,
    required this.onNext,
    required this.onPrevious,
    super.key,
  });

  final int itemCount;
  final int index;
  final IndexedWidgetBuilder itemBuilder;

  /// Called once the top card has flown off to the left.
  final VoidCallback onNext;

  /// Called once the top card has flown off to the right.
  final VoidCallback onPrevious;

  @override
  State<SwipeCardStack> createState() => SwipeCardStackState();
}

class SwipeCardStackState extends State<SwipeCardStack>
    with SingleTickerProviderStateMixin {
  static const double _swipeThreshold = 90;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() => setState(() {}));

  double _dragX = 0;
  double _from = 0;
  double _to = 0;
  VoidCallback? _pending;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _offset =>
      _controller.isAnimating || _controller.isCompleted
      ? _from + (_to - _from) * Curves.easeOut.transform(_controller.value)
      : _dragX;

  void _animateTo(double target, {VoidCallback? then}) {
    _from = _dragX;
    _to = target;
    _pending = then;
    _controller.forward(from: 0).whenComplete(() {
      final callback = _pending;
      _pending = null;
      setState(() {
        _dragX = 0;
        _controller.reset();
      });
      callback?.call();
    });
  }

  /// Sends the top card away to the left and moves on, as the button does.
  void fling({required bool forward}) {
    if (_controller.isAnimating) return;
    final width = context.size?.width ?? 400;
    _animateTo(
      forward ? -width * 1.2 : width * 1.2,
      then: forward ? widget.onNext : widget.onPrevious,
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) return;
    setState(() => _dragX += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_controller.isAnimating) return;
    final velocity = details.primaryVelocity ?? 0;
    final goingLeft = _dragX < -_swipeThreshold || velocity < -600;
    final goingRight = _dragX > _swipeThreshold || velocity > 600;

    if (goingLeft && widget.index < widget.itemCount - 1) {
      fling(forward: true);
    } else if (goingRight && widget.index > 0) {
      fling(forward: false);
    } else {
      _animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();
    final index = widget.index.clamp(0, widget.itemCount - 1);
    final offset = _offset;
    final progress = (offset.abs() / 220).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // The next card, peeking behind so the deck reads as a deck.
        if (index + 1 < widget.itemCount)
          Transform.scale(
            scale: 0.94 + 0.06 * progress,
            child: Opacity(
              opacity: 0.55 + 0.45 * progress,
              child: IgnorePointer(
                child: widget.itemBuilder(context, index + 1),
              ),
            ),
          ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: Transform.translate(
            offset: Offset(offset, 0),
            child: Transform.rotate(
              angle: offset / 2200,
              child: widget.itemBuilder(context, index),
            ),
          ),
        ),
      ],
    );
  }
}
