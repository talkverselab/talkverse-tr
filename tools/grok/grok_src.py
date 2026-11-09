#!/usr/bin/python3
"""회화 JSON + 감정 계획 → Grok 재작성용 글 data/review/grok/src/<편id>.txt (헝가리어 세션 형식, 2026-11-09).
  python3 tools/grok/grok_src.py [편id...]   (없으면 초안 전편)
머리 줄(=== id …) + 대사 줄 `화자 | 터키어 | 한국어 | note | emotion=감정+감정`(문장마다 +, 감정 계획 segs 에서)."""
import glob, json, os, sys
BLIND = '--blind' in sys.argv
if BLIND:
    sys.argv.remove('--blind')
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def eps():
    out = {}
    for f in sorted(glob.glob(ROOT + '/assets/data/dialogues/R*/**/*.json', recursive=True)):
        d = json.load(open(f, encoding='utf-8'))
        if d.get('draft'):
            out[d['id']] = (f, d)
    return out


def src(d):
    plan = {}
    p = ROOT + '/data/tts/plan/%s.json' % d['id']
    if os.path.exists(p):
        plan = json.load(open(p, encoding='utf-8')).get('turns', {})
    sp = d['speakers']
    h = ['=== ' + d['id'], 'kind: ' + d['kind'], 'title: ' + d['title'], 'emoji: ' + d.get('emoji', ''), 'scene: ' + d['scene'],
         'speakers: ' + ', '.join('%s=%s' % kv for kv in sp.items()), 'register: ' + d.get('register', ''),
         'twist: %s %s' % (d.get('twist', ''), d.get('twist_type', '')), 'purpose: ' + ' '.join(d.get('purpose', [])),
         'goal: ' + d.get('goal', ''), 'expressions: ' + '; '.join(d.get('expressions', []))]
    for t in d['turns']:
        segs = plan.get(str(t['num']), {}).get('segs') or [[t.get('emotion', 'neutral'), t['tl']]]
        tl = '?' if BLIND else t['tl']  # 터키어를 보여 주면 Grok 이 거의 그대로 둔다(2026-11-10) → 한국어 뜻만 주고 새로 쓰게
        h.append(' | '.join([t['speaker'], tl, t['ko'], t.get('note', '') if not BLIND else '', 'emotion=' + '+'.join(s[0] for s in segs)]))
    return '\n'.join(h) + '\n'


if __name__ == '__main__':
    E = eps()
    ids = sys.argv[1:] or list(E)
    os.makedirs(ROOT + '/data/review/grok/src', exist_ok=True)
    for i in ids:
        open(ROOT + '/data/review/grok/src/%s.txt' % i, 'w', encoding='utf-8').write(src(E[i][1]))
    print(len(ids), '편')
