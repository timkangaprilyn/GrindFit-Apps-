import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class WorkoutImage extends StatelessWidget {
  const WorkoutImage({
    super.key,
    required this.imageUrl,
    required this.backgroundColor,
    required this.iconColor,
    this.iconSize = 44,
  });

  final String imageUrl;
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) return _placeholder();

    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(color: backgroundColor),
          ),
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.22)),
        Image.network(
          imageUrl,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => _placeholder(),
        ),
      ],
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
