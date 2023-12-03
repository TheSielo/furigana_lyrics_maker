# **Furigana Lyrics Maker**

Are you are a japanese learner like me, and you like to sing anime songs with wrong accents and pronunciation while you cook, do the laundry and drive?
Aren't you tired of manually mixing and matching the japanese and translated texts to follow the score more easily, just to be abused by kanji you don't know yet?

Well fear no more fellow kanji hater! Furigana Lyrics Maker has you covered!
A free and open source tool written in Flutter to create Japanese lyrics with translations and furigana, hosted at [https://lyrics.sielotech.com](https://lyrics.sielotech.com)!

Defeat those nasty kanji in the blink of an eye! Insert the japanese lyrics, the translated lyrics in the language you like, and they will be automagically mixed line by line, with free-as-in-free-beer juicy furigana included!

But there's more! And that's a karaoke mode directly inside the app, so that you can sing along your favorite idol without even downloading or printing your lyrics! [happy tree noises].

Of course, you are more than welcome to use the tool just to add furigana to a piece of text, I use it that way myself a lot of times! You can also use it to merge original and translated texts for languages other than Japanese, just don't add furigana to it I guess :/

You can find a tutorial, the FAQs and the roadmap in the [Wiki](https://github.com/TheSielo/furigana_lyrics_maker/wiki).

## Data collection
The website itself is hosted on Firebase Hosting.
The actual conversion to furigana happens through an endpoint written in Python at api.sielotech.com, also mantained by me, which runs on Google Cloud Run.

While I don't intentionally collect or store any of the data inputted in the website or sent to the endpoint, Google (and possibly other companies) probably log data somewhere. Please don't input any sensitive data if you care (and you should) about that.