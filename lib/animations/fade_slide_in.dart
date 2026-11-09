import 'dart:async';

import 'package:flutter/material.dart';

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 240),
    this.offset = const Offset(0, 0.025),
    this.curve = Curves.easeOutCubic,
  });
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _delay;
  bool _started = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = _controller.drive(CurveTween(curve: widget.curve));
    _slide = _fade.drive(Tween(begin: widget.offset, end: Offset.zero));
    _controller.addStatusListener((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _delay?.cancel();
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        _delay = Timer(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: _controller.status == AnimationStatus.dismissed,
    // Keep layout space while waiting; animate transforms and opacity only.
    child: RepaintBoundary(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    ),
  );
}
