import 'html_stub.dart';

class Lyrics {
  late final bool furiganaAvailable;
  late final bool hasFurigana;
  late final bool hasTranslations;
  late final bool translationsError;
  late final List<FuriganaLine> furiganaLines;
  late final List<String> originalLines;
  late final List<String> translatedLines;
  Map<String, double> timestamps = {};
  int currentLine = 0;

  Lyrics(this.originalLines, this.translatedLines, List<List<String>> furigana,
      {Map<String, double>? timestamps}) {
    bool transError = false;
    hasFurigana = furigana.isNotEmpty;
    if (translatedLines.length > 1 || translatedLines[0].isNotEmpty) {
      hasTranslations = true;
      transError = translatedLines.length != originalLines.length;
    } else {
      hasTranslations = false;
    }
    if (furigana.isNotEmpty) {
      final furiganaResult =
          splitLines(hasTranslations, furigana, translatedLines);
      if (furiganaResult.error) {
        transError = true;
        furiganaLines = [];
      } else {
        furiganaLines = furiganaResult.furiganaLines;
      }
    } else {
      furiganaLines = [];
    }

    translationsError = transError;
    furiganaAvailable =
        !transError && originalLines.isNotEmpty && originalLines[0].isNotEmpty;

    if (timestamps != null) {
      this.timestamps = timestamps;
    }
  }

  Lyrics.empty() {
    furiganaAvailable = false;
    hasFurigana = false;
    hasTranslations = false;
    translationsError = false;
    furiganaLines = [];
    originalLines = [];
    translatedLines = [];
  }

  void setTimestamp(int index, double millis) {
    //Set the millis truncated to the second digit to the key index.
    timestamps[index.toString()] = (millis * 100).truncate() / 100;
    print(timestamps);
  }

  void updateCurrentLine(double currentTimeMillis) {
    for (int i = 0; i < originalLines.length; i++) {
      final value = timestamps[i.toString()];
      if (value != null && (value - 0.5) < currentTimeMillis) {
        currentLine = i;
      }
    }
  }

  FuriganaResult splitLines(
      bool translate, List<List<String>> fullText, List<String> translated) {
    bool error = false;
    List<FuriganaLine> split = [];
    List<Furigana> line = [];
    int linesCounter = 0;
    for (List<String> furigana in fullText) {
      if (furigana[0].contains("@")) {
        if (translate) {
          if (translated.length >= linesCounter) {
            split.add(FuriganaLine(line, translated[linesCounter]));
          } else {
            error = true;
            break;
          }
          do {
            linesCounter++;
          } while (translated[linesCounter].isEmpty);
        } else {
          split.add(FuriganaLine(line, ''));
        }
        line = [];
      } else {
        final base = furigana[0];
        final reading = furigana.length == 2 ? furigana[1] : '';
        line.add(Furigana(base, reading));
      }
    }
    split.add(FuriganaLine(line, translated[linesCounter]));

    final List<FuriganaLine> spacedSplit = [];
    int counter = 0;
    for (String l in originalLines) {
      if (l.isNotEmpty && split.length > counter) {
        spacedSplit.add(split[counter]);
        counter++;
      } else {
        spacedSplit.add(FuriganaLine([], ''));
      }
    }

    return FuriganaResult(error, spacedSplit);
  }

  String getHTML() {
    String text = '';
    for (int i = 0; i < originalLines.length; i++) {
      String jl = '';
      if (!hasFurigana) {
        jl = originalLines[i];
      } else {
        jl = furiganaLines[i].toHTMLString();
      }
      text += '$jl</br>';
      if (hasTranslations && !translationsError) {
        text += '${translatedLines[i]}</br>';
      }
      text += '</br>';
    }

    return '$htmlStart $text $htmlEnd';
  }
}

class FuriganaResult {
  bool error;
  List<FuriganaLine> furiganaLines;

  FuriganaResult(this.error, this.furiganaLines);
}

class FuriganaLine {
  List<Furigana> furiganaList;
  String translatedLine;

  FuriganaLine(this.furiganaList, this.translatedLine);

  @override
  String toString() {
    String text = '';
    for (Furigana furigana in furiganaList) {
      text += furigana.base;
      if (furigana.reading.isNotEmpty) {
        text += '(${furigana.reading}) ';
      } else {
        text += " ";
      }
    }
    return text;
  }

  String toHTMLString() {
    String text = '';
    for (Furigana furigana in furiganaList) {
      text += furigana.toHTMLString();
    }
    return text;
  }
}

class Furigana {
  String base;
  String reading;

  Furigana(this.base, this.reading);

  String toHTMLString() {
    String text = '<ruby>$base';
    if (reading.isNotEmpty) {
      text += '<rt>$reading</rt>';
    }
    text += '</ruby>';
    return text;
  }
}
