import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turkish_universe/screens/curriculum_screen.dart';
import 'package:turkish_universe/services/curriculum.dart';
import 'package:turkish_universe/services/dialogue_service.dart';

DialogueTurn _t(int n, String sp, String tl, String ko) =>
    DialogueTurn(num: n, speaker: sp, tl: tl, reading: '', rd: '', ko: ko, note: '', tags: const [], newWords: const []);

Dialogue _d(String id, String island, int k) => Dialogue(
      id: id,
      region: 'R0',
      island: island,
      kind: 'long',
      title: id,
      emoji: '🙂',
      scene: '',
      speakers: const {'A': 'Ali', 'B': 'Elif'},
      genders: const {},
      turns: [
        for (var i = 1; i <= 6; i++) _t(i, i.isOdd ? 'A' : 'B', 'Merhaba arkadaşım numara$k$i bugün', '안녕 친구 $k-$i'),
      ],
    );

void main() {
  test('점수 — 소수점 버림, 80% 이상만 통과', () {
    expect(scorePercent(4, 5), 80);
    expect(isPass(4, 5), isTrue);
    expect(scorePercent(23, 29), 79); // 79.3 → 79
    expect(isPass(23, 29), isFalse);
    expect(isPass(24, 30), isTrue);
    expect(isPass(7, 9), isFalse); // 77
    expect(isPass(0, 0), isFalse);
  });

  test('간격 반복 — 처음 1일, 맞히면 3일·7일·졸업, 틀리면 1일로', () {
    const today = '2026-11-30';
    final a = reschedule(null, 'x#1', true, today)!;
    expect((a.due, a.step), ('2026-12-01', 0));
    final b = reschedule(a, 'x#1', true, '2026-12-01')!;
    expect((b.due, b.step), ('2026-12-04', 1));
    final c = reschedule(b, 'x#1', true, '2026-12-04')!;
    expect((c.due, c.step), ('2026-12-11', 2));
    expect(reschedule(c, 'x#1', true, '2026-12-11'), isNull);
    final w = reschedule(c, 'x#1', false, '2026-12-11')!;
    expect((w.due, w.step), ('2026-12-12', 0));
  });

  test('오늘 분량·연속 일수', () {
    final s = CurriculumState(dailyGoal: 'light');
    s.rollDay('2026-11-22');
    expect(s.dailyDone('2026-11-22'), isFalse);
    s.todayNew = 1;
    expect(s.dailyDone('2026-11-22'), isTrue);
    s.touchStreak('2026-11-22');
    expect(s.streakCount, 1);
    s.rollDay('2026-11-23');
    s.todayNew = 1;
    s.touchStreak('2026-11-23');
    expect(s.streakCount, 2);
    s.rollDay('2026-11-25');
    s.todayNew = 1;
    s.touchStreak('2026-11-25');
    expect(s.streakCount, 1); // 하루 건너뜀
    // 저장 형식 왕복
    final back = CurriculumState.fromJson(s.toJson());
    expect((back.streakCount, back.dailyGoal, back.todayNew), (1, 'light', 1));
  });

  test('연습 → 줄이 복습 대기열에, 틀린 줄은 1일로', () {
    final d = _d('r0_a', 'love', 1);
    final s = CurriculumState();
    s.addPractice(d, {}, '2026-11-22');
    expect(s.review.length, 6);
    expect(s.dueReviews('2026-11-23').length, 6);
    s.answerReview('r0_a#1', true, '2026-11-23');
    expect(s.review.firstWhere((r) => r.lineId == 'r0_a#1').due, '2026-11-26');
  });

  test('추천 — 통과한 편 빼고 주제가 겹치지 않게', () {
    final pool = [_d('a1', 'love', 1), _d('a2', 'love', 2), _d('b1', 'travel', 3), _d('c1', 'life', 4)];
    final r = Curriculum.recommend(pool, {'b1'}, 3);
    expect(r.length, 3);
    expect(r.contains('b1'), isFalse);
    expect(r.toSet(), {'a1', 'c1', 'a2'});
  });

  test('확인 문제 — 편당 최대 10, 보기 4개에 정답 포함, 시험은 최대 30', () {
    final pool = [for (var k = 0; k < 4; k++) _d('e$k', 'love', k)];
    final qs = makeQuestions(pool[0], pool, rnd: Random(1));
    expect(qs.length, 6);
    for (final q in qs) {
      expect(q.options.length, 4);
      expect(q.options.contains(q.answer), isTrue);
    }
    expect(qs.any((q) => q.kind == 'blank'), isTrue);
    expect(makeExam(pool, pool, rnd: Random(2)).length, lessThanOrEqualTo(30));
  });

  testWidgets('커리큘럼 화면 — 처음 열면 레벨 고르기', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(const MaterialApp(home: CurriculumScreen()));
    for (var i = 0; i < 20; i++) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    expect(find.byKey(const ValueKey('cur-level-R0')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('cur-level-R0')));
    for (var i = 0; i < 10; i++) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
      await t.pump();
    }
    expect(find.byKey(const ValueKey('cur-today')), findsOneWidget);
    expect(find.byKey(const ValueKey('cur-new-course')), findsOneWidget);
    // 통합 앱에서 언어끼리 덮어쓰지 않게 언어 접두가 붙은 키
    expect((await SharedPreferences.getInstance()).getString('tr_curriculum_v1'), contains('"level":"R0"'));
  });

  for (final w in [390.0, 300.0]) {
    testWidgets('코스 고르기 — ${w.toInt()}px 폭에서 넘침 없음(칩 줄 Wrap)', (t) async {
      t.view.physicalSize = Size(w * 3, 2400);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final pool = [_d('a1', 'love', 1), _d('b1', 'travel', 2), _d('c1', 'life', 3), _d('d1', 'work', 4), _d('e1', 'study', 5)];
      await t.pumpWidget(MaterialApp(home: CoursePickerScreen(pool: pool, passed: const {}, hasCourse: true)));
      await t.pump();
      expect(t.takeException(), isNull);
      await t.tap(find.byKey(const ValueKey('cur-recommend')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('cur-start')));
      await t.pump();
      expect(find.byKey(const ValueKey('cur-confirm-new')), findsOneWidget); // 지금 코스가 있으면 화면 안에서 묻기
      expect(t.takeException(), isNull);
    });
  }
}
