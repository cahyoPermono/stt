import 'package:flutter_test/flutter_test.dart';
import 'package:medco_stt/main.dart';
import 'package:medco_stt/models/app_language.dart';

void main() {
  testWidgets('Medco STT initial load smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MedcoSttApp());
    await tester.pump();

    // Verify app title exists
    expect(find.text('Medco STT'), findsOneWidget);

    // Verify language options exist
    expect(find.text('Bahasa Indonesia'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Verify sample phrases menu button exists
    expect(find.text('Contoh Kalimat'), findsOneWidget);
  });

  test('AppLanguage enum attributes test', () {
    expect(AppLanguage.indonesian.code, 'id');
    expect(AppLanguage.indonesian.defaultLocaleId, 'id_ID');
    expect(AppLanguage.english.code, 'en');
    expect(AppLanguage.english.defaultLocaleId, 'en_US');
  });
}
