import 'package:flutter/foundation.dart';
import '../core/prefs.dart';

/// 학습자 프로필(「나」) — 2026-11-02 사용자 지시 "성별이 정해지면 나가 나오는 거니까".
/// 회화의 화자 A = 학습자. 성별 → A 의 목소리(나중엔 장면 그림의 A 도), 이름 → `{name}` 자리.
class LearnerPrefs {
  LearnerPrefs._();
  static const _kName = 'learner_name';
  static const _kGender = 'learner_gender'; // male | female

  static final ValueNotifier<String> name = ValueNotifier('');
  static final ValueNotifier<String> gender = ValueNotifier('male');

  static Future<void> load() async {
    final p = await Prefs.getInstance();
    name.value = p.getString(_kName) ?? '';
    gender.value = p.getString(_kGender) ?? 'male';
  }

  static Future<void> setName(String v) async {
    name.value = v.trim();
    (await Prefs.getInstance()).setString(_kName, name.value);
  }

  static Future<void> setGender(String v) async {
    gender.value = v == 'female' ? 'female' : 'male';
    (await Prefs.getInstance()).setString(_kGender, gender.value);
  }

  static bool get isFemale => gender.value == 'female';

  /// 화자 코드 → 목소리 성별. A = 학습자(프로필), C = 남성 조연, 그 밖(B·D) = 여성.
  static String voiceGender(String speaker) => speaker == 'A' ? gender.value : (speaker == 'C' ? 'male' : 'female');

  /// 이름을 정하지 않았을 때 채울 값 — 생성 음성이 읽는 것과 같다(`data/tts/voices.json` `fill`).
  /// 듣는 말과 보이는 글이 같아야 한다(일본어앱 `view(turn)` 과 같은 원칙, 2026-11-19).
  static const _defaults = {
    '{name}': {'m': ('Aleks', '알렉스', '알렉스'), 'f': ('Emma', '에마', '에마')},
    '{country}': {'': ('Kanada', '카나다', '캐나다')},
    '{city}': {'': ('Toronto', '토론토', '토론토')},
    '{lang}': {'': ('İngilizce', '인길리제', '영어')},
  };

  /// 본문의 `{name}`·`{country}`·`{city}`·`{lang}` 채우기. [field] = tl(터키어) · rd(한글 독음) · ko(한국어 뜻).
  /// 이름은 프로필 이름, 없으면 성별 기본 이름(남 Aleks · 여 Emma). 한국어 뜻은 이름 뒤 조사를 맞춘다.
  static String fill(String text, [String field = 'tl']) {
    if (!text.contains('{')) return text;
    final i = field == 'rd' ? 1 : (field == 'ko' ? 2 : 0);
    String value(String key) {
      if (key == '{name}' && name.value.isNotEmpty) return name.value;
      final d = _defaults[key]!;
      final v = d[isFemale ? 'f' : 'm'] ?? d['']!;
      return [v.$1, v.$2, v.$3][i];
    }
    var s = text;
    if (field == 'ko') {
      s = s.replaceAllMapped(RegExp(r'\{(name|country|city|lang)\}(이라고|이라는|이에요|이랑|이야|으로|라고|라는|예요|은|는|이|가|을|를|과|와|아|야|로|랑)(?![가-힣])'), (m) {
        final w = value('{${m[1]}}');
        return w + josa(w, m[2]!);
      });
    }
    for (final k in _defaults.keys) {
      if (s.contains(k)) s = s.replaceAll(k, value(k));
    }
    return s;
  }

  static const _batchim = {'이라고', '이라는', '이에요', '이랑', '이야', '으로', '은', '이', '을', '과', '아'};
  static const _swap = {'이라고': '라고', '이라는': '라는', '이에요': '예요', '이랑': '랑', '이야': '야', '으로': '로', '은': '는', '이': '가', '을': '를', '과': '와', '아': '야',
      '라고': '이라고', '라는': '이라는', '예요': '이에요', '랑': '이랑', '야': '아', '로': '으로', '는': '은', '가': '이', '를': '을', '와': '과'};

  /// 낱말 끝 받침에 맞춘 조사(한글로 끝나지 않으면 그대로).
  static String josa(String word, String j) {
    if (word.isEmpty) return j;
    final c = word.codeUnitAt(word.length - 1);
    if (c < 0xAC00 || c > 0xD7A3) return j;
    final jong = (c - 0xAC00) % 28;
    if ((j == '으로' || j == '로') && jong == 8) return '로';
    return _batchim.contains(j) == (jong != 0) ? j : (_swap[j] ?? j);
  }
}
