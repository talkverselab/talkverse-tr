import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turkish_universe/core/prefs.dart';
import 'package:turkish_universe/services/curriculum.dart';
import 'package:turkish_universe/services/dialogue_service.dart';

/// 커리큘럼 단계(CURRICULUM_SPEC §12) — 위젯 시험과 섞이면 멈춰서 따로 둔다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('단계 목록 — 서버 rev 가 더 높으면 서버 것(pick·pass·daily 도), 서버 404 면 묶음 기본값', () async {
    SharedPreferences.setMockInitialValues({});
    CurriculumContent.fetchForTest = (_) async =>
        '{"rev":99,"stages":[{"n":1,"title":"1단계","dialogueIds":["r0_culture_a1","없는편"],"pick":[3],"pass":70,"daily":{"light":2,"normal":3,"focus":4}},{"n":2,"title":"2단계","dialogueIds":[]}]}';
    addTearDown(() => CurriculumContent.fetchForTest = null);
    final ss = await CurriculumContent.load(DialogueService.instance);
    expect(ss.map((x) => x.n), [1, 2]);
    expect(ss.first.dialogueIds, ['r0_culture_a1', '없는편']); // 화면에서 앱에 있는 편만 쓴다
    expect(ss.first.pick, [3]);
    expect(ss.first.pass, 70);
    expect(ss.first.daily['normal'], 3);
    expect(ss.last.daily, kDailyGoals); // daily 없으면 1·2·3
    CurriculumContent.fetchForTest = (_) async => null;
    await (await Prefs.getInstance()).remove('curriculum_content'); // 받아 둔 서버 판 지우기
    final base = await CurriculumContent.load(DialogueService.instance);
    expect(base.map((x) => x.n), [1, 2, 3]);
  });
}
