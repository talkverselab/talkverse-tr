import '../core/embed_env.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/dialogue_service.dart';

/// 터키어 접사(격어미·복수·소유·동사 어미) 표 + 자동 분석 — 2026-11-03 사용자 지시
/// ("몽골어에 접사 관련 UX 아이디어를 받아서 빌드해") — 몽골어앱 lib/data/mn_affixes.dart 를 터키어로 옮김.
///
/// 모음조화: 2형(e/a — -de/-da, -ler/-lar) · 4형(i/ı/ü/u — -im/-ım/-üm/-um, -di/-dı/-dü/-du).
/// 어간 끝 자음이 무성(ç f h k p s ş t)이면 d → t(-te/-ta, -ti/-tı …) — [Affix.extra] 에 넣었다.
/// 분석은 규칙 기반이라 틀릴 수 있다(화면에 「자동 분석」 표시). 보수적으로: 2글자 이상 형태만, 어간 2글자 이상(모음 포함)만,
/// 자주 쓰는 통째 낱말([_noSplit])은 나누지 않는다. 낱말 끝에서부터 여러 번 떼어 접사 사슬(ev+ler+im+de)을 만든다.
/// 예문은 앱에 이미 있는 문장(회화 + 여행 표현)에서만 찾는다 — 새 문장은 만들지 않는다.
enum AffixKind { kase, plural, poss, verb }

extension AffixKindX on AffixKind {
  String get label => switch (this) {
        AffixKind.kase => '격어미',
        AffixKind.plural => '복수',
        AffixKind.poss => '소유',
        AffixKind.verb => '동사 어미',
      };
  Color get color => switch (this) {
        AffixKind.kase => AppColors.ai,
        AffixKind.plural => const Color(0xFFE8913A),
        AffixKind.poss => AppColors.matcha,
        AffixKind.verb => AppColors.beniDeep,
      };
}

const _vowels = 'aeıioöuü';

/// 터키어 소문자(İ→i, I→ı 먼저).
String trLower(String s) => s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

/// 어간 마지막 모음 → 모음조화 열쇠. 4형 열쇠 하나를 돌려주고, 2형은 [two] 로 바꿔 쓴다.
/// i = 앞·평순(e i) · ü = 앞·원순(ö ü) · ı = 뒤·평순(a ı) · u = 뒤·원순(o u).
String harmonyOf(String stem) {
  final s = trLower(stem);
  for (var i = s.length - 1; i >= 0; i--) {
    final c = s[i];
    if ('ei'.contains(c)) return 'i';
    if ('öü'.contains(c)) return 'ü';
    if ('aı'.contains(c)) return 'ı';
    if ('ou'.contains(c)) return 'u';
  }
  return 'i';
}

/// 4형 열쇠 → 2형 열쇠(e = 앞모음, a = 뒷모음).
String two(String key4) => (key4 == 'i' || key4 == 'ü') ? 'e' : 'a';

class Affix {
  final String id;
  final AffixKind kind;
  final String name; // 한국어 이름
  final String ko; // 대응 한국어(조사·어미)
  final List<String> koMarkers; // 한국어 낱말 속에서 찾을 조사(테두리 묶기)
  final Map<String, String> forms; // 모음조화 열쇠(2형 e·a 또는 4형 i·ı·ü·u) → 형태
  final List<String> extra; // 자음동화(t-)·연결 자음(y·n·s) 붙은 다른 형태
  final String rule;
  const Affix(this.id, this.kind, this.name, this.ko, this.koMarkers, this.forms, this.rule, {this.extra = const []});

  bool get fourWay => forms.keys.any((k) => k == 'i' || k == 'ı' || k == 'ü' || k == 'u');

  /// 이 어간에 맞는 형태(모음조화만 — 자음동화는 [extra]).
  String? formFor(String stem) {
    final k = harmonyOf(stem);
    return fourWay ? forms[k] : forms[two(k)];
  }

  /// 화면에 늘어놓을 형태(중복 없이).
  List<String> get variants => {
        for (final k in const ['e', 'a', 'i', 'ı', 'ü', 'u'])
          if (forms[k] != null) forms[k]!,
        ...extra,
      }.toList();
  List<String> get allForms => variants;
}

const List<Affix> kTrAffixes = [
  Affix('loc', AffixKind.kase, '처격', '-에 / -에서(있는 곳)', ['에서', '에'], {'e': 'de', 'a': 'da'},
      '있는 곳·때. 앞 모음에 맞춰 -de/-da, 무성 자음(ç f h k p s ş t) 뒤에는 -te/-ta.', extra: ['te', 'ta']),
  Affix('abl', AffixKind.kase, '탈격', '-에서 / -로부터', ['에서', '부터'], {'e': 'den', 'a': 'dan'},
      '어디에서 왔는지·무엇보다. -den/-dan, 무성 자음 뒤 -ten/-tan.', extra: ['ten', 'tan']),
  Affix('dat', AffixKind.kase, '여격', '-에 / -에게 / -로', ['에게', '한테', '에', '로'], {'e': 'ye', 'a': 'ya'},
      '가는 곳·받는 사람. 자음 뒤 -e/-a, 모음 뒤 -ye/-ya(한 글자 꼴은 자동 분석에서 빼 둠).'),
  Affix('acc', AffixKind.kase, '대격', '-을 / -를', ['을', '를'], {'i': 'yi', 'ı': 'yı', 'ü': 'yü', 'u': 'yu'},
      '정해진 목적어. 자음 뒤 -i/-ı/-ü/-u, 모음 뒤 -yi/-yı/-yü/-yu(한 글자 꼴은 자동 분석에서 빼 둠).'),
  Affix('gen', AffixKind.kase, '속격', '-의', ['의'], {'i': 'in', 'ı': 'ın', 'ü': 'ün', 'u': 'un'},
      '소유·소속. 자음 뒤 -in/-ın/-ün/-un, 모음 뒤 -nin/-nın/-nün/-nun.', extra: ['nin', 'nın', 'nün', 'nun']),
  Affix('ins', AffixKind.kase, '공동·도구', '-와 함께 / -로', ['와', '과', '랑', '함께', '로'], {'e': 'le', 'a': 'la'},
      '함께·수단(ile 가 붙은 꼴). 자음 뒤 -le/-la, 모음 뒤 -yle/-yla.', extra: ['yle', 'yla']),
  Affix('pl', AffixKind.plural, '복수', '-들', ['들'], {'e': 'ler', 'a': 'lar'}, '여럿. 앞 모음에 맞춰 -ler/-lar.'),
  Affix('p1s', AffixKind.poss, '나의', '내 ~', ['내', '나의'], {'i': 'im', 'ı': 'ım', 'ü': 'üm', 'u': 'um'},
      '1인칭 단수 소유(ev → evim 내 집). 모음 뒤에는 -m 만(자동 분석에서 빼 둠).'),
  Affix('p2s', AffixKind.poss, '너의', '네 ~', ['네', '너의'], {'i': 'in', 'ı': 'ın', 'ü': 'ün', 'u': 'un'},
      '2인칭 단수 소유(ev → evin 네 집). 속격 -in 과 꼴이 같아 문맥으로 가린다.'),
  Affix('p1p', AffixKind.poss, '우리의', '우리 ~', ['우리'], {'i': 'imiz', 'ı': 'ımız', 'ü': 'ümüz', 'u': 'umuz'},
      '1인칭 복수 소유. 모음 뒤 -miz/-mız/-müz/-muz.', extra: ['miz', 'mız', 'müz', 'muz']),
  Affix('p2p', AffixKind.poss, '너희의', '너희 ~ / 당신의', ['너희', '당신'], {'i': 'iniz', 'ı': 'ınız', 'ü': 'ünüz', 'u': 'unuz'},
      '2인칭 복수·존댓말 소유. 모음 뒤 -niz/-nız/-nüz/-nuz.', extra: ['niz', 'nız', 'nüz', 'nuz']),
  Affix('p3', AffixKind.poss, '그의', '그(것)의 ~', ['그의'], {'i': 'si', 'ı': 'sı', 'ü': 'sü', 'u': 'su'},
      '3인칭 소유. 모음 뒤 -si/-sı/-sü/-su, 자음 뒤 -i/-ı/-ü/-u(한 글자 꼴은 자동 분석에서 빼 둠).'),
  Affix('prog', AffixKind.verb, '현재 진행', '-고 있다 / -한다', ['있', '요', '다'], {'i': 'iyor', 'ı': 'ıyor', 'ü': 'üyor', 'u': 'uyor'},
      '지금 하는 일·요즘. 자음 뒤 -iyor/-ıyor/-üyor/-uyor, 모음 뒤 -yor(어간 끝 a/e 는 ı/i 로 바뀜).', extra: ['yor']),
  Affix('past', AffixKind.verb, '과거', '-했다', ['했', '왔', '갔', '었', '았'], {'i': 'di', 'ı': 'dı', 'ü': 'dü', 'u': 'du'},
      '확실한 과거. -di/-dı/-dü/-du, 무성 자음 뒤 -ti/-tı/-tü/-tu.', extra: ['ti', 'tı', 'tü', 'tu']),
  Affix('fut', AffixKind.verb, '미래', '-할 것이다', ['할', '겠', '거'], {'e': 'ecek', 'a': 'acak'},
      '앞으로 할 일. -ecek/-acak, 모음 뒤 -yecek/-yacak.', extra: ['yecek', 'yacak']),
  Affix('inf', AffixKind.verb, '부정사', '-하기 / -하다(사전형)', ['기', '다'], {'e': 'mek', 'a': 'mak'}, '사전 형태. -mek/-mak.'),
  Affix('abil', AffixKind.verb, '가능', '-할 수 있다', ['수 있', '수'], {'e': 'ebil', 'a': 'abil'},
      '~할 수 있다. -ebil/-abil, 모음 뒤 -yebil/-yabil(뒤에 시제 어미가 또 붙는다).', extra: ['yebil', 'yabil']),
  Affix('neg', AffixKind.verb, '부정', '-지 않다', ['않', '안', '못'], {'e': 'me', 'a': 'ma'}, '~하지 않다. 동사 어간 바로 뒤 -me/-ma(뒤에 시제 어미가 또 붙는다).'),
  Affix('cond', AffixKind.verb, '조건', '-하면', ['면'], {'e': 'se', 'a': 'sa'}, '~하면. -se/-sa.'),
  Affix('opt', AffixKind.verb, '권유', '-하자', ['자'], {'e': 'elim', 'a': 'alım'}, '함께 하자. -elim/-alım, 모음 뒤 -yelim/-yalım.',
      extra: ['yelim', 'yalım']),
  Affix('pers1', AffixKind.verb, '인칭(나)', '나는 ~이다 / -해요', ['요', '다'], {'i': 'im', 'ı': 'ım', 'ü': 'üm', 'u': 'um'},
      '동사·서술어 뒤 1인칭 단수(-yorum, Koreliyim). 소유 -im 과 꼴이 같아 문맥으로 가린다.', extra: ['yim', 'yım', 'yüm', 'yum']),
  Affix('pers2', AffixKind.verb, '인칭(너)', '너는 ~이다 / -해', ['니', '야', '해'], {'i': 'sin', 'ı': 'sın', 'ü': 'sün', 'u': 'sun'},
      '2인칭 단수(-yorsun, istersin). -sin/-sın/-sün/-sun.'),
];

Affix? affixById(String id) => kTrAffixes.where((a) => a.id == id).firstOrNull;

/// 나누지 않는 낱말 — 기능어·인사말처럼 끝이 접사와 같아 보이지만 한 덩어리인 것.
const Set<String> _noSplit = {
  'merhaba', 'selam', 'evet', 'hayır', 'tamam', 'lütfen', 'teşekkür', 'teşekkürler', 'harika', 'şimdi', 'sonra', 'önce',
  'kadar', 'için', 'gibi', 'ama', 'fakat', 'çünkü', 'belki', 'hemen', 'bugün', 'yarın', 'dün', 'burada', 'şurada', 'orada',
  'nerede', 'nereden', 'nereye', 'nasıl', 'neden', 'niye', 'değil', 'daha', 'bile', 'sadece', 'yani', 'şey', 'ile',
  'birlikte', 'beraber', 'hepsi', 'herkes', 'biraz', 'çok', 'güzel', 'iyi', 'kötü', 'büyük', 'küçük', 'mükemmel',
  'memnuniyetle', 'affedersiniz', 'cumartesi', 'pazar', 'pazartesi', 'salı', 'çarşamba', 'perşembe', 'cuma',
  'kahve', 'baklava', 'sanat', 'saat', 'zaman', 'favori', 'süper', 'müze', 'sinema', 'istanbul', 'türkiye', 'türkçe',
  'beşiktaş', 'kadıköy', 'yürüyerek', 'şimdiden', 'aydır', 'mısın', 'musun', 'misin', 'müsün',
  'kedi', 'yedi', 'kadın', 'erkek', 'insan', 'deniz', 'bebek', 'ekmek', 'yemek', 'simit', 'kapı', 'para', 'oda', 'masa',
};

class AffixHit {
  final String word; // 원래 낱말(대소문자 그대로)
  final String stem; // 맨 앞 어간
  final List<(String, Affix)> chain; // 어간 뒤 접사들(앞에서 뒤 순서)
  const AffixHit(this.word, this.stem, this.chain);
  String get suffix => chain.isEmpty ? '' : chain.last.$1;
  Affix get affix => chain.last.$2;
  String get harmony => harmonyOf(stem);
  /// 마지막 접사를 뗀 앞부분(접사 카드의 앞면: evlerim + ＿＿).
  String get beforeLast => word.substring(0, word.length - _lastLen());
  int _lastLen() {
    final w = trLower(word);
    final f = suffix;
    return w.endsWith(f) ? f.length : 0;
  }
  /// 어간 뒤 접사 부분 전체(원래 대소문자 그대로).
  String get tail => word.substring(stem.length);
}

bool _hasVowel(String s) => s.split('').any((c) => _vowels.contains(c));

/// 끝에서 접사 하나를 뗀다(가장 긴 형태 우선). 못 떼면 null.
(String, String, Affix)? _peel(String w) {
  (String, String, Affix)? best;
  for (final a in kTrAffixes) {
    for (final f in a.allForms) {
      if (f.length < 2 || !w.endsWith(f)) continue;
      final stem = w.substring(0, w.length - f.length);
      if (stem.length < 2 || !_hasVowel(stem)) continue;
      // 모음조화가 맞는 형태만(연결 자음·자음동화 형태는 모음만 본다)
      final want = a.formFor(stem);
      final fv = f.split('').firstWhere((c) => _vowels.contains(c), orElse: () => '');
      final wv = want == null ? '' : want.split('').firstWhere((c) => _vowels.contains(c), orElse: () => '');
      if (fv.isNotEmpty && wv.isNotEmpty && fv != wv) continue;
      if (best == null || f.length > best.$2.length) best = (stem, f, a);
    }
  }
  return best;
}

/// 낱말을 어간 + 접사 사슬로 나눈다(끝에서부터 최대 4개). 못 나누면 null.
/// 고유명사 뒤 접사는 아포스트로피로 붙는다(İstanbul'da) — 그 뒤만 접사로 본다.
AffixHit? analyzeWord(String word) {
  final apo = word.indexOf(RegExp("['’]"));
  if (apo > 0) {
    final stem = word.substring(0, apo);
    final tail = trLower(word.substring(apo + 1));
    final chain = <(String, Affix)>[];
    var rest = tail;
    while (rest.isNotEmpty && chain.length < 4) {
      Affix? hit;
      String? form;
      for (final a in kTrAffixes) {
        for (final f in a.allForms) {
          if (rest.startsWith(f) && (form == null || f.length > form.length)) {
            hit = a;
            form = f;
          }
        }
      }
      if (hit == null) break;
      chain.add((form!, hit));
      rest = rest.substring(form.length);
    }
    return chain.isEmpty || rest.isNotEmpty ? null : AffixHit(word, stem, chain);
  }
  final w = trLower(word);
  if (w.length < 4 || _noSplit.contains(w)) return null;
  final chain = <(String, Affix)>[];
  var cur = w;
  while (chain.length < 4 && !_noSplit.contains(cur)) {
    final p = _peel(cur);
    if (p == null) break;
    chain.insert(0, (p.$2, p.$3));
    cur = p.$1;
  }
  if (chain.isEmpty) return null;
  // 소유 -im(내 ~)과 인칭 -im(나는 ~해요)은 꼴이 같다 — 앞이 동사 어미이거나 어간이 현재·초과거형(-er/-ar/-ir…)처럼 끝나면 인칭으로 본다
  final pers = affixById('pers1')!;
  for (var i = 0; i < chain.length; i++) {
    if (chain[i].$2.id != 'p1s') continue;
    final before = i == 0 ? cur : '';
    final verbBefore = i > 0 && chain[i - 1].$2.kind == AffixKind.verb;
    final aorist = i == 0 && RegExp(r'[aeıiuü]r$').hasMatch(before) && before.length >= 4;
    if (verbBefore || aorist) chain[i] = (chain[i].$1, pers);
  }
  // 원래 대소문자를 살려 어간을 자른다
  return AffixHit(word, word.substring(0, cur.length), chain);
}

List<String> splitWords(String s) =>
    s.split(RegExp(r"[^\p{L}\p{M}'’-]+", unicode: true)).where((w) => w.isNotEmpty).toList();

/// 예문 한 줄(앱에 이미 있는 문장).
class AffixExample {
  final String tl, ko, source;
  final AffixHit hit;
  const AffixExample(this.tl, this.ko, this.source, this.hit);
}

/// 회화(dialogue_service) + 여행 표현(assets/data/vocab/travel_expressions.json)에서 접사가 든 문장을 모은다.
class AffixCorpus {
  AffixCorpus._();
  static final AffixCorpus instance = AffixCorpus._();
  Future<void>? _loading;
  final List<AffixExample> _all = [];

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final lines = <(String, String, String)>[];
    await DialogueService.instance.ensureLoaded();
    for (final d in DialogueService.instance.all) {
      for (final t in d.turns) {
        lines.add((t.tl, t.ko, d.title));
      }
    }
    try {
      final j = json.decode(await rootBundle.loadString(assetPath('assets/data/vocab/travel_expressions.json'))) as Map<String, dynamic>;
      for (final th in (j['themes'] as List? ?? const [])) {
        for (final sec in ((th as Map)['sections'] as List? ?? const [])) {
          for (final w in ((sec as Map)['words'] as List? ?? const [])) {
            final m = w as Map;
            lines.add(('${m['tx'] ?? ''}', '${m['ko'] ?? ''}', '${th['title'] ?? ''}'));
          }
        }
      }
    } catch (_) {}
    final seen = <String>{};
    for (final (tl, ko, src) in lines) {
      for (final w in splitWords(tl)) {
        final h = analyzeWord(w);
        if (h == null) continue;
        for (final (_, a) in h.chain) {
          if (!seen.add('${a.id}|${trLower(w)}|$tl')) continue;
          _all.add(AffixExample(tl, ko, src, h));
        }
      }
    }
  }

  /// 이 접사가 든 예문(같은 문장은 한 번만).
  List<AffixExample> examplesOf(String affixId) {
    final seen = <String>{};
    return [for (final e in _all) if (e.hit.chain.any((c) => c.$2.id == affixId) && seen.add(e.tl)) e];
  }
  List<AffixExample> get all => List.unmodifiable(_all);
  int count(String affixId) => examplesOf(affixId).length;
}
