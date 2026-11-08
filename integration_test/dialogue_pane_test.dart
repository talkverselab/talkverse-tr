// 아이패드 두 화면 + 만화책 읽기형 회화 확인용 스크린샷 흐름 — 2026-11-03(몽골어앱 dialogue_pane_test 를 옮김).
// 실행: python3 tools/pane_shots.py <아이패드 UDID> <출력폴더> integration_test/dialogue_pane_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:turkish_universe/widgets/lemma_text.dart';
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

    await t.tap(find.text('회화').last); // first 는 섹션 머리글
    await wait(t, 2500);
    await shot(t, '02_dialogue_home_right');

    await t.tap(find.text('사랑').first);
    await wait(t, 1200);
    await shot(t, '03_topic_list');

    await t.tap(find.text('첫 인사').first);
    await wait(t, 1500);
    await shot(t, '04_reader');

    await t.tapAt(const Offset(605, 895)); // 2턴 — 1턴은 내용어가 없어 칩이 안 나온다
    await wait(t, 1000);
    await t.tap(find.byIcon(Icons.pause_rounded)); // 턴을 누르면 재생이 이어져 칩이 다음 턴으로 넘어간다
    await wait(t, 800);
    await shot(t, '04b_reader_lemmas');
    await t.tap(find.text('selam').last); // first 는 그림 위 라벨
    await wait(t, 1200);
    await shot(t, '04c_lemma_sheet');
    await t.tapAt(const Offset(600, 200));
    await wait(t, 800);

    // 문장 레마 탭 → 단어창: 밑줄 낱말 자리를 실제로 눌러 본다
    final rp = t.renderObject<RenderParagraph>(find.descendant(of: find.byType(LemmaText).last, matching: find.byType(RichText)));
    var off = 0;
    TextSpan? hit;
    (rp.text as TextSpan).visitChildren((s) {
      if (s is TextSpan && s.recognizer != null) {
        hit = s;
        return false;
      }
      if (s is TextSpan && s.children == null) off += s.text?.length ?? 0;
      return true;
    });
    final box = rp.getBoxesForSelection(TextSelection(baseOffset: off, extentOffset: off + hit!.text!.length)).first.toRect();
    await t.tapAt(rp.localToGlobal(box.center));
    await wait(t, 1200);
    await shot(t, '04d_lemma_tap_sheet');
    await t.tapAt(const Offset(600, 200));
    await wait(t, 800);

    // 독음은 기본 미표시 — 켜면 안내
    await t.tap(find.byTooltip('한글독음 표시').first);
    await wait(t, 600);
    await shot(t, '04e_reading_on');
    await t.tap(find.byTooltip('한글독음 숨기기').first);
    await wait(t, 3500);

    await t.tap(find.byIcon(Icons.play_arrow_rounded));
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

    // 절벽 단어 · 앱 소개(2026-11-07)
    await t.tap(rail('홈'));
    await wait(t, 1000);
    await shot(t, '13_home_menu');
    await t.ensureVisible(find.text('절벽 단어').last);
    await wait(t, 500);
    await shot(t, '13b_home_menu_lower');
    await t.tap(find.text('절벽 단어').last);
    await wait(t, 2500);
    await shot(t, '14_cliff_words');
    await t.dragUntilVisible(find.text('R5 · 569-2000'), find.ancestor(of: find.text('R1 · 1-119'), matching: find.byType(Scrollable)).first, const Offset(-200, 0)); // 구간 칩은 가로 스크롤
    await wait(t, 300);
    await t.tap(find.text('R5 · 569-2000'));
    await wait(t, 1500);
    await shot(t, '15_cliff_r5');
    await t.tap(find.textContaining('회화 단어 포함'));
    await wait(t, 800);
    await t.tap(find.text('회화').last);
    await wait(t, 1500);
    await shot(t, '16_cliff_conv');
    await t.tap(find.descendant(of: find.byType(NavigationRail), matching: find.text('앱 소개')));
    await wait(t, 1500);
    await shot(t, '17_about');
    await t.pageBack(); // 앱 소개는 전체 화면으로 열린다
    await wait(t, 1000);

    await t.tap(rail('진행'));
    await wait(t, 1500);
    await shot(t, '08_progress_achievements');

    await t.tap(rail('프로필'));
    await wait(t, 1500);
    await shot(t, '09_profile');

    // 알파벳과 발음(2026-11-08)
    await t.tap(rail('홈'));
    await wait(t, 1000);
    await t.ensureVisible(find.text('알파벳과 발음').last); // 홈이 아래로 스크롤돼 있다
    await wait(t, 500);
    await t.tap(find.text('알파벳과 발음').last);
    await wait(t, 1500);
    await shot(t, '18_alphabet');
    await t.tap(find.text('Ö ö').last);
    await wait(t, 1800);
    await shot(t, '19_alphabet_sheet_vowel');
    Navigator.of(t.element(find.text('IPA [ø / œ]'))).pop();
    await wait(t, 800);
    await t.tap(find.text('Ç ç').last);
    await wait(t, 1500);
    await t.tap(find.text('자음 조음 위치 그림 보기'));
    await wait(t, 1000);
    await shot(t, '20_alphabet_sheet_consonant');
    Navigator.of(t.element(find.text('IPA [tʃ]'))).pop();
    await wait(t, 800);
    await t.tap(find.text('모음조화'));
    await wait(t, 1000);
    await shot(t, '21_vowel_harmony');
  });
}
