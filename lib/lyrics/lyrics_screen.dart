import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:furigana_lyrics_maker/lyrics/drawer_widget.dart';
import 'package:furigana_lyrics_maker/lyrics/input_text_column.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'karaoke/audio_player_widget.dart';
import 'karaoke/karaoke_widget.dart';

import '../utils.dart';
import 'content_strings.dart';
import 'lyrics_cubit.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({Key? key}) : super(key: key);

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen>
    with SingleTickerProviderStateMixin {
  final originalController =
      TextEditingController(text: ContentStrings.defaultOriginal);
  final translationController =
      TextEditingController(text: ContentStrings.defaultTranslation);
  bool _furiganaButtonEnabled = true;
  late final YoutubePlayerController _ytController;

  late final AnimationController _animController;
  late final Animation<double> _animProgress;

  @override
  void initState() {
    _ytController = YoutubePlayerController(
      params: const YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animProgress = Tween<double>(begin: 0, end: 1).animate(_animController)
      ..addListener(() {
        setState(() {});
      });

    super.initState();
  }

  @override
  dispose() {
    super.dispose();
    originalController.dispose();
    translationController.dispose();
  }

  void _updateResult(LyricsCubit cubit, {required bool addFurigana}) {
    /* Disable the furigana button until the original or translated text doesn't
    * change. */
    _furiganaButtonEnabled = !addFurigana;

    /* Produce the central column updated text. */
    cubit.produceResultText(
      originalController.text.trim(),
      translationController.text.trim(),
      addFurigana,
      timestamps: cubit.state.lyrics.timestamps,
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (_) => LyricsCubit(
        originalController.text,
        translationController.text,
        ContentStrings.defaultVideoUrl,
      ),
      child: BlocConsumer<LyricsCubit, LyricsUIState>(
        listener: (context, state) {
          if (state.mainState == LyricsState.newSong) {
            originalController.text = '';
            translationController.text = '';
            setState(() {
              _furiganaButtonEnabled = true;
            });
          } else if (state.mainState == LyricsState.loadedSong) {
            originalController.text = state.lyrics.originalLines.join('\n');
            translationController.text =
                state.lyrics.translatedLines.join('\n');
            setState(() {
              _furiganaButtonEnabled = true;
            });
          }
          if (state.isPlaying) {
            _animController.forward();
          } else {
            _animController.animateBack(0);
          }
        },
        builder: ((context, state) {
          if (isMobile() || width < 800) {
            return _tabbedView(context.read<LyricsCubit>());
          } else {
            return _defaultView(context.read<LyricsCubit>());
          }
        }),
      ),
    );
  }

  Widget _defaultView(LyricsCubit cubit) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
          child: SizedBox(
            width: double.infinity,
            child: _title(),
          ),
        ),
        actions: _buttons(cubit),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Transform.translate(
                offset: Offset((-100 * _animProgress.value), 0),
                child: Opacity(
                  opacity: (1 - _animProgress.value),
                  child: _japaneseColumn(cubit),
                ),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _upperCenter(cubit),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  AudioPlayer(
                    cubit: cubit,
                    ytController: _ytController,
                    animProgress: _animController.value,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: Transform.translate(
                offset: Offset((100 * _animProgress.value), 0),
                child: Opacity(
                  opacity: (1 - _animProgress.value),
                  child: _translationColumn(cubit),
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: DrawerWidget(cubit),
    );
  }

  Widget _tabbedView(LyricsCubit cubit) {
    return DefaultTabController(
      initialIndex: 2,
      length: 3,
      child: Scaffold(
        drawer: DrawerWidget(cubit),
        appBar: AppBar(
          title: _title(),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                text: 'Japanese',
              ),
              Tab(
                text: 'Translation',
              ),
              Tab(
                text: 'Result',
              ),
            ],
          ),
          actions: _buttons(cubit),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _japaneseColumn(cubit),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _translationColumn(cubit),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _upperCenter(cubit),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 24, bottom: 24, right: 24, top: 6),
              child: AudioPlayer(
                cubit: cubit,
                ytController: _ytController,
                animProgress: _animController.value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title() {
    return Text(
      isMobile() ? 'Lyrics Maker' : 'Furigana Lyrics Maker',
    );
  }

  Widget _upperCenter(LyricsCubit cubit) {
    if (cubit.state.mainState == LyricsState.loading) {
      return const Center(
        child: SizedBox(
            width: 100, height: 100, child: CircularProgressIndicator()),
      );
    } else if (originalController.text.trim().isEmpty) {
      return const Center(
        child: Text(
          '<--- Type some text in the Japanese column.',
          style: TextStyle(fontSize: 20),
        ),
      );
    } else if (cubit.state.mainState == LyricsState.ok ||
        cubit.state.mainState == LyricsState.loadedSong) {
      return Karaoke(
        cubit: cubit,
        ytController: _ytController,
      );
    } else if (cubit.state.mainState == LyricsState.errorLineNumber) {
      return _linesNumberIncorrect(cubit);
    } else {
      return const Center(
        child: Text('An error occurred'),
      );
    }
  }

  Widget _linesNumberIncorrect(LyricsCubit cubit) {
    final originalLines = cubit.state.lyrics.originalLines.length;
    final translationLines = cubit.state.lyrics.translatedLines.length;
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xfffcda53),
            border: Border.all(
              width: 1,
              // assign the color to the border color
              color: Colors.grey,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Text(
            'Original and translated text must have the same number of lines.\n\n'
            '<--- The Japanese column has $originalLines lines\n'
            '---> The translation column has $translationLines lines\n\n'
            'Fix the problem to show the result.',
            textAlign: TextAlign.left,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _japaneseColumn(LyricsCubit cubit) {
    return InputTextColumn(
      key: const Key('original_text_field'),
      cubit: cubit,
      textEditingController: originalController,
      labelText: 'Paste the Japanese text here',
      onChanged: () => _updateResult(cubit, addFurigana: false),
    );
  }

  _translationColumn(LyricsCubit cubit) {
    return InputTextColumn(
      cubit: cubit,
      textEditingController: translationController,
      labelText: 'Paste the translated text here',
      onChanged: () => _updateResult(cubit, addFurigana: false),
    );
  }

  List<Widget> _buttons(LyricsCubit cubit) {
    final furiganaOn =
        cubit.state.mainState == LyricsState.ok && _furiganaButtonEnabled;
    return [
      !isMobile()
          ? TextButton(
              onPressed: furiganaOn
                  ? () => _updateResult(cubit, addFurigana: true)
                  : null,
              child: Text(
                'Add furigana',
                style: TextStyle(
                  color: furiganaOn ? Colors.white : Colors.grey,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : IconButton(
              onPressed: furiganaOn
                  ? () => _updateResult(cubit, addFurigana: true)
                  : null,
              icon: const Icon(Icons.subtitles),
              color: furiganaOn ? Colors.white : Colors.grey,
            ),
      SizedBox(
        width: isMobile() ? 0 : 20,
      ),
      IconButton(
        onPressed: cubit.state.mainState == LyricsState.ok
            ? cubit.downloadClicked
            : null,
        icon: const Icon(Icons.download),
        tooltip: 'Download lyrics',
      ),
      const SizedBox(
        width: 20,
      ),
    ];
  }
}
