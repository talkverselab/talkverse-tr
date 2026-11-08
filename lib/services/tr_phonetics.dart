/// 터키어 알파벳 29자 발음 자료 — 「알파벳과 발음」(일본어앱 「50음도와 발음」 구조, 2026-11-08).
/// 한국어 화자 기준 비교. IPA 는 표준 이스탄불 발음.
class TrLetter {
  final String upper, lower;
  final String name; // 글자 이름(읽을 때)
  final String ipa;
  final String hint; // 격자 아래 보조 표기(한글)
  final String place; // 소리 나는 곳·입모양
  final String korSim; // 비슷한 한국어 소리
  final String korDiff; // 한국어와 다른 점
  final String example; // 예시 낱말
  final String exampleKo;
  final bool vowel;
  final bool front; // 모음: 앞 모음(e i ö ü)
  final bool round; // 모음: 원순(o ö u ü)
  final bool high; // 모음: 고모음(ı i u ü)
  final bool special; // 터키어 고유 글자(ç ğ ı ö ş ü)
  final bool tricky; // 한국어 화자가 자주 틀리는 소리
  const TrLetter(this.upper, this.lower, this.name, this.ipa, this.hint, this.place, this.korSim, this.korDiff, this.example, this.exampleKo,
      {this.vowel = false, this.front = false, this.round = false, this.high = false, this.special = false, this.tricky = false});
}

const trLetters = <TrLetter>[
  TrLetter('A', 'a', 'a', 'a', '아', '입을 크게 벌리고 혀는 낮고 가운데·뒤쪽. 입술은 펴진 채.', 'ㅏ', '한국어 ㅏ 와 거의 같다. 길게 끌지 말고 짧게.', 'araba', '자동차',
      vowel: true),
  TrLetter('B', 'b', 'be', 'b', 'ㅂ', '두 입술을 닫았다 떼는 유성 파열음.', 'ㅂ', '말 첫머리에서도 성대를 울린다(유성음). 한국어 첫소리 ㅂ 은 무성이라 [p]에 가깝게 들린다.', 'bir', '하나'),
  TrLetter('C', 'c', 'ce', 'dʒ', 'ㅈ', '혀끝·혓날을 잇몸 뒤에 댔다 떼며 마찰. 성대가 울린다.', 'ㅈ(울리는)', '영어 j 소리. 「c = ㅋ」로 읽지 말 것 — cami 「자미」(모스크).', 'cuma', '금요일',
      tricky: true),
  TrLetter('Ç', 'ç', 'çe', 'tʃ', 'ㅊ', '혀를 잇몸 뒤에 댔다 떼며 숨을 내보낸다(무성).', 'ㅊ', '한국어 ㅊ 과 거의 같다. 아래 꼬리(세디유)가 있으면 ㅊ, 없으면 ㅈ.', 'çay', '차',
      special: true),
  TrLetter('D', 'd', 'de', 'd', 'ㄷ', '혀끝을 윗잇몸에 댔다 떼는 유성 파열음.', 'ㄷ', '첫머리에서도 울리는 소리. 낱말 끝에서는 [t]처럼 약해지기도 한다.', 'deniz', '바다'),
  TrLetter('E', 'e', 'e', 'e', '에', '혀를 앞으로, 입은 반쯤. 입술은 펴진 채.', 'ㅔ', 'ㅔ 와 같다. 일부 낱말(gel, sen)에서는 ㅐ 쪽으로 조금 벌어진다.', 'ev', '집',
      vowel: true, front: true),
  TrLetter('F', 'f', 'fe', 'f', 'ㅍ(f)', '윗니를 아랫입술에 대고 바람을 낸다.', '없음(ㅍ 으로 적음)', '한국어에 없는 소리. 두 입술을 닫는 ㅍ 이 아니라 윗니+아랫입술.', 'fincan', '커피잔',
      tricky: true),
  TrLetter('G', 'g', 'ge', 'ɡ', 'ㄱ', '혀 뒤를 여린입천장에 댔다 떼는 유성 파열음.', 'ㄱ', '첫머리에서도 울리는 소리. e·i·ö·ü 앞에서는 혀가 앞으로 와서 [ɟ]에 가까워진다.', 'gün', '날, 해'),
  TrLetter('Ğ', 'ğ', 'yumuşak ge', '(ː)', '—', '소리가 없다. 앞 모음을 길게 늘이거나 두 모음을 부드럽게 잇는다.', '없음', '「부드러운 g」. 낱말 첫머리에 오지 않는다. dağ 「다아」, değil 「데일」. ㄱ 으로 읽지 말 것.', 'dağ', '산',
      special: true, tricky: true),
  TrLetter('H', 'h', 'he', 'h', 'ㅎ', '목에서 숨이 빠져나가는 소리.', 'ㅎ', '한국어 ㅎ 과 같다. 낱말 끝·자음 앞에서도 약하게 소리 낸다(kahve 「카흐베」).', 'hayır', '아니'),
  TrLetter('I', 'ı', 'ı', 'ɯ', '으', '입술을 펴고 혀는 높고 뒤쪽. 입을 거의 벌리지 않는다.', 'ㅡ', '점 없는 ı 는 ㅡ. 점 있는 i(ㅣ)와 다른 글자다. 대문자 I 는 ı, 대문자 İ 는 i.', 'kız', '여자아이, 딸',
      vowel: true, high: true, special: true, tricky: true),
  TrLetter('İ', 'i', 'i', 'i', '이', '입술을 펴고 혀는 높고 앞쪽.', 'ㅣ', 'ㅣ 와 같다. 대문자에도 점이 있다(İstanbul).', 'iki', '둘',
      vowel: true, front: true, high: true),
  TrLetter('J', 'j', 'je', 'ʒ', 'ㅈ(j)', '혀를 잇몸 뒤에 가까이 두고 울리며 마찰(닿지 않음).', '없음(ㅈ 으로 적음)', '프랑스어 j 소리. c[dʒ]보다 부드럽고 닿지 않는다. 외래어에만 나온다.', 'jüri', '심사위원',
      tricky: true),
  TrLetter('K', 'k', 'ke', 'k', 'ㅋ', '혀 뒤를 여린입천장에 댔다 떼는 무성 파열음.', 'ㅋ~ㄲ', '숨을 조금 내보낸다. 낱말 끝에서는 받침 ㄱ 처럼 들린다(yok 「욕」).', 'kedi', '고양이'),
  TrLetter('L', 'l', 'le', 'l / ɫ', 'ㄹ', '혀끝을 윗잇몸에 대고 옆으로 소리를 흘린다.', 'ㄹ(받침 ㄹ)', '첫머리에서도 혀끝을 붙인다(ㄹ 받침처럼). 뒤 모음(a ı o u) 옆에서는 혀 뒤가 올라간 어두운 [ɫ].', 'lütfen', '부탁해요'),
  TrLetter('M', 'm', 'me', 'm', 'ㅁ', '두 입술을 닫고 코로 내는 소리.', 'ㅁ', '한국어 ㅁ 과 같다.', 'masa', '탁자'),
  TrLetter('N', 'n', 'ne', 'n', 'ㄴ', '혀끝을 윗잇몸에 대고 코로 내는 소리.', 'ㄴ', '한국어 ㄴ 과 같다.', 'ne', '무엇'),
  TrLetter('O', 'o', 'o', 'o', '오', '입술을 둥글게, 혀는 반쯤 높이·뒤쪽.', 'ㅗ', 'ㅗ 와 거의 같다. 입을 조금 더 벌린다.', 'okul', '학교',
      vowel: true, round: true),
  TrLetter('Ö', 'ö', 'ö', 'ø / œ', '외', 'e 를 낼 혀 자리에서 입술만 o 처럼 둥글게.', 'ㅚ(단모음)', '한국어 ㅚ 를 「웨」로 읽으면 틀린다. 입술을 둥글게 한 채 ㅔ 를 낸다. 미끄러지지 않는 한 소리.', 'göz', '눈',
      vowel: true, front: true, round: true, special: true, tricky: true),
  TrLetter('P', 'p', 'pe', 'p', 'ㅍ', '두 입술을 닫았다 떼는 무성 파열음.', 'ㅍ~ㅃ', '숨을 조금 내보낸다. 낱말 끝에서는 받침 ㅂ 처럼(kitap 「키탑」).', 'para', '돈'),
  TrLetter('R', 'r', 're', 'ɾ', 'ㄹ', '혀끝으로 윗잇몸을 한 번 톡 친다. 낱말 끝에서는 바람 섞인 [ɾ̥].', 'ㄹ(모음 사이)', '낱말 끝·자음 앞에서도 소리 낸다(bir 「비르」). 끝의 r 은 「르」보다 짧고 바람이 새는 소리.', 'renk', '색깔',
      tricky: true),
  TrLetter('S', 's', 'se', 's', 'ㅅ', '혀끝을 윗잇몸 가까이 두고 바람을 낸다.', 'ㅅ~ㅆ', 'i 앞에서도 「시」가 아니라 [si] — 한국어처럼 「쉬」로 뭉개지지 않는다.', 'su', '물'),
  TrLetter('Ş', 'ş', 'şe', 'ʃ', '시', '혀를 잇몸 뒤로 넓게 올리고 바람을 낸다. 입술은 살짝 내민다.', '샤·슈·쇼 의 ㅅ', 'ş = 영어 sh. s 와 다른 글자다(şiş 「시시」 꼬치 / sis 「시스」 안개).', 'şehir', '도시',
      special: true),
  TrLetter('T', 't', 'te', 't', 'ㅌ', '혀끝을 윗잇몸에 댔다 떼는 무성 파열음.', 'ㅌ~ㄸ', '숨을 조금 내보낸다. 낱말 끝에서는 받침 ㅅ(ㄷ)처럼(evet 「에벳」).', 'tatlı', '단, 디저트'),
  TrLetter('U', 'u', 'u', 'u', '우', '입술을 둥글게 내밀고 혀는 높고 뒤쪽.', 'ㅜ', 'ㅜ 와 같다.', 'uçak', '비행기',
      vowel: true, round: true, high: true),
  TrLetter('Ü', 'ü', 'ü', 'y', '위', 'i 를 낼 혀 자리에서 입술만 u 처럼 둥글게.', 'ㅟ(단모음)', '한국어 ㅟ 를 「우이」로 미끄러지면 틀린다. 입술을 내민 채 ㅣ 를 낸다.', 'üç', '셋',
      vowel: true, front: true, round: true, high: true, special: true, tricky: true),
  TrLetter('V', 'v', 've', 'v', 'ㅂ(v)', '윗니를 아랫입술에 가볍게 대고 울린다. 모음 사이에서는 [w]처럼 약해지기도.', '없음(ㅂ 으로 적음)', '두 입술 ㅂ 이 아니라 윗니+아랫입술. tavuk 「타북」은 [w]처럼 들린다.', 'var', '있다',
      tricky: true),
  TrLetter('Y', 'y', 'ye', 'j', '이', '혀를 ㅣ 자리로 올렸다가 다음 모음으로 미끄러진다.', 'ㅑ·ㅕ·ㅛ·ㅠ 의 반모음', '자음 글자다. 낱말 끝이나 자음 앞에서는 짧은 「이」(çay 「차이」).', 'yok', '없다'),
  TrLetter('Z', 'z', 'ze', 'z', 'ㅈ(z)', '혀끝을 윗잇몸 가까이 두고 울리며 바람을 낸다.', '없음(ㅈ 으로 적음)', 's 를 울린 소리. 한국어 ㅈ(파찰음)과 다르다 — 혀가 닿지 않는다.', 'yüz', '얼굴, 백',
      tricky: true),
];

/// 모음조화 — 2가지(e/a), 4가지(i/ı/ü/u). 예시는 실제 낱말.
const harmony2 = [
  ('ev', 'evler', '집들'),
  ('okul', 'okullar', '학교들'),
  ('göz', 'gözler', '눈들'),
  ('kız', 'kızlar', '여자아이들'),
];
const harmony4 = [
  ('ev', 'evim', '내 집', 'i'),
  ('kız', 'kızım', '내 딸', 'ı'),
  ('göz', 'gözüm', '내 눈', 'ü'),
  ('okul', 'okulum', '내 학교', 'u'),
];
