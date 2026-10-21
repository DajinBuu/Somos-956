import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:somos_956/l10n.dart';
import 'package:somos_956/local_data.dart';
import 'package:somos_956/main.dart';
import 'package:somos_956/models.dart';
import 'package:somos_956/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bilingual table returns English and Spanish', () {
    const en = S('en');
    const es = S('es');
    expect(en.t('app_title'), 'Somos 956');
    expect(en.t('nav_health'), 'Health');
    expect(es.t('nav_health'), 'Salud');
    expect(en.pick('Hello', 'Hola'), 'Hello');
    expect(es.pick('Hello', 'Hola'), 'Hola');
  });

  test('seed data is populated', () {
    expect(kCareFacilities, isNotEmpty);
    expect(kMedicalTerms, isNotEmpty);
    expect(kBridges, isNotEmpty);
    expect(kCorridors, isNotEmpty);
    expect(kCommunityResources, isNotEmpty);
    expect(kEligibilityPrograms, isNotEmpty);
    expect(kCulturalTips, isNotEmpty);
    expect(kEduResources, isNotEmpty);
  });

  test('bridge wait model returns a bounded value', () {
    final bridge = kBridges.first;
    final wait = BorderService.predictWait(bridge, DateTime(2026, 5, 1, 8));
    expect(wait, inInclusiveRange(3, 90));
    expect(BorderService.stateFor(wait), isA<BridgeState>());

    final forecast = BorderService.forecast(bridge, DateTime(2026, 5, 1, 8));
    expect(forecast, isNotEmpty);
  });

  test('term decoder finds a known term', () {
    final decoder = TermDecoder();
    final hit = decoder.lookup('hypertension');
    expect(hit, isNotNull);
    expect(hit!.term.toLowerCase(), contains('hypertension'));
  });

  testWidgets('app shell renders all navigation tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    await tester.pumpWidget(Somos956App(settings: settings));
    await tester.pump();

    expect(find.text('Somos 956'), findsWidgets);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Health'), findsWidgets);
    expect(find.text('Transport'), findsWidgets);
    expect(find.text('Community'), findsWidgets);
    expect(find.text('Education'), findsWidgets);
  });

  testWidgets('language toggle switches labels', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    await tester.pumpWidget(Somos956App(settings: settings));
    await tester.pump();

    await tester.tap(find.text('ES'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Salud'), findsWidgets);
    expect(find.text('Inicio'), findsWidgets);
  });
}
