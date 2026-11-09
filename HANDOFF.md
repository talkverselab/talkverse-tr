# HANDOFF — talkverse-tr (터키어 앱) · 2026-11-09

## 상태 한눈에

| 항목 | 상태 |
|---|---|
| 최신 커밋 | `6e94b4e` (master = origin) — 가격 확정 d055e84(uk 작성) · 스토어 차별화 문서 a1fc037 · 통합 앱 연결점 6e94b4e |
| Android | Zealot 빌드 20 https://apps.talkverse.uk/7cKdr/421 (서명·versionCode 20 확인) · CI 릴리스 20 · APK PC 백업 완료 |
| iOS | TestFlight 빌드 `2611091215`(커밋 6e94b4e) 업로드 성공 · applesignin 들어감 · IPA PC 백업 완료 |
| 캐릭터 시안 | 통과 2026-11-03 → `CHARACTERS.md`, `data/review/art/chars_tr_v1.jpg` (그림 저장소 `talkverse_art/chars/tr_sheet.jpg`) |
| UX 시안 | 글 `data/review/uxui/sian_tr_01.md` + 그림 `sian_tr_01.jpg` · 사용자 "몽골어 접사 UX 받아서 빌드해"로 진행 |
| 회화 작성 | **제한 해제(11-07)** — Claude 초안 181편 `c9dca1d`(R0 28·R1 55·R2 56·R3 42, 턴 1,981, 카오스 37%), 앱 미연결. 다음 = 음성 → 리뷰 페이지, Grok 재작성(한도로 11/10 이후) |
| 절벽 구간 | **일본어 방식(사용자 결정 11-03): 기본형 + 접미사 각각 토큰 — R1 119 · R2 157 · R3 282 · R4 568**, 상위 2,500 = 91.1% · 앱 목록 568개(`704d0e9`, 시드 `words_seeded_v5`) · 그림 저장소 `tr.csv` 2,300개(`4236128`, 579~ R5) · 방법 비공개 메모 `~/talkverse/_update_kit/cliff/tr_stem_cliff.md` v3. 어간 값 156·219·438·1,034 와 1,525 는 폐기 |
| 단어 그림 | `art/tr/manifest` 420개(공유 그림) · 새 그림 233 + 음식 50 은 uk 세션 대기열 |

## 만든 것(앱)

- **아이패드 두 화면**(일본어앱 구조): 레일 + 왼쪽 탭 칸 + 오른쪽 칸(`openPane`), 폰은 하단 탭. 짧은 변 600+ 만 회전.
- **회화 리더**(시안 02): 좌 스크립트·우 장면 컷(말풍선)·하단 재생/속도/자막, 편 끝 연출, 그림 카드. `lib/services/dialogue_service.dart` 가 L1.json 을 바꾸지 않고 읽는다(A Minjun 남 · B Elif 여 — 목소리는 데이터 성별).
- **어순 맞대기 칸**(몽골어앱 UX 시안 01): 낱말 칩 + 모음조화 점(뒷모음 청록·앞모음 분홍 × 원순 동그라미·평순 네모).
- **접사**(몽골어앱 아이디어 5개, 사용자 지시 2026-11-03): `lib/data/tr_affixes.dart` 접사 22개 + 자동 분석(사슬 최대 4개, 아포스트로피 뒤 접사, 소유/인칭 -im 구분, 통째 낱말 제외 목록) ·
  리더 칸에 어간 + 종류별 색 접사 블록·조사 테두리 · 접사 설명 시트(모음조화 고르기 연출·앱 안 예문) · 접사 카드 · 홈 「접사」 → 접사 사전. 「자동 분석 — 틀릴 수 있어요」 표시.
  데이터에 `align`·`morph` 를 넣으면(회화 작업 때) 자동 분석 대신 그 값을 쓴다.
- **성과 데스크**(「나」 성과: 편 완주·핵심 표현), 프로필 **학습자 이름·성별**.
- **Talkverse ID 로그인(선택)·평생 이용권**: client `tr`, 딥링크 `talkverse.tr://auth`, 상품 iOS `com.talkverse.turkishUniverse.lifetime` / Android `lang_tr`. 지금은 아무것도 잠그지 않는다.
- 빈도 단어: 일본어 방식(기본형 + 접미사 각각 토큰) R1~R4 568개(`assets/data/freq/lang_es_top.csv`, 시드 키 `words_seeded_v5` — 넣기 전에 비움). 접미사는 「-들(복수)」처럼 기능 이름으로 뜻. 방법 메모는 비공개 `~/talkverse/_update_kit/cliff/tr_stem_cliff.md` v3.
- **문장 레마 ↔ 단어장**(§5-1): 턴 `lemmas` + `lib/widgets/lemma_chips.dart`(리더 캡션·카드 뒷면, 누르면 단어 시트, 단어장에 없으면 회색). 다시 만들기 `tools/add_lemmas.py`(zeyrek·punkt 필요). 분석기 오답은 `tools/lemma_fix.json`(레마)·`tools/lemma_surface_fix.json`(표면형, null = 뺌) 로 고친다 — **새 회화를 넣으면 레마 표를 사람 눈으로 점검**(11-06 `ama`→맹인, `sola`→시들다 같은 오답이 있었다). uk 세션이 뜻을 채운 21개는 `lang_es_top.csv` 끝에 `region=conv` 로 합침(`version.json` db 7) — 빈도 목록·진행 숫자(568)에는 안 들어가고 시트에 순위도 안 보인다. 지금 레마 96개 전부 연결, 없는 레마 0.
- **콘텐츠 동기화**: `assets/data/version.json`(`db`·`turns`) + `lib/services/content_sync.dart`·`lib/screens/sync_screen.dart`. `db` 가 바뀌면 단어·동사만 다시 넣고, 턴은 `turns_version` 을 따로 둬 진행 기록을 지운다거나 하지 않는다(일본어앱과 다른 점, 일부러).
- **리더**: 말풍선 없는 `SceneCut` + 문장 띠, 카드 앞면 = 한국어 → 터키어로 말하기, 학습자 이름 묻기(`{name}` 있을 때만, 지금 데이터엔 없음), 여성 학습자는 `_f` 컷 우선(컷이 오면 동작). 아이패드 세로에서 어순 칸은 컷 칸 밖에 둔다.
- 폰 리더(일본어앱 `c558734`): 그림 3:2 고정, 캡션만 스크롤, 칩 한 줄 가로 스크롤. `integration_test/phone_layout_test.dart` 는 아이패드 시뮬레이터에서 크기만 폰으로 줄여 넘침을 본다(사진은 검게 나옴 — 모양은 실기기로 확인).
- 확인: `flutter analyze` 0 · `flutter test` 4 통과 · 폰 크기 넘침 0 · 아이패드 스크린샷 14장 넘침 0(`integration_test/dialogue_pane_test.dart`, `python3 tools/pane_shots.py <UDID> <폴더>`).

## 2026-11-07 개편 메모

- 단어표 2,000위(R5 569-2000) + 회화 단어 9개, db 8. 2,000위 누적 약 90%는 추정 포함(14어 빈도 추정). R5 에 외국 이름 약 24개(jack 등)가 빈도 그대로 남아 있다.
- 탭 = 홈·진행·프로필(학습 탭 삭제). 프로필에서 앱 업데이트 타일을 뺐다 — CLAUDE.md §2·§6 설명이 낡았다(사용자 결정 대기, CLAUDE.md 는 안 고침).
- 검증: `flutter test` 13개 통과(폭 300·390·900, 글자 1.2배), analyze 0, 호스트 렌더링으로 화면 확인. 시뮬레이터 실행은 못 함 — Xcode 27.2 로 오른 뒤 `simctl` 이 `xcodebuild -runFirstLaunch` 에서 멈춘다. `integration_test` 수정분은 미실행.

## 2026-11-07 회화 초안·음성 메모

- 규칙 `tools/prompts/dialogue_tr.md`, 검사 `tools/check_dialogues.py [--fix-rd] [--stats]`, 독음 `tools/rd_tr.py`, 표현 풀 `data/expressions/top_expressions.csv`(135개, 121개 사용).
- 어휘: 회화 상한을 R1 ≤568·R2 ≤1,000·R3 ≤2,000 으로 잡았지만 편당 2개는 못 지켰다. 분석기 측정(오분석 잡음 포함) 상한 밖 내용어 R1 31.5%·R2 23.8%·R3 12.5%. 주로 çay·kedi·teyze·hoca·소재 명사. 단어장에 없는 낱말도 많아 Grok 뒤 `add_lemmas` 를 새 구조에 맞춰 돌려 missing_lemmas 를 uk 에 넘긴다(지금 `add_lemmas.py` 는 L*.json 만 읽음).
- 음성: `tools/tts`, `data/tts`(voices 23·감정 16·계획 181편, 조각 3,444), PC `out/ref_tr`·`out/tr`, 작업 폴더 `~/tts_work/tr`. uk 의 "지금 시작" 뒤에만 PC 사용, 끝나면 "GPU 끝" → `tools/review_html.py data/review/REVIEW_tr.html …` → "REVIEW_tr 갱신". 받아쓰기는 mlx-whisper venv 필요(맥 scratch venv).
- **사용자 결정(11-07): Grok 전 음성은 예시 1편(`r0_love_a1`)만. 전편 음성은 Grok 재작성 뒤.**
- 시험 음성(11-08): `r0_love_a1` 16줄 30초, 13조각 받아쓰기 1.0, 재생성 3조각, 긴 쉼 없음(4파일 표본), 속도 기준 13.2 글자/초. R2 에만 올림(`--no-db`, D1 줄 없음). 도구 `tools/tts/trial.py`, venv `$TMPDIR/tts_venv`. 귀로 듣는 확인은 사용자 몫. 리뷰 `data/review/REVIEW_tr.html`.
- 앱 연결(남은 것): pubspec 에 R*/주제 폴더, DialogueService·seed 새 구조, `content_sync` 음성 매니페스트, `dialogue_audio.dart`.
- 원어민 확인 줄: r1_friends_b2 t4(Şeş beş) · r2_friends_b6 t11 · r2_friends_b7 t11 · r3_friends_b5 t6 · r2_life_b4 t5(kesin 말장난) · r1_love_b3 t8 · r2_love_b5 t7 · r3_love_b1 t10 · r2_travel_b4 t11 · r2_travel_b1 t6 · r3_travel_b1 t2 · r2_study_b1 t4 · r2_study_b6 t12 · r3_work_b4 t12 · r3_study_b3 t1(Bursa 말장난) · r1_culture_b5 t7 · r3_culture_b3 t13 · r2_culture_b6 t5(지어낸 가사, 실존 곡과 겹침 미확인). R0 로 옮겨진 편은 id 앞이 r0_ 일 수 있다.

- (해결됨 11-08 16시, CoreSimulator 1174.21) **iOS 빌드 중지(11-08, M6 허브 지시 `~/logs/rc/RELAY_xcode_20261107.md`)**: Xcode 27.2 ↔ CoreSimulator 1174.9.2. CoreSimulator CFBundleVersion 이 1174.21 이상이 될 때까지 iOS 빌드·`flutter devices`·`simctl`·시뮬레이터 금지, 사용자에게 sudo 요청 금지(허브 처리). 안드로이드는 계속.

- 11-08 알파벳과 발음(기초 첫 줄, `alphabet_screen.dart`·`tr_phonetics.dart`·`tr_sound_sheet.dart`). 조음 그림은 임시(출시 전 Grok 그림, 출처 표기 없음 — 사용자 지시). 절벽 단어 그림은 낱말로만 찾음. 시뮬레이터 테스트 아이패드·폰 통과, 넘침 0.

## 사용자 결정·할 일

1. **평생 이용권이 여는 범위**(R2 이상 잠금 / 회화 전체 잠금 / 당분간 없음) — 아무것도 잠그지 않는 인앱 구입은 App Store 심사에서 거절될 수 있다.
2. Sign in with Apple: IPA 에는 `applesignin` 이 들어갔다(`tools/ios_release.sh` 재서명 단계). 실제 기기 로그인은 아직 안 해 봄 — 안 되면 개발자 포털 App ID `com.talkverse.turkishUniverse` 에서 켜졌는지 확인.
3. 스토어 인앱 상품 등록(iOS·Play), TestFlight 내부 그룹에 본인.
4. Zealot 의 잘못 올라간 항목 https://apps.talkverse.uk/7cKdr/212 (옛 빌드 9 를 다시 올림 — 빌드 실패 뒤 스크립트가 멈추지 않았던 탓) — 지울지 결정(testflight 세션 담당).
5. 템플릿 잔재(「PRINCIPIANTE 1」·진행 화면 「Poco a poco…」·프로필 「Día 1」)와 L→R 재태깅은 콘텐츠 손질이라 콘텐츠 금지가 풀린 뒤. 「성·수」 메뉴는 11-07 개편으로 빠졌고, 「¡Hola!」는 11-07 커밋에서 「Merhaba!」로 바꿨다(원래 미뤄 둔 항목 — 사용자에게 보고함).

## 다음 할 일(세션)

**2026-11-09 추가(사용자 재요청, uk 전달):**
- 출시는 Talkverse 통합 앱 하나(com.talkverse.app). 이 저장소는 패키지 `turkish_universe` — `lib/embed.dart`(embedInit/embedApp), 저장 접두 `tr_`(설정 키·Application Support/tr·DB `tr_turkish_universe`, 단독 앱은 옛 이름을 한 번 옮김), 콜백 스킴 `talkverse.tr://auth`(통합 앱이면 clientId talkverse). 통합 앱 쪽 연결은 uk 가 한다(직접 고치지 말 것).
- 가격 = `~/talkverse/PRICING.md`, 상품 ID lang_tr_1m·3m·1y·life·all_1y·all_life. 스토어 문안·4.3 심사 메모·스크린샷 순서 = `docs/STORE_PRODUCTS.md`. 잠근 기능은 아직 없음(사용자 결정 대기).
- ⚠ 저장 이름이 바뀌어 첫 실행 때 옛 설정·DB 를 옮긴다 — 폰에서 학습 기록이 이어지는지 확인 필요(빌드 20).

**2026-11-08 세션 종료 시점(허브 지시로 종료) — 이어받을 것:**
1. **굴절어 전략**(`~/talkverse/INFLECTED_LANG_STRATEGY.md`) — 맞지 않는 4항목을 사용자에게 알리고 답 대기 중: B15(이미 181편 씀 → 앱 미연결 초안으로 보존), A4(siz 장면 R0·R1 → 그래머2 로 이동), B3(R1 119위는 접미사 위주 → 회화 상한 568), A8·A9(성 없음 → 성별판 불필요, morph_tags 는 격·수·소유·인칭·시제, zeyrek). 답을 받은 뒤에만 착수.
2. **Grok 재작성** — 11-09 13:30 재개(사용자 지시). **Grok 은 자기 크롬으로 직접(한자 세션 대행 중단, `~/logs/rc/RELAY_grok_20261109.md`)**: 자기 포트(`~/talkverse/GROK_CHROME_PORTS.md`)로 크롬을 켜고 M4 에서 `/usr/bin/python3 ~/talkverse-uk/tools/grok_cookie_sync.py 9231 <내 포트>`(ssh macmini4), 도구는 M6 `~/Hanja/tools/grok_req.py`·`grok_cdp.py` 를 복사. uk 의 방은 건드리지 말 것. 장면 컷도 같은 방식. **프롬프트 최소화(11-09 사용자 지시)**: 규칙은 문서 한 번, 방 첫 메시지에 「파일 이름 한 줄만 보낸다」 약속, 이후 한 줄만 — `tools/prompts/dialogue_tr.md` 끝. zh `tools/prompts/rewrite_grok.md`·`rewrite_request.py` 를 복사해 편 1개씩 새 대화방, 「모든 줄 새로」. 재작성본에도 턴 `emotion`·`segs` 를 넣는다(지금 `data/tts/plan/` 계획에서 옮겨 넣을 수 있음).
3. **음성** — 전편은 Grok 재작성 뒤(사용자 결정). uk 의 "지금 시작" 뒤 `$TMPDIR/tts_venv/bin/python tools/tts/run_all.py ~/tts_work/tr`(품질 기준 §5 반영됨), 끝나면 "GPU 끝" → `tools/review_html.py data/review/REVIEW_tr.html <편…>` → "REVIEW_tr 갱신".
4. **앱 연결** — 리뷰 통과 뒤 pubspec 에 R*/주제 폴더, DialogueService·seed 새 구조, 음성 매니페스트(`content_sync`)·`dialogue_audio.dart`(일본어앱 DIALOGUE_AUDIO.md §3). 레마는 `add_lemmas.py` 를 새 구조로 고쳐 missing_lemmas → uk.
5. 조음 그림(`assets/images/ipa/places_of_articulation.png`)은 임시 — 출시 전 Grok 그림으로 교체.

- 회화 작성이 풀리면: `docs/DIALOGUE_tr.md`(독음 표기표·턴 길이) + 공통 원칙 → 새 구조(R1~R4·주제별 JSON) · 턴에 `align`·`morph` 채우기 · 장면 컷 요청(편당 4장, 한자 세션 경유).
- 접사 자동 분석 개선: 알려진 어긋남 — `ısmarlıyorum` → ısmarl+ıyor(원래 ısmarla+yor), `gezdireyim` → gezdire+yim(원래 gezdir+eyim), 한 글자 접사(-e/-a, -i/-ı …)는 일부러 빼 둠.
- 장면 컷이 생기기 전엔 리더 그림이 단어 그림으로 대신 나온다(예: 「Ben」 → 공유 그림 「나」가 여성) — 컷이 오면 자연히 바뀐다.

## 회화·Grok 규칙(사용자 지시 2026-11-03, talkverse.uk 세션 전달 — 회화 작업이 풀리면 적용)

- 반전 비율(공통 원칙 §9): 카오스 30% 이상 · 연애·플러팅 편마다 심쿵 한 줄(여성 주도 편 더 많이) · 편마다 `twist_type`(chaos·slip·reveal·emotion·ignore) · 새 편은 왕초보·초급 위주.
- 장면 그림 = A·B 쌍 1컷, 말풍선·글자 없음, 인물 기준 그림(`CHARACTERS.md` + 시트) 첨부. 원칙 https://talkverse.uk/talkverse/dialogue-rules/
- Grok·Gemini: 그림은 한자 세션 경유. 직접 쓸 땐 M4 `~/chrome-grok` 쿠키를 **M4 안에서** 자기 폴더로 복사 → 자기 포트(배정표 `GROK_CHROME_PORTS.md`)로 띄우고 M6 에서 `ssh -fN -L` 터널.
  상세 `/Users/talkverse/talkverse/GROK_M4_LOGIN.md`, 예 `~/talkverse/ko/tools/grok_base.py`. 사용자 지시 있을 때만 켜고, 탭은 건마다 닫고, 끝나면 Chrome 끄기.
- 2026-11-03: **Grok 작업은 사용자가 따로 지시할 때까지 시작하지 않는다.** M4 Grok 이 새 계정으로 바뀜(원본 `~/chrome-grok`, 9222, 예전 계정은 11/9 까지 한도) — 새 계정엔 프로젝트·챗·GitHub 커넥터 없음.
  시작할 때 순서: ① 쿠키를 M4 안에서 `~/chrome-grok` 에서 다시 복사 ② 샘플 1~2개 먼저 시험 ③ 결과를 PushNotification 으로 보내 사용자 통과 요청 ④ 통과 뒤 본작업.
- Grok 회화 재작성·장면 컷 요청문 작성법(중국어앱 세션 정리, 실제로 통과한 방식): `/Users/talkverse/talkverse/GROK_PROMPT_GUIDE.md` — 틀은 `~/talkverse/zh/tools/`(prompts/rewrite_grok.md·rewrite_request.py·scene_prompts.py·grok_*.py)를 복사해 언어 코드만 바꾼다.

## 공통 절차

- 빌드 전 실제 빌드 수 `ps -axo args= | grep -c '^[^ ]*dartvm .*flutter_tools'` 3 이상이면 기다림(`pgrep -f flutter_tools.snapshot` 은 다른 세션의 대기 명령까지 세어 서로 멈춘다, 11-05). 시뮬레이터는 자기 것 1대(`ACEBB37E…` iPad Pro 11)만, 끝나면 shutdown.
- 로컬 Android: `flutter build apk --release --build-number=<같은 커밋의 CI 번호>` → 서명 SHA-1 `9cc4…476b`·versionCode 확인 → `bash tools/zealot_push.sh "<한 줄>"` → PC 백업. **빌드가 실패하면 업로드하지 말 것**(옛 APK 가 올라간다). `cannot find symbol …Plugin` 이면 `flutter clean && flutter pub get`.
- iOS: `bash tools/ios_release.sh`(백그라운드, 약 5분) — 빌드 번호 KST yymmddHHMM.
- 빌드 뒤 잡음 되돌리기: `analysis_options.yaml`·`android/gradle.properties`·`xcschemes`. 커밋은 경로 지정, CRLF 잡음 금지.
- ⚠ `ios/Flutter/Debug.xcconfig`·`Release.xcconfig` 의 `#include? "Pods/…"` 줄과 `ios/Runner.xcworkspace/contents.xcworkspacedata` 의 Pods 연결은 커밋하지 않되 **되돌리지 말 것** — 지우면 iOS 아카이브가 `Module 'flutter_tts' not found` 로 실패(2026-11-03). 지웠으면 `cd ios && pod install` 후 두 줄을 맨 위에 다시 넣는다.
- 서명 키는 새로 만들지 않는다(CLAUDE.md §1·§8). 아이콘은 talkverse.uk 세션 담당.
