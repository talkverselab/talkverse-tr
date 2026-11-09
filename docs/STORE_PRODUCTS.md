# 스토어 상품·차별화 — 터키어유니버스 (2026-11-09)

출시는 **Talkverse 통합 앱 하나**(com.talkverse.app)로 한다(uk 공지). 이 앱은 통합 앱 안의 터키어 패키지이자, 개발·시험용 단독 앱(Zealot·TestFlight)이다. 가격 = `~/talkverse/PRICING.md`(사용자 확정 2026-11-09)의 앱 정가 / 앱 할인가. **등록은 사용자가** App Store Connect·Google Play Console 에서 한다.

## 1. 상품

| 상품 ID | 이름(한국어 표시) | 종류 | 기간 | 앱 정가 | 스토어 판매가(할인가) |
|---|---|---|---|---|---|
| `lang_tr_1m` | 터키어 1개월 | 자동 갱신 구독 | 1개월 | 5,500 | **3,900** |
| `lang_tr_3m` | 터키어 3개월 | 자동 갱신 구독 | 3개월 | 12,900 | **9,000** |
| `lang_tr_1y` | 터키어 1년 | 자동 갱신 구독 | 1년 | 28,500 | **19,900** |
| `lang_tr_life` | 터키어 평생 이용권(서비스 운영 기간 동안) | 비소모성 | — | 69,900 | **49,000** |
| `all_1y` | 종합 패키지 1년 — 모든 언어 | 자동 갱신 구독 | 1년 | 112,900 | **79,000** |
| `all_life` | 종합 패키지 평생 — 모든 언어(서비스 운영 기간 동안) | 비소모성 | — | 469,000 | **329,000** |

- 앱 결제 시트는 정가를 취소선으로, 스토어 가격을 크게 보여 준다(`Purchase.configure`, `lib/screens/paywall_screen.dart`). 앱 안에서 사이트 가격을 안내·유도하지 않는다.
- 옛 평생 상품 `com.talkverse.turkishUniverse.lifetime`·`lang_tr` 은 판매 중지, 앱은 복원 때 `lang_tr_life` 로 인정한다.
- 약관 https://talkverse.uk/terms/ · 개인정보처리방침 https://talkverse.uk/talkverse/tr/privacy/
- 통합 앱에서는 공용 결제가 스토어 스트림을 듣고 이 언어 상품을 패키지로 넘긴다(EMBED_GUIDE 5단계). `all_*` 의 등록·인정 방식은 uk 가 정한다.
- **아직 잠근 기능이 없다** — 무엇을 유료로 할지 사용자 결정 대기.

## 2. 차별화(애플 지침 4.3 대비, `~/talkverse/STORE_DIFFERENTIATION.md`)

### 스토어 설명 첫 줄(안)
> 터키어는 낱말 끝에 접사를 줄줄이 붙이는 말 — ev·evler·evlerim·evlerimde. 접사 사슬을 블록으로 쪼개 한국어 조사와 맞대고, 모음조화(e/a · i/ı/ü/u)를 귀로 익힙니다.

### 터키어 전용 학습 도구(지금 앱에 있는 것만)
1. **알파벳과 발음** — 29자 격자(터키어 글자 ç ğ ı ö ş ü 표시), 8모음 위치표(앞·뒤 × 평순·원순), 모음조화 2가지·4가지 예시. 글자를 누르면 1초 뒤 재생, IPA, 소리 나는 곳, 조음 위치 그림, 한국어 소리와 비교(ı ≠ i, ö·ü 는 미끄러지지 않는 단모음, ğ 는 소리 없음).
2. **접사 사전 · 접사 블록** — 낱말을 어간 + 접사 블록(복수·소유·격·동사 어미)으로 쪼개 보여 주고, 모음조화로 접사 모음이 골라지는 연출, 격 접사 = 한국어 조사 테두리, 접사 카드·퀴즈.
3. **절벽 단어** — 터키어 영화·드라마 대사를 기본형 + 접미사 각각으로 센 순위: 119개로 55%, 157개 60%, 282개 70%, 568개 80%(접미사가 상위를 차지 — 교착어의 특징). 2,000위까지 20어 단원 타일.
4. **회화 리더** — 문장 속 낱말을 누르면 기본형(-mak/-mek 원형)으로 단어창이 열린다(활용형 → 원형 연결). 한글 독음은 기본 꺼짐.
5. **동사 활용 · 문법 강의·테스트**.

### 출시 전에 채울 것(지금은 없음 — 설명에 쓰지 않는다)
- 회화 181편(R0 28·R1 55·R2 56·R3 42, 1,981턴)은 Claude 초안 — Grok 재작성·사용자 통과 뒤 앱 연결. 지금 앱 회화는 9월 초안 5편.
- 회화 음성은 시험 1편(R2 에만, 앱 미연결). 전편 음성은 Grok 재작성 뒤.
- 장면 컷 없음. 알파벳 조음 그림은 임시(출시 전 Grok 그림으로 교체).
- 굴절어 전략(레벨 = 문법 단계) 적용 여부 사용자 결정 대기.

### 실측 숫자(출시 때 다시 확인)
- 절벽: R1 119 · R2 157 · R3 282 · R4 568 (기본형·접미사), 2,000위 누적 약 90%(추정 포함). 말뭉치 낱말 약 2.2억.
- 회화: 앱 5편 / 초안 181편·1,981턴(출시 전 숫자로 바꿀 것). 음성 줄: 0(앱 기준).

### 심사 메모 문단(영문, 숫자는 출시 판 기준으로 채움)
> This app is one of a family of language-specific apps by Universal Talking Lab (Talkverse). Each app is built from scratch for one target language for Korean speakers and is NOT a re-skin: the Turkish app has its own alphabet & pronunciation module (29 letters including ç ğ ı ö ş ü, an 8-vowel chart and two-way/four-way vowel harmony), its own grammar tools (suffix-chain blocks that split a word into stem + plural/possessive/case/verb suffixes and map case suffixes to Korean particles), [N] original conversation episodes with recorded audio written for this language, and a vocabulary list measured from a Turkish conversation corpus (119 / 157 / 282 / 568 lemma-and-suffix units cover 55 / 60 / 70 / 80 %). Content, curriculum and UI flows differ between apps; we keep them separate because learners search for and buy one language at a time.

### 스크린샷 순서(고유 화면 먼저)
1. 접사 블록 — 낱말 하나가 어간 + 접사 사슬로 쪼개지고 격 접사가 한국어 조사와 맞대지는 화면
2. 알파벳과 발음 — 모음조화 탭(8모음 표 + e/a · i/ı/ü/u 예시) 또는 ö 발음 시트
3. 회화 리더 — 낱말 탭 단어창(활용형 → 원형)
4. 절벽 단어 — 119/157/282/568 표와 20어 단원 타일
5. 결제 시트(정가 취소선·할인가) — 마지막. 홈·프로필로 시작하지 않는다.
