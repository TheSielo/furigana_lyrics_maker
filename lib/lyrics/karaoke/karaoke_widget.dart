import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:furigana_lyrics_maker/lyrics/content_strings.dart';
import 'package:furigana_lyrics_maker/utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:ruby_text/ruby_text.dart';
import '../../preferences/preferences.dart';
import '../lyrics.dart';
import '../lyrics_cubit.dart';

class Karaoke extends StatefulWidget {
  final LyricsCubit cubit;
  final YoutubePlayerController ytController;
  const Karaoke({super.key, required this.cubit, required this.ytController});

  @override
  State<Karaoke> createState() => _KaraokeState();
}

class _KaraokeState extends State<Karaoke> {
  final ItemScrollController _scrollController = ItemScrollController();
  final _currentLineKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (_scrollController.isAttached) {
      final offset = isMobile() ? 0 : 3;
      final index = widget.cubit.state.lyrics.currentLine - offset;
      if (index >= 0) {
        _scrollController.scrollTo(
            index: index,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    }

    return BlocListener<LyricsCubit, LyricsUIState>(
      bloc: widget.cubit,
      listener: (context, state) async {
        if (state.mainState == LyricsState.timestampsUnlocked) {
          final neverUnlocked = await PreferencesHelper.getBool(
              BoolPref.neverUnlockedTimestamps, true);
          PreferencesHelper.setBool(BoolPref.neverUnlockedTimestamps, false);
          if (neverUnlocked) {
            // context.mounted is checked before use in the funtion.
            // ignore: use_build_context_synchronously
            _showMyDialog(context);
          }
        }
      },
      child: _lyrics(),
    );
  }

  Widget _lyrics() {
    return ScrollablePositionedList.builder(
      itemScrollController: _scrollController,
      itemCount: widget.cubit.state.lyrics.originalLines.length,
      itemBuilder: (context, index) {
        final value = widget.cubit.state.lyrics.originalLines[index];
        final lyrics = widget.cubit.state.lyrics;
        final translatedLine = lyrics.translatedLines.length > index
            ? lyrics.translatedLines[index]
            : null;
        final furiganaLine = lyrics.furiganaLines.length > index
            ? lyrics.furiganaLines[index]
            : null;
        return KaraokeLine(
          key: index == lyrics.currentLine ? _currentLineKey : null,
          index: index,
          onClick: () => widget.cubit.state.timestampsLocked
              ? _showSnackbar(context)
              : widget.cubit
                  .setTimestamp(index, widget.ytController.currentTime),
          highlighted: index == lyrics.currentLine,
          originalLine: value,
          translatedLine: translatedLine,
          furiganaLine: furiganaLine,
        );
      },
    );
  }

  void _showSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The sync editor is locked! Unlock it with the lock-shaped button.',
        ),
      ),
    );
  }

  Future<void> _showMyDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('How to syncronize music and lyrics'),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: ListBody(
                children: const <Widget>[
                  Text(ContentStrings.timestampsEditorExplanation),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Undertsood'),
              onPressed: () {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

//To do: Colors should be moved to a centralized place/theme.
class KaraokeLine extends StatelessWidget {
  final int index;
  final Function onClick;
  final bool highlighted;
  final String originalLine;
  final String? translatedLine;
  final FuriganaLine? furiganaLine;
  late final TextStyle originalStyle = TextStyle(
      fontSize: isMobile() ? 24 : 32,
      fontWeight: FontWeight.w500,
      color: highlighted ? Colors.amber : Colors.white);
  late final TextStyle translationStyle = TextStyle(
    fontSize: isMobile() ? 16 : 20,
    color: Colors.grey,
  );

  KaraokeLine({
    super.key,
    required this.index,
    required this.onClick,
    required this.highlighted,
    required this.originalLine,
    required this.translatedLine,
    required this.furiganaLine,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onClick(),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            furiganaLine != null
                ? RubyText(
                    furiganaLine!.furiganaList
                        .map((e) => RubyTextData(e.base, ruby: e.reading))
                        .toList(),
                    style: originalStyle)
                : Text(
                    originalLine,
                    style: originalStyle,
                  ),
            if (translatedLine != null)
              Text(
                translatedLine!,
                style: translationStyle,
              ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
