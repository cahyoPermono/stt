import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'models/app_language.dart';
import 'models/transcript_entry.dart';
import 'services/speech_service.dart';
import 'theme/app_theme.dart';
import 'widgets/history_sheet.dart';
import 'widgets/language_selector_bar.dart';
import 'widgets/locale_info_dialog.dart';
import 'widgets/speech_control_panel.dart';
import 'widgets/transcription_display.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MedcoSttApp());
}

class MedcoSttApp extends StatefulWidget {
  const MedcoSttApp({super.key});

  @override
  State<MedcoSttApp> createState() => _MedcoSttAppState();
}

class _MedcoSttAppState extends State<MedcoSttApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medco Speech to Text',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: SpeechToTextScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class SpeechToTextScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const SpeechToTextScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<SpeechToTextScreen> createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen>
    with WidgetsBindingObserver {
  final SpeechService _speechService = SpeechService();

  AppLanguage _selectedLanguage = AppLanguage.indonesian;
  String _recognizedText = '';
  String _interimText = '';
  double _confidence = 1.0;
  double _soundLevel = 0.0;
  bool _isListening = false;
  bool _isInitializing = false;
  bool _isActionInProgress = false;
  String? _errorMessage;
  String? _statusHint;

  final List<TranscriptEntry> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeechEngine();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isListening) {
        _speechService.cancelListening();
        if (mounted) {
          setState(() {
            _isListening = false;
            _soundLevel = 0.0;
          });
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // Pulihkan engine dan bersihkan session native menggantung saat kembali dari app lain
      _speechService.refreshEngine();
    }
  }

  String _humanizeError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('permission')) {
      return 'Izin mikrofon diperlukan untuk mendengarkan ucapan.';
    } else if (lower.contains('network')) {
      return 'Koneksi jaringan bermasalah saat menghubungi layanan pengenal suara.';
    } else if (lower.contains('audio')) {
      return 'Input mikrofon tidak dapat diakses atau sedang digunakan aplikasi lain.';
    } else if (lower.contains('busy')) {
      return 'Layanan pengenal suara sedang sibuk. Silakan coba sebentar lagi.';
    } else if (lower.contains('no_match') || lower.contains('timeout')) {
      return 'Tidak ada suara terdeteksi. Silakan coba bicara lagi.';
    }
    return 'Pemberitahuan pengenalan suara: $error';
  }

  Future<void> _initSpeechEngine() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _statusHint = null;
    });

    final success = await _speechService.initialize(
      onErrorCallback: (err, isTimeout) {
        if (mounted) {
          setState(() {
            _isListening = false;
            if (isTimeout) {
              // Jika timeout karena hening (tidak ada suara), jangan tampilkan error merah
              _statusHint = _selectedLanguage.isIndonesian
                  ? 'Tidak ada suara terdeteksi. Silakan tekan mic dan coba bicara lagi.'
                  : 'No speech detected. Please tap mic and try speaking again.';
            } else {
              _errorMessage = _humanizeError(err);
            }
          });
        }
      },
      onStatusCallback: (status) {
        if (mounted) {
          setState(() {
            _isListening = _speechService.isListening;
            if (!_isListening) {
              _soundLevel = 0.0;
            }
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isInitializing = false;
        if (!success && _speechService.lastError != null) {
          _errorMessage = _humanizeError(_speechService.lastError!);
        }
      });
    }
  }

  void _onLanguageSelected(AppLanguage newLanguage) async {
    if (_selectedLanguage == newLanguage) return;

    if (_isListening) {
      await _speechService.stopListening();
      _saveCurrentTranscriptToHistory();
    }

    setState(() {
      _selectedLanguage = newLanguage;
      _interimText = '';
    });

    final resolvedLocale = _speechService.resolveLocaleId(newLanguage);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(newLanguage.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bahasa STT: ${newLanguage.name} ($resolvedLocale) aktif.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0EA5E9),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _toggleListening() async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;

    try {
      setState(() {
        _errorMessage = null;
        _statusHint = null;
      });

      if (_isListening) {
        await _speechService.stopListening();
        if (mounted) {
          setState(() {
            _isListening = false;
            _soundLevel = 0.0;
          });
        }
        _saveCurrentTranscriptToHistory();
        return;
      }

      if (!_speechService.isInitialized || !_speechService.hasPermission) {
        final initOk = await _speechService.initialize();
        if (!initOk || !_speechService.hasPermission) {
          if (mounted) {
            setState(() {
              _errorMessage = _speechService.lastError ??
                  'Izin mikrofon diperlukan untuk mendengarkan suara.';
            });
            _showPermissionDialog();
          }
          return;
        }
      }

      setState(() {
        _isListening = true;
        _interimText = '';
      });

      final started = await _speechService.startListening(
        language: _selectedLanguage,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 3),
        onResult: (SpeechRecognitionResult result) {
          if (!mounted) return;
          setState(() {
            _statusHint = null;
            if (result.finalResult) {
              _recognizedText = result.recognizedWords;
              _interimText = '';
              _confidence = result.confidence > 0 ? result.confidence : 1.0;
            } else {
              _interimText = result.recognizedWords;
            }
          });

          if (result.finalResult) {
            _saveCurrentTranscriptToHistory();
          }
        },
        onSoundLevelChange: (level) {
          if (!mounted) return;
          setState(() {
            _soundLevel = level;
          });
        },
      );

      if (!started && mounted) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _soundLevel = 0.0;
            _errorMessage = _speechService.lastError != null
                ? _humanizeError(_speechService.lastError!)
                : 'Tidak dapat memulai speech recognition.';
          });
        }
      }
    } finally {
      // Cooldown singkat 300ms agar native thread Android stabil dan siap menerima rekam berikutnya
      await Future.delayed(const Duration(milliseconds: 300));
      _isActionInProgress = false;
    }
  }

  Future<void> _cancelListening() async {
    await _speechService.cancelListening();
    if (mounted) {
      setState(() {
        _isListening = false;
        _interimText = '';
        _soundLevel = 0.0;
      });
    }
  }

  void _saveCurrentTranscriptToHistory() {
    final text = _recognizedText.trim();
    if (text.isEmpty) return;

    // Hindari duplikasi jika teks sama dengan entri terakhir
    if (_history.isNotEmpty && _history.first.text == text) return;

    setState(() {
      _history.insert(
        0,
        TranscriptEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          language: _selectedLanguage,
          localeId: _speechService.resolveLocaleId(_selectedLanguage),
          timestamp: DateTime.now(),
          confidence: _confidence,
        ),
      );
    });
  }

  void _clearText() {
    setState(() {
      _recognizedText = '';
      _interimText = '';
      _soundLevel = 0.0;
    });
  }

  void _useSamplePhrase(String phrase) {
    setState(() {
      _recognizedText = phrase;
      _interimText = '';
      _confidence = 0.98;
    });
    _saveCurrentTranscriptToHistory();
  }

  void _showLocaleInfo() {
    showDialog(
      context: context,
      builder: (context) => LocaleInfoDialog(
        availableLocales: _speechService.availableLocales,
        activeLocaleId: _speechService.resolveLocaleId(_selectedLanguage),
      ),
    );
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistorySheet(
        history: _history,
        onDeleteEntry: (entry) {
          setState(() {
            _history.removeWhere((item) => item.id == entry.id);
          });
          Navigator.of(context).pop();
        },
        onClearAll: () {
          setState(() {
            _history.clear();
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izin Mikrofon Dibutuhkan'),
        content: const Text(
          'Untuk melakukan Speech-to-Text, aplikasi memerlukan izin mikrofon. Silakan izinkan akses mikrofon saat diminta oleh sistem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initSpeechEngine();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeLocaleId = _speechService.resolveLocaleId(_selectedLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0D9488)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medco STT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Voice to Text Studio',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // History Button with Badge
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Riwayat Transkripsi',
                onPressed: _showHistorySheet,
              ),
              if (_history.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0EA5E9),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_history.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: widget.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12.5, color: Colors.redAccent),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                        onPressed: () => setState(() => _errorMessage = null),
                      ),
                    ],
                  ),
                ),
              ],

              // Status Hint (misal: timeout saat hening / tidak ada suara terdeteksi)
              if (_statusHint != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mic_none_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusHint!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _statusHint = null),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. Language Selector Card (In-App Toggle without changing phone settings)
              LanguageSelectorBar(
                selectedLanguage: _selectedLanguage,
                activeLocaleId: activeLocaleId,
                onLanguageChanged: _onLanguageSelected,
                onInfoPressed: _showLocaleInfo,
              ),

              const SizedBox(height: 16),

              // 2. Real-time Transcription Card
              TranscriptionDisplay(
                recognizedText: _recognizedText,
                interimText: _interimText,
                isListening: _isListening,
                confidence: _confidence,
                currentLanguage: _selectedLanguage,
                onClear: _clearText,
                onUsePhrase: _useSamplePhrase,
              ),

              const SizedBox(height: 20),

              // 3. Audio Visualizer & Interactive Mic Control Panel
              SpeechControlPanel(
                isListening: _isListening,
                isInitializing: _isInitializing,
                soundLevel: _soundLevel,
                currentLanguage: _selectedLanguage,
                onToggleListening: _toggleListening,
                onCancel: _cancelListening,
              ),

              const SizedBox(height: 24),

              // 4. Quick Language Tips & Emulator Guide Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF23324E) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          size: 18,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedLanguage.isIndonesian
                                ? 'Tips: Anda dapat berbicara langsung dalam Bahasa Indonesia tanpa merubah setelan bahasa HP. Engine STT menggunakan model akustik id_ID.'
                                : 'Tips: You can speak directly in English without changing system language. STT engine applies en_US acoustic models.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.devices_other_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Emulator: Jika mic hening/timeout, buka panel Emulator (... > Microphone) lalu centang "Virtual microphone uses host audio input".',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
