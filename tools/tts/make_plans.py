#!/usr/bin/python3
"""(옛 편용 — 새 회화는 감정 열이 있으니 plan_from_dialogue.py 가 알아서 만든다) 간단한 감정 표 → data/tts/plan/<편id>.json. 표 한 줄 = `편id|화자=목소리,…|1:polite 2:surprised,gentle 3:shy …`
턴 값 = 문장마다 감정(쉼표). 감정 하나면 턴 전체. 이웃한 같은 감정은 한 조각으로 합친다. 숫자는 글자로 읽도록 읽기 칸을 만든다.
  python3 tools/tts/make_plans.py <표 파일>..."""
import json, re, sys
import ttslib as L
from plan_from_dialogue import read, split

n = 0
for f in sys.argv[1:]:
    for line in open(f, encoding='utf-8'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        ep, cast, body = [x.strip() for x in line.split('|')]
        d = json.load(open(L.EP[ep], encoding='utf-8'))
        emo = {int(a): b.split(',') for a, b in (x.split(':') for x in body.split())}
        P = {'ep': ep, 'cast': dict(x.split('=') for x in cast.split(',')), 'turns': {}}
        for t in d['turns']:
            s = split(t['tl']); e = emo.get(t['num'])
            if e is None:
                sys.exit(f"{ep} 턴 {t['num']} 감정 없음")
            if len(e) == 1:
                e = e * len(s)
            if len(e) != len(s):
                sys.exit(f"{ep} 턴 {t['num']} 문장 {len(s)}개인데 감정 {len(e)}개: {t['tl']}")
            segs = []
            for a, b in zip(e, s):
                if segs and segs[-1][0] == a:
                    segs[-1][1] += ' ' + b
                else:
                    segs.append([a, b])
            out = []
            for a, b in segs:
                r = read(b)
                out.append([a, b, r] if r != b else [a, b])
            P['turns'][str(t['num'])] = {'segs': out}
        json.dump(P, open(f'{L.R}/data/tts/plan/{ep}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
        n += 1
print('계획', n)
