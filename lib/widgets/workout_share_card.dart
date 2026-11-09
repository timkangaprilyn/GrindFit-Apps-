import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/grindfit_theme.dart';

class WorkoutShareCard extends StatefulWidget {
  const WorkoutShareCard({
    super.key,
    required this.duration,
    required this.calories,
    required this.streak,
  });
  final String duration;
  final int calories;
  final int streak;
  @override
  State<WorkoutShareCard> createState() => _WorkoutShareCardState();
}

class _WorkoutShareCardState extends State<WorkoutShareCard> {
  final _cardKey = GlobalKey();
  bool _sharing = false;
  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final picture = await boundary.toImage(pixelRatio: 3);
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      picture.dispose();
      if (!mounted || bytes == null) return;
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'grindfit-workout.png',
            ),
          ],
          fileNameOverrides: ['grindfit-workout.png'],
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open sharing. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      RepaintBoundary(
        key: _cardKey,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: GrindFitTheme.card,
            border: Border.all(
              color: GrindFitTheme.gold.withValues(alpha: .4),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'GRINDFIT',
                style: TextStyle(
                  color: GrindFitTheme.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'WORKOUT COMPLETE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.duration}  •  ~${widget.calories} kcal',
                style: const TextStyle(color: Colors.white, fontSize: 21),
              ),
              Text(
                '${widget.streak} day streak',
                style: const TextStyle(color: GrindFitTheme.gold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              const Text(
                'Calories are an estimate. Keep showing up.',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Shared image excludes your name, email and injury details.',
        style: TextStyle(fontSize: 11, color: Colors.white60),
      ),
      OutlinedButton.icon(
        onPressed: _sharing ? null : _share,
        icon: const Icon(Icons.share_outlined),
        label: Text(_sharing ? 'Preparing image…' : 'Share workout card'),
      ),
    ],
  );
}
