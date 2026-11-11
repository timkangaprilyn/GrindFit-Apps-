import 'package:flutter/material.dart';

/// Page transition: the new screen fades in while rising slightly and
/// settling from 98.5% scale; the screen underneath dims a little.
class GrindFitTransitions extends PageTransitionsBuilder {
  const GrindFitTransitions();
  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final behind = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: behind.drive(Tween(begin: 1.0, end: .55)),
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: curved.drive(
            Tween(begin: const Offset(0, .03), end: Offset.zero),
          ),
          child: ScaleTransition(
            scale: curved.drive(Tween(begin: .985, end: 1.0)),
            child: child,
          ),
        ),
      ),
    );
  }
}
