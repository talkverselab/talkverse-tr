import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/tr_phonetics.dart';
import '../services/tts_service.dart';

/// 글자 탭 → 발음 상세 시트(일본어앱 kana_sound_sheet 구조). 열리면 1초 뒤 자동 재생, 다시 듣기, IPA,
/// 소리 나는 곳, 모음 위치(모음) 또는 조음 위치 그림(자음), 한국어 화자 비교, 예시 낱말.
Future<void> showTrSoundSheet(BuildContext context, TrLetter l, Color color) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.washi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _TrSoundSheet(l: l, color: color),
    );

/// 글자 소리 — 모음은 그 소리, 자음은 글자 이름(çe·yumuşak ge …)을 읽힌다.
void speakLetter(TrLetter l) => TtsService.instance.speak(l.name);

class _TrSoundSheet extends StatefulWidget {
  final TrLetter l;
  final Color color;
  const _TrSoundSheet({required this.l, required this.color});

  @override
  State<_TrSoundSheet> createState() => _TrSoundSheetState();
}

class _TrSoundSheetState extends State<_TrSoundSheet> {
  Timer? _auto;
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    _auto = Timer(const Duration(seconds: 1), () => speakLetter(widget.l));
  }

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l, color = widget.color;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => SafeArea(
        top: false,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
          children: [
            Center(
              child: Container(
                  width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Text('${l.upper}${l.lower}',
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.washi)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 4),
                  Text('IPA [${l.ipa}]', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                ]),
              ),
              IconButton(
                iconSize: 44,
                color: color,
                tooltip: tr('다시 듣기'),
                icon: const Icon(Icons.play_circle_fill),
                onPressed: () => speakLetter(l),
              ),
            ]),
            const SizedBox(height: 12),
            // 예시 낱말 — 누르면 발음
            InkWell(
              onTap: () => TtsService.instance.speak(l.example),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.volume_up, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(l.example, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l.exampleKo, style: const TextStyle(fontSize: 13, color: AppColors.sumiLight))),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            _section(tr('👄 소리 나는 곳 · 입모양'), l.place, color),
            const SizedBox(height: 14),
            if (l.vowel)
              _box(
                color,
                tr('📍 모음 위치 — 터키어 8모음'),
                TrVowelChart(selected: l.lower),
              )
            else ...[
              InkWell(
                onTap: () => setState(() => _showChart = !_showChart),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Icon(_showChart ? Icons.expand_less : Icons.expand_more, size: 18, color: color),
                    Text(tr('자음 조음 위치 그림 보기'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                  ]),
                ),
              ),
              if (_showChart) ...[ // 임시 그림 — 출시 전 Grok 그림으로 교체(사용자 지시 2026-11-08, 출처 표기 없음)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: Image.asset('assets/images/ipa/places_of_articulation.png', fit: BoxFit.contain),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 14),
            _section(tr('🇰🇷 한국어와 비교'), trf('비슷한 소리: {0}\n\n{1}', [l.korSim, l.korDiff]), color),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body, Color color) =>
      _box(color, title, Text(body, style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.sumi)));

  Widget _box(Color color, String title, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.washiDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 8),
          child,
        ]),
      );
}

/// 터키어 8모음을 혀 위치(앞·뒤 × 높·낮)와 입술(평순·원순)로 찍은 표. 고른 모음은 진하게,
/// 가까운 한국어 모음은 회색 글자로 옆에 둔다.
class TrVowelChart extends StatelessWidget {
  final String selected;
  const TrVowelChart({super.key, required this.selected});

  static const _cells = [
    // (행: 0 높음 · 1 낮음, 열: 0 앞평순 · 1 앞원순 · 2 뒤평순 · 3 뒤원순, 글자, 한국어)
    (0, 0, 'i', 'ㅣ'), (0, 1, 'ü', 'ㅟ'), (0, 2, 'ı', 'ㅡ'), (0, 3, 'u', 'ㅜ'),
    (1, 0, 'e', 'ㅔ'), (1, 1, 'ö', 'ㅚ'), (1, 2, 'a', 'ㅏ'), (1, 3, 'o', 'ㅗ'),
  ];

  @override
  Widget build(BuildContext context) {
    final head = [tr('앞 · 평순'), tr('앞 · 원순'), tr('뒤 · 평순'), tr('뒤 · 원순')];
    Widget cell(int r, int c) {
      final x = _cells.firstWhere((e) => e.$1 == r && e.$2 == c);
      final on = x.$3 == selected;
      return Expanded(
        child: GestureDetector(
          onTap: () => TtsService.instance.speak(x.$3),
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: on ? AppColors.beni : AppColors.washi,
              border: Border.all(color: on ? AppColors.beni : AppColors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              Text(x.$3, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: on ? AppColors.washi : AppColors.sumi)),
              Text(x.$4, style: TextStyle(fontSize: 11, color: on ? AppColors.washi : AppColors.muted)),
            ]),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const SizedBox(width: 36),
        for (final h in head)
          Expanded(
            child: Text(h, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 10, color: AppColors.muted, height: 1.2)),
          ),
      ]),
      for (var r = 0; r < 2; r++)
        Row(children: [
          SizedBox(
            width: 36,
            child: Text(r == 0 ? tr('높음') : tr('낮음'), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ),
          for (var c = 0; c < 4; c++) cell(r, c),
        ]),
      const SizedBox(height: 6),
      Text(tr('앞 모음(e i ö ü) 낱말에는 앞 모음 접미사, 뒤 모음(a ı o u) 낱말에는 뒤 모음 접미사가 붙는다 — 모음조화.'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.sumi, height: 1.45)),
    ]);
  }
}
