import 'package:flutter/material.dart';

import 'fade_slide_in.dart';

/// Shared motion values so every screen moves the same way.
class Motion {
  Motion._();
  static const fast = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 380);
  static const curve = Curves.easeOutCubic;
  static const step = Duration(milliseconds: 55);
}

/// Wraps each child in a [FadeSlideIn], one after another.
///
/// Spacers ([SizedBox] without a child) are left as-is so the delay only
/// counts visible content. Delays are capped so long pages never feel slow.
List<Widget> staggered(
  List<Widget> children, {
  Duration start = Duration.zero,
  Duration step = Motion.step,
  int maxSteps = 8,
}) {
  var index = 0;
  return [
    for (final child in children)
      if (child is SizedBox && child.child == null)
        child
      else
        FadeSlideIn(
          delay: start + step * (index < maxSteps ? index++ : maxSteps),
          duration: Motion.slow,
          offset: const Offset(0, .045),
          child: child,
        ),
  ];
}

/// Gently scales its child down while pressed. It never handles the tap
/// itself, so wrapped buttons, InkWells and ListTiles keep working.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = .97});
  final Widget child;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed && !reduce ? widget.scale : 1,
        duration: Motion.fast,
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}

/// Bottom navigation with a sliding gold pill behind the active tab.
class GrindFitNavBar extends StatelessWidget {
  const GrindFitNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<({IconData icon, String label})> items;

  static const _gold = Color(0xFFF5B800);
  static const _gray = Color(0xFF9CA3AF);
  static const _card = Color(0xFF1C1C1E);
  static const _border = Color(0xFF2E2E31);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: Motion.medium,
                    curve: Curves.easeOutBack,
                    left: width * currentIndex + (width - 52) / 2,
                    top: 8,
                    width: 52,
                    height: 30,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _NavItem(
                            icon: items[i].icon,
                            label: items[i].label,
                            selected: i == currentIndex,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GrindFitNavBar._gold : GrindFitNavBar._gray;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        highlightColor: Colors.transparent,
        splashColor: GrindFitNavBar._gold.withValues(alpha: .12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1,
              duration: Motion.medium,
              curve: Curves.easeOutBack,
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: Motion.medium,
              curve: Motion.curve,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: selected ? .2 : 0,
              ),
              child: ExcludeSemantics(child: Text(label)),
            ),
          ],
        ),
      ),
    );
  }
}
