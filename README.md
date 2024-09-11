# A kanji app

This is simple flashcards app, specifically tuned to learning kanji. All readings (*yomi*) are fetched from [Kanjipedia](https://www.kanjipedia.jp).

![screenshot](screenshot.png)

## Learning

Every card has three states:
- *New* – for new or forgotten card,
- *Repeat* – card was just remembered, should be recalled in the next session,
- *Learned* – card was remembered well.

So if you are good at remembering, state progresses sequentially:
*New --(good)--> Repeat --(good)--> Learned*

Although the app takes hardcore approach, if you don't remember card, state always resets:
*Repeat/Learned --(again)--> New*

There are a couple of shortcuts: In *Learn* window you can press `space` to show back side, and `space` again to mark success, or `x` to mark failure.

## Import, export and editing

You can import the first portion of cards in Database window (*Window -> Database*) with *Database -> Import*. File should have CSV format with two columns separated by semicolon: kanji and integer (0 is *New* and so on). It's also possible to export in this format with *Database -> Export*.

```
低;0
花;1
...
```

In *Database* window you can change states manually, but it's important to remember that learning session **should be saved** with *File -> Save Progress*, because cards are not published to the database automatically during the learning session.