#!/usr/bin/env python3
"""회화 편 JSON 검사기(터키어). 규칙 = docs/DIALOGUE_tr.md, tools/prompts/dialogue_tr.md.
  python3 tools/check_dialogues.py [--fix-rd] [--stats] [파일…]   (파일 없으면 assets/data/dialogues/R*/**/*.json 전부)
오류가 있으면 종료 코드 1. 경고는 통과."""
import collections
import csv
import glob
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tools'))
import rd_tr  # noqa: E402

TURNS = {'R0': (6, 8), 'R1': (6, 8), 'R2': (8, 12), 'R3': (12, 16), 'R4': (12, 16)}
WORDS = {'R0': (2, 7), 'R1': (2, 7), 'R2': (3, 10), 'R3': (4, 14), 'R4': (4, 14)}
SENT = {'R0': 2, 'R1': 2, 'R2': 2, 'R3': 3, 'R4': 3}
TWISTS = {'chaos', 'slip', 'reveal', 'emotion', 'ignore'}
EMOTIONS = set(json.load(open(ROOT / 'data/tts/voices.json', encoding='utf-8'))['emotions'])  # 턴 emotion·segs 가 있으면 검사(11-07 이후 쓰는 회화는 필수)
KINDS = {'survival', 'short', 'long', 'chat'}
ISLANDS = {'survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'}
REGISTERS = {'polite', 'casual', 'chat', 'mixed'}
NEED = ['id', 'region', 'island', 'kind', 'title', 'emoji', 'scene', 'speakers', 'register', 'twist', 'twist_type', 'purpose', 'domain', 'goal', 'expressions', 'turns']
BRANDS = re.compile(r'\b(whatsapp|instagram|tinder|netflix|youtube|tiktok|starbucks|google|facebook|galatasaray|fenerbahçe|beşiktaş)\b', re.I)
VAR = re.compile(r'\{[a-z_]+\}')
OKVARS = {'{name}', '{country}', '{city}', '{lang}'}


def low(s):
    return s.replace('İ', 'i').replace('I', 'ı').lower()


def words(t):
    return [w for w in re.split(r'\s+', re.sub(r"[^\w\s{}'’-]", ' ', t)) if re.search(r'\w', w)]


def main():
    args = sys.argv[1:]
    fix = '--fix-rd' in args
    stats = '--stats' in args
    files = [a for a in args if not a.startswith('--')] or sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R*/**/*.json'), recursive=True))
    pool = [low(r['expr']) for r in csv.DictReader(open(ROOT / 'data/expressions/top_expressions.csv', encoding='utf-8'))]
    errs, warns = [], []
    tw, lv, isl, seen_expr = collections.Counter(), collections.Counter(), collections.Counter(), collections.Counter()
    lines = collections.defaultdict(list)
    titles = collections.defaultdict(list)
    for f in files:
        p = Path(f)
        try:
            d = json.load(open(p, encoding='utf-8'))
        except Exception as e:
            errs.append(f'{p.name}: JSON 오류 {e}')
            continue
        E = lambda m: errs.append(f"{d.get('id', p.stem)}: {m}")
        W = lambda m: warns.append(f"{d.get('id', p.stem)}: {m}")
        for k in NEED:
            if k not in d:
                E(f'칸 없음 {k}')
        if any(k not in d for k in ('id', 'region', 'kind', 'turns', 'island')):
            continue
        reg = d['region']
        if d['id'] != p.stem:
            E('id 와 파일 이름이 다름')
        if p.parent.name != d['island'] or p.parent.parent.name != reg:
            E('폴더가 region/island 와 다름')
        if reg not in TURNS or d['island'] not in ISLANDS or d['kind'] not in KINDS:
            E('region·island·kind 값 오류')
            continue
        if d.get('register') not in REGISTERS:
            E('register 값 오류')
        if d.get('twist_type') not in TWISTS:
            E('twist_type 값 오류')
        tw[d.get('twist_type')] += 1
        lv[reg] += 1
        isl[d['island']] += 1
        titles[d.get('title')].append(d['id'])
        T = d['turns']
        lo, hi = TURNS[reg]
        if not lo <= len(T) <= hi:
            E(f'턴 수 {len(T)} (기준 {lo}~{hi})')
        tws = d.get('twist')
        if not isinstance(tws, int) or not 2 <= tws <= len(T):
            E('twist 턴 번호 오류')
        sp = d.get('speakers', {})
        if sp.get('A') != '{name}':
            E('speakers.A 는 {name}')
        text = ''
        for i, t in enumerate(T, 1):
            n = t.get('num')
            tl = t.get('tl', '')
            if n != i:
                E(f'턴 번호 {n} ≠ {i}')
            if t.get('speaker') not in sp:
                E(f'턴 {i} 화자 {t.get("speaker")} 가 speakers 에 없음')
            if not tl or not t.get('ko') or not t.get('note'):
                E(f'턴 {i} tl·ko·note 빠짐')
                continue
            text += ' ' + low(tl)
            w = len(words(tl))
            a, b = WORDS[reg]
            short_ok = d['kind'] == 'chat' or i == tws or i == len(T) or any(low(tl).strip(' .!?…') == x for x in pool)
            if w > b or (w < a and not short_ok):
                E(f'턴 {i} 단어 {w} (기준 {a}~{b}): {tl}')
            s = len([x for x in re.split(r'[.!?…]+', tl) if re.search(r'\w', x)])
            if s > SENT[reg] + (1 if d['kind'] == 'survival' else 0):
                W(f'턴 {i} 문장 {s}개: {tl}')
            for v in VAR.findall(tl):
                if v not in OKVARS:
                    E(f'턴 {i} 모르는 변수 {v}')
            if BRANDS.search(tl) or BRANDS.search(t['ko']):
                E(f'턴 {i} 브랜드 이름')
            if d['kind'] == 'chat' and t.get('ui') != 'bubble':
                E(f'턴 {i} 채팅 ui=bubble 없음')
            for em in ([t['emotion']] if 'emotion' in t else []) + [x[0] for x in t.get('segs', [])]:
                if em not in EMOTIONS:
                    E(f'턴 {i} 감정 값 오류 {em}')
            if 'segs' in t and re.sub(r'\W', '', ''.join(x[1] for x in t['segs'])) != re.sub(r'\W', '', tl):
                E(f'턴 {i} segs 를 이으면 tl 과 다름')
            if not t.get('rd_manual'):
                r = rd_tr.rd(tl)
                if fix:
                    t['rd'] = r
                elif t.get('rd') != r:
                    E(f'턴 {i} rd 다름')
            lines[low(re.sub(r'[^\w ]', '', tl)).strip()].append(d['id'])
        padded = ' ' + re.sub(r"[^\w']", ' ', text) + ' '
        hits = [x for x in pool if f' {x} ' in re.sub(r' +', ' ', padded)]
        for x in hits:
            seen_expr[x] += 1
        if len(hits) < 2:
            E(f'표현 풀 {len(hits)}개(2개 이상): {hits}')
        if d['island'] == 'love' and not any('simkung' in t.get('tags', []) for t in T):
            E('연애 편에 tags "simkung" 턴 없음')
        if T and re.search(r'teşekkür|sağ ol', low(T[-1].get('tl', ''))):
            W('감사로 끝남')
        if fix:
            open(p, 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=1) + '\n')
    for k, v in titles.items():
        if len(v) > 1:
            errs.append(f'제목 겹침 「{k}」: {v}')
    for k, v in lines.items():
        if len(set(v)) > 2 and len(k.split()) >= 4:
            warns.append(f'같은 줄 {len(set(v))}편: {k}')
    for m in warns[:60 if stats else 15]:
        print('경고', m)
    for m in errs:
        print('오류', m)
    n = sum(tw.values())
    print(f'편 {n} · 오류 {len(errs)} · 경고 {len(warns)}')
    if stats and n:
        print('구간', dict(sorted(lv.items())), '주제', dict(sorted(isl.items())))
        print('반전', {k: f'{v} ({v / n:.0%})' for k, v in tw.most_common()})
        print('표현 풀 쓴 수', len(seen_expr), '/', len(pool), '· 상위', seen_expr.most_common(12))
    sys.exit(1 if errs else 0)


if __name__ == '__main__':
    main()
