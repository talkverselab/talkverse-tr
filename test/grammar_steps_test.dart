import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkish_universe/screens/grammar_lesson_screen.dart';
import 'package:turkish_universe/services/script_sync.dart';

String sha(String s) => sha1.convert(utf8.encode(s)).toString().substring(0, 12);

/// 문법 스텝 1~10 — 내용은 서버 원고가 있으면 그것, 없으면 앱 안 것, 내용 없는 스텝은 숨김(2026-11-23).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  final orig = ScriptSync.instance;
  setUp(() => dir = Directory.systemTemp.createTempSync('grammar_steps'));
  tearDown(() {
    ScriptSync.instance = orig;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('서버를 못 받으면 묶음 목록(15칸) — 내용 있는 1스텝만 보인다', () async {
    final steps = json.decode(File('assets/data/grammar/steps.json').readAsStringSync()) as Map<String, dynamic>;
    expect((steps['steps'] as List).length, 15);
    ScriptSync.instance = ScriptSync.forTest(dir: dir, fetch: (_) async => null, baseline: {'rev': 2, 'files': {}});
    final ls = await GrammarLesson.loadAll(refresh: false);
    expect(ls.map((l) => l.number), [1]);
  });

  test('서버에 스텝 2 내용이 올라오면 앱을 다시 내지 않고 나타나고, 서버의 스텝 1 이 앱 것을 덮는다. 빈 스텝은 숨김', () async {
    const l1 = '{"lesson":1,"title":"서버 1","patterns":[{"id":"p","key":"k","label":"l","examples":[]}]}';
    const l2 = '{"lesson":2,"title":"서버 2","patterns":[{"id":"q","key":"k","label":"l","examples":[]}]}';
    const l3 = '{"lesson":3,"title":"빈 스텝","patterns":[]}';
    final files = {'grammar/lesson1.json': sha(l1), 'grammar/lesson2.json': sha(l2), 'grammar/lesson3.json': sha(l3)};
    Future<String?> fetch(String url) async {
      if (url.endsWith('/index.json')) return json.encode({'rev': 3, 'files': files});
      if (url.contains('lesson1.json')) return l1;
      if (url.contains('lesson2.json')) return l2;
      if (url.contains('lesson3.json')) return l3;
      return null;
    }

    ScriptSync.instance = ScriptSync.forTest(dir: dir, fetch: fetch, baseline: {'rev': 2, 'files': {}});
    final ls = await GrammarLesson.loadAll();
    expect(ls.map((l) => l.title), ['서버 1', '서버 2']);
  });

  test('서버 목록에서 스텝이 빠지면(묶음엔 있어도) 안 보이고, 순서·제목은 서버 목록을 따른다', () async {
    const l2 = '{"lesson":2,"title":"서버 2","patterns":[{"id":"q","key":"k","label":"l","examples":[]}]}';
    const steps = '{"steps":[{"step":2,"file":"grammar/lesson2.json","title":"둘째 스텝"}]}';
    final files = {'grammar/steps.json': sha(steps), 'grammar/lesson2.json': sha(l2)};
    Future<String?> fetch(String url) async {
      if (url.endsWith('/index.json')) return json.encode({'rev': 3, 'files': files});
      if (url.contains('steps.json')) return steps;
      if (url.contains('lesson2.json')) return l2;
      return null;
    }

    ScriptSync.instance = ScriptSync.forTest(dir: dir, fetch: fetch, baseline: {'rev': 2, 'files': {}});
    final ls = await GrammarLesson.loadAll();
    expect(ls.map((l) => l.title), ['둘째 스텝']); // 묶음 lesson1 은 서버 목록에 없어 숨김
  });
}
