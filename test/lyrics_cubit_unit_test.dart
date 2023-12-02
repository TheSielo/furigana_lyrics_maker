import 'package:flutter_test/flutter_test.dart';
import 'package:furigana_lyrics_maker/lyrics/lyrics_cubit.dart';

void main() {
  const originalText = '私の車は黒いです';
  const translatedText = 'My car is black';

  test('Initialization correct', () async {
    final cubit = LyricsCubit(originalText, translatedText, '');
    expect(cubit.state.lyrics.originalLines[0] == originalText, true);
    expect(cubit.state.lyrics.translatedLines[0] == translatedText, true);
  });

  test('Furigana added correctly', () async {
    const expectedFuriganaHTML =
        '<ruby>私<rt>わたくし</rt></ruby><ruby>の</ruby><ruby>車<rt>くるま</rt>'
        '</ruby><ruby>は</ruby><ruby>黒<rt>くろ</rt></ruby><ruby>い</ruby><ruby>です</ruby>';
    final cubit = LyricsCubit(originalText, translatedText, '');
    await cubit.produceResultText(originalText, translatedText, true);
    final producedHTML = cubit.state.lyrics.furiganaLines[0].toHTMLString();
    expect(producedHTML == expectedFuriganaHTML, true);
  });
}
