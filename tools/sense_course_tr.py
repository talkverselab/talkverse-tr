#!/usr/bin/env python3
"""언어감각 과정 원고(튀르키예어) → assets/data/grammar/sense_course.json (일본어앱 빌드 96~112 꼴, 2026-11-18 전달).

급마다 외울 대화 1회(kind memorize, 10줄) + 참고 1회(kind ref). 문장은 자체 제작(Claude 초안 — uk 원칙상 대사는 Grok 몫이라
다시 쓸지는 사용자 결정, 그때까지 이 원고를 쓴다). `{글자|번호}` = 어미 자리 — 같은 번호는 터키어·한국어에서 같은 색.
한글 독음 rd 는 tools/rd_tr.py 로 만든다.
  python3 tools/sense_course_tr.py      # JSON 다시 만들기 → 바뀌었으면 tools/script_publish.py --publish
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from rd_tr import rd  # noqa: E402

OUT = ROOT / 'assets/data/grammar/sense_course.json'
MARK = re.compile(r'\{([^|}]+)\|(\d+)\}')
NOTE = '일부러 규칙을 설명하지 않았어요. 대화를 통째로 외우면 색칠한 어미가 저절로 익어요.'


def plain(s):
    return MARK.sub(lambda m: m.group(1), s)


def S(who, tl, ko):
    return {'who': who, 'tl': tl, 'rd': rd(plain(tl)), 'ko': ko}


def P(head, tip, *pairs):
    return {'head': head, 'tip': tip, 'sentences': [{'tl': t, 'rd': rd(t), 'ko': k} for t, k in pairs]}


LEVELS = [
    ('L1', '장소 — -de · -e · -den', '어디에 · 어디로 · 어디에서', [
        S('Elif', 'Neredesin? Ben kafe{de|1} oturuyorum.', '어디야? 나 카페{에|1} 앉아 있어.'),
        S('나', 'Pardon, hâlâ otobüs{te|1}yim.', '미안, 아직 버스{에|1} 있어.'),
        S('Elif', 'Kafe{ye|2} mi geliyorsun, ev{e|2} mi gidiyorsun?', '카페{로|2} 와, 아니면 집{으로|2} 가?'),
        S('나', 'Kafe{ye|2} geliyorum. Beş dakika sonra otobüs{ten|3} iniyorum.', '카페{로|2} 가. 5분 뒤에 버스{에서|3} 내려.'),
        S('Elif', 'Şemsiyen var mı? Dışarı{da|1} yağmur yağıyor.', '우산 있어? 밖{에|1} 비 와.'),
        S('나', 'Yok. Şemsiye ev{de|1} kaldı.', '없어. 우산은 집{에|1} 두고 왔어.'),
        S('Elif', 'Tamam, ben kapı{ya|2} çıkıyorum.', '알았어, 내가 문{으로|2} 나갈게.'),
        S('나', 'Durak{tan|3} kafe{ye|2} kaç dakika?', '정류장{에서|3} 카페{까지|2} 몇 분이야?'),
        S('Elif', 'Sadece iki dakika. Köşe{de|1} seni bekliyorum.', '2분이면 돼. 모퉁이{에서|1} 기다릴게.'),
        S('나', 'Geldim! Seni uzak{tan|3} görüyorum.', '왔어! 멀리{서|3} 네가 보여.'),
    ], [
        '-de·-da — 「있는 곳」. 한국어 「에 있어 / 에서 기다려」 둘 다 -de 예요.',
        '-e·-a — 「가는 곳」. 한국어는 「카페에 있어 / 카페에 가」 둘 다 「에」지만 터키어는 갈라요. 모음 뒤엔 -ye·-ya.',
        '-den·-dan — 「떠나는 곳」. 버스에서 내리다 = otobüsten inmek.',
        '어미 모음은 앞 낱말 모음을 따라가요(모음조화) — a·ı·o·u 뒤엔 -da, e·i·ö·ü 뒤엔 -de. p·ç·t·k·f·h·s·ş 뒤에선 d 가 t 로(otobüste).',
    ], [
        P('-de / -da (-te / -ta)  ~에, ~에서', '있는 곳. a·ı·o·u 단어는 -da, e·i·ö·ü 단어는 -de. 센 자음 뒤에선 -te·-ta.',
          ('Evdeyim.', '집에 있어요.'), ('Kitapta resim var.', '책에 그림이 있어요.')),
        P('-e / -a (-ye / -ya)  ~에, ~로', '가는 곳. 모음으로 끝나면 y 를 넣어 -ye·-ya.',
          ('Okula gidiyorum.', '학교에 가요.'), ('Kafeye geliyorum.', '카페로 가요.')),
        P('-den / -dan (-ten / -tan)  ~에서, ~부터', '떠나는 곳·출발점. 나라·사람 이름 뒤엔 작은따옴표.',
          ('İşten çıktım.', '회사에서 나왔어요.'), ("Kore'den geldim.", '한국에서 왔어요.')),
    ]),
    ('L2', '정해진 「을/를」 — -(y)ı', '그거 사 · 아무거나 사', [
        S('Emre', 'Akşam için ne alıyorsun?', '저녁에 먹을 거 뭐 사?'),
        S('나', 'Ekmek alıyorum, bir de peynir.', '빵 사, 그리고 치즈도.'),
        S('Emre', 'Geçen haftaki peynir{i|1} çok sevdim.', '지난주 그 치즈{를|1} 엄청 좋아했어.'),
        S('나', 'Hangisi{ni|1}? Beyaz peynir{i|1} mi?', '어느 거{를|1}? 흰 치즈{를|1}?'),
        S('Emre', 'Evet, o{nu|1}. Bir de zeytin al.', '응, 그거{를|1}. 그리고 올리브도 사.'),
        S('나', 'Tamam. Listen{i|1} bana gönder.', '알았어. 네 목록{을|1} 나한테 보내 줘.'),
        S('Emre', 'Gönderdim. Mesaj{ı|1} okudun mu?', '보냈어. 메시지{를|1} 읽었어?'),
        S('나', 'Okudum. Çay da alıyorum.', '읽었어. 차도 살게.'),
        S('Emre', 'Çay{ı|1} unutma! Geçen sefer unuttun.', '차{를|1} 잊지 마! 지난번에 잊었잖아.'),
        S('나', 'Bu sefer unutmam. Söz!', '이번엔 안 잊어. 약속!'),
    ], [
        '-ı·-i·-u·-ü — 「그」 물건·이미 말한 것에만 붙는 「을/를」. 아무 빵이나는 맨몸(ekmek alıyorum).',
        '한국어는 「빵을 사 / 그 빵을 사」 둘 다 「을」이지만 터키어는 정해진 것에만 붙여요.',
        '모음으로 끝나면 y·n 을 넣어요 — o → onu, hangisi → hangisini.',
    ], [
        P('-(y)ı · -(y)i · -(y)u · -(y)ü  정해진 「을/를」', '그 물건·이미 말한 것에만. 아무거나는 맨몸.',
          ('Kitap okuyorum.', '책 읽어요. (아무 책)'), ('Kitabı okudum.', '그 책을 읽었어요.')),
        P('k → ğ · p → b · ç → c · t → d', '모음 어미가 붙으면 끝 자음이 부드러워져요.',
          ('Ağacı görüyor musun?', '그 나무 보여?'), ('Kitabı masaya koy.', '그 책 탁자에 놔.')),
        P('이름·대명사는 늘', '사람 이름과 beni·seni·onu 는 늘 「을/를」 꼴.',
          ('Seni seviyorum.', '너를 사랑해.'), ("Elif'i gördüm.", 'Elif 를 봤어.')),
    ]),
    ('L3', '소유 — 내·네·그의를 끝에', '내 거 · 네 거 · 누구 거', [
        S('Elif', 'Bu çanta senin mi?', '이 가방 네 거야?'),
        S('나', 'Evet, çanta{m|1}. Teşekkürler!', '응, {내|1} 가방이야. 고마워!'),
        S('Elif', 'Telefon{un|2} da yerde.', '{네|2} 폰도 바닥에 있어.'),
        S('나', 'Of, anahtar{ım|1} nerede?', '아, {내|1} 열쇠 어디 있지?'),
        S('Elif', 'Anahtar{ın|2} masada.', '{네|2} 열쇠 탁자 위에 있어.'),
        S('나', "Bu da Emre'nin kitab{ı|3}.", '이건 Emre{의|3} 책이야.'),
        S('Elif', "Emre'nin kitab{ı|3} neden sende?", 'Emre{의|3} 책이 왜 너한테 있어?'),
        S('나', 'Arkadaş{ım|1} ya, bana verdi.', '{내|1} 친구잖아, 나한테 줬어.'),
        S('Elif', 'Peki benim kalem{im|1} nerede?', '그럼 {내|1} 펜은 어디 있어?'),
        S('나', 'Kalem{in|2} saç{ın|2}da!', '{네|2} 펜, {네|2} 머리에 꽂혀 있어!'),
    ], [
        '「내·네」를 앞에 두지 않고 명사 끝에 붙여요 — çantam 내 가방, çantan 네 가방.',
        '「Emre 의 책」은 양쪽에 다 붙어요 — Emre\'nin(의) kitabı(그의 책).',
        'saçında = saç(머리카락) + ın(네) + da(에). 어미가 차례로 쌓여요.',
    ], [
        P('-(ı)m  내 · -(ı)n  네', '명사 끝에. 모음으로 끝나면 -m·-n 만.',
          ('Evim çok küçük.', '내 집은 아주 작아요.'), ('Araban nerede?', '네 차 어디 있어?')),
        P('-(s)ı  그의 · -(ı)mız  우리', '모음 뒤엔 -sı. 「우리」는 -(ı)mız.',
          ('Annesi öğretmen.', '그의 엄마는 선생님이에요.'), ('Evimiz yakın.', '우리 집은 가까워요.')),
        P("X'in Y'si  X의 Y", '가진 사람에 -(n)in, 가진 것에 -(s)ı — 양쪽에 다 붙어요.',
          ("Elif'in kedisi çok tatlı.", 'Elif 의 고양이는 너무 귀여워요.'), ('Kapının rengi mavi.', '문 색깔은 파란색이에요.')),
    ]),
    ('L4', '지금 하는 일 — -iyor', '뭐 하고 있어?', [
        S('Emre', 'Ne yap{ıyor|1}sun?', '뭐 하{고 있어|1}?'),
        S('나', 'Yemek yap{ıyor|1}um. Sen?', '밥 하{고 있어|1}. 너는?'),
        S('Emre', 'Ben de sana gel{iyor|1}um.', '나도 너한테 가{고 있어|1}.'),
        S('나', 'Şimdi mi? Ev çok dağınık!', '지금? 집 엄청 지저분해!'),
        S('Emre', 'Sorun değil. Merdivenleri çık{ıyor|1}um.', '괜찮아. 계단 올라가{고 있어|1}.'),
        S('나', 'Bekle! Hızlıca topl{uyor|1}um.', '잠깐! 빨리 치우{고 있어|1}.'),
        S('Emre', 'Zili çal{ıyor|1}um. Duyuyor musun?', '벨 누르{고 있어|1}. 들려?'),
        S('나', 'Gel{iyor|1}um, gel{iyor|1}um!', '나가{고 있어|1}, 나간다고!'),
        S('Emre', 'Neden gül{üyor|1}sun?', '왜 웃{고 있어|1}?'),
        S('나', 'Çünkü hâlâ pijama giy{iyor|1}um.', '아직 잠옷 입{고 있거든|1}.'),
    ], [
        '-iyor 는 「지금 ~하고 있다」와 「요즘·곧 ~한다」를 다 맡아요.',
        '누가 하는지는 맨 끝에 — yapıyorum 나, yapıyorsun 너, yapıyor 그. 한국어는 끝이 같아도 터키어는 사람마다 달라요.',
        '모음으로 끝나는 동사는 그 모음이 빠져요 — topla → topluyorum, bekle → bekliyorum.',
    ], [
        P('-iyor  ~하고 있다 · ~한다', '모음조화로 -ıyor·-iyor·-uyor·-üyor. 모음 끝 동사는 그 모음이 빠져요.',
          ('Bekliyorum.', '기다리고 있어요.'), ('Türkçe öğreniyorum.', '터키어 배우고 있어요.')),
        P('-um · -sun · -uz  누가', 'geliyorum 나, geliyorsun 너, geliyor 그, geliyoruz 우리.',
          ('Nereye gidiyorsun?', '어디 가?'), ('Biz de geliyoruz.', '우리도 가.')),
        P('-iyor 로 가까운 미래', '「내일 가」도 -iyor 로 말해요.',
          ("Yarın İstanbul'a gidiyorum.", '내일 이스탄불에 가요.'), ('Akşam geliyor musun?', '저녁에 와?')),
    ]),
    ('L5', '지난 일 — -dı 와 -mış', '봤어 · 했대', [
        S('Elif', "Dün Emre'yi gör{dü|1}n mü?", '어제 Emre {봤|1}어?'),
        S('나', 'Gör{dü|1}m. Parkta beraber koş{tu|1}k.', '{봤|1}어. 공원에서 같이 {뛰었|1}어.'),
        S('Elif', 'Emre yeni bir iş bul{muş|2}.', 'Emre 새 일 {찾았대|2}.'),
        S('나', 'Gerçekten mi? Bana hiç söyleme{di|1}.', '진짜? 나한테 전혀 말 안 {했|1}어.'),
        S('Elif', 'Ben de bilmiyordum. Ayşe anlat{tı|1}.', '나도 몰랐어. Ayşe 가 얘기{했|1}어.'),
        S('나', 'Ayşe başka ne de{miş|2}?', 'Ayşe 가 또 뭐라고 {했대|2}?'),
        S('Elif', 'Emre biriyle tanış{mış|2}.', 'Emre 가 누구를 {만났대|2}.'),
        S('나', 'Dur! Dün parkta bir kız var{dı|1}.', '잠깐! 어제 공원에 어떤 여자가 {있었|1}어.'),
        S('Elif', 'Ne yap{tı|1}nız?', '뭐 {했|1}어?'),
        S('나', 'Ben koş{tu|1}m, onlar dondurma ye{di|1}.', '나는 {뛰었|1}고, 걔네는 아이스크림 {먹었|1}어.'),
    ], [
        '-dı — 내가 직접 본 지난 일. 센 자음 뒤에선 -tı (koştuk, anlattı).',
        '-mış — 남한테 들었거나 나중에 알게 된 일. 한국어 「~했대」「~했네」 자리예요.',
        '한국어는 「했어」 하나로 말해도 터키어는 본 일(-dı)과 들은 일(-mış)을 갈라요.',
    ], [
        P('-dı (-di · -du · -dü · -tı …)  ~했다', '직접 본 일. 모음조화 넷, 센 자음 뒤에선 t.',
          ('Dün film izledim.', '어제 영화 봤어요.'), ('Otobüs geç geldi.', '버스가 늦게 왔어요.')),
        P('-mış (-miş · -muş · -müş)  ~했대 · ~했네', '들은 일·나중에 안 일.',
          ('Elif evlenmiş!', 'Elif 결혼했대!'), ('Kar yağmış.', '(일어나 보니) 눈이 왔네.')),
        P('부정은 -me- 를 앞에', 'gelmedi 안 왔어 · gelmemiş 안 왔대.',
          ('Emre gelmedi.', 'Emre 안 왔어요.'), ('Paket gelmemiş.', '택배가 안 왔대요.')),
    ]),
    ('L6', '있다 · 없다 — var · yok', '있어? 없어!', [
        S('나', 'Yakında eczane {var|1} mı?', '근처에 약국 {있어|1}?'),
        S('Emre', '{Var|1}, ama şimdi kapalı.', '{있어|1}, 근데 지금 닫았어.'),
        S('나', 'Of. Başım ağrıyor, ilacım {yok|2}.', '아. 머리 아픈데 약이 {없어|2}.'),
        S('Emre', 'Bende {var|1}. Çantamda hep ilaç {var|1}.', '나한테 {있어|1}. 내 가방엔 늘 약이 {있어|1}.'),
        S('나', 'Su da {var|1} mı?', '물도 {있어|1}?'),
        S('Emre', 'Su {yok|2}, ama çay {var|1}.', '물은 {없고|2}, 차는 {있어|1}.'),
        S('나', 'Sıcak çay mı? Ama bardak {yok|2}.', '뜨거운 차? 근데 컵이 {없잖아|2}.'),
        S('Emre', 'Termosum {var|1}. Kapağı bardak oluyor.', '보온병이 {있어|1}. 뚜껑이 컵이 돼.'),
        S('나', 'Senin çantanda ne {yok|2} ki?', '네 가방엔 {없는|2} 게 뭐야?'),
        S('Emre', 'Sadece para {yok|2}.', '돈만 {없어|2}.'),
    ], [
        'var 「있다」·yok 「없다」는 동사 없이 말 끝에 놓아요. 물을 땐 var mı? / yok mu?',
        '「나는 약이 있다」는 「내 약 있다」 — ilacım var. 「가지다」 동사를 쓰지 않아요.',
        '「나한테 있어」는 bende var (ben + de).',
    ], [
        P('var  있다 · yok  없다', '말 끝에. 물을 땐 var mı? / yok mu?',
          ('Bugün toplantı var.', '오늘 회의 있어요.'), ('Süt yok mu?', '우유 없어?')),
        P('-(ı)m var  나는 ~가 있다', '소유 어미 + var. 「가지다」 동사 없이.',
          ('Bir kardeşim var.', '동생이 하나 있어요.'), ('Zamanım yok.', '시간이 없어요.')),
        P('bende · sende  나한테 · 너한테', '사람 + -de + var.',
          ('Bende şarj aleti var.', '나한테 충전기 있어.'), ('Sende kalem var mı?', '너 펜 있어?')),
    ]),
    ('L7', '안 · ~니? — -me 와 mı', '안 마셔 · 마실래?', [
        S('Elif', 'Kahve ister {mi|2}sin?', '커피 마실{래|2}?'),
        S('나', 'Hayır, kahve iç{mi|1}yorum.', '아니, 커피 {안|1} 마셔.'),
        S('Elif', 'Hiç {mi|2} iç{me|1}din?', '한 번도 {안|1} 마셔 봤{어|2}?'),
        S('나', 'İçtim ama sev{me|1}dim.', '마셔 봤는데 {안|1} 좋았어.'),
        S('Elif', 'Çay sever {mi|2}sin?', '차는 좋아{해|2}?'),
        S('나', 'Çok severim!', '완전 좋아해!'),
        S('Elif', 'Şeker koyayım {mı|2}?', '설탕 넣을{까|2}?'),
        S('나', 'Hayır, şeker koy{ma|1}.', '아니, 설탕 넣지 {마|1}.'),
        S('Elif', 'Tatlı da ye{mi|1}yor {mu|2}sun?', '디저트도 {안|1} 먹{어|2}?'),
        S('나', 'Tatlıya hayır de{me|1}m!', '디저트는 거절 {안|1} 해!'),
    ], [
        '-me·-ma 「안」은 동사 줄기 바로 뒤에 — sevmedim 안 좋았어, koyma 넣지 마. -iyor 앞에선 -mi (içmiyorum).',
        'mı·mi·mu·mü 「~니?」는 띄어 쓰고, 누가 하는지는 mı 뒤에 붙어요 — ister misin, yemiyor musun.',
        'mı 는 물을 낱말 바로 뒤에 — Hiç mi? 「한 번도?」를 묻는 거예요.',
    ], [
        P('-me / -ma  안 ~', '동사 줄기 바로 뒤. -iyor 앞에선 -mi·-mı·-mu·-mü.',
          ('Gelmiyorum.', '안 가요.'), ('Sigara içmem.', '담배 안 피워요.')),
        P('mı · mi · mu · mü  ~니?', '물을 말 뒤에 띄어 써요. 누가 하는지는 mı 에 붙어요.',
          ('Türk müsün?', '터키 사람이야?'), ('Yarın mı geliyorsun?', '내일 오는 거야?')),
        P('-me 명령  ~하지 마', '동사 줄기 + -me·-ma.',
          ('Unutma!', '잊지 마!'), ('Korkma.', '겁먹지 마.')),
    ]),
    ('L8', '앞일 — -ecek 와 -mek istiyorum', '할 거야 · 하고 싶어', [
        S('Emre', 'Hafta sonu ne yap{acak|1}sın?', '주말에 뭐 {할 거야|1}?'),
        S('나', 'Denize git{mek istiyorum|2}.', '바다에 가{고 싶어|2}.'),
        S('Emre', 'Ben de gel{mek istiyorum|2}!', '나도 가{고 싶어|2}!'),
        S('나', 'Tamam, cumartesi sabah çık{acağ|1}ız.', '좋아, 토요일 아침에 출발{할 거야|1}.'),
        S('Emre', 'Arabayı ben sür{eceğ|1}im.', '운전은 내가 {할게|1}.'),
        S('나', 'Yolda kahvaltı yap{mak istiyorum|2}.', '가는 길에 아침 먹{고 싶어|2}.'),
        S('Emre', 'Annem börek yap{acak|1}.', '우리 엄마가 뵈렉 만드{실 거야|1}.'),
        S('나', 'Harika! Ben de meyve getir{eceğ|1}im.', '좋다! 나는 과일 가져{갈게|1}.'),
        S('Emre', 'Yüz{mek istiyor|2} musun? Su soğuk ol{acak|1}.', '수영{하고 싶어|2}? 물 차{가울 거야|1}.'),
        S('나', 'Ben sadece kumda uyu{mak istiyorum|2}.', '난 그냥 모래 위에서 자{고 싶어|2}.'),
    ], [
        '-ecek·-acak — 「~할 거야 / ~할게」. 사람 어미 앞에서 k 가 ğ 로 (çıkacağız, süreceğim).',
        '-mek istiyorum — 「~하고 싶어」. 동사 원형(-mek·-mak) + istemek(원하다).',
        '모음으로 끝나는 동사엔 y 를 넣어요 — oku → okuyacağım.',
    ], [
        P('-ecek / -acak  ~할 것이다', '모음 뒤엔 y (okuyacağım). 사람 어미 앞에서 k → ğ.',
          ('Yarın arayacağım.', '내일 전화할게요.'), ('Hava güzel olacak.', '날씨 좋을 거예요.')),
        P('-mek / -mak istiyorum  ~하고 싶다', '동사 원형 + istiyorum.',
          ("Türkiye'ye gitmek istiyorum.", '튀르키예에 가고 싶어요.'), ('Ne yemek istiyorsun?', '뭐 먹고 싶어?')),
        P('-(y)elim / -(y)alım  ~하자', '같이 하자고 할 때.',
          ('Gidelim!', '가자!'), ('Biraz oturalım.', '좀 앉자.')),
    ]),
    ('L9', '할 수 있어 · ~하면 — -ebil 과 -se', '도와줄 수 있어?', [
        S('나', 'Bana yardım ed{ebil|1}ir misin?', '나 좀 도와{줄 수 있|1}어?'),
        S('Elif', 'Tabii. Ne yap{abil|1}irim?', '당연하지. 내가 뭘 {할 수 있|1}어?'),
        S('나', 'Bu kutuyu taşı{yabil|1}ir misin?', '이 상자 옮{길 수 있|1}어?'),
        S('Elif', "Çok ağır{sa|2}, Emre'yi çağırırız.", '너무 무거우{면|2}, Emre 부르자.'),
        S('나', 'Emre gel{ebil|1}ir mi? Bugün çalışıyor.', 'Emre {올 수 있|1}을까? 오늘 일하는데.'),
        S('Elif', 'Arar{sa|2}n gelir.', '네가 전화하{면|2} 와.'),
        S('나', 'Ben arar{sa|2}m açmaz. Sen ara!', '내가 전화하{면|2} 안 받아. 네가 해!'),
        S('Elif', 'Peki. Ama bana pizza ısmarlar{sa|2}n.', '알았어. 대신 네가 피자 사{면|2}.'),
        S('나', 'Kutuyu sen taşı{yabil|1}ir{sen|2}, iki pizza!', '네가 상자 옮{길 수 있|1}으{면|2}, 피자 두 판!'),
        S('Elif', 'Anlaştık! Ben her şeyi taşı{yabil|1}irim!', '콜! 나 뭐든 옮{길 수 있|1}어!'),
    ], [
        '-ebil·-abil — 「~할 수 있다」. 동사 줄기 뒤에, 모음 뒤엔 y (taşıyabilir).',
        '-se·-sa — 「~하면」. 보통 -r 꼴 뒤에 붙어요 (ararsan 네가 전화하면).',
        '「못 해」는 -ebil 의 부정이 아니라 -eme (gelemiyorum 못 가).',
    ], [
        P('-ebil / -abil  ~할 수 있다', '모음 뒤엔 y. 부탁할 땐 -ebilir misin?',
          ('Türkçe konuşabiliyorum.', '터키어 할 수 있어요.'), ('Pencereyi açabilir misin?', '창문 열어 줄 수 있어?')),
        P('-eme / -ama  ~할 수 없다', '부정은 -ebil 이 아니라 -eme.',
          ('Gelemiyorum.', '못 가요.'), ('Uyuyamadım.', '잠을 못 잤어요.')),
        P('-se / -sa  ~하면', '조건. var·yok 뒤에도 바로 붙어요 (varsa 있으면).',
          ('Yağmur yağarsa evde kalırız.', '비 오면 우리 집에 있을 거예요.'), ('Zamanın varsa gel.', '시간 있으면 와.')),
    ]),
    ('L10', '존댓말 — siz 와 -in', '호텔에서', [
        S('직원', 'Hoş geldi{niz|1}! Nasıl yardımcı olabilirim?', '어서 오{세요|1}! 무엇을 도와드릴까요?'),
        S('나', 'Bir rezervasyonum var, iki gece.', '예약했어요, 이틀 밤이요.'),
        S('직원', 'Pasaportunuzu verir mi{siniz|1}?', '여권 주시겠어{요|1}?'),
        S('나', 'Tabii, buyurun.', '네, 여기요.'),
        S('직원', 'Şu formu doldur{un|2}, lütfen.', '이 서류 작성해 주{세요|2}.'),
        S('나', 'Kahvaltı saat kaçta?', '아침은 몇 시예요?'),
        S('직원', 'Yediden ona kadar. Restoran ikinci katta.', '7시부터 10시까지예요. 식당은 2층에 있어요.'),
        S('나', 'Wi-fi şifresini söyler mi{siniz|1}?', '와이파이 비밀번호 알려 주시겠어{요|1}?'),
        S('직원', 'Kartın arkasında. Lütfen sakla{yın|2}.', '카드 뒷면에 있어요. 잘 보관하{세요|2}.'),
        S('나', 'Çok teşekkür ederim. İyi akşamlar!', '정말 감사합니다. 좋은 저녁 되세요!'),
    ], [
        '모르는 어른·손님·가게에선 siz(당신) — 동사 끝이 -siniz·-sınız (verir misiniz).',
        '「~하세요」는 동사 줄기 + -(y)ın (doldurun, saklayın). 친구에겐 줄기만 (doldur, sakla).',
        '부탁을 부드럽게 할 땐 -ir misiniz? 「~해 주시겠어요?」.',
    ], [
        P('siz  당신 (존댓말·여럿)', '처음 보는 사람·가게·윗사람. 동사 끝 -siniz·-sınız.',
          ('Nerelisiniz?', '어디 분이세요?'), ('Türkçe biliyor musunuz?', '터키어 하세요?')),
        P('-(y)ın / -(y)in  ~하세요', '동사 줄기 + -(y)ın. lütfen 을 붙이면 더 부드러워요.',
          ('Buyurun, oturun.', '어서 앉으세요.'), ('Lütfen bekleyin.', '기다려 주세요.')),
        P('-ir misiniz?  ~해 주시겠어요?', '손님이 부탁할 때 가장 많이 쓰는 꼴.',
          ('Yardım eder misiniz?', '도와주시겠어요?'), ('Hesabı getirir misiniz?', '계산서 갖다주시겠어요?')),
    ]),
]


def main():
    levels = []
    for lid, title, sub, lines, foot, points in LEVELS:
        if len(lines) != 10:
            sys.exit(f'{lid}: 외울 대화는 10줄 — {len(lines)}')
        for s in lines:  # 양쪽 표시 번호가 맞는지
            a = {m.group(2) for m in MARK.finditer(s['tl'])}
            b = {m.group(2) for m in MARK.finditer(s['ko'])}
            if a != b:
                sys.exit(f'{lid}: 표시 번호가 다름 {a} / {b} — {s["tl"]}')
        levels.append({'id': lid, 'title': title, 'lessons': [
            {'id': f'{lid}-1', 'title': sub, 'kind': 'memorize', 'video': '', 'note': NOTE, 'sentences': lines, 'footnotes': foot},
            {'id': f'{lid}-ref', 'kind': 'ref', 'title': f'{title.split(" — ")[0]} 한눈에', 'points': points},
        ]})
    data = {'title': '언어감각 익히기', 'subtitle': 'L1 장소 어미부터 L10 존댓말까지 · 대화 통째로 외우기', 'levels': levels}
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(f'{OUT.relative_to(ROOT)} — 급 {len(levels)} · 외울 문장 {sum(len(l[3]) for l in LEVELS)} · 참고 문장 {sum(len(p["sentences"]) for l in LEVELS for p in l[5])}')


if __name__ == '__main__':
    main()
