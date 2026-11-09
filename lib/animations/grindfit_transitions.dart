import 'package:flutter/material.dart';

class GrindFitTransitions extends PageTransitionsBuilder {
  const GrindFitTransitions();
  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(
      position: curved.drive(
        Tween(begin: const Offset(.025, 0), end: Offset.zero),
      ),
      child: FadeTransition(
        opacity: curved.drive(Tween(begin: .9, end: 1.0)),
        child: child,
      ),
    );
  }
}
