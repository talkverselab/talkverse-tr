#!/usr/bin/python3
"""튀르키예어 회화 장면 컷(A·B 한 쌍 = 1컷, 글자·말풍선 없음) — 베트남어앱 grok_scene_vi.py 를 tr 판으로(2026-11-19, uk 「tr 그림 시작」).
PC 크롬 9252(「빠른」 모드), 요청마다 새 방(https://grok.com/) + 인물 시트 첨부(PC 경로 D:\\grok_att\\tr). 요청당 1컷(SCENE_CHUNK).
받은 그림은 1168×784 로 맞춰 그림 저장소 sparse 클론 ~/talkverse/tr-art 의 talkverse_art/scene/tr/<편id>/cut<N>.jpg.
  /usr/bin/python3 tools/grok/grok_scene_tr.py <편id> ... [--push] [--female]"""
import base64, glob, json, os, re, subprocess, sys, time
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9252')
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ART = os.path.expanduser('~/talkverse/tr-art')
SHEET = r'D:\grok_att\tr\chars_tr_v1.jpg'  # 브라우저가 PC 라서 PC 경로 — 원본 data/review/art/chars_tr_v1.jpg(CHARACTERS.md)
a = sys.argv[1:]
tab = 'grok.com'
push = '--push' in a
fetch_only = '--fetch-only' in a
FEMALE = '--female' in a
ids = [x for x in a if not x.startswith('--')]
CAST = {'Elif': '시트의 엘리프(짙은 갈색 긴 곱슬 웨이브, 머스터드 니트, 연청 데님)',
        'Can': '시트의 잔(짧은 곱슬 흑발·짧은 수염, 흰 티 + 짙은 녹색 앞치마)',
        'Zeynep': '시트의 제이넵(연한 장미색 스카프, 크림색 롱 카디건, 남색 롱스커트, 스케치북)',
        'Emre': '시트의 엠레(뒤로 넘긴 흑발·다듬은 수염, 짙은 회흑색 재킷 + 흰 티, 가장 큰 키)',
        '{name}': '시트의 남자 학습자(짧은 곱슬 갈색 머리, 청록 후드티, 베이지 바지, 갈색 백팩)'}
if FEMALE:
    CAST['{name}'] = '시트의 여자 학습자(검은 단발 보브, 남색 재킷 + 청록 티, 베이지 바지, 갈색 백팩) — 남자 학습자 대신'


def who(name):
    return CAST.get(name, f'{name}(시트에 없는 조연 — 튀르키예 사람, 같은 점토 톤, 실존 인물 닮지 않게)')


def find(eid):
    fs = glob.glob(os.path.join(ROOT, f'assets/data/dialogues/R*/*/{eid}.json'))
    return fs[0] if fs else None


def prompt(ep, cuts, part):
    cast = ', '.join(f'{k}={who(v)}' for k, v in ep['speakers'].items())
    lines = [f"{n}. " + ' / '.join(f"{t['speaker']}: {t['ko']}" for t in pair) for n, pair in cuts]
    return (f"[SC-{ep['id']}{'-F' if FEMALE else ''}-{part}] 지금 바로 이미지 {len(cuts)}장 생성(글 설명 없이 그림만, 컷마다 1장). "
            f"첨부 시트 인물 그대로, 부드러운 펠트·점토 인형 톤, 크림 배경, 튀르키예(이스탄불)의 실제 장소 느낌, 3:2 가로, 글자·말풍선·간판 글씨·로고 없음.\n"
            f"장면: {ep['scene']}\n등장: {cast}\n" + '\n'.join(lines))

def imgs_ready(c, want):
    srcs = c.ev("(()=>{const r=[...document.querySelectorAll('.response-content-markdown')];const e=r[r.length-1];if(!e)return [];return [...e.closest('[class*=message],[class*=response]')?.querySelectorAll('img')||e.querySelectorAll('img')].map(i=>i.src)})()") or []
    busy = c.ev("!![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')")
    real = [s for s in srcs if s.startswith('http') and 'assets.grok.com' in s]
    data = [s for s in srcs if s.startswith('data:')]
    return real, (busy or data)

def last_imgs(c):
    # 마지막 답 근처의 생성 그림(assets.grok.com) — 답 요소 밖 갤러리에 붙는 경우가 있어 문서 전체에서 마지막 것들을 본다
    # 첨부 썸네일(64px 안팎)은 빼고, 생성 그림(가로 300px 이상)만
    return c.ev("[...document.querySelectorAll('img')].filter(i=>i.src.includes('assets.grok.com')&&i.src.includes('/generated/')&&i.naturalWidth>=300).map(i=>i.src)") or []

def fetch_b64(c, url):
    js = ("fetch(%s,{credentials:'include'}).then(r=>r.blob()).then(b=>new Promise(ok=>{const f=new FileReader();f.onload=()=>ok(f.result);f.readAsDataURL(b)}))" % json.dumps(url))
    d = c.ev(js)
    return base64.b64decode(d.split(',', 1)[1]) if isinstance(d, str) and d.startswith('data:') else None

def fit(src, dst):
    # 3:2 로 가운데 자르고 1168×784
    w = int(subprocess.run(['sips', '-g', 'pixelWidth', src], capture_output=True, text=True).stdout.split()[-1])
    h = int(subprocess.run(['sips', '-g', 'pixelHeight', src], capture_output=True, text=True).stdout.split()[-1])
    if w / h > 1.5: cw, ch = int(h * 1.5), h
    else: cw, ch = w, int(w / 1.5)
    subprocess.run(['sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '88', '--cropToHeightWidth', str(ch), str(cw), src, '--out', dst], capture_output=True)
    subprocess.run(['sips', '-z', '784', '1168', dst], capture_output=True)

def do(eid):
    path = find(eid)
    if not path: print('편 없음', eid); return False
    ep = json.load(open(path, encoding='utf-8'))
    turns = ep['turns']
    cuts = [((i // 2) + 1, turns[i:i + 2]) for i in range(0, len(turns), 2)]
    out = os.path.join(ART, 'talkverse_art/scene/tr', ep['id'] + ('_f' if FEMALE else ''))
    os.makedirs(out, exist_ok=True)
    N = int(os.environ.get('SCENE_CHUNK', '1'))  # 2026-11-18 오후: 「빠른」이 4장 요청에 1장만 그려 → 요청당 1컷(환경변수로 4·6 가능)
    for part, k in enumerate(range(0, len(cuts), N), 1):
        chunk = cuts[k:k + N]
        if all(os.path.exists(os.path.join(out, f'cut{n}.jpg')) for n, _ in chunk):
            print('SKIP', ep['id'], part, flush=True); continue
        pf = os.path.join(ROOT, 'data/review/scene', f"{ep['id']}_scene{part}_prompt.md")
        open(pf, 'w', encoding='utf-8').write(prompt(ep, chunk, part))
        c = g.CDP(g.tab(tab)); c.call('Page.bringToFront')
        before = set() if fetch_only else set(last_imgs(c))
        if fetch_only:
            last = 'OK'
        else:
          # 그림은 새 대화에서만 안정적으로 나온다(2026-11-03: 긴 대화에서 그림 없이 "완료"만 답함) → 요청마다 프로젝트 첫 화면으로
          c.call('Page.navigate', url='https://grok.com/'); time.sleep(8)
          r = subprocess.run(['/usr/bin/python3', os.path.join(ROOT, 'tools/grok/grok_send.py'), pf, pf.replace('_prompt.md', '_answer.md'),
                            '--tab', tab, '--wait', '90', '--attach', SHEET], capture_output=True, text=True)
          last = (r.stdout.strip().splitlines() or [''])[-1]
        if last.startswith('LIMIT'):
            print('LIMIT', ep['id'], last, flush=True); return False
        new = []
        idle = 0
        for _ in range(80):  # 그림은 글보다 늦게 온다 — 새 assets 그림이 컷 수만큼 될 때까지(최대 20분)
            c = g.CDP(g.tab(tab))
            cur = [s for s in last_imgs(c) if s not in before]
            seen = []
            for s in cur:
                if s not in seen: seen.append(s)
            busy = c.ev("!![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')") or \
                   c.ev("[...document.querySelectorAll('img')].some(i=>i.src.startsWith('data:image')&&i.naturalWidth>200)")
            new = seen
            if len(new) >= len(chunk) and not busy: break
            # 답이 끝났는데 그림이 1분 넘게 0장이면 그림 없이 끝난 것(2026-11-03 여러 번) → 빨리 실패하고 새 대화로 재시도
            idle = (idle + 1) if not busy else 0  # 2026-11-18: 1장만 오고 멈추는 경우도 1분 넘으면 끝
            if idle >= 5: break
            time.sleep(15)
        print(ep['id'], part, 'imgs', len(new), flush=True)
        if len(new) < len(chunk):
            print('FAIL', ep['id'], part, '그림 수 부족', len(new), flush=True); return False
        for (n, _), url in zip(chunk, new[:len(chunk)]):
            b = fetch_b64(c, url)
            if not b: print('FAIL 받기', url[:80]); return False
            tmp = os.path.join(out, f'.raw{n}')
            open(tmp, 'wb').write(b)
            fit(tmp, os.path.join(out, f'cut{n}.jpg')); os.remove(tmp)
        print('OK', ep['id'], part, [n for n, _ in chunk], flush=True)
    return True

def git_push(msg):
    subprocess.run(['git', '-C', ART, 'add', 'talkverse_art/scene/tr'], check=True)
    if subprocess.run(['git', '-C', ART, 'diff', '--cached', '--quiet']).returncode == 0: return
    subprocess.run(['git', '-C', ART, 'commit', '-q', '-m', msg], check=True)
    for _ in range(4):  # 다른 세션이 같은 저장소에 자주 푸시한다 — 밀리면 다시 받고 재시도
        subprocess.run(['git', '-C', ART, 'pull', '-q', '--rebase'])
        if subprocess.run(['git', '-C', ART, 'push', '-q']).returncode == 0: break
        time.sleep(5)
    print('PUSHED', msg, flush=True)

done, failed = [], []
for eid in ids:
    ok = do(eid) or do(eid)  # 그림이 안 오면 새 대화로 한 번 더(2026-11-03 r1_culture_b5: 그림 대신 다른 경로로 1장만 옴)
    if ok: done.append(eid)
    else:
        failed.append(eid); print('SKIPFAIL', eid, flush=True)
        if open(os.path.join(ROOT, 'data/review/scene/scene_batch.log')).read().count('LIMIT'): break
        if len(failed) >= 5 and not done[-3:]: print('STOP 연속 실패', flush=True); break
        continue
    if push and len(done) % 5 == 0: git_push(f'scene/tr: {", ".join(done[-5:])}')
if push and done: git_push(f'scene/tr: {", ".join(done[-(len(done) % 5 or 5):])}')
print('DONE', len(done), 'FAILED', ' '.join(failed), flush=True)
