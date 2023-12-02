import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:furigana_lyrics_maker/lyrics/drawer_tile_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'lyrics_cubit.dart';

class DrawerWidget extends StatefulWidget {
  final LyricsCubit cubit;
  const DrawerWidget(this.cubit, {super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Version ${info.version} alpha';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 12,
            ),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('new_song_button'),
                onPressed: widget.cubit.state.mainState == LyricsState.ok
                    ? () {
                        widget.cubit.changeSong(null);
                        Navigator.pop(context); //Close the drawer
                      }
                    : null,
                child: const Text(
                  'New song',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          BlocBuilder(
            bloc: widget.cubit,
            builder: (context, state) {
              return Expanded(
                child: ListView.builder(
                  itemCount: widget.cubit.state.songs
                      .length, // Sostituisci con il numero di elementi nella tua lista
                  itemBuilder: (context, index) {
                    final song = widget.cubit.state.songs[index];
                    final songId = song[0];
                    final songTitle = song[1];
                    final isActive = songId == widget.cubit.state.currentSongId;
                    return DrawerTileWidget(
                      widget.cubit,
                      songId,
                      songTitle,
                      isActive,
                    );
                  },
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 24,
              bottom: 12,
            ),
            child: SizedBox(
              height: 50,
              child: InkWell(
                key: const Key('buy_me_a_Coffee_button'),
                onTap: () {
                  widget.cubit.openLink('https://buymeacoffee.com/sielo');
                  Navigator.of(context).pop();
                },
                child: Image.asset('assets/images/buy-me-a-coffe.png'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: SizedBox(
              child: InkWell(
                  onTap: () {
                    widget.cubit.openLink(
                        'https://github.com/TheSielo/furigana_lyrics_maker');
                    Navigator.of(context).pop();
                  },
                  child: const Text('This project is open source!')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 6,
              bottom: 24,
            ),
            child: Text(_appVersion),
          ),
        ],
      ),
    );
  }
}
