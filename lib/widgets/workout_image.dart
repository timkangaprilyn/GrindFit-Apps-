import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/exercise_images.dart';

class WorkoutImage extends StatelessWidget {
  const WorkoutImage({
    super.key,
    required this.imageUrl,
    required this.backgroundColor,
    required this.iconColor,
    this.iconSize = 44,
    this.exerciseName,
    this.showMovement = false,
  });

  final String imageUrl;
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;

  /// When a bundled position photo exists for this exercise, it is shown
  /// instead of [imageUrl].
  final String? exerciseName;

  /// Alternate between the start and finish positions so the movement is
  /// visible. Otherwise only the start position is shown.
  final bool showMovement;

  @override
  Widget build(BuildContext context) {
    final positions = ExerciseImages.forName(exerciseName);
    if (positions.isNotEmpty) {
      return showMovement
          ? _MovementImages(
              assets: positions,
              backgroundColor: backgroundColor,
              fallback: _placeholder(),
            )
          : _framed(
              (fit) => Image.asset(
                positions.first,
                fit: fit,
                errorBuilder: (_, _, _) => _placeholder(),
              ),
              backgroundColor,
            );
    }

    if (imageUrl.trim().isEmpty) return _placeholder();

    return _framed(
      (fit) => Image.network(
        imageUrl,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => fit == BoxFit.cover
            ? ColoredBox(color: backgroundColor)
            : _placeholder(),
      ),
      backgroundColor,
    );
  }

  Widget _placeholder() => ColoredBox(
    color: backgroundColor,
    child: Center(
      child: Icon(
        Icons.fitness_center_rounded,
        color: iconColor,
        size: iconSize,
      ),
    ),
  );
}

/// The whole photo, centered over a blurred, cropped copy that fills the frame.
Widget _framed(Widget Function(BoxFit fit) image, Color backgroundColor) {
  return Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: backgroundColor),
      ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: image(BoxFit.cover),
      ),
      ColoredBox(color: Colors.black.withValues(alpha: 0.22)),
      image(BoxFit.contain),
    ],
  );
}

class _MovementImages extends StatefulWidget {
  const _MovementImages({
    required this.assets,
    required this.backgroundColor,
    required this.fallback,
  });

  final List<String> assets;
  final Color backgroundColor;
  final Widget fallback;

  @override
  State<_MovementImages> createState() => _MovementImagesState();
}

class _MovementImagesState extends State<_MovementImages> {
  static const _labels = ['Start', 'Finish'];
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (mounted) setState(() => _index = (_index + 1) % widget.assets.length);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in widget.assets) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final asset = widget.assets[_index];
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 350),
          child: KeyedSubtree(
            key: ValueKey(asset),
            child: _framed(
              (fit) => Image.asset(
                asset,
                fit: fit,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => widget.fallback,
              ),
              widget.backgroundColor,
            ),
          ),
        ),
        Positioned(
          left: 10,
          bottom: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                _labels[_index % _labels.length],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
