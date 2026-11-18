#!/usr/bin/env python3
"""심사용 회화 고르기(사용자 지시 2026-11-18 「다이얼로그는 30%」「각 레벨별 다이얼로그를 분산시켜서」).

급마다 정한 수(일본어앱 분량의 30% — R0 14 · R1 21 · R2 17 · R3 13)를 주제마다 돌아가며 고른다.
결과 = assets/data/dialogues/_release.json(앱이 보여 줄 편 id). 이 파일도 서버 원고(script_publish.py)에 실려
나중에 편을 늘리려면 이 파일만 고쳐 --publish 하면 된다.

  python3 tools/pick_release.py           # 고른 결과만 보기
  python3 tools/pick_release.py --write
"""
import glob
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/data/dialogues/_release.json'
TARGET = {'R0': 14, 'R1': 21, 'R2': 17, 'R3': 13}
ALWAYS = {'r0_love_a1'}  # 시험 음성이 있는 편


def key(i):
    return re.sub(r'\d+', lambda m: m.group(0).zfill(3), i)


def main():
    by = defaultdict(lambda: defaultdict(list))
    for p in glob.glob(str(ROOT / 'assets/data/dialogues/R[0-4]/*/*.json')):
        d = json.load(open(p, encoding='utf-8'))
        if d.get('turns'):
            by[d['region']][d['island']].append(d['id'])
    pick = []
    for lv, n in TARGET.items():
        isl = {k: sorted(v, key=key) for k, v in sorted(by[lv].items())}
        got = [i for v in isl.values() for i in v if i in ALWAYS]
        while len(got) < n and any(isl.values()):
            for k in list(isl):
                if len(got) >= n:
                    break
                while isl[k] and isl[k][0] in got:
                    isl[k].pop(0)
                if isl[k]:
                    got.append(isl[k].pop(0))
        pick += sorted(got, key=key)
        print(lv, len(got), '/', sum(len(v) for v in by[lv].values()))
    print('합', len(pick))
    if '--write' in sys.argv:
        OUT.write_text(json.dumps({'ids': pick}, ensure_ascii=False, indent=0) + '\n', encoding='utf-8')
        print('씀', OUT.relative_to(ROOT))


if __name__ == '__main__':
    main()
