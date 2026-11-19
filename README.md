# DoneBuzz

A tiny iOS to-do app with a pixel side-scroller look: add an item (typed or dictated, optionally with a time estimate from 5 min to 1 hour), tap the button on the right to complete it, and a pixel cat hops to knock out a coin (with a haptic and an 8-bit sound) while it walks toward today's finish flag. Finished items stay in today's list until midnight and can be un-ticked; everything finished is kept in history. Chinese and English UI, switchable in Settings.

SwiftUI + SwiftData, iOS 17+, no dependencies, local storage only.

## Run on a Mac

```bash
brew install xcodegen
cd DoneBuzz
xcodegen            # generates DoneBuzz.xcodeproj from project.yml
open DoneBuzz.xcodeproj
```

In Xcode: select the DoneBuzz target → Signing & Capabilities → pick your Team, then run.
Haptics only work on a real iPhone, not the simulator.

Without XcodeGen: create a new iOS App project in Xcode (SwiftUI, SwiftData off), delete its generated Swift files, and drag the `DoneBuzz/` folder in.

## Layout

- `DoneBuzz/Models/Todo.swift` — the data model and duration options
- `DoneBuzz/Services/FeedbackService.swift` — haptics and the synthesized hop + coin sound
- `DoneBuzz/Services/Language.swift` — the language setting and every UI string in Chinese and English
- `DoneBuzz/Services/SpeechInput.swift` — dictation, in the chosen language
- `DoneBuzz/Views/PixelArt.swift` — the cat, coin and cloud sprites, drawn in code
- `DoneBuzz/Views/StageView.swift` — the scene with the hopping cat and finish flag
- `DoneBuzz/Views/` — To do list, add/edit sheet, Done history, Settings, theme
