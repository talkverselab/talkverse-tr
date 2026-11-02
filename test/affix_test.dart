import 'package:flutter_test/flutter_test.dart';
import 'package:turkish_universe/data/tr_affixes.dart';

String show(String w) {
  final h = analyzeWord(w);
  if (h == null) return '$w → -';
  return '$w → ${h.stem} + ${h.chain.map((c) => '${c.$1}(${c.$2.id})').join(' + ')}';
}

void main() {
  test('접사 사슬', () {
    expect(show('evlerimde'), 'evlerimde → ev + ler(pl) + im(p1s) + de(loc)');
    expect(show("İstanbul'da"), "İstanbul'da → İstanbul + da(loc)");
    expect(show('merhaba'), 'merhaba → -');
    expect(show('kediler'), 'kediler → kedi + ler(pl)');
    expect(show('severim'), 'severim → sever + im(pers1)');
    expect(show('öğreniyorum'), 'öğreniyorum → öğren + iyor(prog) + um(pers1)');
    expect(show('evlerimde'), 'evlerimde → ev + ler(pl) + im(p1s) + de(loc)');
  });
  test('보기', () {
    for (final w in ['öğreniyorum', 'çalışıyorum', 'oturuyorsun', 'istersin', 'alalım', 'gidebiliriz', 'Koreliyim', 'kediler',
      'buranın', 'tatlısı', 'şehri', 'sana', 'benimle', 'gezdireyim', 'ödüyorum', 'ısmarlıyorum', 'Nerelisin', 'günler',
      'sinemaya', 'arkadaşlarımızla', 'evden', 'kitabı', 'yaptı', 'gelecek']) {
      // ignore: avoid_print
      print(show(w));
    }
  });
}
