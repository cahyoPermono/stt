enum AppLanguage {
  indonesian(
    code: 'id',
    name: 'Bahasa Indonesia',
    flag: '🇮🇩',
    defaultLocaleId: 'id_ID',
    tagline: 'Mengenali ucapan dalam Bahasa Indonesia',
    samplePhrases: [
      'Halo dokter, saya ingin konsultasi',
      'Resep obat sudah saya terima dengan baik',
      'Pemeriksaan tekanan darah menunjukkan hasil normal',
      'Selamat pagi, ini adalah uji coba speech to text',
    ],
  ),
  english(
    code: 'en',
    name: 'English',
    flag: '🇬🇧',
    defaultLocaleId: 'en_US',
    tagline: 'Recognizes speech in English (US/UK)',
    samplePhrases: [
      'Hello doctor, I would like to schedule a consultation',
      'The prescription has been received successfully',
      'Blood pressure test results are within normal range',
      'Good morning, this is a speech to text trial',
    ],
  );

  final String code;
  final String name;
  final String flag;
  final String defaultLocaleId;
  final String tagline;
  final List<String> samplePhrases;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.flag,
    required this.defaultLocaleId,
    required this.tagline,
    required this.samplePhrases,
  });

  bool get isIndonesian => this == AppLanguage.indonesian;
  bool get isEnglish => this == AppLanguage.english;
}
