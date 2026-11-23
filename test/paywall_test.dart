import 'package:flutter_test/flutter_test.dart';
import 'package:turkish_universe/data/entitlement.dart';
import 'package:turkish_universe/data/purchase.dart';
import 'package:turkish_universe/screens/sense_course_screen.dart';
import 'package:turkish_universe/services/curriculum.dart';

/// 이용권 잠금 경계(PAYWALL_SPEC §2, 2026-11-23) — 1단계 열림 · 2단계 잠김 · 이용권 있으면 열림.
void main() {
  tearDown(() => Purchase.owned.value = const {});

  test('커리큘럼 단계 — 서버 free 가 없으면 1단계만 무료, 있으면 서버 값', () {
    expect(CStage.fromJson({'n': 1}).free, isTrue);
    expect(CStage.fromJson({'n': 2}).free, isFalse);
    expect(CStage.fromJson({'n': 2, 'free': true}).free, isTrue);
    expect(CStage.fromJson({'n': 1, 'free': false}).free, isFalse);
  });

  test('회화 — R0·R1·L1 무료, R2 이상 잠김', () {
    expect(Entitlement.freeRegion('R0'), isTrue);
    expect(Entitlement.freeRegion('R1'), isTrue);
    expect(Entitlement.freeRegion('L1'), isTrue);
    expect(Entitlement.freeRegion('R2'), isFalse);
    expect(Entitlement.freeRegion('R3'), isFalse);
  });

  test('이용권 — lang_tr_* 또는 all_* 가 유효하면 열림, 다른 언어 것·만료된 것은 아님', () {
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = {'lang_ja_life': 0};
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = {'lang_tr_1m': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch};
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = {'lang_tr_1y': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch};
    expect(Entitlement.premium, isTrue);
    Purchase.owned.value = {'all_life': 0};
    expect(Entitlement.premium, isTrue);
  });

  test('언어감각 — freeSenseLevels(기본 1)급까지 무료', () {
    final d = {
      'levels': [
        {'id': 'L1', 'lessons': [{'id': 'a'}, {'id': 'b'}]},
        {'id': 'L2', 'lessons': [{'id': 'c'}]},
      ],
    };
    CurriculumContent.freeSenseLevels = 1;
    expect(SenseCourse.freeAt(d, 0), isTrue);
    expect(SenseCourse.freeAt(d, 1), isTrue);
    expect(SenseCourse.freeAt(d, 2), isFalse);
    CurriculumContent.freeSenseLevels = 2;
    expect(SenseCourse.freeAt(d, 2), isTrue);
    CurriculumContent.freeSenseLevels = 1;
  });
}
