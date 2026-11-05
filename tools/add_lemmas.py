#!/usr/bin/env python3
"""회화 JSON 의 턴마다 `lemmas`(내용어 [표면형, 기본형, 읽기]) 를 채운다 — 문장 레마 ↔ 단어장 연결(일본어앱 2026-11-04 방식).
내용어 = 명사·동사·형용사·부사(기능어·대명사·접속사·후치사·감탄사·숫자 제외). 기본형은 형태소 분석기 레마(동사 -mak/-mek).
읽기 칸은 비워 둔다(라틴 문자). 단어장(assets/data/freq/lang_es_top.csv)에 없는 레마는 data/review/write/missing_lemmas.csv 로(uk 세션에 넘김).
문장·뜻은 바꾸지 않는다 — lemmas 칸만 더한다.
  NLTK_DATA=<punkt> python tools/add_lemmas.py   (zeyrek 필요)
"""
import collections, csv, json, logging, re, sys
from pathlib import Path

logging.disable(logging.CRITICAL)
import zeyrek

ROOT = Path(__file__).resolve().parent.parent
CONTENT = {'Noun', 'Verb', 'Adj', 'Adv'}
an = zeyrek.MorphAnalyzer()


def lower(s):
    return s.replace('İ', 'i').replace('I', 'ı').lower()


def lemma(word):
    """(기본형, 품사) — 못 나누면 None. 고유명사·숫자는 None."""
    w = lower(word)
    try:
        ps = [p for g in an.analyze(w) for p in g if p.lemma and p.lemma.lower() != 'unk' and p.pos != 'Unk']
    except Exception:
        return None
    if not ps:
        return None
    # 고유명사가 아닌 해석 중 어간이 가장 긴 것(빈도표 만들 때와 같은 규칙)
    ln = lambda l: len(l) - 3 if l.endswith(('mak', 'mek')) else len(l)
    p = sorted(ps, key=lambda p: (p.lemma[:1].isupper(), -ln(p.lemma.lower())))[0]
    if p.lemma[:1].isupper() or p.morphemes[0] not in CONTENT:
        return None
    return p.lemma.lower(), p.morphemes[0]


FIX = json.load(open(ROOT / 'tools/lemma_fix.json', encoding='utf-8'))  # 분석기 오분석 → 바른 기본형(빈도표 검수에서 모은 것)
SURFACE = json.load(open(ROOT / 'tools/lemma_surface_fix.json', encoding='utf-8'))  # 문맥을 봐야 아는 낱말 — 표면형 → 기본형, null 은 뺌(대명사·기능어·지명)
vocab = set()
for r in csv.DictReader(open(ROOT / 'assets/data/freq/lang_es_top.csv', encoding='utf-8')):
    vocab.add(r['word'])
miss = collections.Counter()
ex = {}
tot = hit = 0
for f in sorted((ROOT / 'assets/data/dialogues').glob('L*.json')):
    d = json.load(open(f, encoding='utf-8'))
    changed = False
    for ep in d.get('episodes', []):
        for t in ep.get('turns', []):
            an = zeyrek.MorphAnalyzer()  # 분석기 버그(앞 낱말이 뒤 낱말 분석을 망가뜨림) 때문에 턴마다 새로
            out = []
            text = re.sub(r'\{[a-z_]+\}', ' ', t.get('tl') or t.get('es') or '')
            for i, w in enumerate(re.findall(r"[^\W\d_]+(?:['’][^\W\d_]+)?", text)):
                if i > 0 and w[:1].isupper():
                    continue  # 문장 중간 대문자 = 이름(Elif·Minjun·İstanbul …)
                stem = w.split("'")[0].split('’')[0]
                key = lower(stem)
                if key in SURFACE:
                    if SURFACE[key] is None:
                        continue
                    base = SURFACE[key]
                else:
                    lp = lemma(stem)
                    if lp is None:
                        continue
                    base = FIX.get(lp[0], lp[0])
                out.append([w, base, ''])
                tot += 1
                if base in vocab:
                    hit += 1
                else:
                    miss[base] += 1
                    ex.setdefault(base, t.get('tl') or t.get('es'))
            if t.get('lemmas') != out:
                t['lemmas'] = out
                changed = True
    if changed:
        open(f, 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=1) + '\n')
(ROOT / 'data/review/write').mkdir(parents=True, exist_ok=True)
with open(ROOT / 'data/review/write/missing_lemmas.csv', 'w', encoding='utf-8', newline='') as fo:
    w = csv.writer(fo, lineterminator='\n')
    w.writerow(['lemma', 'count', 'example'])
    for b, n in miss.most_common():
        w.writerow([b, n, ex[b]])
print(f'내용어 {tot} · 단어장 있음 {hit / max(tot, 1):.0%} · 없는 레마 {len(miss)} → data/review/write/missing_lemmas.csv')
