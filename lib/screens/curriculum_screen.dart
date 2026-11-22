import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/curriculum.dart';
import '../services/dialogue_service.dart';
import '../services/learner_prefs.dart';
import '../services/tts_service.dart';

/// 토크버스 커리큘럼 — 레벨 고르기 → 코스(고른 다이얼로그) → 편마다 연습·확인 문제 → 복습 → 코스 시험(80%).
/// 기준 ~/talkverse/CURRICULUM_SPEC.md(2026-11-22). 기존 화면은 건드리지 않는 새 메뉴.
class CurriculumScreen extends StatefulWidget {
  /// 시험용 — 오늘 날짜를 바꿔 끼울 수 있게.
  final DateTime Function()? clock;
  const CurriculumScreen({super.key, this.clock});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final svc = DialogueService.instance;
  CurriculumState? s;
  bool pickingLevel = false;

  String get today => dayKey((widget.clock ?? DateTime.now)());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await svc.ensureLoaded();
    final st = await Curriculum.load();
    st.rollDay(today);
    if (!mounted) return;
    setState(() {
      s = st;
      pickingLevel = st.level == null;
    });
  }

  Future<void> _save() async {
    s!.touchStreak(today);
    await Curriculum.save(s!);
    if (mounted) setState(() {});
  }

  List<Dialogue> get levelPool => s?.level == null ? const [] : svc.list(region: s!.level);

  @override
  Widget build(BuildContext context) {
    final st = s;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('토크버스 커리큘럼'))),
      body: st == null
          ? const Center(child: CircularProgressIndicator())
          : pickingLevel
              ? _levelPicker(st)
              : _home(st),
    );
  }

  Widget _levelPicker(CurriculumState st) {
    final ls = Curriculum.levels(svc);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)),
      children: [
        Text(tr('레벨을 고르세요'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
        const SizedBox(height: 4),
        Text(tr('처음이면 가장 낮은 레벨부터 권해요.'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
        const SizedBox(height: 12),
        for (final (i, l) in ls.indexed)
          Builder(builder: (_) {
            final open = Curriculum.unlocked(svc, st, l);
            final n = svc.count(l);
            final done = svc.list(region: l).where((d) => st.passedDialogues.contains(d.id)).length;
            return Card(
              key: ValueKey('cur-level-$l'),
              child: ListTile(
                enabled: open,
                leading: CircleAvatar(backgroundColor: open ? AppColors.ai : AppColors.line, child: Text(l, style: const TextStyle(color: Colors.white, fontSize: 13))),
                title: Text('${tr(DialogueService.levelKo[l] ?? l)}${i == 0 && st.level == null ? ' · ${tr('추천')}' : ''}'),
                subtitle: Text(open ? trf('회화 {0}편 · 통과 {1}', [n, done]) : tr('앞 레벨을 모두 통과하면 열려요')),
                trailing: open ? const Icon(Icons.chevron_right) : const Icon(Icons.lock_outline, size: 18),
                onTap: open
                    ? () async {
                        st.level = l;
                        await _save();
                        setState(() => pickingLevel = false);
                      }
                    : null,
              ),
            );
          }),
      ],
    );
  }

  Widget _home(CurriculumState st) {
    final due = st.dueReviews(today);
    final c = st.course;
    final newLeft = max(0, st.newGoal - st.todayNew);
    final total = st.newGoal + st.todayReview + due.length;
    final doneN = st.todayNew.clamp(0, st.newGoal) + st.todayReview;
    final dailyDone = st.dailyDone(today);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
      children: [
        Row(children: [
          Text('${st.level} · ${tr(DialogueService.levelKo[st.level] ?? '')}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const Spacer(),
          TextButton(key: const ValueKey('cur-change-level'), onPressed: () => setState(() => pickingLevel = true), child: Text(tr('레벨 바꾸기'))),
        ]),
        // 오늘 분량
        Card(
          key: const ValueKey('cur-today'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(dailyDone ? tr('오늘 분량 끝') : trf('오늘: 복습 {0} · 새 편 {1}', [due.length, newLeft]),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sumi)),
                const Spacer(),
                if (st.streakCount > 0) Text(trf('연속 {0}일', [st.streakCount]), style: const TextStyle(color: AppColors.ai, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: total == 0 ? 1 : (doneN / total).clamp(0.0, 1.0), minHeight: 6, color: AppColors.ai, backgroundColor: AppColors.line),
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: [
                for (final g in kDailyGoals.keys)
                  ChoiceChip(
                    key: ValueKey('cur-goal-$g'),
                    label: Text({'light': tr('가볍게'), 'normal': tr('보통'), 'focus': tr('집중')}[g]!),
                    selected: st.dailyGoal == g,
                    onSelected: (_) async {
                      st.dailyGoal = g;
                      await _save();
                    },
                  ),
              ]),
              if (due.isNotEmpty) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const ValueKey('cur-review'),
                  onPressed: () => _review(st),
                  icon: const Icon(Icons.replay),
                  label: Text(trf('복습하기 ({0})', [due.length])),
                ),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 8),
        if (c == null)
          _noCourse(st)
        else
          _course(st, c),
      ],
    );
  }

  Widget _noCourse(CurriculumState st) {
    final pool = levelPool;
    final left = pool.where((d) => !st.passedDialogues.contains(d.id)).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(left == 0 && pool.isNotEmpty ? tr('이 레벨의 회화를 모두 통과했어요') : tr('코스를 만들어 시작하세요'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const SizedBox(height: 4),
          Text(tr('회화를 3·5·10편 골라 연습하고, 코스 시험 80% 이상이면 다음 코스로 넘어가요.'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
          const SizedBox(height: 10),
          FilledButton(key: const ValueKey('cur-new-course'), onPressed: () => _pickCourse(st), child: Text(tr('코스 만들기'))),
        ]),
      ),
    );
  }

  Widget _course(CurriculumState st, CourseState c) {
    final ds = [for (final id in c.dialogueIds) if (svc.byId(id) != null) svc.byId(id)!];
    final next = ds.where((d) => !c.practiced.contains(d.id)).firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(trf('지금 코스 · {0}편', [ds.length]), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sumi)),
            const Spacer(),
            TextButton(onPressed: () => _pickCourse(st), child: Text(tr('새 코스'))),
          ]),
          if (c.examScores.isNotEmpty)
            Text(trf('시험 기록: {0}', [c.examScores.map((e) => '$e%').join(' · ')]), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
          const SizedBox(height: 6),
          for (final d in ds)
            ListTile(
              key: ValueKey('cur-ep-${d.id}'),
              contentPadding: EdgeInsets.zero,
              leading: Text(d.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(d.title),
              subtitle: Text(tr(DialogueService.islandKo[d.island] ?? d.island)),
              trailing: Icon(c.practiced.contains(d.id) ? Icons.check_circle : Icons.play_circle_outline,
                  color: c.practiced.contains(d.id) ? AppColors.matcha : AppColors.ai),
              onTap: () => _practice(st, d),
            ),
          const SizedBox(height: 6),
          if (next != null)
            FilledButton(key: const ValueKey('cur-next'), onPressed: () => _practice(st, next), child: Text(trf('다음 연습: {0}', [next.title])))
          else
            FilledButton.icon(
                key: const ValueKey('cur-exam'), onPressed: () => _exam(st, ds), icon: const Icon(Icons.flag), label: Text(tr('코스 시험 보기'))),
        ]),
      ),
    );
  }

  Future<void> _pickCourse(CurriculumState st) async {
    final ids = await Navigator.push<List<String>>(
        context, MaterialPageRoute(builder: (_) => _CoursePicker(pool: levelPool, passed: st.passedDialogues.toSet(), hasCourse: st.course != null)));
    if (ids == null || ids.isEmpty) return;
    st.course = CourseState(id: '${st.level}-${DateTime.now().millisecondsSinceEpoch}', dialogueIds: ids);
    await _save();
  }

  Future<void> _practice(CurriculumState st, Dialogue d) async {
    final wrong = await Navigator.push<Set<int>>(context, MaterialPageRoute(builder: (_) => _PracticeScreen(d: d, pool: levelPool)));
    if (wrong == null) return;
    final c = st.course;
    final firstTime = c != null && !c.practiced.contains(d.id);
    if (c != null && c.dialogueIds.contains(d.id) && firstTime) st.course = c.copyWith(practiced: [...c.practiced, d.id]);
    if (firstTime) st.todayNew++;
    st.addPractice(d, wrong, today);
    await _save();
  }

  Future<void> _review(CurriculumState st) async {
    final due = st.dueReviews(today);
    final qs = <CQuestion>[];
    final r = Random();
    for (final it in due.take(20)) {
      final p = it.lineId.split('#');
      final d = svc.byId(p.first);
      final n = int.tryParse(p.length > 1 ? p[1] : '');
      if (d == null || n == null) {
        st.review.removeWhere((x) => x.lineId == it.lineId);
        continue;
      }
      qs.addAll(makeQuestions(d, svc.list(region: d.region), max: 1, rnd: r, onlyTurns: [n]));
    }
    if (qs.isEmpty) {
      await _save();
      return;
    }
    final res = await Navigator.push<List<(CQuestion, bool)>>(context, MaterialPageRoute(builder: (_) => _QuizScreen(title: tr('복습'), qs: qs)));
    if (res == null) return;
    for (final (q, ok) in res) {
      st.answerReview(q.lineId, ok, today);
    }
    st.todayReview += res.length;
    await _save();
  }

  Future<void> _exam(CurriculumState st, List<Dialogue> ds) async {
    final qs = makeExam(ds, levelPool);
    if (qs.isEmpty) return;
    final res = await Navigator.push<List<(CQuestion, bool)>>(context, MaterialPageRoute(builder: (_) => _QuizScreen(title: tr('코스 시험'), qs: qs)));
    if (res == null || !mounted) return;
    final ok = res.where((e) => e.$2).length;
    final pct = scorePercent(ok, res.length);
    final c = st.course!;
    final wrongEps = {for (final (q, good) in res) if (!good) q.lineId.split('#').first};
    final pass = isPass(ok, res.length);
    if (pass) {
      st.passedDialogues = {...st.passedDialogues, ...c.dialogueIds}.toList();
      st.course = null;
    } else {
      // 틀린 편만 다시 연습 → 다시 시험
      st.course = c.copyWith(examScores: [...c.examScores, pct], practiced: c.practiced.where((id) => !wrongEps.contains(id)).toList());
    }
    await _save();
    if (!mounted) return;
    final levelDone = pass && levelPool.every((d) => st.passedDialogues.contains(d.id));
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => _ResultScreen(
                pct: pct, pass: pass, levelDone: levelDone, wrongTitles: [for (final id in wrongEps) svc.byId(id)?.title ?? id])));
  }
}

/// 코스 고르기 — 3·5·10편, 추천으로 채우기, 지금 코스가 있으면 화면 안에서 버릴지 묻기.
class _CoursePicker extends StatefulWidget {
  final List<Dialogue> pool;
  final Set<String> passed;
  final bool hasCourse;
  const _CoursePicker({required this.pool, required this.passed, required this.hasCourse});
  @override
  State<_CoursePicker> createState() => _CoursePickerState();
}

class _CoursePickerState extends State<_CoursePicker> {
  int size = 5;
  final picked = <String>[];
  bool confirming = false;

  @override
  Widget build(BuildContext context) {
    final full = picked.length == size;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('코스 만들기'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(children: [
            for (final n in kCourseSizes)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: ValueKey('cur-size-$n'),
                  label: Text(trf('{0}편', [n])),
                  selected: size == n,
                  onSelected: (_) => setState(() {
                    size = n;
                    if (picked.length > n) picked.removeRange(n, picked.length);
                  }),
                ),
              ),
            const Spacer(),
            TextButton(
              key: const ValueKey('cur-recommend'),
              onPressed: () => setState(() {
                final r = Curriculum.recommend(widget.pool, widget.passed, size, keep: picked);
                picked
                  ..clear()
                  ..addAll(r);
              }),
              child: Text(tr('추천으로 채우기')),
            ),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: [
            for (final d in widget.pool)
              CheckboxListTile(
                key: ValueKey('cur-pick-${d.id}'),
                value: picked.contains(d.id),
                onChanged: (v) => setState(() {
                  if (v == true && picked.length < size) picked.add(d.id);
                  if (v == false) picked.remove(d.id);
                }),
                secondary: Text(d.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(d.title),
                subtitle: Text('${tr(DialogueService.islandKo[d.island] ?? d.island)}${widget.passed.contains(d.id) ? ' · ${tr('통과')} ✓' : ''}'),
              ),
          ]),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
          color: AppColors.washiDeep,
          child: confirming
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(tr('지금 코스를 버리고 새로 시작할까요? 연습 기록과 복습은 남아요.'), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => setState(() => confirming = false), child: Text(tr('취소')))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: FilledButton(
                            key: const ValueKey('cur-confirm-new'), onPressed: () => Navigator.pop(context, picked), child: Text(tr('새로 시작')))),
                  ]),
                ])
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('cur-start'),
                    onPressed: full ? () => widget.hasCourse ? setState(() => confirming = true) : Navigator.pop(context, picked) : null,
                    child: Text(trf('{0}/{1}편 · 시작', [picked.length, size])),
                  ),
                ),
        ),
      ]),
    );
  }
}

/// 편 연습 — 듣기·읽기(줄마다 뜻 보기, 줄 반복 듣기) → 확인 문제. 결과로 틀린 턴 번호를 돌려준다.
class _PracticeScreen extends StatefulWidget {
  final Dialogue d;
  final List<Dialogue> pool;
  const _PracticeScreen({required this.d, required this.pool});
  @override
  State<_PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<_PracticeScreen> {
  final shown = <int>{};
  int session = 0;
  int? playing;

  @override
  void dispose() {
    session++;
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _say(DialogueTurn t) =>
      TtsService.instance.speakAs(LearnerPrefs.fill(t.tl), gender: widget.d.voiceGender(t.speaker));

  Future<void> _playAll() async {
    final my = ++session;
    for (final t in widget.d.turns) {
      if (!mounted || my != session) return;
      setState(() => playing = t.num);
      await _say(t);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (mounted && my == session) setState(() => playing = null);
  }

  Future<void> _quiz() async {
    session++;
    await TtsService.instance.stop();
    if (!mounted) return;
    final qs = makeQuestions(widget.d, widget.pool);
    final res = await Navigator.push<List<(CQuestion, bool)>>(context, MaterialPageRoute(builder: (_) => _QuizScreen(title: widget.d.title, qs: qs)));
    if (res == null || !mounted) return;
    Navigator.pop(context, {for (final (q, ok) in res) if (!ok) int.parse(q.lineId.split('#').last)});
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(d.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        children: [
          Text(d.scene, style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
          const SizedBox(height: 8),
          Text(tr('1. 듣고 읽기 — 줄을 누르면 뜻이 보여요. 스피커는 그 줄 다시 듣기(따라 말해 보세요).'),
              style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
          const SizedBox(height: 8),
          for (final t in d.turns)
            Card(
              color: playing == t.num ? AppColors.kinBright : null,
              child: ListTile(
                key: ValueKey('cur-line-${t.num}'),
                title: Text('${d.speakerName(t.speaker)}: ${LearnerPrefs.fill(t.tl)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: shown.contains(t.num) ? Text(LearnerPrefs.fill(t.ko, 'ko')) : null,
                trailing: IconButton(icon: const Icon(Icons.volume_up), onPressed: () => _say(t)),
                onTap: () => setState(() => shown.contains(t.num) ? shown.remove(t.num) : shown.add(t.num)),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
        child: Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  key: const ValueKey('cur-play-all'), onPressed: _playAll, icon: const Icon(Icons.play_arrow), label: Text(tr('전체 듣기')))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton(key: const ValueKey('cur-quiz'), onPressed: _quiz, child: Text(tr('2. 확인 문제')))),
        ]),
      ),
    );
  }
}

/// 문제 풀기 — 4지선다, 고르면 바로 정답 표시, 다음. 끝나면 [(문제, 맞음)] 을 돌려준다.
class _QuizScreen extends StatefulWidget {
  final String title;
  final List<CQuestion> qs;
  const _QuizScreen({required this.title, required this.qs});
  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  int i = 0;
  String? chosen;
  final res = <(CQuestion, bool)>[];

  @override
  Widget build(BuildContext context) {
    if (widget.qs.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: Center(child: FilledButton(onPressed: () => Navigator.pop(context, res), child: Text(tr('끝')))));
    }
    final q = widget.qs[i];
    final last = i == widget.qs.length - 1;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text('${widget.title} · ${i + 1}/${widget.qs.length}')),
      body: ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)), children: [
        Text(q.kind == 'blank' ? tr('빈칸에 들어갈 낱말은?') : tr('이 문장의 뜻은?'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
        const SizedBox(height: 8),
        Text(q.prompt, key: const ValueKey('cur-q-prompt'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.sumi)),
        if (q.hint.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(q.hint, style: const TextStyle(color: AppColors.sumiLight))),
        const SizedBox(height: 16),
        for (final (k, o) in q.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              key: ValueKey('cur-opt-$k'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(14),
                backgroundColor: chosen == null
                    ? null
                    : o == q.answer
                        ? AppColors.matcha.withValues(alpha: 0.15)
                        : o == chosen
                            ? AppColors.sakuraDeep.withValues(alpha: 0.12)
                            : null,
              ),
              onPressed: chosen != null
                  ? null
                  : () => setState(() {
                        chosen = o;
                        res.add((q, o == q.answer));
                      }),
              child: Text(o, style: const TextStyle(fontSize: 15, color: AppColors.sumi)),
            ),
          ),
        if (chosen != null)
          FilledButton(
            key: const ValueKey('cur-q-next'),
            onPressed: () => last
                ? Navigator.pop(context, res)
                : setState(() {
                    i++;
                    chosen = null;
                  }),
            child: Text(last ? tr('끝') : tr('다음')),
          ),
      ]),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final int pct;
  final bool pass, levelDone;
  final List<String> wrongTitles;
  const _ResultScreen({required this.pct, required this.pass, required this.levelDone, required this.wrongTitles});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.washi,
        appBar: AppBar(title: Text(tr('코스 시험'))),
        body: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset(context)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('$pct%', key: const ValueKey('cur-score'), textAlign: TextAlign.center,
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: pass ? AppColors.matcha : AppColors.sakuraDeep)),
            const SizedBox(height: 8),
            Text(pass ? (levelDone ? tr('통과! 이 레벨을 모두 마쳐 다음 레벨이 열렸어요.') : tr('통과! 다음 코스를 만들어 이어 가세요.')) : tr('80% 에 못 미쳤어요. 틀린 편을 다시 연습하고 다시 시험 봐요.'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.sumi)),
            if (!pass && wrongTitles.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final t in wrongTitles) Text('· $t', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.sumiLight)),
            ],
            const Spacer(),
            FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr('확인'))),
          ]),
        ),
      );
}
