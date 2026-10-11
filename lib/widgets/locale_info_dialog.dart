import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class LocaleInfoDialog extends StatelessWidget {
  final List<LocaleName> availableLocales;
  final String activeLocaleId;

  const LocaleInfoDialog({
    super.key,
    required this.availableLocales,
    required this.activeLocaleId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded, color: Color(0xFF0EA5E9), size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Cara Kerja Bahasa STT',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(isDark ? 30 : 20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withAlpha(60),
                ),
              ),
              child: const Text(
                'Aplikasi ini mengirimkan parameter localeId langsung ke Speech Recognition Engine (Google Speech Services / Apple SpeechKit) pada setiap sesi pendengaran.\n\nDengan cara ini, Anda bebas berganti antara Bahasa Indonesia (id_ID) dan English (en_US) kapan saja tanpa perlu mengubah Bahasa Sistem di Pengaturan HP Anda!',
                style: TextStyle(fontSize: 12.5, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Locale Aktif Saat Ini:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activeLocaleId,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0EA5E9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Locale yang Terdeteksi di HP (${availableLocales.length}):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: availableLocales.isEmpty
                  ? Text(
                      'Belum ada daftar locale dari engine (menggunakan default fallback locale id_ID / en_US).',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableLocales.length,
                      itemBuilder: (context, index) {
                        final loc = availableLocales[index];
                        final isCurrent = loc.localeId == activeLocaleId;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${loc.name} (${loc.localeId})${isCurrent ? " ★ AKTIF" : ""}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isCurrent
                                  ? const Color(0xFF10B981)
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Mengerti'),
        ),
      ],
    );
  }
}
