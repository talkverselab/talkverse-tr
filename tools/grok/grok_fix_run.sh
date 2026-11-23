#!/bin/zsh
# Grok 2차(uk 11-23): 길이 초과 6편 + 옛 이야기 L1 5편 — 편마다 새 방, 규칙 첨부 + 그 편의 단어 수 범위를 첫 메시지에.
#   zsh tools/grok/grok_fix_run.sh      결과 R 편 data/review/grok/out_fix/<id>.md · L1 data/review/grok/out_l1/L1_<ep>.md
# 시작 전: PC 크롬 9252(Grok-Chrome-tr-9252) 켜기 + 터널, 「빠른」 모드 확인. 끝나면 크롬 끄기(크롬 규칙).
cd "$(dirname "$0")/../.."
export GROK_CDP_PORT=9252
mkdir -p data/review/grok/out_fix data/review/grok/out_l1
typeset -A RANGE
RANGE=(r1_friends_b1 "2~7" r1_life_b1 "2~7" r1_life_b4 "2~7" r1_travel_b3 "2~7" r3_love_b6 "4~14" r3_study_b5 "4~14")
jobs=(${(k)RANGE} L1_ep1 L1_ep2 L1_ep3 L1_ep4 L1_ep5)
for id in ${(o)jobs}; do
  if [[ $id == L1_* ]]; then out=data/review/grok/out_l1/$id.md; w="2~7"; else out=data/review/grok/out_fix/$id.md; w=$RANGE[$id]; fi
  [[ -s $out ]] && { echo "skip $id"; continue; }
  print -r -- "첨부한 rewrite_grok_tr.md 가 이 방의 규칙이다. 원문 문장을 그대로 두거나 낱말만 바꾸면 실패. 이 편은 모든 턴을 터키어 ${w}단어로(지난번 길이 기준을 벗어남). 편: $id.txt" > $TMPDIR/grok_tr_fix.txt
  r=$(python3 tools/grok/grok_text.py $TMPDIR/grok_tr_fix.txt $out tools/prompts/rewrite_grok_tr.md data/review/grok/src/$id.txt 2>&1); rc=$?
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E '저장|LIMIT|빠른|TIMEOUT' | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  sleep 20
done
echo "전부 끝"
