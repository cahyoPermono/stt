import 'app_language.dart';

class TranscriptEntry {
  final String id;
  final String text;
  final AppLanguage language;
  final String localeId;
  final DateTime timestamp;
  final double confidence;

  TranscriptEntry({
    required this.id,
    required this.text,
    required this.language,
    required this.localeId,
    required this.timestamp,
    this.confidence = 1.0,
  });

  int get wordCount =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  int get characterCount => text.length;
}
