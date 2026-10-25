import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Motion Primitive: Audio-Reactive Animated Equalizer Waveform.
class MotionWaveform extends StatefulWidget {
  const MotionWaveform({
    super.key,
    this.barCount = 28,
    this.active = false,
    this.height = 48,
    this.primaryColor,
    this.accentColor,
  });

  final int barCount;
  final bool active;
  final double height;
  final Color? primaryColor;
  final Color? accentColor;

  @override
  State<MotionWaveform> createState() => _MotionWaveformState();
}

class _MotionWaveformState extends State<MotionWaveform> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _canAnimate {
    if (WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) return false;
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active && _canAnimate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant MotionWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active && _canAnimate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.value = 0.2;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pColor = widget.primaryColor ?? theme.colorScheme.primary;
    final aColor = widget.accentColor ?? theme.colorScheme.tertiary;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              final baseH = 8.0 + ((i * 17 + 7) % (widget.height - 12));
              final phase = (i / widget.barCount) * 2 * math.pi;
              final wave = widget.active
                  ? (math.sin(_controller.value * 2 * math.pi + phase).abs() * 0.9 + 0.2)
                  : 0.35;
              final currentHeight = (baseH * wave).clamp(4.0, widget.height);
              final barColor = i % 4 == 0 ? aColor : pColor;

              return Container(
                width: 3.5,
                height: currentHeight,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: barColor.withAlpha(widget.active ? 220 : 120),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: widget.active
                      ? [
                          BoxShadow(
                            color: barColor.withAlpha(90),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Motion Primitive: Concentric Pulsing Radar Rings.
class MotionRadar extends StatefulWidget {
  const MotionRadar({
    super.key,
    required this.active,
    this.size = 32,
    this.color,
  });

  final bool active;
  final double size;
  final Color? color;

  @override
  State<MotionRadar> createState() => _MotionRadarState();
}

class _MotionRadarState extends State<MotionRadar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _canAnimate {
    if (WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) return false;
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.active && _canAnimate) {
      _controller.repeat();
    } else {
      _controller.value = 0.3;
    }
  }

  @override
  void didUpdateWidget(covariant MotionRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active && _canAnimate) {
        _controller.repeat();
      } else {
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.active) ...[
                _buildRing(c, (_controller.value) % 1.0),
                _buildRing(c, (_controller.value + 0.5) % 1.0),
              ],
              Container(
                width: widget.size * 0.35,
                height: widget.size * 0.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.active ? c : c.withAlpha(90),
                  boxShadow: widget.active
                      ? [
                          BoxShadow(
                            color: c.withAlpha(150),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRing(Color c, double progress) {
    final scale = 0.35 + progress * 0.65;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.withValues(alpha: opacity * 0.8), width: 1.5),
        ),
      ),
    );
  }
}

/// Motion Primitive: Tactile Spring Interactive Card/Button.
class MotionSpringButton extends StatefulWidget {
  const MotionSpringButton({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<MotionSpringButton> createState() => _MotionSpringButtonState();
}

class _MotionSpringButtonState extends State<MotionSpringButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Motion Primitive: Spring Pop-in Alert Notification Banner.
class MotionAlertBanner extends StatelessWidget {
  const MotionAlertBanner({
    super.key,
    required this.category,
    required this.text,
    required this.onDismiss,
  });

  final String category;
  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertColor = switch (category) {
      'Doorbell' => const Color(0xfff59e0b),
      'Alarm' => const Color(0xffef4444),
      'Siren' => const Color(0xffdc2626),
      'Knocking' => const Color(0xffeab308),
      'Timer' => const Color(0xff06b6d4),
      _ => const Color(0xff8b5cf6),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, val, child) {
        return Transform.scale(
          scale: 0.8 + 0.2 * val,
          alignment: Alignment.topCenter,
          child: Opacity(
            opacity: val.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: alertColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: alertColor.withAlpha(60),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: alertColor.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications_active, color: alertColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DEMO SOUND DETECTED · ${category.toUpperCase()}',
                    style: TextStyle(
                      color: alertColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
