# Trasher

Trasher is a short, landscape iPad game built with SwiftUI for Swift Playgrounds.

The player follows a discarded plastic bottle through a neon city, storm drain,
polluted waterway, and recycling facility. The story is designed to be completed
in under three minutes and to communicate one idea clearly:

> Waste does not disappear. You can choose where it goes.

## Project Structure

- `Trasher.swiftpm/` - the finished Swift Playgrounds package.
- `Trasher.swiftpm/Sources/AppModule/` - the game source code.
- `RULES.md` - contest requirements and submission constraints.

The original starter Xcode files are still present in this repository, but the
current app to open, test, and submit is `Trasher.swiftpm`.

## Features

- Complete five-scene story flow from opening to ending.
- Offline-only implementation using SwiftUI and Apple frameworks.
- Runtime-generated visuals and audio, keeping the package very small.
- Touch interactions for dodging, route choice, and recycling sorting.
- Automatic scene progression so the experience never gets stuck.
- Reduced-motion support through system accessibility settings.

## How To Run

1. Open `Trasher.swiftpm` in Swift Playgrounds or Xcode.
2. Run the `Trasher` app on an iPad simulator or a real iPad.
3. Play through once manually before submission to confirm touch gestures feel good.

## Submission Notes

- Target platform: iPad, landscape orientation.
- Expected playtime: under 3 minutes.
- External network access: none.
- Compressed package size target: safely under 25 MB.
