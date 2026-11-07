#!/usr/bin/python3
"""회화 파일의 감정 열(턴 `emotion`·`segs`) → 감정 계획 data/tts/plan/<편id>.json. 감정을 다시 손으로 적지 않기 위한 것.
  python3 tools/tts/plan_from_dialogue.py [편id...]   (없으면 전편) — 감정 열이 빠진 턴이 있는 편은 건너뛰고 알린다, 그런 편이 있으면 종료 코드 1
make_jobs·run_all 이 작업을 만들기 전에 sync() 를 부르므로 보통은 따로 돌릴 일이 없다. 참고 음성은 계획의 (목소리, 감정)을 그대로 따른다.
목소리: 편의 `cast` 칸 → 있던 계획의 cast → 아래 이름표 순서(이름은 Elif 인데 실제로 엄마가 답하는 편처럼 이름표가 틀릴 때가 있다). 못 찾으면 그 편을 만들지 않는다(편에 "cast":{"C":"man_o"} 를 적는다)."""
import json, os, re, sys
import ttslib as L
ONES = ['', 'bir', 'iki', 'üç', 'dört', 'beş', 'altı', 'yedi', 'sekiz', 'dokuz']
TENS = ['', 'on', 'yirmi', 'otuz', 'kırk', 'elli', 'altmış', 'yetmiş', 'seksen', 'doksan']
EMOJI = re.compile(r'[\U0001F000-\U0001FFFF☀-➿️‍]')
CAST = {'Elif': 'elif', 'Can': 'can', 'Zeynep': 'zeynep', 'Emre': 'emre', 'Garson': 'waiter', 'Satıcı': 'vendor', 'Simitçi': 'vendor', 'Bakkal': 'vendor',
        'Taksici': 'taxi', 'Teyze': 'teyze', 'Müdür': 'boss', 'Hoca': 'hoca', 'Resepsiyon': 'staff', 'Anne': 'mom', 'Baba': 'dad', 'Anons': 'announce'}


def num(n):
    n = int(n)
    if n == 0:
        return 'sıfır'
    o = []
    if n >= 1000:
        o.append(('' if n // 1000 == 1 else num(n // 1000) + ' ') + 'bin'); n %= 1000
    if n >= 100:
        o.append(('' if n // 100 == 1 else ONES[n // 100] + ' ') + 'yüz'); n %= 100
    if n >= 10:
        o.append(TENS[n // 10]); n %= 10
    if n:
        o.append(ONES[n])
    return ' '.join(o)


def read(s):
    """음성 모델이 읽을 글: 이모지를 빼고 숫자는 글자로."""
    r = EMOJI.sub('', s)
    r = re.sub(r"(\d+)(?:['’]\w+)?", lambda m: m.group(0) if "'" in m.group(0) or '’' in m.group(0) else num(m.group(1)), r)
    return re.sub(r'\s+', ' ', r).strip()


def split(tl):
    return [x for x in re.split(r'(?<=[.!?…])\s+', tl.strip()) if x]


def seg(a, b):
    r = read(b)
    return [a, b, r] if r != b else [a, b]


def cast_of(d, old):
    out = {}
    for k, name in d['speakers'].items():
        if k == 'A':
            continue
        v = d.get('cast', {}).get(k) or old.get(k) or CAST.get(name)
        if v not in L.V['voices']:
            return None, f'목소리 없음 {k}={name}'
        out[k] = v
    return out, ''


def build(d, old=None):
    """편 → 계획. 만들 수 없으면 (None, 이유)."""
    old = old or {}
    cast, why = cast_of(d, old.get('cast', {}))
    if cast is None:
        return None, why
    P = {'ep': d['id'], 'cast': cast, 'turns': {}}
    for t in d['turns']:
        if t.get('segs'):
            segs = [seg(x[0], x[1]) for x in t['segs']]
        elif t.get('emotion'):
            segs = [seg(t['emotion'], t['tl'])]
        else:
            return None, f"턴 {t['num']} 감정 열 없음"
        for x in segs:
            if x[0] not in L.V['emotions']:
                return None, f"턴 {t['num']} 감정 {x[0]}"
        T = {'segs': segs}
        o = old.get('turns', {}).get(str(t['num']), {})
        for g in 'mf':
            if g in o:
                T[g] = o[g]  # 판별 본문은 손으로 쓴 것을 그대로 둔다
        P['turns'][str(t['num'])] = T
    return P, ''


def sync(ids=None):
    """감정 열이 다 있는 편의 계획을 새로 쓴다. 돌려주는 값 = (쓴 편 수, [(편, 이유)])."""
    n, skip = 0, []
    for ep in ids or sorted(L.EP):
        d = json.load(open(L.EP[ep], encoding='utf-8'))
        f = f'{L.R}/data/tts/plan/{ep}.json'
        old = json.load(open(f, encoding='utf-8')) if os.path.exists(f) else None
        P, why = build(d, old)
        if P is None:
            skip.append((ep, why)); continue
        json.dump(P, open(f, 'w', encoding='utf-8'), ensure_ascii=False, indent=0); n += 1
    return n, skip


if __name__ == '__main__':
    n, skip = sync(sys.argv[1:])
    for ep, why in skip[:20]:
        print('건너뜀', ep, why)
    print('계획', n, '건너뜀', len(skip))
    sys.exit(1 if skip else 0)
