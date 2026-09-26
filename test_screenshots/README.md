# Screenshots

Photographs of every screen in the app, in English and French, for design work.

```sh
flutter test test_screenshots --update-goldens
```

The PNGs land in `test_screenshots/shots/<locale>/`, 824x1830 each. They are gitignored, so the
only way to get a set is to generate one - which is what keeps them from going stale against the
code.

To produce a set without a checkout, run the `Screenshots` workflow by hand (Actions ->
Screenshots -> Run workflow, or `gh workflow run screenshots.yml --ref <branch>`) and download the
artifact it attaches to the run. It is manual-only for now: it gates nothing, and nobody needs a
fresh set on every push.

## Why it is built this way

No emulator, no backend, no running app. Each screen is pumped in a widget test against a fake
server (`fake_server.dart`) that answers with plausible data, so every screen photographs *full* —
a wallet with a balance, tables with players, a hand mid-flop — instead of showing the empty or
"could not load" state that an unreachable server would produce. The whole run takes ~15 seconds.

`matchesGoldenFile` is used purely as a way to write a PNG (that is what `--update-goldens` does).
Nothing is compared against a baseline, so this can never fail over a pixel. It fails only if a
screen throws while being drawn — an overflow, a missing font, an exception — which is worth
failing over, and has already caught several.

## Adding a screen

Add one entry to `_screens` in `app_screens_test.dart`, and a fixture to `fake_server.dart` for
any endpoint the screen calls. A path with no fixture answers 404, so the gap shows up in the shot
rather than hanging the run.

## Fonts

The app's own typeface (Bricolage Grotesque, in `assets/fonts/`) is registered in the test VM, so
these shots carry the real typography rather than a substitute. Roboto is registered alongside it
as the fallback for any glyph it does not cover.

Card suits are drawn as paths rather than typed as `♠ ♥ ♦ ♣`, so they no longer depend on a font
having a glyph for them.
