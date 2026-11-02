import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';

/// 「어순 맞대기」 — 몽골어앱 UX 시안 01(사용자 통과 2026-11-03)의 접사·모음조화 칸을 터키어에 옮김(사용자 지시 2026-11-03).
/// 현재 문장의 낱말을 칩으로 늘어놓고, 낱말마다 모음조화 점(뒷모음 a ı o u = 청록, 앞모음 e i ö ü = 분홍)을 찍는다 —
/// 접사의 모음(-lar/-ler, -da/-de)이 앞 모음을 따라가는 것이 점 색으로 보인다. 터키어도 한국어처럼 주어-목적어-동사 어순이다.
/// 점 모양: 원순 모음(o ö u ü)은 동그라미, 평순(a ı e i)은 네모 — 4갈래 조화(-ı/-i/-u/-ü)가 색 × 모양으로 보인다.
/// 턴에 낱말 대응 데이터(`align`: [[터키어, 한국어], …])가 있으면 한국어 낱말을 아래에 맞대어 보인다.
/// 턴에 `morph` 가 있으면 그 낱말은 어간 칩 + 접사 칩(종류별 색)으로 쪼개 보인다(몽골어앱 아이디어 「접사 블록」). 둘 다 회화 작업 때 채운다(지금은 없음).
class WordOrderPanel extends StatelessWidget {
  final DialogueTurn turn;
  const WordOrderPanel({super.key, required this.turn});

  static const _back = 'aıouAIOU';
  static const _front = 'eiöüEİÖÜ';
  static const _backColor = AppColors.beniLight;
  static const _frontColor = Color(0xFFE88BB8);

  static List<String> _words(String s) => s.split(RegExp(r'[^\p{L}\p{M}-]+', unicode: true)).where((w) => w.isNotEmpty).toList();

  static const _rounded = 'oöuüOÖUÜ';

  /// 낱말 속 모음마다 (색, 원순인가).
  static List<(Color, bool)> _dots(String w) => [
    for (final ch in w.split(''))
      if (_back.contains(ch))
        (_backColor, _rounded.contains(ch))
      else if (_front.contains(ch))
        (_frontColor, _rounded.contains(ch)),
  ];

  /// 접사 종류별 색: 격 = 인디고 · 소유 = 초록 · 복수 = 주황 · 동사 어미 = 진한 파랑.
  static Color _kindColor(String kind) => switch (kind) {
    'case' => AppColors.ai,
    'poss' => AppColors.matcha,
    'plural' => const Color(0xFFE0822E),
    'verb' => const Color(0xFF1E4E8C),
    _ => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final pairs = turn.align.isNotEmpty ? turn.align : [for (final w in _words(turn.tl)) (w, '')];
    if (pairs.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.washi,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_vert, size: 16, color: AppColors.beni),
              const SizedBox(width: 6),
              Text(
                tr('어순 맞대기'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi),
              ),
              const Spacer(),
              _legend(_backColor, tr('뒷모음')),
              const SizedBox(width: 10),
              _legend(_frontColor, tr('앞모음')),
              const SizedBox(width: 10),
              _shapeLegend(),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final (tl, ko) in pairs) _pair(tl, ko, turn.morph[tl])]),
        ],
      ),
    );
  }

  Widget _legend(Color c, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        t,
        style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _shapeLegend() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _dot(AppColors.muted, true),
      const SizedBox(width: 2),
      Text(
        tr('원순'),
        style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600),
      ),
      const SizedBox(width: 6),
      _dot(AppColors.muted, false),
      const SizedBox(width: 2),
      Text(
        tr('평순'),
        style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600),
      ),
    ],
  );

  static Widget _dot(Color c, bool round) => Container(
    width: 6,
    height: 6,
    margin: const EdgeInsets.only(right: 3),
    decoration: BoxDecoration(
      color: c,
      shape: round ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: round ? null : BorderRadius.circular(1),
    ),
  );

  /// 어간 칩 + 접사 칩(종류별 색), 칩 아래 각자의 한국어 뜻.
  Widget _blocks(Morph m) => Wrap(
    spacing: 3,
    runSpacing: 3,
    children: [_block(m.root, '', AppColors.sumi), for (final x in m.suffixes) _block(x.s, x.ko, _kindColor(x.kind))],
  );

  Widget _block(String t, String ko, Color c) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
        child: Text(
          t,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      if (ko.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(ko, style: const TextStyle(fontSize: 11, color: AppColors.sumiLight)),
        ),
    ],
  );

  Widget _pair(String tl, String ko, Morph? morph) {
    final dots = _dots(tl);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morph != null && morph.suffixes.isNotEmpty)
          _blocks(morph)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.beni.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Text(
              tl,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi),
            ),
          ),
        if (dots.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [for (final (c, round) in dots.take(6)) _dot(c, round)]),
          ),
        if (ko.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFDEFF6), borderRadius: BorderRadius.circular(10)),
            child: Text(
              ko,
              style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
