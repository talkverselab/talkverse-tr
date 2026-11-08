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
    await t.ensureVisible(find.text('회화').last); // 기초 묶음이 생겨 폰에서는 아래로 밀렸다
    await wait(t, 500);
    await t.tap(find.text('회화').last); // first 는 섹션 머리글
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

    // 절벽 단어 타일·앱 소개도 폰 폭에서 넘치지 않는지
    Navigator.of(t.element(find.byIcon(Icons.play_arrow_rounded))).popUntil((r) => r.isFirst);
    await wait(t, 1500);
    await t.ensureVisible(find.text('절벽 단어').last);
    await wait(t, 500);
    await t.tap(find.text('절벽 단어').last);
    await wait(t, 2500);
    await t.tap(find.textContaining('회화 단어 포함'));
    await wait(t, 800);
    await t.fling(find.byType(ListView).last, const Offset(0, -2000), 3000);
    await wait(t, 1500);
    Navigator.of(t.element(find.textContaining('회화 단어 포함'))).pop();
    await wait(t, 1000);
    await t.tap(find.text('프로필'));
    await wait(t, 1000);
    await t.scrollUntilVisible(find.text('앱 소개'), 200, scrollable: find.byType(Scrollable).last); // 목록 아래쪽은 아직 안 그려져 있다
    await wait(t, 500);
    await t.tap(find.text('앱 소개'));
    await wait(t, 1500);
    Navigator.of(t.element(find.text('1. 단어 기준'))).pop();
    await wait(t, 800);
    await t.tap(find.text('홈'));
    await wait(t, 1000);
    await t.ensureVisible(find.text('알파벳과 발음').last);
    await wait(t, 500);
    await t.tap(find.text('알파벳과 발음').last);
    await wait(t, 1500);
    await shot(t, 'p3_alphabet');
    await t.tap(find.text('Ü ü').last);
    await wait(t, 1800);
    await shot(t, 'p4_alphabet_sheet');
  });
}
