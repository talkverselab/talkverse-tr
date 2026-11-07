# 회화 초안 작성 규칙 — 터키어 (2026-11-07, Claude 초안 단계)

공통 원칙 https://talkverse.uk/talkverse/dialogue-rules/ + `docs/DIALOGUE_tr.md`. 흐름: Claude 초안 → 검사기 → Grok 재작성(모든 줄 새로) → 최소 수정 → 사용자 리뷰 → `approved` → 장면 컷 → 앱 반영.

## 톤
- 외우고 싶은 짧은 한 줄이 편마다 있어야 한다. 킥(웃음·놀람)은 편마다 1번 이상, 끝 줄은 짧은 한 방.
- 지금 튀르키예 20대가 실제로 하는 말. 교과서체·번역투·설명 대사·정리된 느낌 금지. 다짐·감사로 끝내지 않는다.
- 구조: 질문 → 대답 + 이유나 농담 → 상대가 받아 되치기. 설명 대신 반응으로 정보를 내보낸다. 중반에 오해·놀림·내기·흥정 같은 작은 갈등.
- 연애: 썸·플러팅까지(클럽 포함), 여성이 먼저 다가가는 편을 더 많이, 말을 끝맺지 않는 여백, 마음을 들키는 순간. 클리셰는 일부 편만. 성적 묘사 금지(iOS 12+).
- 최우선: `data/expressions/top_expressions.csv` 표현을 편마다 2개 이상, 레벨이 올라도 반복. SNS·1:1 채팅·데이팅앱 장면을 많이.
- ko 는 직역 금지 — 한국 사람이 실제로 하는 말, 말투도 터키어와 같게(siz = 존댓말, sen = 반말).

## 반전
편마다 `twist`(턴 번호, 본론 후반) + `twist_type` 하나: chaos(일이 걷잡을 수 없이 커짐) · slip(말실수·오해) · reveal(의외 사실) · emotion(심쿵·감정) · ignore(읽씹·무시). chaos 는 전체 30% 이상. 심쿵 줄은 tags 에 `simkung` — 연애 편은 편마다 필수, 다른 주제도 자주.

## 인물
A = 학습자(`{name}`, 국적·성별 고정 금지, 변수 `{name}`·`{country}`·`{city}`·`{lang}`만). 터키어는 성별 표현이 없으니 그대로 둔다. `abi`·`abla` 처럼 A 의 성별이 드러나는 호칭을 A 에게 쓰지 않는다.
| 인물 | 주제 | 성격 |
|---|---|---|
| Elif | 연애(주)·문화·여행 | 밝고 수다스러움, 차이·길고양이 좋아함, 놀리다가 먼저 마음을 들킴 |
| Emre | 연애·일 | 솔직·직진, 무심한 듯 다정, 말이 짧음 |
| Can | 친구·생활 | 카페 직원, 느긋한 장난꾸러기, 먹보 |
| Zeynep | 학업·문화·친구 | 디자인 전공, 말수 적은데 정곡을 찌름 |
| 조연(이름 없이 역할명 — Garson·Taksici·Eczacı·Komşu·Teyze…) | 서바이벌·생활·여행 | 매뉴얼대로인데 타이밍이 기막힘 |
콜백(앞 편 대사 재사용)은 tags `callback:<편id>`.

## 분량
- 턴: R1 6~8 · R2 8~12 · R3 12~16. 한 턴 1~2문장(R3 은 3까지).
- 단어 수(띄어쓰기): R1 2~7 · R2 3~10 · R3 4~14. 1단어 턴은 채팅·반전 턴·끝 줄·표현 풀 한마디만.
- kind: survival · short(a) · long(b) · chat(c). 채팅은 모든 턴 `"ui":"bubble"`, `"at":"21:03"`, 이모지 `"stamp"` 1~2개.
- 어휘: `assets/data/freq/lang_es_top.csv` 순위 안에서 R1 ≤568 · R2 ≤1000 · R3 ≤2000. 절벽 R1(119위)은 대부분 기능어·접미사라 그 안에서는 문장이 안 되므로 80% 선까지 넓혔다. 벗어나는 낱말은 편당 2개까지, 턴 note 에 뜻.
- 말투: 낯선 사이·가게·일 = siz, 친구·연인 = sen, 채팅 = sen + 줄임. `register` = polite·casual·chat·mixed.
- 금지: 출처·작품·실존 인물·브랜드, 종교·정치 논쟁, 미성년 연애. 술 언급은 `flags: ["alcohol"]`.

## 칸
`id`(`r1_friends_a1`) `region` `island` `kind` `draft:true` `purpose[]`(travel·study_abroad·work_abroad·media·love·making_friends) `domain[]`(life·friends·love·work·study·culture·travel) `title`(한국어, 짧게) `emoji` `scene`(장면 한 줄) `speakers{"A":"{name}","B":…}` `register` `twist` `twist_type` `flags[]` `goal` `expressions[]` `review{"draft":"claude 2026-11-07"}` `turns[{num,speaker,tl,rd,ko,note,tags[],new[]}]`.
note = 턴 핵심 하나 「X = 뜻」. tags = `expr:…`·`form:…`·`simkung`·`callback:…`. new = 새 낱말 기본형. rd 는 비우고 `python3 tools/check_dialogues.py --fix-rd <파일>` 로 채운다.
파일: `assets/data/dialogues/R<레벨>/<주제>/<id>.json`. 이 폴더는 pubspec 에 아직 안 올라가서 앱에 나오지 않는다(리뷰 통과 뒤 연결).
