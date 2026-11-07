# 회화 음성 감정 계획 작성법 (터키어)

**2026-11-07 이후 쓰는 회화는 손으로 적지 않는다** — 턴의 `emotion`·`segs` 를 `tools/tts/plan_from_dialogue.py` 가 읽어 이 계획을 만든다(`make_jobs.py`·`run_all.py` 는 그 전에 자동으로 부른다). 조연 목소리가 이름표에 없으면 편에 `"cast":{"C":"man_o"}` 를 적는다. 아래는 계획 파일의 모양과 감정·목소리 규칙이다.

편마다 `data/tts/plan/<편id>.json` 한 파일. 검사 `python3 tools/tts/check_plan.py <편id>...`. 일본어앱 `data/tts/PLAN_GUIDE.md` 와 같은 틀.

```json
{"ep":"r1_x_a1",
 "cast":{"B":"elif"},
 "turns":{
  "1":{"segs":[["cheerful","Pardon, burası boş mu?"]]},
  "2":{"segs":[["surprised","Ha? Gerçekten mi?"],["gentle","O zaman birlikte gidelim."]]},
  "3":{"segs":[["amused","Saat 5'te geldim.","Saat beşte geldim."]]}
 }}
```

- **segs** = 턴을 말하는 순서대로 나눈 조각 `[감정, 본문]` 또는 `[감정, 본문, 읽기]`. 이어 붙이면 그 턴의 `tl` 과 같아야 한다(공백·문장부호·숫자·괄호 지문·이모지는 검사에서 무시).
- **읽기(세 번째 칸)** = 음성 모델이 읽을 글. 숫자는 글자로(`5` → `beş`), 이모지·지문은 뺀다. 쓸 때만 넣는다.
- **감정은 문장마다 대사 맥락으로 정한다.** 감정이 바뀌는 곳에서만 나눈다. neutral 만 쓰지 말 것 — 점원·안내는 polite, 받아치기는 tsukkomi, 심쿵 턴은 gentle·shy. 두 글자 미만 조각은 만들지 않는다.
  감정: neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle.
- **cast**: A(학습자)는 쓰지 않는다(자동 am/af). Elif=elif · Can=can · Zeynep=zeynep · Emre=emre · 점원·프런트·직원(여)=staff · Garson=waiter · Satıcı·Simitçi·Bakkal=vendor · Taksici·운전기사=taxi · Teyze·Komşu(여)=teyze · Müdür=boss · Hoca=hoca · 엄마=mom · 아빠=dad · 안내 방송=announce. 그 밖은 나이·성별로 man_y/man_m/man_o/woman_y/woman_m/woman_o/kid. speakers 의 A 말고 모든 화자를 넣는다.
- **자리 표시**: `{name}`·`{country}`·`{city}`·`{lang}` 은 그대로 둔다(자동: 남성판 Aleks, 여성판 Emma · Kanada · Toronto · İngilizce).
- **남성판·여성판**: 터키어는 성별로 말이 바뀌지 않으므로 `m`·`f` 칸을 쓰지 않는다. 이름에 접미사가 붙는 턴(`{name}'e`)은 판마다 모음조화가 다를 수 있으니 그 턴만 `m`·`f`(`text`·`rd`·`ko`·`segs`)를 따로 쓴다.
