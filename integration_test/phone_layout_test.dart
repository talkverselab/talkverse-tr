// 폰 크기 회화 리더 넘침 확인 — 아이패드 시뮬레이터 한 대에서 화면 크기만 폰으로 줄여 본다.
// 실행: python3 tools/pane_shots.py <UDID> <출력폴더> integration_test/phone_layout_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:turkish_universe/core/l10n.dart';
import 'package:turkish_universe/data/db/app_database.dart';
import 'package:turkish_universe/data/db/seed_loader.dart';
import 'package:turkish_universe/main.dart';
import 'package:turkish_universe/services/achievement_service.dart';
import 'package:turkish_universe/services/ko_reading.dart';
import 'package:turkish_universe/services/learner_prefs.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester t, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await wait(t, 1500);
    // ignore: avoid_print
    print('SHOT:$name');
    await wait(t, 2500);
  }

  testWidgets('phone reader', timeout: const Timeout(Duration(minutes: 6)), (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    appDb = AppDatabase();
    await SeedLoader(appDb).seedIfNeeded();
    await KoReadingPrefs.load();
    await AppLangPrefs.load();
    await LearnerPrefs.load();
    await AchievementService.instance.load();
    await t.pumpWidget(const TurkishUniverseApp());
    await wait(t, 1500);
    await t.tap(find.text('회화').first);
    await wait(t, 1500);
    await t.tap(find.text('사랑').first);
    await wait(t, 1500);
    await t.tap(find.text('첫 인사').first);
    await wait(t, 1500);
    await shot(t, 'p1_reader');
    await t.tap(find.byIcon(Icons.play_arrow_rounded)); // 턴이 넘어가며 칩·긴 문장이 모두 지나간다
    await wait(t, 12000);
    await shot(t, 'p2_playing');
    await t.tap(find.byIcon(Icons.pause_rounded));
    await wait(t, 500);
  });
}
