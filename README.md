# A kanji app

This is simple flashcards app, specifically tuned to learning kanji. All readings (*yomi*) are fetched from [Kanjipedia](https://www.kanjipedia.jp).

<img src="screenshot.png" height="600" />

## Learning

Every card has three states:
- *New* – for new or forgotten card,
- *Repeat* – card was just remembered, should be recalled in the next session,
- *Learned* – card was remembered well.

So if you are good at remembering, state progresses sequentially:
*New --(good)--> Repeat --(good)--> Learned*

Although the app takes hardcore approach, if you don't remember card, state always resets:
*Repeat/Learned --(again)--> New*

There are a couple of shortcuts: In *Learn* window you can press `space` to show back side, and `space` again to mark success, or `x` to mark failure. You can also undo your answers with `⌘Z`.

In *Database* you can provide example words that will be shown while learning, e.g. *自転車* is displayed for every kanji in the word: *自*, *転*, and *車*.

### Settings

You can change certain learning parameters in Settings window (*Window -> Settings*):
- Total maximum of cards, 0 is infinity,
- Maximum number of additional cards, i.e. not marked for repeating,
- Ratio between new and learned cards in that amount.

## Import, export and editing

You can import the first portion of cards and examples in *Database* window (*Window -> Database*). For kanji import file should be in CSV format with two columns separated by semicolon: kanji and integer (0 is *New* and so on). If you don't specify status, in other words, if only kanji is provided, then status reads as *New*.

```
低;0
花;1
...
```
File with examples should contain only words, on import system will match corresponding kanji automatically.

```
自転車
男の子
...
```
In *Database* window you can find button, which exports cards and examples in corresponding format.
