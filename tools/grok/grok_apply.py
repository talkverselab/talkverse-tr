#!/usr/bin/python3
"""Grok 재작성 답 data/review/grok/out/<편id>.md → 회화 JSON 에 반영(대사·한국어·note·독음·감정 열).
  python3 tools/grok/grok_apply.py [--write] [편id...]   (없으면 out 에 있는 전편, --write 없으면 검사만)
지키는 것: 줄 수·화자 순서(다르면 그 편은 건너뜀), tags. 바뀌는 것: tl·ko·note·rd(rd_tr)·emotion/segs(문장 수와 감정 수가 맞을 때 segs),
title·scene(답에서 바뀌었으면), new(새 대사에 남은 낱말만), review.grok. 반영 뒤 tools/check_dialogues.py 와 plan_from_dialogue.py 를 돌린다."""
import glob, json, os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, ROOT + '/tools')
from rd_tr import rd  # noqa: E402

EMO = set(json.load(open(ROOT + '/data/tts/voices.json', encoding='utf-8'))['emotions'])


def split(tl):
    return [x for x in re.split(r'(?<=[.!?…])\s+', tl.strip()) if x]


def parse(path):
    s = open(path, encoding='utf-8').read()
    m = re.search(r'```[a-z]*\n(.*?)```', s, re.S)
    s = m.group(1) if m else s
    head, turns = {}, []
    for ln in s.splitlines():
        ln = ln.strip()
        if not ln:
            continue
        if '|' in ln and re.match(r'^[A-E]\s*\|', ln):
            c = [x.strip() for x in ln.split('|')]
            emo = next((x[8:] for x in c if x.startswith('emotion=')), '')
            c = [x for x in c if not x.startswith('emotion=')]
            turns.append({'speaker': c[0], 'tl': c[1], 'ko': c[2] if len(c) > 2 else '', 'note': c[3] if len(c) > 3 else '', 'emo': emo})
        elif ':' in ln:
            k, v = ln.split(':', 1)
            head[k.strip()] = v.strip()
    return head, turns


def lowtr(s):
    return s.replace('I', 'ı').replace('İ', 'i').lower()


def apply(f, d, head, nt):
    old = d['turns']
    if len(nt) != len(old):
        return '줄 수 %d ≠ %d' % (len(nt), len(old))
    for o, n in zip(old, nt):
        if o['speaker'] != n['speaker']:
            return '턴 %d 화자 %s ≠ %s' % (o['num'], n['speaker'], o['speaker'])
        if not n['tl'] or not n['ko']:
            return '턴 %d 빈 칸' % o['num']
    warn = []
    for o, n in zip(old, nt):
        o['tl'], o['ko'], o['note'] = n['tl'], n['ko'], n['note'] or o.get('note', '')
        o['rd'] = rd(n['tl'])
        emos = [e.strip() for e in n['emo'].split('+') if e.strip()]
        bad = [e for e in emos if e not in EMO]
        if bad or not emos:
            warn.append('턴 %d 감정 %s → neutral' % (o['num'], n['emo']))
            emos = [e for e in emos if e in EMO] or ['neutral']
        sents = split(n['tl'])
        o.pop('segs', None); o.pop('emotion', None)
        if len(emos) > 1 and len(emos) == len(sents):
            o['segs'] = [[e, x] for e, x in zip(emos, sents)]
        else:
            if len(emos) > 1:
                warn.append('턴 %d 감정 %d개·문장 %d개 → 첫 감정' % (o['num'], len(emos), len(sents)))
            o['emotion'] = emos[0]
        words = set(re.findall(r"[\wçğıöşüâîû']+", lowtr(n['tl'])))
        o['new'] = [w for w in o.get('new', []) if any(x.startswith(lowtr(w)) for x in words)]
    for k in ('title', 'scene'):
        if head.get(k):
            d[k] = head[k]
    d.setdefault('review', {})['grok'] = 'grok 전문가 2026-11-09'
    return warn


if __name__ == '__main__':
    a = sys.argv[1:]
    write = '--write' in a
    a = [x for x in a if x != '--write']
    E = {}
    for f in glob.glob(ROOT + '/assets/data/dialogues/R*/**/*.json', recursive=True):
        d = json.load(open(f, encoding='utf-8'))
        E[d['id']] = (f, d)
    ids = a or sorted(os.path.basename(p)[:-3] for p in glob.glob(ROOT + '/data/review/grok/out/*.md'))
    ok = 0
    for i in ids:
        f, d = E[i]
        head, nt = parse(ROOT + '/data/review/grok/out/%s.md' % i)
        r = apply(f, d, head, nt)
        if isinstance(r, str):
            print('건너뜀', i, r); continue
        ok += 1
        for w in r:
            print('  ', i, w)
        if write:
            open(f, 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=1) + '\n')
    print('반영' if write else '검사', ok, '/', len(ids))
