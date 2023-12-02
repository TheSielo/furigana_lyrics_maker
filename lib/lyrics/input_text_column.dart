import 'package:flutter/material.dart';
import 'package:furigana_lyrics_maker/lyrics/lyrics_cubit.dart';

class InputTextColumn extends StatelessWidget {
  final LyricsCubit cubit;
  final TextEditingController textEditingController;
  final String labelText;
  final Function onChanged;
  const InputTextColumn(
      {super.key,
      required this.cubit,
      required this.textEditingController,
      required this.labelText,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: cubit.state.mainState != LyricsState.loading,
      onChanged: (String value) => onChanged(),
      controller: textEditingController,
      minLines: 1000,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }
}
