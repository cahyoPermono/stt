import 'package:flutter/material.dart';
import '../models/app_language.dart';
import 'sound_wave_visualizer.dart';

class SpeechControlPanel extends StatefulWidget {
  final bool isListening;
  final bool isInitializing;
  final double soundLevel;
  final AppLanguage currentLanguage;
  final VoidCallback onToggleListening;
  final VoidCallback onCancel;

  const SpeechControlPanel({
    super.key,
    required this.isListening,
    required this.isInitializing,
    required this.soundLevel,
    required this.currentLanguage,
    required this.onToggleListening,
    required this.onCancel,
  });

  @override
  State<SpeechControlPanel> createState() => _SpeechControlPanelState();
}

class _SpeechControlPanelState extends State<SpeechControlPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didUpdateWidget(covariant SpeechControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Sound wave visualizer
        SoundWaveVisualizer(
          isListening: widget.isListening,
          soundLevel: widget.soundLevel,
          primaryColor: widget.currentLanguage.isIndonesian
              ? const Color(0xFF06B6D4)
              : const Color(0xFF6366F1),
        ),

        const SizedBox(height: 12),

        // Main Mic button with pulsing glow
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring when listening
              if (widget.isListening)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.28);
                    final opacity = 0.5 - (_pulseController.value * 0.35);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEF4444).withValues(alpha: opacity.clamp(0.0, 1.0)),
                        ),
                      ),
                    );
                  },
                ),

              // Button container
              GestureDetector(
                onTap: widget.isInitializing ? null : widget.onToggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isListening
                          ? [
                              const Color(0xFFEF4444),
                              const Color(0xFFDC2626),
                            ]
                          : [
                              const Color(0xFF0EA5E9),
                              const Color(0xFF0D9488),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isListening
                            ? const Color(0xFFEF4444).withAlpha(120)
                            : const Color(0xFF0EA5E9).withAlpha(90),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.isInitializing
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            widget.isListening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            size: 38,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Hint label & cancel action
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.isListening
                  ? 'Ketuk untuk berhenti'
                  : 'Ketuk mikrofon untuk mulai bicara',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.isListening
                    ? const Color(0xFFEF4444)
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
            if (widget.isListening) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Batal', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
