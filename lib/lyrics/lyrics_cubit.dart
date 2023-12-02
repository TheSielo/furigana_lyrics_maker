import 'dart:async';
import 'dart:html';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:furigana_lyrics_maker/lyrics/content_strings.dart';
import 'package:furigana_lyrics_maker/preferences/preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'lyrics.dart';

///This Cubit holds the data for LyricsScreen to present.
class LyricsCubit extends Cubit<LyricsUIState> {
  late Lyrics _lastLyrics;
  String currentVideoUrl = "";
  String currentSongId = "";

  ///Public constructor
  LyricsCubit(String originalText, String translatedText, String videoUrl)
      : super(
          LyricsUIState(
            mainState: LyricsState.loading,
            lyrics: Lyrics.empty(),
            videoUrl: videoUrl,
            currentSongId: ContentStrings.defaultSongId,
            songs: [],
            isPlaying: false,
            timestampsLocked: true,
          ),
        ) {
    _init(originalText, translatedText, videoUrl);
  }

  ///Initializes the Cubit with the supplied original and translated text,
  ///then emits a new state with MainState.ok and the updated resultText.
  void _init(
      String originalText, String translatedText, String videoUrl) async {
    currentVideoUrl = videoUrl;
    final lastId = await PreferencesHelper.getString(StringPref.lastSongId);
    if (lastId.isNotEmpty && lastId != ContentStrings.defaultSongId) {
      currentSongId = lastId;
      await changeSong(lastId);
    } else {
      currentSongId = ContentStrings.defaultSongId;
      produceResultText(originalText, translatedText, false,
          timestamps: ContentStrings.defaultTimestamps);
    }
  }

  ///Makes a network call to api.sielotech.com/furigana, supplying the original
  ///text (should be Japanese text to obtain something useful) and returns a
  ///list of words and their furigana readings (when present).
  Future<List<List<String>>> _getFurigana(String text) async {
    /* Replace any newline with a @, then if there are more @ consecutevly, 
    replace them with a single @. This is necessary because we want to use a @ 
    to mark newlines because they are lost when passed to the furigana endpoint
    but at the same time, we don't want multiple consecutive newlines. */
    final regex = RegExp(r'@+');
    final textArg = text.replaceAll('\n', '@').replaceAll(regex, '@');

    /* Get the furigana and decode the resulting json. */
    final result = await http.post(
      Uri.parse('https://api.sielotech.com/furigana'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
        {'text': textArg},
      ),
    );
    final List<dynamic> list = jsonDecode(result.body);

    /* Convert to a list of lists of strings and return it. */
    return list.map((e) => List<String>.from(e)).toList();
  }

  ///Produces a new TranslatedText based on the input, and emits a new state.
  Future<void> produceResultText(
      String originalText, String translatedText, bool furigana,
      {Map<String, double>? timestamps}) async {
    /* If furigana is true, then set the state to loading. */
    if (furigana) {
      emit(state.copyWith(mainState: LyricsState.loading));
    }

    /* Get two lists splitting the original and translated text at every
    newline. */
    final japLines = originalText.trim().split('\n');
    final transLines = translatedText.trim().split('\n');

    List<List<String>> furiganaList = [];

    /* If furigana is true, get also the furigana list from the furigana 
    endpoint. */
    if (furigana) {
      furiganaList = await _getFurigana(originalText);
    }

    /* Updates the _lastTranslatedText with the new updated instance. */
    _lastLyrics = Lyrics(
      japLines,
      transLines,
      furiganaList,
      timestamps: timestamps,
    );

    final newState = _lastLyrics.translationsError
        ? LyricsState.errorLineNumber
        : LyricsState.ok;

    emit(state.copyWith(
      mainState: newState,
      lyrics: _lastLyrics,
    ));

    updateSongFile();
  }

  Future<void> loadSongData(String uuid) async {
    final songData = json.decode(await PreferencesHelper.readFile(uuid));
    final String videoUrl = songData['video_url'] ?? '';
    final String originalText = songData['original_text'] ?? '';
    final String translatedText = songData['translated_text'] ?? '';
    final Map timestampsDynamic = json.decode(songData['timestamps'] ?? '{}');
    final Map<String, double> timestamps =
        timestampsDynamic.map((key, value) => MapEntry(key, value.toDouble()));

    List<List<String>> furiganaList = [];

    /* Get two lists splitting the original and translated text at every
    newline. */
    final japLines = originalText.trim().split('\n');
    final transLines = translatedText.trim().split('\n');
    /* Updates the _lastTranslatedText with the new updated instance. */
    _lastLyrics = Lyrics(
      japLines,
      transLines,
      furiganaList,
      timestamps: timestamps,
    );

    currentVideoUrl = videoUrl;

    emit(state.copyWith(
      mainState: LyricsState.loadedSong,
      lyrics: _lastLyrics,
    ));

    emit(state.copyWith(mainState: LyricsState.ok));
  }

  void setTimestampsLocked(bool locked) {
    final currentState = state.mainState;
    if (!locked) {
      emit(state.copyWith(mainState: LyricsState.timestampsUnlocked));
    }
    emit(state.copyWith(mainState: currentState, timestampsLocked: locked));
  }

  void setVideoUrl(String videoUrl) {
    currentVideoUrl = videoUrl;
    updateSongFile();
    emit(state.copyWith(videoUrl: currentVideoUrl));
  }

  Future<void> deleteSong(String songId) async {
    final List<List<String>> songsList = await loadSongs();
    final List<List<String>> newList = [];
    for (int i = 0; i < songsList.length; i++) {
      if (songsList[i][0] != songId) {
        newList.add(songsList[i]);
      }
    }
    PreferencesHelper.deleteFile(songId);

    await writeSongs(newList);
    emit(state.copyWith(songs: newList));
  }

  Future<void> setTitle(String songId, String title) async {
    final List<List<String>> songsList = await loadSongs();
    for (int i = 0; i < songsList.length; i++) {
      if (songsList[i][0] == songId) {
        songsList[i][1] = title;
        break;
      }
    }
    await writeSongs(songsList);
    emit(state.copyWith(songs: songsList));
  }

  Future<void> changeSong(String? songId) async {
    final List<List<String>> songsList = await loadSongs();
    if (songId == null) {
      emit(state.copyWith(mainState: LyricsState.newSong));
      final id = const Uuid().v4();

      List<String> newSong = [];
      newSong.add(id);
      newSong.add('Untitled song');
      songsList.add(newSong);
      currentSongId = id;
      currentVideoUrl = '';
      await writeSongs(songsList);
      await loadSongData(id);
    } else {
      currentSongId = songId;
      await loadSongData(songId);
    }

    emit(state.copyWith(
      mainState: LyricsState.ok,
      videoUrl: currentVideoUrl,
      currentSongId: currentSongId,
      songs: songsList,
    ));
    PreferencesHelper.setString(StringPref.lastSongId, currentSongId);
  }

  Future<List<List<String>>> loadSongs() async {
    final songsListJson = await PreferencesHelper.getString(
      StringPref.songsList,
      defaultValue: '[]',
    );
    final List<dynamic> songsDynamic = json.decode(songsListJson);
    final List<List<String>> songs = songsDynamic
        .map((item) => List<String>.from(item.map((e) => e.toString())))
        .toList();
    return songs;
  }

  Future<void> writeSongs(List<List<String>> songs) async {
    await PreferencesHelper.setString(
      StringPref.songsList,
      json.encode(songs),
    );
  }

  ///This marks the lyrics's line at [index] with the specified [millis].
  ///It means that this line plays at [millis] in the current song.
  ///Then it saves the timestamps maps in the preferences for persistence.
  void setTimestamp(int index, Future<double> millisFuture) async {
    print('setTimestamp');
    final millis = await millisFuture;
    _lastLyrics.setTimestamp(index, millis);
    updateSongFile();
  }

  Future<void> updateSongFile() async {
    final fileMap = {};
    fileMap['video_url'] = currentVideoUrl;
    fileMap['original_text'] = _lastLyrics.originalLines.join("\n");
    fileMap['translated_text'] = _lastLyrics.translatedLines.join("\n");
    fileMap['timestamps'] = json.encode(_lastLyrics.timestamps);
    await PreferencesHelper.writeFile(currentSongId, json.encode(fileMap));
  }

  Future<void> updatePlayerTime(Future<double> currentTimeFuture) async {
    print('update player time');
    final lastLine = _lastLyrics.currentLine;
    final currentTimeMillis = await currentTimeFuture;
    _lastLyrics.updateCurrentLine(currentTimeMillis);
    if (_lastLyrics.currentLine != lastLine) {
      print('new line');
      emit(state.copyWith(lyrics: _lastLyrics));
    }
  }

  void setIsPlaying(bool isPlaying) {
    emit(state.copyWith(isPlaying: isPlaying));
  }

  ///Produces an HTML file from the data in _lastTranslatedText and prompts
  ///the download in the browser.
  downloadClicked() async {
    String output = _lastLyrics.getHTML();
    final List<int> bytes = utf8.encode(output);
    final content = base64Encode(bytes);
    AnchorElement(
        href: "data:application/octet-stream;charset=utf-16le;base64,$content")
      ..setAttribute("download", "lyrics.html")
      ..click();
  }

  /// Attempts to open the specified page in a new browser tab
  /// using the [url_launcher] package.
  Future<void> openLink(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      //todo: manage error
    }
  }
}

///This are the major states in which the screen can be.
enum LyricsState {
  loading, //The cubit is working on a long running operation to wait for.
  ok, //No critical work running.
  timestampsUnlocked,
  newSong,
  loadedSong,
  errorLineNumber, //The screen supplied a wrong combination of original and translated text.
  errorHttp, //There was an error in the furigana endpoint call.
}

///The cubit state.
class LyricsUIState {
  final LyricsState mainState;
  final Lyrics lyrics;
  final String videoUrl;
  final String currentSongId;
  final List<List<String>> songs;
  final bool isPlaying;
  final bool timestampsLocked;

  LyricsUIState({
    required this.mainState,
    required this.lyrics,
    required this.videoUrl,
    required this.currentSongId,
    required this.songs,
    required this.isPlaying,
    required this.timestampsLocked,
  });

  copyWith({
    LyricsState? mainState,
    Lyrics? lyrics,
    String? videoUrl,
    String? currentSongId,
    List<List<String>>? songs,
    bool? isPlaying,
    bool? timestampsLocked,
  }) {
    return LyricsUIState(
      mainState: mainState ?? this.mainState,
      lyrics: lyrics ?? this.lyrics,
      videoUrl: videoUrl ?? this.videoUrl,
      currentSongId: currentSongId ?? this.currentSongId,
      songs: songs ?? this.songs,
      isPlaying: isPlaying ?? this.isPlaying,
      timestampsLocked: timestampsLocked ?? this.timestampsLocked,
    );
  }
}
