# Changelog

## 1.9.0

Full UI customisation, shared with Android 1.9.0 (see CONTRACT.md).

- AWS Amplify liveness upgraded from 1.4.2 to 1.6.0.
- `LivenessUIConfig` gains `showStartPage`, `hideCancelButton`, `colors` (`LivenessColors`) and `fonts` (`LivenessFonts`). Existing fields and the existing initialiser keep working.
- Colours and fonts now style the AWS detector too, through its theme API. The detector follows `theme` instead of the device's light/dark setting.
- All SourceID text is overridable and translatable through the app's `Localizable.strings` (`sid_liveness_*` keys).
- The start page warns about the flashing colours (`sid_liveness_start_guideline_photosensitivity`).
- Fix: in the dark theme without a primary colour, the start button no longer shows white text on a white button.
- Fix: camera permission is requested before AWS's detector starts (as on Android), so a first-time permission prompt no longer fails the check when `showStartPage` is false. A denied camera returns `CAMERA_PERMISSION_DENIED` immediately.
- New `CONTRACT.md`: the cross-platform reference for config fields, results and error codes.
- Building now requires approving AWS's `SmithyCodeGeneratorPlugin` once per machine (Xcode: Trust & Enable; CI: `-skipPackagePluginValidation`). See README, "Approving AWS's build plugin".
