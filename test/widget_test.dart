import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:somos_956/l10n.dart';
import 'package:somos_956/local_data.dart';
import 'package:somos_956/location.dart';
import 'package:somos_956/main.dart';
import 'package:somos_956/models.dart';
import 'package:somos_956/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bilingual table returns English and Spanish', () {
    const en = S('en');
    const es = S('es');
    const bi = S('en', bilingual: true);
    expect(en.t('app_title'), 'Somos 956');
    expect(en.t('nav_health'), 'Health');
    expect(es.t('nav_health'), 'Salud');
    expect(en.pick('Hello', 'Hola'), 'Hello');
    expect(es.pick('Hello', 'Hola'), 'Hola');
    expect(bi.pickSecondary('Hello', 'Hola'), 'Hola');
    expect(bi.secondaryLang, 'es');
  });

  test('seed data is populated', () {
    expect(kCareFacilities, isNotEmpty);
    expect(kMedicalTerms, isNotEmpty);
    expect(kBridges, isNotEmpty);
    expect(kCommunityResources, isNotEmpty);
    expect(kEligibilityPrograms, isNotEmpty);
    expect(kCulturalTips, isNotEmpty);
    expect(kEduResources, isNotEmpty);
  });

  test('bridges carry real CBP port numbers', () {
    expect(kBridges, isNotEmpty);
    for (final b in kBridges) {
      expect(b.portNumber, isNotEmpty);
      expect(int.tryParse(b.portNumber), isNotNull);
    }
  });

  test('bridge wait model returns a bounded value', () {
    final bridge = kBridges.first;
    final wait = BorderService.predictWait(bridge, DateTime(2026, 5, 1, 8));
    expect(wait, inInclusiveRange(2, 120));
    expect(BorderService.stateFor(wait), isA<BridgeState>());

    final forecast = BorderService.forecast(bridge, DateTime(2026, 5, 1, 8));
    expect(forecast, isNotEmpty);
  });

  test('rush-hour estimate exceeds the overnight estimate', () {
    final bridge = kBridges.first;
    final rush = BorderService.predictWait(bridge, DateTime(2026, 5, 1, 17));
    final night = BorderService.predictWait(bridge, DateTime(2026, 5, 1, 3));
    expect(rush, greaterThan(night));
  });

  test('distance math is accurate', () {
    // McAllen to Brownsville is ~54 miles straight-line.
    final d = LocationService.miles(26.2034, -98.2300, 25.9018, -97.4975);
    expect(d, inInclusiveRange(45, 65));
    // Same point is zero.
    expect(LocationService.miles(26.2, -98.2, 26.2, -98.2), closeTo(0, 0.001));
  });

  test('more crossings and locations are present', () {
    expect(kBridges.length, greaterThanOrEqualTo(12));
    expect(kCareFacilities.length, greaterThanOrEqualTo(20));
    expect(
        kCareFacilities.any((c) => c.city == 'Rio Grande City'), isTrue);
    expect(kBridges.any((b) => b.city == 'Roma'), isTrue);
  });

  test('day-of-week model makes Fri/Mon heavier than Sat', () {
    final b = kBridges.first;
    final fri = BorderService.predictWaitForDay(b, DateTime.friday, 8);
    final mon = BorderService.predictWaitForDay(b, DateTime.monday, 8);
    final sat = BorderService.predictWaitForDay(b, DateTime.saturday, 8);
    expect(fri, greaterThan(sat));
    expect(mon, greaterThan(sat));
    // Deterministic: same inputs give the same answer.
    expect(BorderService.predictWaitForDay(b, DateTime.friday, 8), fri);
  });

  test('dailyAverages and peakHourForDay are well formed', () {
    final b = kBridges.first;
    final avgs = BorderService.dailyAverages(b);
    expect(avgs.length, 7);
    for (final a in avgs) {
      expect(a, inInclusiveRange(2, 120));
    }
    final (hour, wait) = BorderService.peakHourForDay(b, DateTime.friday);
    expect(hour, inInclusiveRange(0, 23));
    expect(wait, inInclusiveRange(2, 120));
  });

  test('road service strips HTML and maps severity', () async {
    final client = MockClient((req) async {
      return http.Response(
        '{"features":[{"attributes":{"OBJECTID":56,"condition":"Construction",'
        '"route_name":"FM0676","roadway":"","from_limit":"1040 Feet W of FM2220",'
        '"to_limit":"0 Feet W of FM2220",'
        '"description":"- Alternating lanes closed.<br/>- Expect delays.<br/>",'
        '"delay_flag":"True","detour_flag":"False"},"geometry":{"x":-98.1,"y":26.3}},'
        '{"attributes":{"OBJECTID":99,"condition":"Closure","route_name":"US0083",'
        '"roadway":"","from_limit":"","to_limit":"",'
        '"description":"Road closed<br/>","delay_flag":"False","detour_flag":"True"},'
        '"geometry":{"x":-97.8,"y":26.1}}]}',
        200,
      );
    });
    final svc = RoadService(client: client);
    final events = await svc.closures();
    expect(events.length, 2);
    // Closure sorts first.
    expect(events.first.severity, RoadSeverity.closure);
    expect(events.first.route, 'US0083');
    // HTML tags are stripped from the description.
    final con = events.firstWhere((e) => e.route == 'FM0676');
    expect(con.description.contains('<br'), isFalse);
    expect(con.description.toLowerCase(), contains('alternating lanes closed'));
    expect(con.description.contains('FM0676'), isTrue);
    expect(con.severity, RoadSeverity.major);
  });

  test('bridge predictions differ across crossings', () {
    final now = DateTime(2026, 5, 1, 8);
    final waits = {for (final b in kBridges) b.id: BorderService.predictWait(b, now)};
    // Hidalgo (busiest, pm-major shape) should not equal a light crossing.
    expect(waits['hidalgo'], isNot(waits['los-ebanos']));
    // At least four distinct values at the same hour — not all identical.
    expect(waits.values.toSet().length, greaterThanOrEqualTo(4));
    // Hidalgo runs heavier than the smallest crossings.
    expect(waits['hidalgo']!, greaterThan(waits['falcon']!));
  });

  test('live readings use the standard lane, not the fastest', () async {
    final client = MockClient((req) async {
      return http.Response(
        '[{"date":"05/01/2026","time":"10:00:00","port_number":"230501",'
        '"port_name":"Hidalgo","port_status":"Open",'
        '"passenger_vehicle_lanes":{"standard_lanes":{"delay_minutes":"40",'
        '"operational_status":"delay"},'
        '"NEXUS_SENTRI_lanes":{"delay_minutes":"2","operational_status":"no delay"}}}]',
        200,
      );
    });
    final svc = BorderService(client: client);
    final readings = await svc.currentReadings();
    final hidalgo = readings.firstWhere((r) => r.bridge.portNumber == '230501');
    // Headline waits on the standard lane (40), not the NEXUS 2-minute lane.
    expect(hidalgo.waitMinutes, 40);
    expect(hidalgo.passengerWait, 40);
    // The opt-in express lane is still surfaced separately.
    expect(hidalgo.fastestLaneWait, 2);
    expect(hidalgo.live, isTrue);
    // Bridges with no feed row stay clearly marked as estimates.
    final roma = readings.firstWhere((r) => r.bridge.portNumber == '231001');
    expect(roma.live, isFalse);
  });

  test('manual location overrides distance reference', () {
    final svc = LocationService();
    expect(svc.hasFix, isFalse);
    expect(svc.origin, isNull);
    svc.setManual(25.9018, -97.4975);
    expect(svc.hasFix, isTrue);
    expect(svc.isManual, isTrue);
    expect(svc.reference.$1, closeTo(25.9018, 0.0001));
    expect(svc.distanceTo(26.2034, -98.2300), inInclusiveRange(45, 65));
    expect(svc.origin, isNotNull);
    svc.clearManual();
    expect(svc.isManual, isFalse);
    expect(svc.hasFix, isFalse);
  });

  test('weather code mapping is friendly text', () {
    expect(WeatherService.conditionForCode(0), 'Clear');
    expect(WeatherService.conditionForCode(61), 'Rain');
    expect(WeatherService.conditionForCode(95), 'Thunderstorm');
  });

  test('term decoder finds a known term', () {
    final decoder = TermDecoder();
    final hit = decoder.lookup('hypertension');
    expect(hit, isNotNull);
    expect(hit!.term.toLowerCase(), contains('hypertension'));
  });

  testWidgets('first launch shows the language chooser', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    await tester.pumpWidget(Somos956App(settings: settings));
    await tester.pump();

    expect(find.text('Choose your language'), findsWidgets);
    expect(find.text('English'), findsWidgets);
    expect(find.text('Español'), findsWidgets);
    expect(find.text('Bilingual · Bilingüe'), findsWidgets);
  });

  testWidgets('app shell renders all navigation tabs after onboarding',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'lang': 'en'});
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
    SharedPreferences.setMockInitialValues({'onboarded': true, 'lang': 'en'});
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

  testWidgets('bilingual mode shows both languages', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'onboarded': true, 'lang': 'en', 'bilingual': true});
    final settings = AppSettings();
    await settings.load();
    await tester.pumpWidget(Somos956App(settings: settings));
    await tester.pump();

    expect(find.text('Home'), findsWidgets);
    await tester.tap(find.text('Transport').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('International bridges'), findsOneWidget);
    expect(find.text('Puentes internacionales'), findsOneWidget);
  });

  testWidgets('onboarding selection completes and persists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    await tester.pumpWidget(Somos956App(settings: settings));
    await tester.pump();

    expect(find.text('Choose your language'), findsWidgets);
    final cta = find.textContaining('Continue · Continuar');
    await tester.ensureVisible(cta);
    await tester.pump();
    await tester.tap(cta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(settings.onboarded, isTrue);
    expect(find.text('Home'), findsWidgets);
  });
}
