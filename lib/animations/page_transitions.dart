import 'package:flutter/material.dart';

/// GrindFit's reusable page transition.
class GrindFitPageRoute<T> extends PageRouteBuilder<T> {
  GrindFitPageRoute({
    required this.page,
    super.fullscreenDialog = false,
  }) : super(
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Forward Curve: Mabilis na pasok, napakapurol na paghinto sa dulo
            final primaryCurved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );

            // Exit Curve para sa lumalabas na screen
            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );

            // Subtle slide movement
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(primaryCurved);

            // Exit page scale-out (mas seamless ang lipat ng screens)
            final secondaryScaleAnimation = Tween<double>(
              begin: 1.0,
              end: 0.98,
            ).animate(secondaryCurved);

            return ScaleTransition(
              scale: secondaryScaleAnimation,
              child: FadeTransition(
                opacity: primaryCurved,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
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