import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/art_service.dart';
import '../services/content_sync.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';

/// 절벽 단어 — 빈도 1~2,000위를 구간(R1~R5)별 **20어 단원**, 단어는 **네모 타일**(일본어앱 2026-11-07).
/// 「회화 단어 포함」이면 회화에 나오지만 2,000위 밖인 단어(DB region=conv)가 「회화」 구간으로 뒤에 붙는다(등장 횟수순).
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

const int kUnit = 20;

class _Region {
  final String label;
  final Color color;
  const _Region(this.label, this.color);
}

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<WordRow> _words = const [];
  List<WordRow> _conv = const [];
  bool _loading = true;
  bool _withConv = false;
  String _filter = 'ALL';
  String _query = '';

  static Map<String, _Region> get _regions => {
        'ALL': _Region(tr('전체'), AppColors.tinta),
        'R1': const _Region('R1 · 1-119', AppColors.beni),
        'R2': const _Region('R2 · 120-157', AppColors.beniLight),
        'R3': const _Region('R3 · 158-282', AppColors.mar),
        'R4': const _Region('R4 · 283-568', AppColors.matcha),
        'R5': const _Region('R5 · 569-2000', AppColors.muted),
        'conv': _Region(tr('회화'), AppColors.ai),
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await (appDb.select(appDb.words)..orderBy([(w) => OrderingTerm.asc(w.rank)])).get();
    await DialogueService.instance.ensureLoaded();
    final seen = <String, int>{};
    for (final d in DialogueService.instance.all) {
      for (final t in d.turns) {
        for (final l in t.lemmas) {
          seen[l.base] = (seen[l.base] ?? 0) + 1;
        }
      }
    }
    final conv = all.where((w) => w.region == 'conv').toList()
      ..sort((a, b) => (seen[b.word] ?? 0).compareTo(seen[a.word] ?? 0));
    ArtService.instance.urlFor('').then((_) { // 그림 목록이 오면 타일에 그림이 붙는다(기다리지 않음)
      if (mounted) setState(() {});
    });
    if (!mounted) return;
    setState(() {
      _words = all.where((w) => w.region != 'conv').toList();
      _conv = conv;
      _loading = false;
    });
  }

  void _mode(bool withConv) => setState(() {
        _withConv = withConv;
        if (!withConv && _filter == 'conv') _filter = 'ALL';
      });

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final pool = _withConv ? [..._words, ..._conv] : _words;
    final shown = pool
        .where((w) => _filter == 'ALL' || w.region == _filter)
        .where((w) => q.isEmpty || w.word.toLowerCase().contains(q) || (w.meaningKo ?? '').contains(q))
        .toList();
    final units = [
      for (var i = 0; i < shown.length; i += kUnit) shown.sublist(i, (i + kUnit).clamp(0, shown.length)),
    ];
    final regions = _regions;
    final chips = regions.entries.where((e) => e.key != 'conv' || _withConv).toList();
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('절벽 단어')),
          Text(trf('빈도 {0}위 · {1}어 단원 · 탭하면 발음', ['2,000', kUnit]),
              style: const TextStyle(color: AppColors.tintaLight, fontSize: 10)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Container(
                color: AppColors.calDeep,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(children: [
                  Row(children: [
                    _ModeButton(label: tr('절벽구간 단어만'), selected: !_withConv, onTap: () => _mode(false)),
                    const SizedBox(width: 8),
                    _ModeButton(label: trf('회화 단어 포함 (+{0})', [_conv.length]), selected: _withConv, onTap: () => _mode(true)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      for (final e in chips)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _filter == e.key ? e.value.color : AppColors.cal,
                                border: Border.all(color: e.value.color, width: _filter == e.key ? 1.5 : 0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(e.value.label,
                                  style: TextStyle(color: _filter == e.key ? AppColors.cal : e.value.color, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: tr('단어 / 뜻 검색'),
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset(context)),
                  itemCount: units.length,
                  itemBuilder: (context, i) => _UnitBlock(index: i + 1, words: units[i], regions: regions),
                ),
              ),
            ]),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.tinta : AppColors.cal,
              border: Border.all(color: selected ? AppColors.tinta : AppColors.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: TextStyle(color: selected ? AppColors.cal : AppColors.tinta, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      );
}

/// 한 단원 = 20어. 머리줄(단원 번호·순위 범위·구간) + 네모 타일 격자.
class _UnitBlock extends StatelessWidget {
  final int index;
  final List<WordRow> words;
  final Map<String, _Region> regions;
  const _UnitBlock({required this.index, required this.words, required this.regions});

  @override
  Widget build(BuildContext context) {
    final first = words.first;
    final conv = first.region == 'conv';
    final region = regions[first.region];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
          child: Row(children: [
            Text(trf('{0}단원', [index]), style: const TextStyle(color: AppColors.tinta, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            if (!conv) Text('#${first.rank}-${words.last.rank}', style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
            const Spacer(),
            if (region != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: region.color, borderRadius: BorderRadius.circular(2)),
                child: Text(conv ? tr('회화') : '${first.region}', style: const TextStyle(color: AppColors.cal, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
          ]),
        ),
        LayoutBuilder(builder: (context, c) {
          // 칸 수 = 이 칸의 너비 ÷ 112(아이패드 오른쪽 칸은 화면 전체보다 좁다)
          final cols = (c.maxWidth / 112).floor().clamp(3, 8);
          // 높이는 너비의 1/0.85, 단 좁은 폰·글자 1.2배에서도 넘치지 않게 110 아래로는 내리지 않는다
          final tileW = (c.maxWidth - 6 * (cols - 1)) / cols;
          final tileH = tileW / 0.85 < 110 ? 110.0 : tileW / 0.85;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 6, crossAxisSpacing: 6, mainAxisExtent: tileH),
            itemCount: words.length,
            itemBuilder: (context, i) => _WordTile(w: words[i], color: regions[words[i].region]?.color ?? AppColors.tinta),
          );
        }),
      ]),
    );
  }
}

/// 네모 타일 — 순위 · 그림(있으면) · 단어 · 뜻 한 줄. 탭하면 발음.
class _WordTile extends StatelessWidget {
  final WordRow w;
  final Color color;
  const _WordTile({required this.w, required this.color});

  @override
  Widget build(BuildContext context) {
    final conv = w.region == 'conv';
    final url = ArtService.instance.urlForSync(w.word, rank: conv ? null : w.rank);
    return InkWell(
      onTap: () => TtsService.instance.speak(w.word.replaceAll('-', '')),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(color: AppColors.cal, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(builder: (context, c) {
          final art = (c.maxHeight - 68).clamp(20.0, 64.0); // 글자 줄(1.2배까지)을 빼고 남는 높이
          return Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(conv ? tr('회화') : '#${w.rank}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (url != null) ...[
                  SizedBox(
                    width: art,
                    height: art,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image(image: artProvider(url), fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(w.word, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.tinta)),
                ),
                if ((w.meaningKo ?? '').isNotEmpty)
                  Text(w.meaningKo!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: AppColors.tintaLight)),
              ]),
            ),
          ]);
        }),
      ),
    );
  }
}
