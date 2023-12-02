import 'package:flutter/material.dart';
import 'package:furigana_lyrics_maker/lyrics/lyrics_cubit.dart';

class DrawerTileWidget extends StatefulWidget {
  final LyricsCubit cubit;
  final String songId;
  final String title;
  final bool isActive;

  const DrawerTileWidget(this.cubit, this.songId, this.title, this.isActive,
      {super.key});

  @override
  State<DrawerTileWidget> createState() => _DrawerTileWidgetState();
}

class _DrawerTileWidgetState extends State<DrawerTileWidget> {
  bool editMode = false;
  late final TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController(text: widget.title);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        widget.cubit.changeSong(widget.songId);
        Navigator.pop(context); //Close the drawer
      },
      title: !editMode
          ? Text(
              widget.title,
              style: TextStyle(
                color: widget.isActive
                    ? Colors.amber
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            )
          : TextField(
              controller: controller,
            ),
      trailing: widget.isActive
          ? IconButton(
              onPressed: () {
                if (editMode) {
                  widget.cubit.setTitle(widget.songId, controller.text);
                }
                setState(() {
                  editMode = !editMode;
                });
              },
              icon: !editMode
                  ? const Icon(
                      Icons.edit,
                    )
                  : const Icon(
                      Icons.check,
                    ),
              tooltip: !editMode ? 'Rename' : 'Confirm',
            )
          : IconButton(
              onPressed: () {
                widget.cubit.deleteSong(widget.songId);
              },
              icon: const Icon(
                Icons.close,
              ),
              tooltip: 'Delete',
            ),
    );
  }
}
