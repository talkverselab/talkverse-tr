// 아이패드 두 화면 + 만화책 읽기형 회화 확인용 스크린샷 흐름 — 2026-11-03(몽골어앱 dialogue_pane_test 를 옮김).
// 실행: python3 tools/pane_shots.py <아이패드 UDID> <출력폴더> integration_test/dialogue_pane_test.dart
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
    await wait(t, 2000);
    // ignore: avoid_print
    print('SHOT:$name');
    await wait(t, 3000);
  }

  Finder rail(String label) => find.descendant(of: find.byType(NavigationRail), matching: find.text(label));

  testWidgets('dialogue pane', timeout: const Timeout(Duration(minutes: 10)), (t) async {
    // main() 과 같은 시작 순서
    appDb = AppDatabase();
    await SeedLoader(appDb).seedIfNeeded();
    await KoReadingPrefs.load();
    await AppLangPrefs.load();
    await LearnerPrefs.load();
    await AchievementService.instance.load();
    await t.pumpWidget(const TurkishUniverseApp());
    await wait(t, 1500);
    await shot(t, '01_home_wide');

    await t.tap(find.text('회화').first);
    await wait(t, 2500);
    await shot(t, '02_dialogue_home_right');

    await t.tap(find.text('사랑').first);
    await wait(t, 1200);
    await shot(t, '03_topic_list');

    await t.tap(find.text('첫 인사').first);
    await wait(t, 1500);
    await shot(t, '04_reader');

    await t.tap(find.text('재생').first);
    await wait(t, 6000);
    await shot(t, '05_reader_playing');

    await t.tap(find.byTooltip('그림 카드(글자 없이)'));
    await wait(t, 1500);
    await shot(t, '06_card_front');
    await t.tap(find.text('탭해서 확인'));
    await wait(t, 800);
    await shot(t, '07_card_back');
    await t.pageBack();
    await wait(t, 1200);

    // 접사(2026-11-03, 몽골어앱 아이디어): 홈 접사 사전 → 설명 시트 → 카드
    await t.tap(rail('홈'));
    await wait(t, 1000);
    await t.tap(find.text('접사').first);
    await wait(t, 2000);
    await shot(t, '10_affix_dictionary');
    await t.tap(find.text('처격').first);
    await wait(t, 2500);
    await shot(t, '11_affix_sheet');
    await t.tapAt(const Offset(600, 200)); // 시트는 오른쪽 칸 안에 뜬다 — 그 칸의 어두운 막을 눌러 닫는다
    await wait(t, 2500); // 시트가 다 닫힌 뒤에 눌러야 앱바 버튼에 닿는다
    await t.tap(find.byTooltip('접사 카드로 연습').last);
    await wait(t, 2000);
    await shot(t, '12_affix_quiz');
    await t.pageBack();
    await wait(t, 1200);

    await t.tap(rail('진행'));
    await wait(t, 1500);
    await shot(t, '08_progress_achievements');

    await t.tap(rail('프로필'));
    await wait(t, 1500);
    await shot(t, '09_profile');
  });
}
