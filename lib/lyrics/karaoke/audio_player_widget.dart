import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:furigana_lyrics_maker/lyrics/content_strings.dart';
import 'package:furigana_lyrics_maker/lyrics/lyrics_cubit.dart';
import 'package:furigana_lyrics_maker/preferences/preferences.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class AudioPlayer extends StatefulWidget {
  final LyricsCubit cubit;
  final YoutubePlayerController ytController;
  final double animProgress;
  const AudioPlayer({
    super.key,
    required this.ytController,
    required this.cubit,
    required this.animProgress,
  });

  @override
  State<AudioPlayer> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioPlayer>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  late final YoutubePlayer _player;
  double _videoDuration = 0;
  bool gettingDuration = false;

  @override
  void initState() {
    _urlController.text = widget.cubit.currentVideoUrl;
    _player = YoutubePlayer(
      controller: widget.ytController,
      aspectRatio: 16 / 9,
    );
    widget.ytController.loadVideo(
      ContentStrings.defaultVideoUrl,
    );
    widget.ytController.pauseVideo();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.cubit.state;
    return BlocListener<LyricsCubit, LyricsUIState>(
      bloc: widget.cubit,
      listenWhen: (previous, current) {
        print("PREVIOUS: ${previous.videoUrl}");
        print("CURRENT: ${current.videoUrl}");
        return current.videoUrl != previous.videoUrl;
      },
      listener: (context, state) async {
        setState(() {
          _urlController.text = state.videoUrl;
        });
        await widget.ytController.stopVideo();
        await widget.ytController.loadVideo(widget.cubit.currentVideoUrl);
        await widget.ytController.pauseVideo();
        widget.cubit.setIsPlaying(false);
      },
      child: Column(
        children: [
          SizedBox(
            height: 0,
            child: _player,
          ),
          Transform.translate(
            offset: Offset(0, 50 * widget.animProgress),
            child: Opacity(
              opacity: (1 - widget.animProgress),
              child: widget.animProgress == 1
                  //Remove the widget when animation complete to
                  //more space for lyrics. Todo: find a better way.
                  ? null
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText:
                                  "Paste a YouTube url here and confirm to change track",
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton(
                          onPressed: () async {
                            widget.cubit
                                .setVideoUrl(_urlController.text.trim());
                          },
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: FloatingActionButton(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  onPressed: () async {
                    final isPlaying = state.isPlaying;
                    if (isPlaying) {
                      widget.ytController.pauseVideo();
                    } else {
                      widget.ytController.playVideo();
                      /* I didn't find a better solution yet. The following loop is needed because there seem
                      to be a bug that doesn't populate the video metadata (where I should take
                      the duration from), so I need to use _ytController.duration until it
                      returns something different from zero. "Why don't put it in a separate function
                      instead of in this callback" you said? Because then it stops working and the Future
                      .duration never returns in that case! Maybe I did something wrong, I hope to
                      clean up a bit this process beacuse I don't like how it's done either... */
                      if (_videoDuration == 0 && !gettingDuration) {
                        gettingDuration = true;
                        while (_videoDuration == 0) {
                          _videoDuration = (await widget.ytController.duration);
                          await Future.delayed(const Duration(seconds: 1));
                        }
                      }
                    }
                    widget.cubit.setIsPlaying(!isPlaying);
                  },
                  child: state.isPlaying
                      ? const Icon(Icons.pause)
                      : const Icon(Icons.play_arrow),
                ),
              ),
              StreamBuilder<YoutubeVideoState>(
                stream: widget.ytController.videoStateStream,
                initialData: const YoutubeVideoState(),
                builder: (context, snapshot) {
                  widget.cubit
                      .updatePlayerTime(widget.ytController.currentTime);
                  final position = snapshot.data?.position.inSeconds ?? 0;
                  double value = position == 0 || _videoDuration == 0
                      ? 0
                      : position / _videoDuration;
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Expanded(
                        child: Slider(
                          value: value,
                          onChanged: (positionFraction) {
                            value = positionFraction;
                            setState(() {});
                            widget.ytController.seekTo(
                              seconds: (value * _videoDuration).toDouble(),
                              allowSeekAhead: true,
                            );
                          },
                          min: 0,
                          max: 1,
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: FloatingActionButton(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  onPressed: () async {
                    widget.cubit.setTimestampsLocked(!state.timestampsLocked);
                  },
                  tooltip: state.timestampsLocked
                      ? 'Unlock sync editor'
                      : 'Lock sync editor',
                  child: Icon(
                    state.timestampsLocked
                        ? Icons.lock_outline
                        : Icons.lock_open,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
