# 심사 메모 · 개인정보 답안 — 터키어유니버스 (2026-11-02, 한자 앱 문안을 옮김)

> Talkverse ID 로그인(선택) + 평생 이용권 인앱 구입(비소모성) 이 들어간 판. 서버 = auth.talkverse.uk(Cloudflare).
> ⚠ **이용권이 여는 범위가 아직 정해지지 않았다**(사용자 결정 대기). 아무것도 잠그지 않는 인앱 구입은 App Store 심사(지침 3.1.1)에서 거절될 수 있다 —
> 범위를 정하고 아래 [인앱 구입] 문단의 "어디서 사는지"를 채운 뒤 제출한다.

## App Store Connect "심사 정보 → 메모"

```
[로그인] 로그인은 선택입니다. 모든 학습 기능은 로그인 없이 사용할 수 있고, 로그인은 구매 복원과 기기 간 이용권 공유에만 쓰입니다.
- 로그인 화면: 프로필 탭 → 계정 → 로그인. Apple로 로그인 + 이메일 로그인(심사·테스트용).
- 데모 계정(이메일 로그인): review@talkverse.uk / 비밀번호: <Doppler keys/prd TALKVERSE_REVIEW_ACCOUNT 에서 복사> — 평생 이용권(tr)이 들어 있습니다.
- 계정 삭제: 프로필 탭 → 계정 → 계정 삭제(확인 창) → 서버에서 개인정보가 삭제되고 모든 기기에서 로그아웃됩니다.
[인앱 구입] 비소모성 "평생 이용권"(com.talkverse.turkishUniverse.lifetime) 1개. 프로필 탭 → 평생 이용권 → [평생 이용권 구매] 로 구매, [이전 구매 복원] 으로 복원. <잠긴 화면에서 여는 경로 — 범위 확정 뒤 적기> Sandbox 계정으로 시험 가능, 로그인 없이도 구매·복원이 됩니다.
[마이크·음성 인식] 말하기 연습에서만 씁니다. 기기의 음성 인식을 쓰며 녹음은 서버로 보내지 않습니다.

[Sign-in] Optional. Every learning feature works without an account; sign-in is only for restoring purchases across devices.
- Where: Profile tab → Account → Sign in (Sign in with Apple, or email sign-in for review/testing).
- Demo account (email sign-in): review@talkverse.uk / password: <paste from Doppler> — it already owns the Lifetime Pass.
- Account deletion: Profile tab → Account → Delete account (confirmation) → personal data is deleted server-side and all sessions are revoked.
[IAP] One non-consumable "Lifetime Pass" (com.talkverse.turkishUniverse.lifetime). Profile tab → Lifetime Pass → [Buy] / [Restore purchases]. <where locked content opens the pass — fill in>. Works with a Sandbox account; sign-in is not required.
[Microphone / speech] Used only in speaking practice, through the device's speech recognizer. Audio is not sent to our servers.
```

## App Store — 앱 개인정보 보호

| 질문 | 답 |
|---|---|
| 데이터를 수집하나요? | **예**(로그인·구매한 사용자만) |
| 연락처 정보 → 이메일 주소 | 앱 기능(계정·구매 복원) · 사용자와 연결됨 · 추적 아님 |
| 연락처 정보 → 이름 | Apple/Google 로그인이 넘길 때만 · 앱 기능 · 연결됨 · 추적 아님 |
| 식별자 → 사용자 ID | Talkverse 계정 ID · 앱 기능 · 연결됨 · 추적 아님 |
| 구매 → 구매 내역 | 이용권 복원·기기 간 공유 · 앱 기능 · 연결됨 · 추적 아님 |
| 그 밖(위치·건강·금융·사용 데이터·진단·검색·오디오) | 수집 안 함(말하기 연습 음성은 기기 안 인식) |
| 추적(ATT) | 아니요 |

- 학습 기록·설정은 기기 안(SQLite·shared_preferences)에만. 계정 동기화를 넣으면 "사용자 콘텐츠 → 기타(학습 진도)" 추가.
- Privacy Manifest: `NSPrivacyTracking=false`, 수집 항목 EmailAddress·Name·UserID·PurchaseHistory(linked, no tracking, AppFunctionality), UserDefaults `CA92.1`.

## Google Play — 데이터 보안

| 질문 | 답 |
|---|---|
| 수집·공유 | 수집 예, 공유 없음 |
| 항목 | 이메일·이름(선택, 계정 관리) · 사용자 ID · 구매 내역(앱 기능) — 모두 선택 |
| 전송 암호화 | 예(HTTPS) |
| 삭제 요청 | 예 — 앱 "프로필 → 계정 → 계정 삭제" + https://talkverse.uk/account/delete |
| 광고·광고 ID | 아니요 |
| 앱 액세스 권한 | 모든 기능 로그인 없이 사용 가능 — 그래도 데모 계정(review@talkverse.uk)을 안내에 적는다 |

## 개인정보처리방침에 넣을 절 (talkverse.uk 세션에 요청 — 터키어앱 방침 페이지)
"계정(선택)·결제" 절은 한자 앱 방침 §8 과 같은 문안에 앱 이름만 터키어유니버스로. 계정 삭제 안내 https://talkverse.uk/account/delete.
