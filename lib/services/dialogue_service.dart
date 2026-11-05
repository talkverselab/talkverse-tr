import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'learner_prefs.dart';

/// 회화 리더(일본어앱 시안 02 구조)가 읽는 회화 — 2026-11-03.
///
/// 지금 데이터(`assets/data/dialogues/L1.json`, 5편 × 8턴)를 **바꾸지 않고 읽어서** 일본어앱 모델 모양으로 바꾼다.
/// 칸: 대상어 `es`(스페인어 템플릿 이름) → [DialogueTurn.tl], 한글 독음 `rd`, 한국어 `ko`, `note`, `tags`.
/// 레벨은 R 로 다시 매기지 않고 `L1`(「이야기」), 주제는 회화 공통 원칙대로 연애 서사 = `love`.
/// 새 구조(R0~R4·주제별 편 JSON)로 다시 쓰는 것은 회화 작업이 풀린 뒤.
/// 문장 내용어 한 개: 표면형(문장 속)·기본형(레마)·읽기(터키어는 빈 값) — 단어장 연결(일본어앱 2026-11-04).
class Lemma {
  final String surface, base, reading;
  const Lemma(this.surface, this.base, this.reading);
}

class DialogueTurn {
  final int num;
  final String speaker; // A·B
  final String tl; // 터키어
  final String reading; // 보조 줄(터키어는 없음 — 일본어앱의 가나 자리)
  final String rd; // 한글 독음
  final String ko;
  final String note;
  final List<String> tags;
  final List<String> newWords;
  /// 「어순 맞대기」 낱말 대응 [(터키어, 한국어)] — 데이터에 `align: [[tr, ko], …]` 가 있을 때만(회화 작업 때 채움).
  final List<(String, String)> align;
  /// 접사 블록 — 낱말 → 어간 + 접사들(kind: case 격 · poss 소유 · plural 복수 · verb 동사 어미).
  /// 데이터 `morph: {"evlerimde": {"root": "ev", "suffixes": [{"s": "-ler", "ko": "-들", "kind": "plural"}, …]}}` 가 있을 때만(회화 작업 때 채움).
  final Map<String, Morph> morph;
  final List<Lemma> lemmas; // 문장 내용어 — tools/add_lemmas.py 가 채움
  final String? at; // 채팅 시각(일본어앱 모델 호환, 지금 데이터엔 없음)
  final String? stamp; // 채팅 스탬프 이모지(일본어앱 모델 호환, 지금 데이터엔 없음)
  final String? art;
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required this.tl,
    required this.reading,
    required this.rd,
    required this.ko,
    required this.note,
    required this.tags,
    required this.newWords,
    this.align = const [],
    this.morph = const {},
    this.lemmas = const [],
    this.at,
    this.stamp,
    this.art,
  });

  factory DialogueTurn.fromJson(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: (j['tl'] ?? j['es']) as String? ?? '',
        reading: '',
        rd: j['rd'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        newWords: (j['new'] as List?)?.cast<String>() ?? const [],
        align: [
          for (final a in (j['align'] as List? ?? const []))
            if (a is List && a.length >= 2) ('${a[0]}', '${a[1]}'),
        ],
        morph: {
          for (final e in ((j['morph'] as Map?) ?? const {}).entries)
            if (e.value is Map) '${e.key}': Morph.fromJson(e.value as Map),
        },
        lemmas: [
          for (final l in (j['lemmas'] as List? ?? const []))
            if (l is List && l.length >= 2) Lemma('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : ''),
        ],
        at: j['at'] as String?,
        stamp: j['stamp'] as String?,
        art: j['art'] as String?,
      );

  /// 그림 조회용 핵심 단어 후보: new → note 의 「낱말 = 뜻」 앞쪽.
  List<String> get pictureWords {
    final out = <String>[...newWords];
    final m = RegExp(r'^\s*([^=]+?)\s*=').firstMatch(note);
    if (m != null) out.add(m.group(1)!.replaceAll(RegExp(r'^-'), ''));
    return out;
  }
}

/// 낱말 하나의 어간 + 접사(몽골어앱 아이디어 「접사 블록」, 2026-11-03).
class Morph {
  final String root;
  final List<({String s, String ko, String kind})> suffixes;
  const Morph(this.root, this.suffixes);
  factory Morph.fromJson(Map j) => Morph('${j['root'] ?? ''}', [
        for (final x in (j['suffixes'] as List? ?? const []))
          if (x is Map) (s: '${x['s'] ?? ''}', ko: '${x['ko'] ?? ''}', kind: '${x['kind'] ?? ''}'),
      ]);
}

class Dialogue {
  final String id;
  final String region; // L1(이야기) — 회화가 풀리면 R0~R4
  final String island; // love …
  final String kind;
  final String title;
  final String emoji;
  final String scene;
  final Map<String, String> speakers; // A → 이름
  final Map<String, String> genders; // A → male|female (데이터에 정해진 성별)
  final List<String> expressions; // 핵심 표현(일본어앱 모델 호환, 지금 데이터엔 없음)
  final List<DialogueTurn> turns;
  final String? art;
  const Dialogue({
    required this.id,
    required this.region,
    required this.island,
    required this.kind,
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.genders,
    this.expressions = const [],
    required this.turns,
    this.art,
  });

  bool get isChat => kind == 'chat';

  /// 화자 표시 이름. 데이터의 이름을 쓰고, `{name}` 자리면 프로필 이름(없으면 「나」).
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (raw.contains('{name}')) return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    return raw;
  }

  /// 목소리 성별 — 데이터에 정해진 성별이 우선(남자 이름 대사를 여자 목소리로 읽지 않게), 없으면 프로필 규칙.
  String voiceGender(String sp) {
    final raw = speakers[sp] ?? '';
    if (raw.contains('{name}')) return LearnerPrefs.gender.value;
    return genders[sp] ?? LearnerPrefs.voiceGender(sp);
  }

  String get orderKey => id.replaceAllMapped(RegExp(r'\d+'), (m) => m.group(0)!.padLeft(3, '0'));
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const islands = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'];
  static const islandKo = {
    'survival': '서바이벌',
    'friends': '친구',
    'love': '사랑',
    'life': '생활',
    'travel': '여행',
    'culture': '문화',
    'work': '일',
    'study': '학업',
  };
  static const islandEmoji = {
    'survival': '🧭',
    'friends': '🧑‍🤝‍🧑',
    'love': '💕',
    'life': '🏠',
    'travel': '✈️',
    'culture': '🎬',
    'work': '💼',
    'study': '📚',
  };
  static const levelKo = {'L1': '이야기', 'R0': '왕초보', 'R1': '초보', 'R2': '중급', 'R3': '고급', 'R4': '최상급'};
  static const _files = {'L1': 'assets/data/dialogues/L1.json'};
  static const _prefLast = 'dialogue_last';

  final Map<String, Dialogue> _byId = {};
  final List<String> _regions = [];
  String? _lastOpened;
  Future<void>? _loading;

  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await SharedPreferences.getInstance()).setString(_prefLast, id);
  }

  /// 데이터에 있는 레벨(지금은 L1 하나).
  List<String> get regions => List.unmodifiable(_regions);

  /// 넓은 화면에서 탭들이 동시에 불러도 한 번만 읽는다.
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    _lastOpened = (await SharedPreferences.getInstance()).getString(_prefLast);
    for (final e in _files.entries) {
      try {
        final j = json.decode(await rootBundle.loadString(e.value)) as Map<String, dynamic>;
        final chars = (j['characters'] as Map?) ?? const {};
        final names = <String, String>{};
        final genders = <String, String>{};
        chars.forEach((k, v) {
          if (v is Map) {
            names['$k'] = '${v['name'] ?? k}';
            if (v['gender'] != null) genders['$k'] = '${v['gender']}';
          }
        });
        for (final ep in (j['episodes'] as List? ?? const [])) {
          final m = ep as Map<String, dynamic>;
          final id = '${e.key}_${m['id']}';
          _byId[id] = Dialogue(
            id: id,
            region: e.key,
            island: 'love',
            kind: 'long',
            title: m['title'] as String? ?? '',
            emoji: m['emoji'] as String? ?? '💬',
            scene: m['scenario'] as String? ?? '',
            speakers: names,
            genders: genders,
            turns: ((m['turns'] as List?) ?? const [])
                .map((t) => DialogueTurn.fromJson(t as Map<String, dynamic>))
                .toList(),
          );
        }
        if (!_regions.contains(e.key)) _regions.add(e.key);
      } catch (_) {
        // 파일이 없거나 깨졌으면 그 레벨만 빠진다
      }
    }
  }

  Dialogue? byId(String id) => _byId[id];
  List<Dialogue> get all => _byId.values.toList()..sort((a, b) => a.orderKey.compareTo(b.orderKey));

  List<Dialogue> list({String? region, String? island}) => all
      .where((d) => (region == null || d.region == region) && (island == null || d.island == island))
      .toList();

  List<String> islandsOf(String region) =>
      islands.where((i) => _byId.values.any((d) => d.region == region && d.island == i)).toList();

  int count(String region) => _byId.values.where((d) => d.region == region).length;
}
