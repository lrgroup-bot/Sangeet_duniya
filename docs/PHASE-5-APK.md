# Phase 5 — Premium Avatar + Private APK Design

## Status

**IMPLEMENTING — AVATAR CONTROLS + PRIVATE LICENSING**

Phase 5 now includes the premium interactive Sangeeta layer plus a private activation gate.

## Implemented in this phase

- Full-body original Flutter Sangeeta avatar with live animation.
- Play state → Sangeeta dances above the Play/Pause control.
- Pause state → Sangeeta uses a seated pose on the central control.
- Next state → Sangeeta animates to the Next control.
- Previous state → Sangeeta animates to the Previous control.
- Mini-player avatar state follows playback.
- Wardrobe presets: Casual modern, Party, Romantic, Traditional Odia, Gym / Chill, Resort swimwear, Elegant satin nightwear.
- Optional external Rive runtime source.
- Rive state-machine URL can be configured from Settings.
- Private activation system with owner mode and 7-day, 30-day, 365-day, or Ultimate Lifetime tokens.
- Annual private-use price label: ₹100 / year.

## External avatar runtime

The app uses the official Rive Flutter runtime as an optional host for externally supplied .riv characters. The built-in Flutter avatar remains the offline fallback, so the application is not dependent on a remote animation file.

Official runtime repository: https://github.com/rive-app/rive-flutter

## Licensing note

The current token implementation is designed for private/personal distribution. Its signing secret is embedded in the application, so it should not be considered tamper-proof DRM. A future hardened release can move token issuance to a private service and use asymmetric signatures.

## Remaining Phase 5 work

- Final 3D Sangeeta art pack based on the supplied visual references, while keeping the character original.
- Release signing and keystore strategy.
- Production APK/AAB build.
- Install and runtime regression on the user's physical Android phone.
- Performance and startup profiling.
- Final permissions/privacy review.
