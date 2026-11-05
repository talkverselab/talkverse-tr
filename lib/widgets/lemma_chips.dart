import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';

/// 문장의 내용어(레마) 칩 — 단어장(빈도 단어)에 있는 말은 누르면 단어 시트, 없는 말은 회색(일본어앱 2026-11-04 사용자 지시
/// "문장 레마별로 단어장이랑 연결"). 같은 기본형은 한 번만. 단어장에 없는 레마는 uk 세션이 채운다(data/review/write/missing_lemmas.csv).
class LemmaChips extends StatelessWidget {
  final DialogueTurn turn;
  final bool compact;
  const LemmaChips({super.key, required this.turn, this.compact = false});

  static Future<Map<String, WordRow>> _lookup(List<String> bases) async {
    if (bases.isEmpty) return const {};
    final rows = await (appDb.select(appDb.words)..where((w) => w.word.isIn(bases))).get();
    return {for (final r in rows) r.word: r};
  }

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final lemmas = [for (final l in turn.lemmas) if (seen.add(l.base)) l];
    if (lemmas.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<Map<String, WordRow>>(
      key: ValueKey('${turn.num}:${turn.tl}'),
      future: _lookup([for (final l in lemmas) l.base]),
      builder: (context, snap) {
        final found = snap.data ?? const {};
        final chips = [
          for (final l in lemmas)
            _Chip(
              label: l.base,
              gloss: found[l.base]?.meaningKo,
              compact: compact,
              onTap: found[l.base] == null ? null : () => _showWord(context, found[l.base]!),
            ),
          if (snap.connectionState == ConnectionState.done && found.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(tr('단어장에 없는 말'), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            ),
        ];
        // 폰(compact)은 한 줄 가로 스크롤 — 칩이 쌓여 그림을 밀어내지 않게
        if (compact) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [for (var i = 0; i < chips.length; i++) ...[if (i > 0) const SizedBox(width: 6), chips[i]]]),
          );
        }
        return Wrap(spacing: 6, runSpacing: 6, children: chips);
      },
    );
  }

  static Future<void> _showWord(BuildContext context, WordRow w) => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        backgroundColor: AppColors.washi,
        builder: (c) => Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset(c)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(w.word, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.sumi))),
              IconButton(
                onPressed: () => TtsService.instance.speak(w.word),
                icon: const Icon(Icons.volume_up, color: AppColors.beni),
              ),
            ]),
            if ((w.meaningKo ?? '').isNotEmpty)
              Text(w.meaningKo!, style: const TextStyle(fontSize: 17, color: AppColors.sumiLight, height: 1.4)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              if ((w.region ?? '').isNotEmpty && w.region != 'conv') _tag(w.region!),
              if ((w.pos ?? '').isNotEmpty) _tag(w.pos!),
              if (w.region != 'conv') _tag(trf('빈도 {0}위', [w.rank])), // 회화 레마 단어는 절벽 목록 밖 — 순위를 보이지 않는다
            ]),
          ]),
        ),
      );

  static Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.washiDeep, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final String? gloss;
  final bool compact;
  final VoidCallback? onTap;
  const _Chip({required this.label, this.gloss, this.compact = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
        decoration: BoxDecoration(
          color: on ? AppColors.washi : AppColors.washiDeep,
          border: Border.all(color: on ? AppColors.beni.withValues(alpha: 0.7) : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  fontSize: compact ? 12 : 13.5, fontWeight: FontWeight.w800, color: on ? AppColors.sumi : AppColors.muted)),
          if (gloss != null && gloss!.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(gloss!.split(RegExp(r'[,;·/]')).first.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: compact ? 10 : 11, color: AppColors.sumiLight)),
          ],
        ]),
      ),
    );
  }
}
