import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../services/tts_service.dart';

/// 단어 퀴즈 복습(일본어앱 `gairaigo_quiz_screen.dart` 110번을 터키어로, 2026-11-19).
/// 두 꼴 — 철자(바르게 쓴 터키어 고르기)와 뜻 고르기, 보기 1~4, 10문제. 틀린 단어는 다음 복습에 먼저.
/// 철자 문제의 틀린 보기는 터키어 글자를 바꾼 꼴(ı↔i·ş↔s·ç↔c·ğ↔g·ö↔o·ü↔u, ğ 빼기)로 만든다.
const int kWordQuizSize = 10;
const String _kWrong = 'word_quiz_wrong';

class WQWord {
  final String tx, rd, ko;
  const WQWord(this.tx, this.rd, this.ko);
}

const _pairs = {'ı': 'i', 'i': 'ı', 'ş': 's', 's': 'ş', 'ç': 'c', 'c': 'ç', 'ğ': 'g', 'g': 'ğ', 'ö': 'o', 'o': 'ö', 'ü': 'u', 'u': 'ü'};
const _special = 'ışçğöü';

/// 글자를 바꾼 틀린 꼴들(실제 단어와 겹치는 것은 뺀다). 터키어 특수 글자가 걸린 꼴을 앞에 둔다.
List<String> turkishMisspellings(String tx, Set<String> real) {
  final c = tx.split('');
  final first = <String>{}, rest = <String>{};
  final idx = <int>[];
  for (var i = 0; i < c.length; i++) {
    final s = _pairs[c[i]];
    if (s == null) continue;
    idx.add(i);
    final w = ([...c]..[i] = s).join();
    (_special.contains(c[i]) || _special.contains(s) ? first : rest).add(w);
    if (c[i] == 'ğ') first.add(([...c]..removeAt(i)).join());
  }
  // 두 글자를 함께 바꾼 꼴 — 짧은 단어도 보기 셋을 채우게.
  for (var a = 0; a < idx.length; a++) {
    for (var b = a + 1; b < idx.length; b++) {
      final x = [...c];
      x[idx[a]] = _pairs[c[idx[a]]]!;
      x[idx[b]] = _pairs[c[idx[b]]]!;
      rest.add(x.join());
    }
  }
  return {...first, ...rest}.where((s) => s != tx && s.isNotEmpty && !real.contains(s)).toList();
}

class _Q {
  final WQWord w;
  final bool spelling; // true = 철자, false = 뜻
  final List<String> options;
  const _Q(this.w, this.spelling, this.options);
  String get answer => spelling ? w.tx : w.ko;
}

class WordQuizScreen extends StatefulWidget {
  final List<WQWord> words;
  final int? seed;
  const WordQuizScreen({super.key, required this.words, this.seed});
  @override
  State<WordQuizScreen> createState() => _WordQuizScreenState();
}

class _WordQuizScreenState extends State<WordQuizScreen> {
  late final _rnd = Random(widget.seed);
  List<_Q>? _qs;
  int _i = 0;
  String? _picked;
  int _right = 0;
  final List<WQWord> _missed = [];

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final p = await Prefs.getInstance();
    final wrong = (p.getStringList(_kWrong) ?? const []).toSet();
    final uniq = <String, WQWord>{for (final w in widget.words) if (w.tx.isNotEmpty && w.ko.isNotEmpty) w.tx: w}.values.toList()..shuffle(_rnd);
    uniq.sort((a, b) => (wrong.contains(b.tx) ? 1 : 0) - (wrong.contains(a.tx) ? 1 : 0));
    final picked = uniq.take(kWordQuizSize).toList()..shuffle(_rnd);
    final real = {for (final w in widget.words) w.tx};
    final qs = <_Q>[];
    for (var k = 0; k < picked.length; k++) {
      final w = picked[k];
      final miss = (turkishMisspellings(w.tx, real)..shuffle(_rnd)).take(3).toList();
      if (k.isEven && miss.length == 3) {
        qs.add(_Q(w, true, [w.tx, ...miss]..shuffle(_rnd)));
      } else {
        final others = ({for (final o in uniq) if (o.ko != w.ko) o.ko}.toList()..shuffle(_rnd)).take(3);
        qs.add(_Q(w, false, [w.ko, ...others]..shuffle(_rnd)));
      }
    }
    if (mounted) setState(() => _qs = qs);
  }

  Future<void> _record(String tx, bool ok) async {
    final p = await Prefs.getInstance();
    final s = (p.getStringList(_kWrong) ?? const []).toSet();
    ok ? s.remove(tx) : s.add(tx);
    await p.setStringList(_kWrong, s.toList());
  }

  void _again() => setState(() {
        _qs = null;
        _i = 0;
        _picked = null;
        _right = 0;
        _missed.clear();
        _build();
      });

  @override
  Widget build(BuildContext context) {
    final qs = _qs;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('퀴즈 복습'))),
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : _i >= qs.length
              ? _summary(qs.length)
              : _question(qs[_i], qs.length),
    );
  }

  Widget _summary(int n) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(trf('{0}문제 중 {1}개 맞힘', [n, _right]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            if (_missed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(tr('틀린 단어 — 다음 복습에 먼저 나와요'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
              const SizedBox(height: 6),
              for (final w in _missed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${w.tx}  ${w.ko}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                ),
            ],
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton(key: const ValueKey('wq-again'), onPressed: _again, child: Text(tr('한 번 더'))),
              const SizedBox(width: 10),
              FilledButton(onPressed: () => Navigator.of(context).maybePop(), style: FilledButton.styleFrom(backgroundColor: AppColors.sumi), child: Text(tr('나가기'))),
            ]),
          ]),
        ),
      );

  Widget _question(_Q q, int n) {
    final w = q.w;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${tr(q.spelling ? '철자' : '뜻')} · ${_i + 1} / $n', style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
        const SizedBox(height: 14),
        Text(
          q.spelling ? w.ko : w.tx,
          key: const ValueKey('wq-stem'),
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.sumi, decoration: TextDecoration.underline, decorationColor: AppColors.sumiLight),
        ),
        const SizedBox(height: 8),
        Text(tr(q.spelling ? '터키어로 바르게 쓴 것을 고르세요.' : '뜻으로 맞는 것을 고르세요.'), style: const TextStyle(fontSize: 14, color: AppColors.sumi)),
        if (_picked != null && w.rd.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(q.spelling ? '${w.tx} · ${w.rd}' : w.rd, style: const TextStyle(fontSize: 13, color: AppColors.ai, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 14),
        for (var k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: ValueKey('wq-opt-$k'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: _picked == null ? null : (q.options[k] == q.answer ? const Color(0x3336A35B) : (q.options[k] == _picked ? const Color(0x33D83A3A) : null)),
                side: BorderSide(color: _picked != null && q.options[k] == q.answer ? AppColors.matcha : AppColors.line, width: 1.4),
              ),
              onPressed: _picked != null
                  ? null
                  : () {
                      final ok = q.options[k] == q.answer;
                      TtsService.instance.speak(w.tx);
                      _record(w.tx, ok);
                      setState(() {
                        _picked = q.options[k];
                        ok ? _right++ : _missed.add(w);
                      });
                    },
              child: Row(children: [
                SizedBox(width: 26, child: Text('${k + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumiLight))),
                Expanded(child: Text(q.options[k], style: TextStyle(fontSize: q.spelling ? 20 : 16, fontWeight: FontWeight.w800, color: AppColors.sumi))),
              ]),
            ),
          ),
        if (_picked != null)
          FilledButton(
            key: const ValueKey('wq-next'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sumi, minimumSize: const Size.fromHeight(48)),
            onPressed: () => setState(() {
              _i++;
              _picked = null;
            }),
            child: Text(tr('다음 →')),
          ),
      ]),
    );
  }
}
