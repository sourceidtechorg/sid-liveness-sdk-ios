# LivenessTester

A small iOS app for testing this repository's `LivenessCheck` sources by hand, on a simulator or a phone. It references the package at `../..`, so it always builds the code on the current branch.

## Run

1. Open `LivenessTester/LivenessTester.xcodeproj`, choose your signing team for the `LivenessTester` target, and run it on an iPhone. The camera check needs a real device; on a simulator you can still check the start page and error handling.
2. Create a liveness session on your server (never in an app) and paste its id into the app, or start it from a Mac:

```bash
xcrun devicectl device process launch --console --device <UDID> \
  tech.sourceid.liveness.tester -- -sessionId <SESSION_ID> -preset dib -autostart YES
```

| Argument | Values |
| --- | --- |
| `-sessionId` | AWS liveness session id |
| `-preset` | `standard` (no customisation), `dib` (dark theme, custom colours and fonts, no start page), `dibStart` (light theme, custom colours and fonts, start page) |
| `-environment` | `development`, `sandbox` or `production`: turns on the pre-flight check and result fetch. The phone must reach that gateway. |
| `-autostart` | `YES` to start immediately |
| `-AppleLanguages` | `"(ar)"` to run in Arabic and check text overrides and right-to-left layout |

Every outcome is shown on screen and printed as `LIVENESS_TESTER …`, which `--console` streams to the Mac.

`LivenessTester/ar.lproj/Localizable.strings` holds sample Arabic overrides for testing only; they are unreviewed placeholder translations. The Exo 2 fonts are bundled under the SIL Open Font License (`Fonts/Exo2-OFL.txt`).
