// 2026-11-07 단어·메뉴 개편 — 절벽 단어(단원·타일·회화 단어) · 앱 소개 · 문장 레마 밑줄 · 독음 기본값. 폰·좁은 칸 넘침 확인.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turkish_universe/data/db/app_database.dart';
import 'package:turkish_universe/data/db/seed_loader.dart';
import 'package:turkish_universe/main.dart';
import 'package:turkish_universe/screens/about_screen.dart';
import 'package:turkish_universe/screens/word_freq_screen.dart';
import 'package:turkish_universe/services/dialogue_service.dart';
import 'package:turkish_universe/services/ko_reading.dart';
import 'package:turkish_universe/widgets/lemma_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    appDb = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedLoader(appDb).seedIfNeeded();
    await DialogueService.instance.ensureLoaded();
  });

  Future<void> pumpAt(WidgetTester t, Widget w, Size size) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await t.pumpWidget(MaterialApp(
        // 앱의 글자 확대 상한(1.2배)에서도 넘치지 않아야 한다
        builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(1.2)), child: child!),
        home: w,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 800));
    });
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  test('단어표 — 2,000위 + 회화 단어 9개', () async {
    final all = await appDb.select(appDb.words).get();
    expect(all.where((w) => w.region != 'conv').length, 2000);
    expect(all.where((w) => w.region == 'R5').length, 1432);
    expect(all.where((w) => w.region == 'conv').length, 9);
    final words = {for (final w in all) w.word};
    for (final d in DialogueService.instance.all) {
      for (final turn in d.turns) {
        for (final l in turn.lemmas) {
          expect(words, contains(l.base));
        }
      }
    }
  });

  test('독음 기본 미표시', () async {
    await KoReadingPrefs.load();
    expect(KoReadingPrefs.show.value, isFalse);
  });

  for (final size in const [Size(300, 800), Size(390, 844), Size(900, 1200)]) {
    testWidgets('절벽 단어 ${size.width.toInt()}폭 — 단원·구간·회화 단어, 넘침 없음', (t) async {
      await pumpAt(t, const WordFreqScreen(), size);
      expect(find.text('1단원'), findsOneWidget);
      expect(find.text('#1-20'), findsOneWidget);
      await t.tap(find.textContaining('회화 단어 포함 (+9)'));
      await t.pump();
      await t.dragUntilVisible(find.text('회화'), find.byType(ListView).first, const Offset(-120, 0));
      await t.pump();
      await t.tap(find.text('회화').first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('ısmarlamak'), findsOneWidget);
    });

    testWidgets('앱 소개 ${size.width.toInt()}폭 — 구간표, 넘침 없음', (t) async {
      await pumpAt(t, const AboutScreen(), size);
      expect(find.text('1-119'), findsOneWidget);
      expect(find.text('283-568'), findsOneWidget);
      expect(find.text('569-2000'), findsOneWidget);
    });
  }

  testWidgets('문장 레마 — 단어장에 있는 낱말만 눌린다', (t) async {
    final turn = DialogueService.instance.all.first.turns.firstWhere((x) => x.lemmas.isNotEmpty);
    await pumpAt(t, Scaffold(body: LemmaText(text: turn.tl, lemmas: turn.lemmas, style: const TextStyle())), const Size(390, 844));
    final span = t.widget<RichText>(find.byType(RichText)).text as TextSpan;
    expect(span.toPlainText(), turn.tl);
    final taps = <InlineSpan>[];
    span.visitChildren((s) {
      if (s is TextSpan && s.recognizer != null) taps.add(s);
      return true;
    });
    expect(taps, isNotEmpty);
  });
}
