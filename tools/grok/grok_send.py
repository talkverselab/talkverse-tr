#!/usr/bin/python3
"""Grok 프로젝트 챗에 프롬프트 파일을 보내고 답을 기다려 저장한다. 한도 문구가 뜨면 LIMIT 줄을 출력(세션이 CronCreate 로 재개).
  /usr/bin/python3 tools/grok_send.py <프롬프트파일> <저장파일> [--tab project/d73988ce] [--wait 300] [--attach a.png,b.png]
출력 마지막 줄: OK <저장파일> | LIMIT <HH:MM 또는 ?> <문구> | TIMEOUT | NOINPUT
"""
import re, sys, time
import os
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9252')  # tr 전용 PC 크롬(프로필 D:\chrome-grok-tr)

a = sys.argv[1:]
src, dst = a[0], a[1]
frag = a[a.index('--tab') + 1] if '--tab' in a else 'project/d73988ce'
wait = int(a[a.index('--wait') + 1]) if '--wait' in a else 300
attach = [x for x in a[a.index('--attach') + 1].split(',') if x] if '--attach' in a else []  # 첨부 파일(쉼표 구분, 절대경로) — input[type=file] 에 DOM.setFileInputFiles
LIMIT_RE = re.compile(r'(한도|limit|제한|rate|너무 많|사용량|초기화|다시 시도|try again|upgrade|SuperGrok)', re.I)
TIME_RE = re.compile(r'(\d{1,2}):(\d{2})')


def answers(c):
    els = c.ev("[...document.querySelectorAll('.response-content-markdown')].map(e=>e.innerText)")
    return els


c = g.CDP(g.tab(frag)); c.call('Page.bringToFront')
_els0 = answers(c); last_answer = _els0[-1] if _els0 else ''
text = open(src, encoding='utf-8').read().strip()
if c.ev("document.querySelector('.ProseMirror')") is None:
    print('NOINPUT'); sys.exit(2)
if attach:
    import os as _os
    doc = c.call('DOM.getDocument', depth=1)
    q = c.call('DOM.querySelector', nodeId=doc['root']['nodeId'], selector='input[type=file]')
    c.call('DOM.setFileInputFiles', nodeId=q['nodeId'], files=[x if ':' in x[:3] else _os.path.abspath(x) for x in attach]); time.sleep(4 + 2 * len(attach))
    print('attached', len(attach))
c.ev("document.querySelector('.ProseMirror').focus()")
c.call('Input.insertText', text=text); time.sleep(1)
c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(e=>['제출','보내기'].includes(e.getAttribute('aria-label')||''));if(b)b.click()})()")
time.sleep(3)
left = c.ev("document.querySelector('.ProseMirror').innerText.trim().length")
if left > 5:
    for typ in ('keyDown', 'keyUp'):
        c.call('Input.dispatchKeyEvent', type=typ, key='Enter', code='Enter', windowsVirtualKeyCode=13, nativeVirtualKeyCode=13)
    time.sleep(3)
t0 = time.time(); reloaded = False; stable = 0; prev = None
while time.time() - t0 < wait:
    body = c.ev("document.body.innerText")
    tail = body[-1500:]
    if LIMIT_RE.search(tail) and ('한도' in tail or 'limit' in tail.lower() or '초기화' in tail):
        m = TIME_RE.search(tail[tail.lower().find('한도') if '한도' in tail else 0:])
        print('LIMIT', m.group(0) if m else '?', '|', re.sub(r'\s+', ' ', tail[-300:]))
        sys.exit(3)
    busy = '작업 중' in body or c.ev("!![...document.querySelectorAll('button')].find(e=>['응답 중지','중지','Stop'].includes(e.getAttribute('aria-label')||''))")
    els = answers(c)
    # 2026-11-09: Grok 화면이 바뀌어 '응답 중지' 단추로 진행 중을 못 잡는다 → 답 길이가 20초(3회) 그대로일 때만 끝난 것으로 본다
    cur = els[-1] if els else ''
    stable = stable + 1 if cur == prev else 0; prev = cur
    if not busy and stable >= 3 and els and not els[-1].startswith('[J') and not els[-1].startswith('[G'):
        if len(els[-1]) > 150 and els[-1] != last_answer:
            open(dst, 'w', encoding='utf-8').write(els[-1]); print('OK', dst); sys.exit(0)
        if not reloaded and len(els[-1]) <= 150 and stable >= 12:
            c.call('Page.reload'); reloaded = True; time.sleep(9); c = g.CDP(g.tab(frag)); continue
    time.sleep(8)
print('TIMEOUT'); sys.exit(1)
