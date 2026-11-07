import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../services/dialogue_service.dart';
import 'lemma_chips.dart';

/// 회화 문장을 내용어(레마) 단위로 나눈다 — 단어장에 있는 말은 밑줄, 누르면 단어창(일본어앱 2026-11-07 §6).
/// 없는 말·기능어는 그냥 글자. 문장 줄을 누르는 동작(턴 이동)은 낱말 밖을 누르면 그대로 된다.
class LemmaText extends StatefulWidget {
  final String text;
  final List<Lemma> lemmas;
  final TextStyle style;
  const LemmaText({super.key, required this.text, required this.lemmas, required this.style});

  @override
  State<LemmaText> createState() => _LemmaTextState();
}

class _LemmaTextState extends State<LemmaText> {
  Map<String, WordRow> _found = const {};
  final List<TapGestureRecognizer> _taps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(LemmaText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _load();
  }

  Future<void> _load() async {
    final text = widget.text;
    final found = await LemmaChips.lookup({for (final l in widget.lemmas) l.base}.toList());
    if (mounted && text == widget.text) setState(() => _found = found);
  }

  void _clearTaps() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _clearTaps();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clearTaps();
    final text = widget.text;
    final spans = <InlineSpan>[];
    var at = 0;
    for (final l in widget.lemmas) {
      final w = _found[l.base];
      final i = text.indexOf(l.surface, at);
      if (i < 0) continue;
      if (w == null) continue; // 단어장에 없는 말은 앞뒤 글자와 함께 그대로 둔다
      if (i > at) spans.add(TextSpan(text: text.substring(at, i)));
      final tap = TapGestureRecognizer()..onTap = () => LemmaChips.showWord(context, w);
      _taps.add(tap);
      spans.add(TextSpan(
        text: l.surface,
        recognizer: tap,
        style: const TextStyle(decoration: TextDecoration.underline, decorationColor: AppColors.aiLight, decorationThickness: 1.5),
      ));
      at = i + l.surface.length;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
