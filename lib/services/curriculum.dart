import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../core/embed_env.dart';
import '../core/prefs.dart';
import 'dialogue_service.dart';
import 'learner_prefs.dart';

/// 토크버스 커리큘럼(전 언어 공통 기준 ~/talkverse/CURRICULUM_SPEC.md, 2026-11-22).
/// 회화 레벨(R0~)에서 다이얼로그를 골라 코스 → 편마다 연습·확인 문제 → 간격 반복 복습(1·3·7일) → 코스 시험 80% 이상 통과.
/// 저장 키 `curriculum_v1`(전 언어 같음 — Prefs 가 통합 앱용 언어 접두를 붙인다).
const kCurriculumKey = 'curriculum_v1';
const kReviewSteps = [1, 3, 7];
const kPassPercent = 80;
const kCourseSizes = [3, 5, 10];
const kDailyGoals = {'light': 1, 'normal': 2, 'focus': 3};

/// 점수 = 정답 수 / 문제 수, 소수점 버림.
int scorePercent(int correct, int total) => total <= 0 ? 0 : (correct * 100) ~/ total;
bool isPass(int correct, int total, [int pass = kPassPercent]) => total > 0 && scorePercent(correct, total) >= pass;

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime _day(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String addDays(String day, int n) {
  final d = _day(day);
  return dayKey(DateTime(d.year, d.month, d.day + n));
}

class ReviewItem {
  final String lineId; // <편id>#<턴 번호>
  final String due; // yyyy-mm-dd
  final int step; // kReviewSteps 의 자리
  const ReviewItem(this.lineId, this.due, this.step);
  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory ReviewItem.fromJson(Map j) => ReviewItem('${j['lineId']}', '${j['due']}', (j['step'] as num?)?.toInt() ?? 0);
}

/// 간격 반복: 맞히면 다음 간격(1 → 3 → 7일, 7일 뒤 맞히면 졸업 = null), 틀리면 1일로.
/// [it] 이 null 이면 처음 넣는 줄(연습한 편의 줄) — 1일 뒤.
ReviewItem? reschedule(ReviewItem? it, String lineId, bool correct, String today) {
  if (it == null || !correct) return ReviewItem(lineId, addDays(today, kReviewSteps[0]), 0);
  final next = it.step + 1;
  if (next >= kReviewSteps.length) return null;
  return ReviewItem(lineId, addDays(today, kReviewSteps[next]), next);
}

class CourseState {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  final String? passedAt;
  const CourseState({required this.id, required this.dialogueIds, this.practiced = const [], this.examScores = const [], this.passedAt});
  bool get allPracticed => dialogueIds.every(practiced.contains);
  CourseState copyWith({List<String>? practiced, List<int>? examScores, String? passedAt}) => CourseState(
      id: id, dialogueIds: dialogueIds, practiced: practiced ?? this.practiced, examScores: examScores ?? this.examScores, passedAt: passedAt ?? this.passedAt);
  Map<String, dynamic> toJson() =>
      {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory CourseState.fromJson(Map j) => CourseState(
        id: '${j['id']}',
        dialogueIds: [for (final e in (j['dialogueIds'] as List? ?? const [])) '$e'],
        practiced: [for (final e in (j['practiced'] as List? ?? const [])) '$e'],
        examScores: [for (final e in (j['examScores'] as List? ?? const [])) (e as num).toInt()],
        passedAt: j['passedAt'] as String?,
      );
}

class CurriculumState {
  String? level;
  String dailyGoal;
  CourseState? course;
  List<String> passedDialogues;
  List<ReviewItem> review;
  int streakCount;
  String? streakLastDay;
  // 오늘 한 양(기준 형식 밖 보조 칸 — 「오늘 분량」 막대용)
  String? todayDay;
  int todayNew;
  int todayReview;

  CurriculumState({
    this.level,
    this.dailyGoal = 'normal',
    this.course,
    List<String>? passedDialogues,
    List<ReviewItem>? review,
    this.streakCount = 0,
    this.streakLastDay,
    this.todayDay,
    this.todayNew = 0,
    this.todayReview = 0,
  })  : passedDialogues = passedDialogues ?? [],
        review = review ?? [];

  Map<String, dynamic> toJson() => {
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': [for (final r in review) r.toJson()],
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
        'today': {'day': todayDay, 'new': todayNew, 'review': todayReview},
      };

  factory CurriculumState.fromJson(Map j) {
    final s = (j['streak'] as Map?) ?? const {};
    final t = (j['today'] as Map?) ?? const {};
    return CurriculumState(
      level: j['level'] as String?,
      dailyGoal: kDailyGoals.containsKey(j['dailyGoal']) ? j['dailyGoal'] as String : 'normal',
      course: j['course'] is Map ? CourseState.fromJson(j['course'] as Map) : null,
      passedDialogues: [for (final e in (j['passedDialogues'] as List? ?? const [])) '$e'],
      review: [for (final e in (j['review'] as List? ?? const [])) if (e is Map) ReviewItem.fromJson(e)],
      streakCount: (s['count'] as num?)?.toInt() ?? 0,
      streakLastDay: s['lastDay'] as String?,
      todayDay: t['day'] as String?,
      todayNew: (t['new'] as num?)?.toInt() ?? 0,
      todayReview: (t['review'] as num?)?.toInt() ?? 0,
    );
  }

  /// 단계 JSON 의 daily(없으면 1·2·3) — 화면이 지금 단계 값을 넣어 준다.
  Map<String, int> goals = kDailyGoals;
  int get newGoal => goals[dailyGoal] ?? kDailyGoals[dailyGoal] ?? 2;

  /// 날이 바뀌었으면 오늘 칸을 0 으로.
  void rollDay(String today) {
    if (todayDay != today) {
      todayDay = today;
      todayNew = 0;
      todayReview = 0;
    }
  }

  List<ReviewItem> dueReviews(String today) => review.where((r) => r.due.compareTo(today) <= 0).toList();

  bool dailyDone(String today) => todayDay == today && todayNew >= newGoal && dueReviews(today).isEmpty;

  /// 오늘 분량을 막 끝냈으면 연속 일수를 올린다(어제도 했으면 +1, 아니면 1).
  void touchStreak(String today) {
    if (!dailyDone(today) || streakLastDay == today) return;
    streakCount = streakLastDay == addDays(today, -1) ? streakCount + 1 : 1;
    streakLastDay = today;
  }

  /// 연습한 편: 줄을 모두 복습 대기열에(이미 있으면 그대로), 틀린 줄은 1일로.
  void addPractice(Dialogue d, Set<int> wrongTurns, String today) {
    for (final t in d.turns) {
      final id = '${d.id}#${t.num}';
      final i = review.indexWhere((r) => r.lineId == id);
      if (i < 0) {
        review.add(reschedule(null, id, true, today)!);
      } else if (wrongTurns.contains(t.num)) {
        review[i] = reschedule(review[i], id, false, today)!;
      }
    }
  }

  void answerReview(String lineId, bool correct, String today) {
    final i = review.indexWhere((r) => r.lineId == lineId);
    final next = reschedule(i < 0 ? null : review[i], lineId, correct, today);
    if (i >= 0) review.removeAt(i);
    if (next != null) review.add(next);
  }
}

class Curriculum {
  static Future<CurriculumState> load() async {
    final raw = (await Prefs.getInstance()).getString(kCurriculumKey);
    if (raw == null || raw.isEmpty) return CurriculumState();
    try {
      return CurriculumState.fromJson(json.decode(raw) as Map);
    } catch (_) {
      return CurriculumState();
    }
  }

  static Future<void> save(CurriculumState s) async =>
      (await Prefs.getInstance()).setString(kCurriculumKey, json.encode(s.toJson()));

  /// 회화 레벨(R0~) — 이야기(L1)는 넣지 않는다.
  static List<String> levels(DialogueService svc) => svc.regions.where((r) => r.startsWith('R')).toList()..sort();

  /// (참고용) 앞 레벨 편을 모두 통과했는지 — 레벨 잠금은 없다(일본어 기준 ceb91c3).
  static bool unlocked(DialogueService svc, CurriculumState s, String level) {
    final ls = levels(svc);
    final i = ls.indexOf(level);
    if (i <= 0) return i == 0;
    final prev = svc.list(region: ls[i - 1]);
    return prev.isNotEmpty && prev.every((d) => s.passedDialogues.contains(d.id));
  }

  /// 「추천으로 채우기」: 아직 통과 안 한 편에서 주제가 겹치지 않게 돌아가며 [n] 편.
  static List<String> recommend(List<Dialogue> pool, Set<String> passed, int n, {List<String> keep = const []}) {
    final out = [...keep];
    final byIsland = <String, List<Dialogue>>{};
    for (final d in pool) {
      if (passed.contains(d.id) || out.contains(d.id)) continue;
      byIsland.putIfAbsent(d.island, () => []).add(d);
    }
    final used = {for (final id in out) pool.firstWhere((d) => d.id == id, orElse: () => pool.first).island};
    final keys = byIsland.keys.toList()..sort((a, b) => (used.contains(a) ? 1 : 0).compareTo(used.contains(b) ? 1 : 0));
    var round = 0;
    while (out.length < n && byIsland.values.any((l) => l.length > round)) {
      for (final k in keys) {
        final l = byIsland[k]!;
        if (out.length < n && l.length > round) out.add(l[round].id);
      }
      round++;
    }
    return out;
  }
}

/// 확인 문제 한 개 — 뜻 고르기(4지선다) 또는 빈칸 낱말 고르기.
class CQuestion {
  final String lineId;
  final String kind; // meaning | blank
  final String prompt; // 보여 줄 터키어(빈칸이면 ___ 들어감)
  final String hint; // 빈칸 문제의 한국어 뜻
  final List<String> options;
  final String answer;
  const CQuestion(this.lineId, this.kind, this.prompt, this.hint, this.options, this.answer);
}

final _word = RegExp(r"[A-Za-zÇĞİÖŞÜçğıöşüÂâÎîÛû']+");

/// 한 편의 줄로 확인 문제를 만든다 — 줄 수만큼, 최대 [max]. 뜻·빈칸을 번갈아, 보기가 모자라면 뜻 문제로.
/// [pool] = 틀린 보기를 가져올 다른 편(같은 레벨).
List<CQuestion> makeQuestions(Dialogue d, List<Dialogue> pool, {int max = 10, Random? rnd, Iterable<int>? onlyTurns}) {
  final r = rnd ?? Random();
  final turns = d.turns.where((t) => t.tl.trim().isNotEmpty && t.ko.trim().isNotEmpty && (onlyTurns == null || onlyTurns.contains(t.num))).toList()
    ..shuffle(r);
  final others = [for (final x in pool) if (x.id != d.id) x];
  final src = others.isEmpty ? [d] : others; // 오답 보기 = 같은 레벨 다른 편(일본어 기준)
  final otherKo = <String>{for (final x in src) for (final t in x.turns) LearnerPrefs.fill(t.ko, 'ko')};
  final otherWords = <String>{
    for (final x in src) for (final t in x.turns) for (final m in _word.allMatches(LearnerPrefs.fill(t.tl))) if (m.group(0)!.length >= 3) m.group(0)!
  };
  final out = <CQuestion>[];
  for (final t in turns.take(max)) {
    final id = '${d.id}#${t.num}';
    final tl = LearnerPrefs.fill(t.tl), ko = LearnerPrefs.fill(t.ko, 'ko');
    if (out.length.isOdd) {
      final words = _word.allMatches(tl).map((m) => m.group(0)!).where((w) => w.length >= 3).toList();
      if (words.isNotEmpty) {
        words.sort((a, b) => b.length.compareTo(a.length));
        final w = words.first;
        final lw = w.toLowerCase();
        final wrong = (otherWords.where((x) => x.toLowerCase() != lw).toList()..shuffle(r)).take(3).toList();
        if (wrong.length == 3) {
          out.add(CQuestion(id, 'blank', tl.replaceFirst(w, '＿＿＿'), ko, ([w, ...wrong]..shuffle(r)), w));
          continue;
        }
      }
    }
    final wrong = (otherKo.where((x) => x != ko).toList()..shuffle(r)).take(3).toList();
    if (wrong.length < 3) continue;
    out.add(CQuestion(id, 'meaning', tl, '', ([ko, ...wrong]..shuffle(r)), ko));
  }
  return out;
}

/// 코스 시험 — 편마다 최소 3문제, 전체 최대 30문제.
List<CQuestion> makeExam(List<Dialogue> ds, List<Dialogue> pool, {Random? rnd}) {
  final r = rnd ?? Random();
  if (ds.isEmpty) return [];
  final per = max(3, min(10, 30 ~/ ds.length)); // 편당 max(3, min(10, 30÷편수))
  final out = <CQuestion>[for (final d in ds) ...makeQuestions(d, pool, max: per, rnd: r)];
  out.shuffle(r);
  return out.take(30).toList();
}

/// 커리큘럼 단계(1~5) — 어느 편이 어느 단계인지는 서버가 준다(CURRICULUM_SPEC §12, 2026-11-23).
class CStage {
  final int n;
  final String title, desc;
  final List<String> dialogueIds;
  final List<int> pick;
  final int pass;
  final Map<String, int> daily; // 하루 새 편 수 light·normal·focus
  const CStage(this.n, this.title, this.desc, this.dialogueIds, this.pick, this.pass, [this.daily = kDailyGoals]);
  String get key => '$n';
  factory CStage.fromJson(Map j) => CStage(
        (j['n'] as num).toInt(),
        '${j['title'] ?? '${j['n']}단계'}',
        '${j['desc'] ?? ''}',
        [for (final e in (j['dialogueIds'] as List? ?? const [])) '$e'],
        [for (final e in (j['pick'] as List? ?? kCourseSizes)) (e as num).toInt()],
        (j['pass'] as num?)?.toInt() ?? kPassPercent,
        {
          for (final k in kDailyGoals.keys)
            k: ((j['daily'] as Map?)?[k] as num?)?.toInt() ?? kDailyGoals[k]!,
        },
      );
}

/// 옛 저장값(R0~R5) → 단계 번호(R0·R1 → 1, R2 → 2 …).
String stageOfLevel(String? level) {
  if (level == null) return '';
  final m = RegExp(r'^R(\d)$').firstMatch(level);
  if (m == null) return level;
  final r = int.parse(m.group(1)!);
  return '${r <= 1 ? 1 : r}';
}

/// 단계 목록 — 앱에 묶은 `assets/curriculum_tr.json`(기본값) < 기기에 받아 둔 서버 판 < 서버의 더 높은 rev.
/// 서버 `GET https://talkverse.uk/api/curriculum/tr`(배포 전엔 404 → 묶음 그대로). 다 실패하면 회화 레벨로 만든 단계.
class CurriculumContent {
  static const url = 'https://talkverse.uk/api/curriculum/tr';
  static const _kCache = 'curriculum_content';
  static Future<String?> Function(String url)? fetchForTest;

  static Future<List<CStage>> load(DialogueService svc, {bool refresh = true}) async {
    Map? best;
    try {
      best = json.decode(await rootBundle.loadString(assetPath('assets/curriculum_tr.json'))) as Map;
    } catch (_) {}
    final prefs = await Prefs.getInstance();
    try {
      final c = prefs.getString(_kCache);
      if (c != null) {
        final j = json.decode(c) as Map;
        if (_rev(j) > _rev(best)) best = j;
      }
    } catch (_) {}
    if (refresh) {
      try {
        final body = await (fetchForTest ?? _get)(url).timeout(const Duration(seconds: 6));
        if (body != null) {
          final j = json.decode(body) as Map;
          if (j['stages'] is List && _rev(j) > _rev(best)) {
            best = j;
            await prefs.setString(_kCache, body);
          }
        }
      } catch (_) {}
    }
    final out = <CStage>[];
    try {
      for (final e in (best?['stages'] as List? ?? const [])) {
        if (e is Map) out.add(CStage.fromJson(e));
      }
    } catch (_) {
      out.clear();
    }
    if (out.isEmpty) {
      // 기본값: 회화 레벨로 단계(R0+R1 → 1 …)
      final by = <int, List<String>>{};
      for (final d in svc.all) {
        final s = int.tryParse(stageOfLevel(d.region)) ?? 0;
        if (s > 0) by.putIfAbsent(s, () => []).add(d.id);
      }
      for (final n in by.keys.toList()..sort()) {
        out.add(CStage(n, '$n단계', '', by[n]!, kCourseSizes, kPassPercent));
      }
    }
    out.sort((a, b) => a.n.compareTo(b.n));
    return out;
  }

  static int _rev(Map? j) => (j?['rev'] as num?)?.toInt() ?? 0;

  static Future<String?> _get(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close().timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      return await res.transform(utf8.decoder).join();
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
