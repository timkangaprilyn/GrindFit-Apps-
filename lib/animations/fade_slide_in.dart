import 'package:flutter/material.dart';

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
    this.offset = const Offset(0, 0.04), // Subtle, ultra-smooth movement
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fade = curvedAnimation;
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curvedAnimation);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      // Iniiwasan ang async build jank sa tulong ng delay
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Iniiwasan ang pag-pop / pagpapakita ng child habang naghihintay ng delay
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.status == AnimationStatus.dismissed &&
            widget.delay > Duration.zero) {
          return const SizedBox.shrink(); // Tago habang nasa delay state
        }
        return child!;
      },
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: widget.child,
        ),
      ),
    );
  }
}