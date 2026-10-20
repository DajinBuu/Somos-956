import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgv_ready/l10n.dart';
import 'package:rgv_ready/local_data.dart';
import 'package:rgv_ready/main.dart';
import 'package:rgv_ready/models.dart';
import 'package:rgv_ready/services.dart';

void main() {
  testWidgets('app builds with dashboard', (tester) async {
    final settings = AppSettings();
    await settings.load();
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RgvReadyApp(settings: settings));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('RGV Ready'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Heat'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Traffic'), findsOneWidget);
  });

  test('heat index thresholds', () {
    expect(heatLevelFor(85), HeatLevel.normal);
    expect(heatLevelFor(95), HeatLevel.caution);
    expect(heatLevelFor(110), HeatLevel.extreme);
    expect(heatLevelFor(130), HeatLevel.danger);
    final hi = heatIndexF(100, 50);
    expect(hi, greaterThan(100));
  });

  test('bilingual strings exist in both languages', () {
    final keys = {
      'app_title',
      'nav_heat',
      'nav_water',
      'nav_traffic',
      'stage2',
      'worker_tips',
      'bridge_delays',
      'hydration_reminders',
      'flood_prone',
    };
    for (final k in keys) {
      final en = const S('en').t(k);
      final es = const S('es').t(k);
      expect(en, isNotEmpty);
      expect(es, isNotEmpty);
      expect(en == k, isFalse, reason: 'missing EN translation for $k');
      expect(es == k, isFalse, reason: 'missing ES translation for $k');
    }
  });

  test('local data sanity', () {
    expect(kSites.length, greaterThanOrEqualTo(20));
    expect(kZones.length, 6);
    expect(kBridges.length, greaterThanOrEqualTo(3));
    expect(kHazards.length, greaterThanOrEqualTo(5));
    expect(kWorkerTips.length, greaterThanOrEqualTo(8));
    for (final site in kSites) {
      expect(site.lat, inInclusiveRange(25.5, 26.5));
      expect(site.lon, inInclusiveRange(-98.5, -97.0));
    }
    for (final zone in kZones) {
      expect(zone.stage, inInclusiveRange(0, 4));
      expect(zone.rulesEs.length, zone.rulesEn.length);
    }
  });

  test('reservoir fallback returns both lakes', () async {
    final readings = await ReservoirService().fetch();
    expect(readings.length, 2);
    for (final r in readings) {
      expect(r.percentFull, inInclusiveRange(0, 100));
      expect(r.name, contains('Reservoir'));
    }
  });
}
