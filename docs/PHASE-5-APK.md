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
- Private activation system with owner mode and 7-day, 30-day, 365-day, or Ultimate Lifetime tokens.
- Payment disabled: no payment gateway, checkout, subscription purchase, or money collection.
- Local Admin Dashboard with user name, phone, access period and days-left statistics.
- Free offline QR/download link generation.

## Mobile-only avatar runtime

The live Sangeeta avatar is rendered locally by Flutter and stored/controlled on the phone. No external avatar server, remote Rive file, Supabase, Vercel, or other cloud runtime is required.

## Licensing note

The current token implementation is designed for private/personal distribution. Its signing secret is embedded in the application, so it should not be considered tamper-proof DRM. A future hardened release can move token issuance to a private service and use asymmetric signatures.

## Free-only distribution

The app does not collect money. The 7-day, 30-day, 365-day and Ultimate choices only control access validity. No Supabase, Vercel, payment service, or cloud database is used at runtime.

## Remaining Phase 5 work

- Final 3D Sangeeta art pack based on the supplied visual references, while keeping the character original.
- Release signing and keystore strategy.
- Production APK/AAB build.
- Install and runtime regression on the user's physical Android phone.
- Performance and startup profiling.
- Final permissions/privacy review.
