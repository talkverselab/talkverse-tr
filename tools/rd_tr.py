#!/usr/bin/env python3
"""튀르키예어 → 한글 독음(rd). 표기표 = docs/DIALOGUE_tr.md §5. `python tools/rd_tr.py "Bir kahve, lütfen."`"""
import re
import sys

V = 'aeıioöuü'
JUNG = {'a': 'ㅏ', 'e': 'ㅔ', 'ı': 'ㅡ', 'i': 'ㅣ', 'o': 'ㅗ', 'ö': 'ㅚ', 'u': 'ㅜ', 'ü': 'ㅟ'}
Y = {'a': 'ㅑ', 'e': 'ㅖ', 'ı': 'ㅣ', 'i': 'ㅣ', 'o': 'ㅛ', 'ö': 'ㅚ', 'u': 'ㅠ', 'ü': 'ㅟ'}
SH = {'a': 'ㅑ', 'e': 'ㅖ', 'ı': 'ㅣ', 'i': 'ㅣ', 'o': 'ㅛ', 'ö': 'ㅚ', 'u': 'ㅠ', 'ü': 'ㅟ'}
ON = {'b': 'ㅂ', 'c': 'ㅈ', 'ç': 'ㅊ', 'd': 'ㄷ', 'f': 'ㅍ', 'g': 'ㄱ', 'h': 'ㅎ', 'j': 'ㅈ', 'k': 'ㅋ', 'l': 'ㄹ', 'm': 'ㅁ', 'n': 'ㄴ',
      'p': 'ㅍ', 'r': 'ㄹ', 's': 'ㅅ', 'ş': 'ㅅ', 't': 'ㅌ', 'v': 'ㅂ', 'z': 'ㅈ', 'y': 'ㅇ', 'x': 'ㅋ', 'w': 'ㅇ', 'q': 'ㅋ'}
CHO = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ'
JU = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ'
JONG = ['', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']
BAT = {'m': 'ㅁ', 'n': 'ㄴ', 'l': 'ㄹ', 'k': 'ㄱ', 'p': 'ㅂ'}  # 받침으로 쓰는 자음(t 는 낱말 끝만 ㅅ)


def syl(c, j, b=''):
    return chr(0xAC00 + (CHO.index(c) * 21 + JU.index(j)) * 28 + JONG.index(b))


def lower(s):
    return s.replace('İ', 'i').replace('I', 'ı').lower().replace('â', 'a').replace('î', 'i').replace('û', 'u')


def onset(c, v):
    if c == 'y':
        return '이으' if v == 'ı' else syl('ㅇ', Y[v])  # hayır 하이으르
    if c == 'ş':
        return syl('ㅅ', SH[v])
    return syl(ON.get(c, 'ㅇ'), JUNG[v])


def word(w):
    w = lower(w).replace('ğ', '').replace("'", '').replace('’', '')
    w = re.sub(r'([kptfsşcçbdgzv])\1', r'\1', w)  # 겹자음은 한 번(teşekkür 테셰퀴르, affedersiniz 아페데르시니즈)
    if not w:
        return ''
    # 음절 나누기: 모음마다 한 음절, 모음 사이 자음은 마지막 하나가 뒤 음절 첫소리
    idx = [i for i, ch in enumerate(w) if ch in V]
    if not idx:
        return ''.join(syl(ON.get(c, 'ㅇ'), 'ㅡ') for c in w)
    out = []  # (앞 자음들, 모음, 뒤 자음들)
    pre = w[:idx[0]]
    for n, i in enumerate(idx):
        nxt = idx[n + 1] if n + 1 < len(idx) else None
        mid = w[i + 1:nxt] if nxt is not None else w[i + 1:]
        if nxt is None:
            out.append([pre, w[i], mid])
        else:
            out.append([pre, w[i], mid[:-1]])
            pre = mid[-1:]
    res = ''
    for n, (o, v, c) in enumerate(out):
        for ch in o[:-1]:  # 낱말 앞 자음 겹침(tren → 트렌)
            res += syl(ON.get(ch, 'ㅇ'), 'ㅡ')
        s = onset(o[-1], v) if o else (syl('ㅇ', JUNG[v]))
        # l 첫소리: 앞 음절이 받침 없이 끝나면 앞에 ㄹ 받침(selam 셀람, sütlü 쉬틀뤼, izle 이즐레, şeyler 셰일레르)
        if o == 'l' and res and n > 0:
            p = ord(res[-1]) - 0xAC00
            if 0 <= p < 11172 and p % 28 == 0:
                res = res[:-1] + chr(ord(res[-1]) + JONG.index('ㄹ'))
        last = n == len(out) - 1
        tail = ''
        nxt_on = out[n + 1][0] if not last else ''
        for k, ch in enumerate(c):
            before_l = nxt_on == 'l' and k == len(c) - 1
            if k == 0 and ch in BAT and not (ch in 'kp' and before_l):
                s = s[:-1] + chr(ord(s[-1]) + JONG.index(BAT[ch]))
            elif k == 0 and ch == 't' and last and len(c) == 1:
                s = s[:-1] + chr(ord(s[-1]) + JONG.index('ㅅ'))
            elif ch == 'm' and k == 1 and c[0] == 'l':
                tail += '름'  # film 필름
            elif ch == 'y':
                tail += '이'
            elif ch == 'ş':
                tail += '시'
            elif ch in 'cç':
                tail += syl(ON[ch], 'ㅣ')
            else:
                tail += syl(ON.get(ch, 'ㅇ'), 'ㅡ')
        res += s + tail
    return res


TOKEN = re.compile(r"\{[a-z_]+\}|[^\W\d_]+(?:['’][^\W\d_]+)*|\d+|[,.!?…\"\-~()]|\s+")


def rd(text):
    out = []
    for m in TOKEN.finditer(text):
        t = m.group()
        if t.startswith('{') or t[0].isdigit() or not t[0].isalpha():
            out.append(t)
        else:
            out.append(word(t))
    return re.sub(r'\s+', ' ', ''.join(out)).strip()


if __name__ == '__main__':
    print(rd(' '.join(sys.argv[1:])))
