#!/bin/zsh
# 남은 편을 20편씩 방을 새로 열어 차례로(한도 문구가 나오면 멈춤). 로그 data/review/grok/run.log
# 대상 = 앱에 넣은 편(assets/data/dialogues/_release.json) 가운데 답이 없는 것. ALL=1 이면 초안 전편.
# uk 11-18: 「빠른」 모드, 방은 20~30편마다 새로, PC 크롬 창이 꺼지지 않게 빈 탭 하나를 남긴다.
cd "$(dirname "$0")/../.."
if [[ -n $ALL ]]; then
  ids=($(ls data/review/grok/src | sed 's/.txt$//' | sort))
else
  ids=($(python3 -c "import json;print(' '.join(json.load(open('assets/data/dialogues/_release.json'))['ids']))"))
fi
todo=(); for i in $ids; do [[ -s data/review/grok/out/$i.md || ! -s data/review/grok/src/$i.txt ]] || todo+=$i; done
echo "남은 편 ${#todo}"
curl -s -m 5 -X PUT 'http://127.0.0.1:9252/json/new?about:blank' >/dev/null
for ((k = 1; k <= ${#todo}; k += 20)); do
  zsh tools/grok/grok_rewrite_run.sh ${todo[k,k+19]} || { echo "멈춤(한도 등)"; exit 3; }
done
echo "전부 끝"
