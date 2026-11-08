import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/tr_phonetics.dart';
import '../services/tts_service.dart';
import '../widgets/tr_sound_sheet.dart';

/// 알파벳과 발음 — 터키어 29자 격자 + 묶음 칩 + 한글 보조 표기 토글 + 모음조화(일본어앱 「50음도와 발음」 구조, 2026-11-08).
/// 글자를 누르면 발음 상세 시트(1초 뒤 자동 재생·IPA·소리 나는 곳·한국어 비교).
class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  int _set = 0; // 0 전체 · 1 모음 · 2 터키어 고유 글자 · 3 한국어 화자 주의 · 4 모음조화
  bool _showHint = true;

  static Color colorOf(TrLetter l) => l.vowel ? (l.front ? AppColors.beni : AppColors.rojo) : (l.special ? AppColors.sakuraDeep : AppColors.tinta);

  List<TrLetter> get _letters => switch (_set) {
        1 => trLetters.where((l) => l.vowel).toList(),
        2 => trLetters.where((l) => l.special).toList(),
        3 => trLetters.where((l) => l.tricky).toList(),
        _ => trLetters,
      };

  @override
  Widget build(BuildContext context) {
    final labels = [
      trf('전체 {0}', [trLetters.length]),
      trf('모음 {0}', [trLetters.where((l) => l.vowel).length]),
      trf('터키어 글자 {0}', [trLetters.where((l) => l.special).length]),
      trf('주의할 소리 {0}', [trLetters.where((l) => l.tricky).length]),
      tr('모음조화'),
    ];
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        backgroundColor: AppColors.washi,
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('알파벳과 발음'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(tr('탭하면 발음·IPA 상세'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 2)),
        ]),
        actions: [
          IconButton(
            tooltip: tr('한글 보조 표기'),
            icon: Text('가',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _showHint ? AppColors.beni : AppColors.sumiLight)),
            onPressed: () => setState(() => _showHint = !_showHint),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: AppColors.washiDeep,
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _set = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _set == i ? AppColors.beni : AppColors.washi,
                        border: Border.all(color: AppColors.beni, width: _set == i ? 1.5 : 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(labels[i],
                          style: TextStyle(color: _set == i ? AppColors.washi : AppColors.beni, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _set == 4 ? _harmony() : _grid()),
      ]),
    );
  }

  Widget _grid() {
    final ls = _letters;
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / 96).floor().clamp(4, 8);
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + bottomInset(context)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 96),
        itemCount: ls.length,
        itemBuilder: (context, i) {
          final l = ls[i], color = colorOf(l);
          return InkWell(
            onTap: () => showTrSoundSheet(context, l, color),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.washi,
                border: Border.all(color: color.withValues(alpha: 0.6), width: l.special ? 1.6 : 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                FittedBox(
                  child: Text('${l.upper} ${l.lower}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
                ),
                if (_showHint) ...[
                  const SizedBox(height: 2),
                  Text(l.hint, style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
                ],
              ]),
            ),
          );
        },
      );
    });
  }

  /// 모음조화 — 낱말 마지막 모음이 접미사 모음을 고른다. 칸을 누르면 발음.
  Widget _harmony() {
    Widget word(String w, String ko) => InkWell(
          onTap: () => TtsService.instance.speak(w),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              const Icon(Icons.volume_up, size: 16, color: AppColors.beni),
              const SizedBox(width: 6),
              Text(w, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.sumi)),
              const SizedBox(width: 8),
              Flexible(child: Text(ko, style: const TextStyle(fontSize: 12.5, color: AppColors.sumiLight))),
            ]),
          ),
        );
    Widget card(String title, String rule, List<Widget> rows) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.washiDeep,
            border: Border.all(color: AppColors.beni.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.beni)),
            const SizedBox(height: 4),
            Text(rule, style: const TextStyle(fontSize: 12.5, color: AppColors.sumi, height: 1.5)),
            const SizedBox(height: 6),
            ...rows,
          ]),
        );
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)),
      children: [
        Text(tr('터키어 접미사는 앞 낱말의 마지막 모음에 맞춰 모음이 바뀐다. 외우는 표가 아니라 귀로 익히는 규칙.'),
            style: const TextStyle(fontSize: 13, color: AppColors.sumi, height: 1.5)),
        const SizedBox(height: 12),
        const TrVowelChart(selected: ''),
        const SizedBox(height: 16),
        card(tr('2가지 — e / a'), tr('앞 모음(e i ö ü) 뒤 → e, 뒤 모음(a ı o u) 뒤 → a. 예: 복수 -ler / -lar'),
            [for (final x in harmony2) word('${x.$1} → ${x.$2}', x.$3)]),
        card(tr('4가지 — i / ı / ü / u'), tr('e·i 뒤 → i, a·ı 뒤 → ı, ö·ü 뒤 → ü, o·u 뒤 → u. 예: 「내 ~」 -im / -ım / -üm / -um'),
            [for (final x in harmony4) word('${x.$1} → ${x.$2}', x.$3)]),
      ],
    );
  }
}
