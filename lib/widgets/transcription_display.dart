import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_language.dart';

class TranscriptionDisplay extends StatelessWidget {
  final String recognizedText;
  final String interimText;
  final bool isListening;
  final double confidence;
  final AppLanguage currentLanguage;
  final VoidCallback onClear;
  final Function(String phrase) onUsePhrase;

  const TranscriptionDisplay({
    super.key,
    required this.recognizedText,
    required this.interimText,
    required this.isListening,
    required this.confidence,
    required this.currentLanguage,
    required this.onClear,
    required this.onUsePhrase,
  });

  void _copyToClipboard(BuildContext context) {
    final fullText = (recognizedText.isNotEmpty ? recognizedText : interimText).trim();
    if (fullText.isEmpty) return;

    Clipboard.setData(ClipboardData(text: fullText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Teks berhasil disalin ke clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasContent = recognizedText.isNotEmpty || interimText.isNotEmpty;
    final words = hasContent
        ? (recognizedText + (interimText.isNotEmpty ? ' $interimText' : ''))
            .trim()
            .split(RegExp(r'\s+'))
            .length
        : 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isListening
              ? const Color(0xFF06B6D4).withAlpha(180)
              : (isDark ? const Color(0xFF23324E) : const Color(0xFFE2E8F0)),
          width: isListening ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isListening
                ? const Color(0xFF06B6D4).withAlpha(isDark ? 40 : 25)
                : Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening
                          ? const Color(0xFFEF4444)
                          : (hasContent ? const Color(0xFF10B981) : Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isListening
                        ? 'Merekam Suara...'
                        : (hasContent ? 'Hasil Transkripsi' : 'Menunggu Ucapan'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isListening
                          ? const Color(0xFFEF4444)
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              if (hasContent)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$words kata',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    if (confidence > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withAlpha(isDark ? 30 : 20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(confidence * 100).toInt()}% akurasi',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Main text area
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120, maxHeight: 260),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: hasContent
                  ? RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                        ),
                        children: [
                          TextSpan(text: recognizedText),
                          if (interimText.isNotEmpty)
                            TextSpan(
                              text: (recognizedText.isNotEmpty ? ' ' : '') + interimText,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF0284C7),
                              ),
                            ),
                        ],
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mic_none_rounded,
                              size: 40,
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentLanguage.isIndonesian
                                  ? 'Tekan tombol mikrofon di bawah dan mulailah berbicara dalam Bahasa Indonesia.'
                                  : 'Tap the microphone button below and start speaking in English.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Bottom action toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sample phrases button
              PopupMenuButton<String>(
                tooltip: 'Gunakan Contoh Kalimat',
                onSelected: onUsePhrase,
                constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                itemBuilder: (context) {
                  return currentLanguage.samplePhrases.map((phrase) {
                    return PopupMenuItem<String>(
                      value: phrase,
                      child: Row(
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              phrase,
                              style: const TextStyle(fontSize: 12.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 15,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Contoh Kalimat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons (Copy, Clear)
              Row(
                children: [
                  if (hasContent) ...[
                    IconButton.filledTonal(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      tooltip: 'Hapus Teks',
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: onClear,
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Salin Teks',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _copyToClipboard(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
