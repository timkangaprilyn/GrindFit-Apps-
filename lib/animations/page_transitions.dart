import 'package:flutter/material.dart';

/// GrindFit's reusable page transition.
class GrindFitPageRoute<T> extends PageRouteBuilder<T> {
  GrindFitPageRoute({required this.page, super.fullscreenDialog = false})
    : super(
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          final curved = animation.drive(
            CurveTween(curve: Curves.easeOutCubic),
          );
          return SlideTransition(
            position: curved.drive(
              Tween(begin: const Offset(0, 0.025), end: Offset.zero),
            ),
            child: FadeTransition(
              opacity: curved.drive(Tween(begin: .9, end: 1.0)),
              child: child,
            ),
          );
        },
      );

  final Widget page;
}

/// Small convenience helpers so call sites read cleanly, e.g.:
/// `Navigator.of(context).pushGrindFit(const HomeScreen());`
extension GrindFitNavigation on NavigatorState {
  Future<T?> pushGrindFit<T>(Widget page) {
    return push<T>(GrindFitPageRoute<T>(page: page));
  }

  Future<T?> pushReplacementGrindFit<T, TO>(Widget page) {
    return pushReplacement<T, TO>(GrindFitPageRoute<T>(page: page));
  }

  Future<T?> pushAndRemoveUntilGrindFit<T>(Widget page) {
    return pushAndRemoveUntil<T>(
      GrindFitPageRoute<T>(page: page),
      (route) => false,
    );
  }
}
