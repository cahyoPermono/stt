import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/app_language.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  static const MethodChannel _nativeChannel = MethodChannel('com.medco.stt/engine');

  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _hasPermission = false;
  List<LocaleName> _availableLocales = [];
  String? _lastError;
  String _status = 'idle';

  Function(String error, bool isTimeout)? _onErrorCallback;
  Function(String status)? _onStatusCallback;

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  bool get hasPermission => _hasPermission;
  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;
  List<LocaleName> get availableLocales => _availableLocales;
  String? get lastError => _lastError;
  String get status => _status;

  /// Inisialisasi SpeechToText dan periksa izin mikrofon
  Future<bool> initialize({
    Function(String error, bool isTimeout)? onErrorCallback,
    Function(String status)? onStatusCallback,
  }) async {
    if (onErrorCallback != null) _onErrorCallback = onErrorCallback;
    if (onStatusCallback != null) _onStatusCallback = onStatusCallback;

    if (_isInitialized) return true;
    if (_isInitializing) return false;

    _isInitializing = true;
    _lastError = null;

    try {
      // Inisialisasi engine Speech-to-Text (secara otomatis meminta izin mikrofon pada Android & iOS)
      _isInitialized = await _speech.initialize(
        onError: (SpeechRecognitionError error) {
          final errorLower = error.errorMsg.toLowerCase();
          final isTimeout = errorLower.contains('timeout') ||
              errorLower.contains('no_match') ||
              errorLower.contains('speech_timeout') ||
              error.errorMsg == 'error_speech_timeout' ||
              error.errorMsg == 'error_no_match';
          _lastError = error.errorMsg;
          debugPrint('SpeechService Error: ${error.errorMsg} - permanent: ${error.permanent} - isTimeout: $isTimeout');
          _onErrorCallback?.call(_lastError!, isTimeout);
        },
        onStatus: (String currentStatus) {
          _status = currentStatus;
          debugPrint('SpeechService Status: $currentStatus');
          _onStatusCallback?.call(currentStatus);
        },
        debugLogging: kDebugMode,
        options: [
          SpeechConfigOption('android', 'noBluetooth', true),
        ],
      );

      _hasPermission = await _speech.hasPermission;

      // 3. Ambil daftar locale bahasa yang didukung oleh engine HP
      if (_isInitialized) {
        try {
          _availableLocales = await _speech.locales();
          debugPrint('SpeechService: Ditemukan ${_availableLocales.length} locale di perangkat.');
        } catch (e) {
          debugPrint('SpeechService: Gagal memuat daftar locale: $e');
        }
      }
    } catch (e) {
      _lastError = 'Gagal inisialisasi speech engine: $e';
      debugPrint(_lastError);
      _isInitialized = false;
    } finally {
      _isInitializing = false;
    }

    return _isInitialized;
  }

  /// Menemukan ID locale yang paling cocok untuk bahasa yang dipilih
  /// TANPA MENGGANTI BAHASA DI SETTINGS HP
  String resolveLocaleId(AppLanguage language) {
    if (_availableLocales.isEmpty) {
      return language.defaultLocaleId;
    }

    if (language == AppLanguage.indonesian) {
      // Cari locale Bahasa Indonesia (id_ID, id-ID, in_ID)
      for (final loc in _availableLocales) {
        final id = loc.localeId.toLowerCase().replaceAll('-', '_');
        if (id == 'id_id' || id == 'in_id') {
          return loc.localeId;
        }
      }
      for (final loc in _availableLocales) {
        final id = loc.localeId.toLowerCase();
        if (id.startsWith('id') || id.startsWith('in')) {
          return loc.localeId;
        }
      }
      return language.defaultLocaleId;
    } else {
      // Cari locale English (en_US, en_GB, en)
      for (final loc in _availableLocales) {
        final id = loc.localeId.toLowerCase().replaceAll('-', '_');
        if (id == 'en_us') {
          return loc.localeId;
        }
      }
      for (final loc in _availableLocales) {
        final id = loc.localeId.toLowerCase().replaceAll('-', '_');
        if (id == 'en_gb') {
          return loc.localeId;
        }
      }
      for (final loc in _availableLocales) {
        final id = loc.localeId.toLowerCase();
        if (id.startsWith('en')) {
          return loc.localeId;
        }
      }
      return language.defaultLocaleId;
    }
  }

  /// Mulai mendengarkan suara dengan locale yang ditentukan
  Future<bool> startListening({
    required AppLanguage language,
    required Function(SpeechRecognitionResult result) onResult,
    Function(double soundLevel)? onSoundLevelChange,
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return false;
    }

    // Pastikan sesi sebelumnya benar-benar dibatalkan dan buffer mikrofon bersih
    if (_speech.isListening) {
      await _speech.cancel();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final targetLocaleId = resolveLocaleId(language);
    debugPrint('SpeechService: Mulai mendengarkan dengan localeId: $targetLocaleId (${language.name})');

    try {
      await _speech.listen(
        onResult: onResult,
        onSoundLevelChange: onSoundLevelChange,
        listenOptions: SpeechListenOptions(
          localeId: targetLocaleId,
          listenFor: listenFor,
          pauseFor: pauseFor,
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
      return true;
    } catch (e) {
      _lastError = 'Gagal memulai perekaman: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  /// Berhenti mendengarkan dan proses hasil akhir
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
      // Beri jeda kecil agar native AudioRecord melepas hardware mic dengan sempurna
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  /// Batalkan sesi perekaman saat ini
  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  /// Reset internal recognizer dan pulihkan session Android saat aplikasi resume dari background
  Future<void> refreshEngine() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _nativeChannel.invokeMethod('resetRecognizer');
      }
      await Future.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      debugPrint('SpeechService: refreshEngine warning: $e');
    }
  }
}
