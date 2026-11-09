import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/app_alert.dart';
import '../theme/grindfit_theme.dart';

/// One bounded, composited slide/fade layer. The page beneath never rebuilds
/// on animation ticks. No blur, particle effects or repeating animations.
class NotificationPopupHost extends StatefulWidget {
  const NotificationPopupHost({
    super.key,
    required this.child,
    required this.alerts,
    required this.onOpen,
  });
  final Widget child;
  final Stream<AppAlert?> alerts;
  final ValueChanged<AppAlert> onOpen;
  @override
  State<NotificationPopupHost> createState() => _NotificationPopupHostState();
}

class _NotificationPopupHostState extends State<NotificationPopupHost>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _fade = _controller.drive(
    CurveTween(curve: Curves.easeOutCubic),
  );
  late final Animation<Offset> _slide = _fade.drive(
    Tween(begin: const Offset(0, -.15), end: Offset.zero),
  );
  StreamSubscription<AppAlert?>? _subscription;
  final Queue<AppAlert> _queue = Queue();
  AppAlert? _current;
  Timer? _dismissTimer;
  bool _closing = false;
  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listen();
  }

  void _listen() {
    _subscription = widget.alerts.listen(_receive);
  }

  @override
  void didUpdateWidget(covariant NotificationPopupHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alerts != widget.alerts) {
      _subscription?.cancel();
      _clear();
      _listen();
    }
  }

  void _receive(AppAlert? alert) {
    if (!mounted) return;
    if (alert == null) {
      _clear();
      return;
    }
    if (_current?.id == alert.id || _queue.any((a) => a.id == alert.id)) return;
    if (_queue.length >= 3) _queue.removeFirst();
    _queue.add(alert);
    if (_current == null) _next();
  }

  void _next() {
    if (!mounted || _queue.isEmpty) return;
    setState(() {
      _current = _queue.removeFirst();
      _closing = false;
    });
    if (_reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
    _dismissTimer?.cancel();
    _dismissTimer = Timer(
      MediaQuery.accessibleNavigationOf(context)
          ? const Duration(seconds: 12)
          : const Duration(seconds: 6),
      _dismiss,
    );
  }

  Future<void> _dismiss() async {
    if (_closing || _current == null) return;
    _closing = true;
    _dismissTimer?.cancel();
    if (!_reduceMotion) {
      try {
        await _controller.reverse().orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _current = null;
      _closing = false;
    });
    _next();
  }

  void _clear() {
    _dismissTimer?.cancel();
    _queue.clear();
    _controller.stop();
    if (mounted) {
      setState(() {
        _current = null;
        _closing = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _clear();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alert = _current;
    return Stack(
      children: [
        widget.child,
        if (alert != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SlideTransition(
                      position: _slide,
                      child: FadeTransition(
                        opacity: _fade,
                        child: RepaintBoundary(child: _banner(alert)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _banner(AppAlert alert) => Semantics(
    liveRegion: true,
    child: Material(
      color: GrindFitTheme.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: GrindFitTheme.gold.withValues(alpha: .55)),
      ),
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -100) _dismiss();
        },
        child: InkWell(
          onTap: () {
            _dismiss();
            widget.onOpen(alert);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: GrindFitTheme.gold.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    switch (alert.type) {
                      'Achievements' => Icons.emoji_events_outlined,
                      'Recovery' => Icons.self_improvement_rounded,
                      'Reminders' => Icons.fitness_center_rounded,
                      _ => Icons.notifications_active_outlined,
                    },
                    color: GrindFitTheme.gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GRINDFIT',
                        style: TextStyle(
                          color: GrindFitTheme.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        alert.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (alert.body.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          alert.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: GrindFitTheme.gray,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Semantics(
                  label: 'Dismiss notification',
                  button: true,
                  child: IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: GrindFitTheme.gray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
