# **Furigana Lyrics Maker**

Are you are a japanese learner like me, and you like to sing anime songs with wrong accents and pronunciation while you cook, do the laundry and drive?
Aren't you tired of manually mixing and matching the japanese and translated texts to follow the score more easily, just to be abused by kanji you don't know yet?

Well fear no more fellow kanji hater! Furigana Lyrics Maker has you covered!
A free and open source tool written in Flutter to create Japanese lyrics with translations and furigana, hosted at [https://lyrics.sielotech.com](https://lyrics.sielotech.com)!

Defeat those nasty kanji in the blink of an eye! Insert the japanese lyrics, the translated lyrics in the language you like, and they will be automagically mixed line by line, with free-as-in-free-beer juicy furigana included!

Of course, you are more than welcome to use the tool just to add furigana to a piece of text, I use it that way myself a lot of times! You can also use it to merge original and translated texts for languages other than Japanese, just don't add furigana to it I guess :/

## Do you hate GUIs?
You would love to use this tool but you can't absolutely stand graphical interfaces, in fact you are reading this with w3m on a custom linux distro you implemented from scratch using vi? I will soon release lyrics-maker-stoneage-edition, just for you! It's a CLI tool and works even offline as a bonus! It's the backbone powering this project, without all the bells and whistles.

## FAQ
**Why are the lyrics only exported as HTML?**
Sadly ruby text (furigana) is supported on a very small number of programs and formats by default. HTML is the simplest way to display furigana correctly with a program that anyone has installed (your browser). You are free to copy-paste the text from the HTML document to your favourite program/tool and see how it goes (but sadly it will probably go really bad.) I'm open to suggestions though! The next export formats I plan to add are:
1. PDF - It should technically be capable of showing a rendered HTML file without problems;
2. TXT - It can't display furigana above kanji because it's plain text, but it will be universally usable, because furigana will be normal text inside parenthesis like so:
日本語 (にほんご).

**I don't see some functionalities in the hosted version**
I update the hosted version at lyrics.sielotech.com only when I reach a new stable milestone that adds useful features. So it's very possible that the hosted version will be behind the last version in the Git repository most of the time.

## Data collection
The website itself is hosted on Firebase Hosting.
The actual conversion to furigana happens through an endpoint written in Python at api.sielotech.com, also mantained by me, which runs on Google Cloud Run.

While I don't intentionally collect or store any of the data inputted in the website or sent to the endpoint, I cannot guarantee that Google or other companies don't log any data somewhere, so please don't input any sensitive data if you (like me) care about that.

## Roadmap
Next things I plan to do:
1. Probably more refactoring to make the code more maintainable;
3. Write more tests;
4. I'm trying to integrate a karaoke-like functionality that highlights the lyrics matching the progress of the audio track. The player is ok now, but I'm still working on the karaoke part;
5. Integration of WaniKani API to toggle furigana only for kanji not studied yet.
