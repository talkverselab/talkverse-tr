import 'package:flutter_test/flutter_test.dart';
import 'package:turkish_universe/services/learner_prefs.dart';

void main() {
  tearDown(() {
    LearnerPrefs.name.value = '';
    LearnerPrefs.gender.value = 'male';
  });

  test('이름이 없으면 음성과 같은 기본 이름', () {
    expect(LearnerPrefs.fill('Of {name}, E diyorum.'), 'Of Aleks, E diyorum.');
    expect(LearnerPrefs.fill('오프 {name}, 에', 'rd'), '오프 알렉스, 에');
    expect(LearnerPrefs.fill('아휴 {name}, E라니까.', 'ko'), '아휴 알렉스, E라니까.');
    LearnerPrefs.gender.value = 'female';
    expect(LearnerPrefs.fill('{name} geldi.'), 'Emma geldi.');
  });

  test('한국어 뜻은 이름 뒤 조사를 맞춘다', () {
    expect(LearnerPrefs.fill('{name}은 어디 있어?', 'ko'), '알렉스는 어디 있어?');
    LearnerPrefs.name.value = '민준';
    expect(LearnerPrefs.fill('{name}가 왔어', 'ko'), '민준이 왔어');
    expect(LearnerPrefs.fill('{name}, geldin mi?'), '민준, geldin mi?');
  });

  test('나라·도시·언어 자리', () {
    expect(LearnerPrefs.fill('{country}dan geldim', 'tl'), 'Kanadadan geldim');
    expect(LearnerPrefs.fill('{country}에서 왔어', 'ko'), '캐나다에서 왔어');
  });
}
