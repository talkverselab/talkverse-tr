import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/tr_affixes.dart';
import '../widgets/affix_sheet.dart';

/// 홈 「접사 사전」 — 격어미·복수·소유·동사 어미를 종류별로. 줄을 누르면 설명 시트(모음조화 연출·앱 안 예문).
class AffixDictionaryScreen extends StatelessWidget {
  const AffixDictionaryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.washi,
        appBar: AppBar(
          title: Text(tr('접사 사전')),
          actions: [
            IconButton(
              tooltip: tr('접사 카드로 연습'),
              icon: const Icon(Icons.style_outlined),
              onPressed: () => openFull(context, (_) => const AffixQuizScreen()),
            ),
          ],
        ),
        body: FutureBuilder(
          future: AffixCorpus.instance.ensureLoaded(),
          builder: (context, snap) => ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
            children: [
              Text(tr('터키어는 낱말 끝에 접사를 줄줄이 붙여 뜻을 바꿉니다(ev → evler → evlerim → evlerimde). 한국어 조사·어미와 거의 1:1 — 모양은 앞 모음에 맞춰 골라요(모음조화).'),
                  style: const TextStyle(fontSize: 13.5, color: AppColors.sumiLight, height: 1.45)),
              for (final k in AffixKind.values) ...[
                const SizedBox(height: 18),
                Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: k.color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(tr(k.label), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                ]),
                const SizedBox(height: 8),
                for (final a in kTrAffixes.where((a) => a.kind == k)) _AffixRow(a: a, count: AffixCorpus.instance.count(a.id)),
              ],
            ],
          ),
        ),
      );
}

class _AffixRow extends StatelessWidget {
  final Affix a;
  final int count;
  const _AffixRow({required this.a, required this.count});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.washi,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
          boxShadow: kCardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: () => AffixSheet.show(context, a),
            title: Text(tr(a.name), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.sumi)),
            subtitle: Text(a.variants.map((f) => '-$f').join(' / '),
                style: TextStyle(fontSize: 13, color: a.kind.color, fontWeight: FontWeight.w700)),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(border: Border.all(color: a.kind.color, width: 1.2), borderRadius: BorderRadius.circular(8)),
                child: Text(a.ko.split(' / ').first, style: TextStyle(fontSize: 11.5, color: a.kind.color, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 2),
              Text(trf('예문 {0}', [count]), style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
            ]),
          ),
        ),
      );
}

/// 접사 카드 — 앞면: 어간 + 빈칸, 한국어 조사 힌트와 문장 뜻. 모음조화로 맞는 형태를 고른다.
/// 문제는 앱 안 문장에서 나눈 낱말로만 만든다(형태가 2개 이상인 접사).
class AffixQuizScreen extends StatefulWidget {
  final String? affixId;
  const AffixQuizScreen({super.key, this.affixId});
  @override
  State<AffixQuizScreen> createState() => _AffixQuizScreenState();
}

class _AffixQuizScreenState extends State<AffixQuizScreen> {
  List<AffixExample> _qs = [];
  bool _ready = false;
  int _i = 0, _right = 0;
  String? _chosen;

  @override
  void initState() {
    super.initState();
    AffixCorpus.instance.ensureLoaded().then((_) {
      final src = widget.affixId == null ? AffixCorpus.instance.all : AffixCorpus.instance.examplesOf(widget.affixId!);
      final seen = <String>{};
      final qs = [
        for (final e in src)
          if ((widget.affixId == null || e.hit.affix.id == widget.affixId) && e.hit.affix.variants.length >= 2 && seen.add(e.hit.word.toLowerCase())) e,
      ]..shuffle(Random());
      if (!mounted) return;
      setState(() {
        _qs = qs.take(12).toList();
        _ready = true;
      });
    });
  }

  void _pick(String f) {
    if (_chosen != null) return;
    final q = _qs[_i];
    setState(() {
      _chosen = f;
      if (f.toLowerCase() == q.hit.suffix.toLowerCase()) _right++;
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _chosen = null;
        _i++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('접사 카드'))),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : _qs.isEmpty
              ? Center(child: Text(tr('아직 앱 문장에는 이 접사가 없어요.'), style: const TextStyle(color: AppColors.muted)))
              : _i >= _qs.length
                  ? _done()
                  : _card(_qs[_i]),
    );
  }

  Widget _done() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(trf('끝! 맞음 {0} / {1}', [_right, _qs.length]),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr('닫기'))),
        ]),
      );

  Widget _card(AffixExample q) {
    final a = q.hit.affix;
    final c = a.kind.color;
    final ok = q.hit.suffix.toLowerCase();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset(context)),
          children: [
            Text('${_i + 1} / ${_qs.length}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.washi, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(q.hit.beforeLast, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                  Container(
                    margin: const EdgeInsets.only(left: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: c, width: 1.6), borderRadius: BorderRadius.circular(10)),
                    child: Text(_chosen == null ? '＿＿' : '-${q.hit.suffix}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c)),
                  ),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: c, width: 1.2), borderRadius: BorderRadius.circular(8)),
                  child: Text('${tr(a.name)} · ${a.ko}', style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                Text(q.ko, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.sumiLight)),
                if (_chosen != null) ...[
                  const SizedBox(height: 6),
                  Text(q.tl, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.sumi, fontWeight: FontWeight.w600)),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            Text(tr('앞 모음에 맞는 형태를 고르세요'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
            const SizedBox(height: 10),
            Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
              for (final f in a.variants)
                ChoiceChip(
                  label: Text('-$f', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  selected: _chosen == f,
                  selectedColor: f.toLowerCase() == ok ? AppColors.matcha.withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.18),
                  side: BorderSide(color: _chosen != null && f.toLowerCase() == ok ? AppColors.matcha : AppColors.line, width: 1.4),
                  onSelected: (_) => _pick(f),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}
