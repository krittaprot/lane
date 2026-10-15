# Lane

A tiny menu bar app that becomes your default browser and sends each link to the browser you choose.

- **Menu bar → Open Links In:** pick one browser for every link, or **Ask Every Time** to get a picker.
- **Picker:** appears at the pointer. Press 1–9 or click to choose, Return for the first, esc to cancel, ⌘C to copy the link.
- **Hold ⌥** while clicking a link to get the picker, even when a browser is set.
- **Make Lane the Default Browser…** in the menu hands links to Lane (macOS asks you to confirm).
- **Open at Login** keeps it in the menu bar after a restart.

Native macOS app (Swift, AppKit + SwiftUI), macOS 14+. Not a PWA, unlike the rest of `smollab-app`.

## Build and install

Run from the project root:

```bash
scripts/install.sh
```

That builds `build/Lane.app`, installs it to `~/Applications`, and opens it. `scripts/build.sh` only builds.
The app is ad-hoc signed, so it runs on this Mac but isn't notarized for other machines.

Settings live in `UserDefaults` (`com.krittaprot.lane`, key `browserID`).

## Origin

Written from scratch after studying what Velja does (its Info.plist, extensions and UI text). No Velja code or artwork is used.
