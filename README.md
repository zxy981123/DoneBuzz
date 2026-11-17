# DoneBuzz

A tiny iOS to-do app: add an item (optionally 5 min / 20 min / 1 hour), tap to complete it with a shake, haptic and chime, and keep a history of everything finished.

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
- `DoneBuzz/Services/FeedbackService.swift` — haptics and the synthesized chime
- `DoneBuzz/Views/` — To do list, add/edit sheet, Done history
