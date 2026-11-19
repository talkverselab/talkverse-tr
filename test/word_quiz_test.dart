import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turkish_universe/screens/word_quiz_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('틀린 철자 보기 — 실제 단어와 겹치지 않고, 터키어 글자를 바꾼 꼴', () {
    final m = turkishMisspellings('çiçek', {'çiçek', 'cicek'});
    expect(m, isNot(contains('çiçek')));
    expect(m, isNot(contains('cicek')));
    expect(m, contains('ciçek'));
    expect(m.length, greaterThanOrEqualTo(3));
    expect(turkishMisspellings('dağ', {'dağ'}), contains('da'));
    expect(turkishMisspellings('su', {'su'}).length, greaterThanOrEqualTo(3));
  });

  testWidgets('퀴즈 복습 — 보기 4개, 10문제 뒤 결과, 폭 320 넘침 없음', (t) async {
    t.view.physicalSize = const Size(320, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final words = [
      for (final w in const [
        ('su', '수', '물'), ('çiçek', '치첵', '꽃'), ('otobüs', '오토뷔스', '버스'), ('kahve', '카흐베', '커피'),
        ('şehir', '셰히르', '도시'), ('dağ', '다', '산'), ('kapı', '카프', '문'), ('otel', '오텔', '호텔'),
        ('ekmek', '에크멕', '빵'), ('istasyon', '이스타시온', '역'), ('güzel', '귀젤', '예쁜'), ('köpek', '쾨펙', '개'),
      ])
        WQWord(w.$1, w.$2, w.$3),
    ];
    await t.pumpWidget(MaterialApp(home: WordQuizScreen(words: words, seed: 7)));
    await t.pumpAndSettle();
    for (var i = 0; i < kWordQuizSize; i++) {
      expect(t.takeException(), isNull);
      expect(find.byKey(const ValueKey('wq-opt-3')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('wq-opt-0')));
      await t.pump();
      await t.ensureVisible(find.byKey(const ValueKey('wq-next')));
      await t.tap(find.byKey(const ValueKey('wq-next')));
      await t.pump();
    }
    expect(t.takeException(), isNull);
    expect(find.byKey(const ValueKey('wq-again')), findsOneWidget);
  });
}
