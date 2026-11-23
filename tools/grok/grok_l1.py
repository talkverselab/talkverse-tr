#!/usr/bin/python3
"""옛 이야기 L1(assets/data/dialogues/L1.json, 5편 × 8턴)을 Grok 재작성 틀에 맞춘다(2026-11-23, uk Grok 2차).
  python3 tools/grok/grok_l1.py src            → data/review/grok/src/L1_<ep>.txt (터키어 칸은 ? — 한국어 뜻만 보냄)
  python3 tools/grok/grok_l1.py apply [--write] ← data/review/grok/out_l1/L1_<ep>.md (줄 수·화자 같을 때만, 턴마다 2~7단어 검사)
L1 의 대상어 칸 이름은 `es`(템플릿 흔적). 독음 rd 는 rd_tr 로 다시 만든다. R 편과 섞이지 않게 답은 out_l1/ 에 둔다."""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, ROOT + '/tools')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rd_tr import rd  # noqa: E402
from grok_apply import parse  # noqa: E402

L1 = ROOT + '/assets/data/dialogues/L1.json'
WORDS = (2, 7)


def src():
    d = json.load(open(L1, encoding='utf-8'))
    names = {k: v.get('name', k) for k, v in d.get('characters', {}).items()}
    os.makedirs(ROOT + '/data/review/grok/src', exist_ok=True)
    for e in d['episodes']:
        h = ['=== L1_' + e['id'], 'kind: long', 'title: ' + e['title'], 'emoji: ' + e.get('emoji', ''), 'scene: ' + e.get('scenario', ''),
             'speakers: ' + ', '.join('%s=%s' % (k, names.get(k, k)) for k in sorted({t['speaker'] for t in e['turns']})),
             'register: casual', 'goal: 왕초보 — 턴마다 터키어 %d~%d단어' % WORDS]
        for t in e['turns']:
            h.append(' | '.join([t['speaker'], '?', t['ko'], '', 'emotion=neutral']))
        open(ROOT + '/data/review/grok/src/L1_%s.txt' % e['id'], 'w', encoding='utf-8').write('\n'.join(h) + '\n')
    print(len(d['episodes']), '편')


def apply(write):
    d = json.load(open(L1, encoding='utf-8'))
    ok = 0
    for e in d['episodes']:
        p = ROOT + '/data/review/grok/out_l1/L1_%s.md' % e['id']
        if not os.path.exists(p):
            print('답 없음', e['id']); continue
        head, nt = parse(p)
        if len(nt) != len(e['turns']) or any(o['speaker'] != n['speaker'] or n.get('bad') or not n['tl'] for o, n in zip(e['turns'], nt)):
            print('건너뜀', e['id'], '줄 수·화자·칸이 다름'); continue
        long = [(o['num'], n['tl']) for o, n in zip(e['turns'], nt) if not WORDS[0] <= len(re.findall(r"[\wçğıöşüâîû']+", n['tl'])) <= WORDS[1]]
        if long:
            print('길이', e['id'], long)
        for o, n in zip(e['turns'], nt):
            o['es'], o['ko'], o['rd'] = n['tl'], n['ko'], rd(n['tl'])
            if n['note']:
                o['note'] = n['note']
        if head.get('title'):
            e['title'] = head['title']
        ok += 1
    if write:
        open(L1, 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=1) + '\n')
    print('반영' if write else '검사', ok, '/', len(d['episodes']))


if __name__ == '__main__':
    a = sys.argv[1:]
    if a and a[0] == 'src':
        src()
    elif a and a[0] == 'apply':
        apply('--write' in a)
    else:
        sys.exit(__doc__)
