import 'dart:math' as math;
import 'package:flutter/material.dart';

class SoundWaveVisualizer extends StatefulWidget {
  final bool isListening;
  final double soundLevel;
  final Color primaryColor;

  const SoundWaveVisualizer({
    super.key,
    required this.isListening,
    this.soundLevel = 0.0,
    this.primaryColor = const Color(0xFF06B6D4),
  });

  @override
  State<SoundWaveVisualizer> createState() => _SoundWaveVisualizerState();
}

class _SoundWaveVisualizerState extends State<SoundWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SoundWaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_animController.isAnimating) {
      _animController.repeat();
    } else if (!widget.isListening && _animController.isAnimating) {
      _animController.stop();
      _animController.reset();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(12, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 3.5,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      );
    }

    // Normalized sound level: usually between -10 to 10 dB or 0 to 100
    final normalizedLevel = (widget.soundLevel.abs() % 20) / 20;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SizedBox(
          height: 64,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(16, (index) {
                // Wave calculation with sine offset
                final phase = index * (math.pi / 8);
                final wave = math.sin(_animController.value * 2 * math.pi + phase);
                final baseHeight = 12.0;
                final dynamicHeight = (wave.abs() * 28.0) + (normalizedLevel * 20.0);
                final barHeight = (baseHeight + dynamicHeight).clamp(8.0, 56.0);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 3.5,
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.primaryColor,
                        widget.primaryColor.withAlpha(160),
                        const Color(0xFF10B981),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withAlpha(90),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
