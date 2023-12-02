// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furigana_lyrics_maker/lyrics/lyrics_screen.dart';

void main() {
  testWidgets('Interface builds correctly', (WidgetTester tester) async {
    Widget lyricsWidget = const MediaQuery(
      data: MediaQueryData(),
      child: MaterialApp(
        home: LyricsScreen(),
      ),
    );
    // Build our app and trigger a frame.
    await tester.pumpWidget(lyricsWidget);
  });
}
