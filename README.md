# LR's Sangeet_Duniya 🎵

A free, Android-first Flutter music application with a premium black-and-gold interface, background playback, local library support, and the future Sangeeta voice companion.

Development rule: A phase is marked COMPLETED only after code is implemented and the automated/device tests for that phase pass.

## Current status

| Phase | Scope | Status | Testing |
|---|---|---|---|
| 1 | Foundation: UI + player + background audio | 🟡 BUILD VERIFIED | ✅ CI PASS; 📱 device test pending |
| 2 | Sangeeta voice/chat assistant | 🟡 IMPLEMENTED | ✅ CI/device voice verification pending |
| 3 | Sangeeta dancing avatar + wardrobe | 🟡 IMPLEMENTED | ✅ CI/device animation verification pending |
| 4 | Music engine: downloads, lyrics, playlists, smart library | 🟡 IMPLEMENTED | ✅ CI/device offline verification pending |
| 5 | APK build, optimization, release | 🎨 DESIGN ONLY | ⬜ Not started |

## Phase 1 — Foundation

Target features:

- Premium black-and-gold AMOLED UI.
- Vector Sangeeta logo with gradient, glow and layered 3D-style lettering.
- Splash screen and app branding.
- Home, Search, Library, and Player screens.
- Demo streaming playback as the test transport.
- Background playback through audio_service + just_audio.
- Android media notification and lock-screen controls.
- Mini-player UI.
- Clean project structure ready for later Sangeeta integration.

### Phase 1 acceptance tests

- [x] flutter analyze passes.
- [x] flutter test passes.
- [x] Android debug APK builds successfully.
- [ ] App launches without a crash.
- [ ] Demo track can play and pause.
- [ ] Playback continues when the app is minimized.
- [ ] Android notification controls work.
- [ ] Lock-screen media controls work.

Automated Phase 1 checks passed on GitHub Actions. Phase 1 remains open until the APK is installed and background playback, notification controls, and lock-screen controls are verified on a real Android device.

## Phase 2 — Sangeeta

Sangeeta is the single assistant identity for the app.

Planned capabilities:

- Wake phrases including Hey Sangeeta, Hi Sangeeta, Hello Sangeeta, Hey Sweetheart, Hi Baby, and Hello Darling.
- Default Sweetheart personality.
- Friendly, affectionate, playful conversation in Odia, with Hindi and English options.
- Text chat and voice commands.
- Playback control: play, pause, next, previous, search, and playlist commands.
- No separate AI DJ.

## Phase 3 — Sangeeta Avatar

Planned avatar system:

- Sangeeta appears as the app's original virtual character.
- Floating mini-dancer while music plays.
- Full-screen Dance Mode.
- Music-reactive animations.
- Multiple dance styles by song category.
- Lip-sync for assistant responses.
- Wardrobe presets for romantic, party, Odia/traditional, Bollywood, devotional, festival, and other user-selected styles.
- Optional user-controlled avatar style settings.
- Supplied reference images are treated as visual references; the final character is kept as an original app character.

## Phase 4 — Music Engine

Planned features:

- Local/offline library.
- Download and cache management where source terms permit.
- Favorites.
- User playlists.
- Recently played.
- Lyrics integration.
- Multiple source/plugin adapters designed with clear licensing boundaries.
- Smart recommendations that can run locally where possible.

## Phase 5 — APK + Release

Release checklist:

- [ ] Release build.
- [ ] Android install test.
- [ ] Background playback regression test.
- [ ] Notification/lock-screen regression test.
- [ ] Performance check.
- [ ] Permissions and privacy review.
- [ ] README and CHANGELOG updated.
- [ ] APK artifact attached to the release/build.

## Architecture

~~~text
lib/
├── data/
├── models/
├── screens/
├── services/
├── theme/
├── widgets/
└── main.dart

test/
tool/
.github/workflows/
~~~

The initial code uses open-source Flutter packages rather than copying source code from another application. The project can take architectural inspiration from open-source music clients while keeping this repository's implementation independently authored.

## Local setup

Install Flutter stable, then:

~~~bash
flutter pub get
flutter run
~~~

For Android:

~~~bash
flutter build apk --debug
~~~

The CI workflow can generate the Android platform files when needed and then build the APK.

## Documentation

- Phase 1: docs/PHASE-1.md
- Phase 2 — Sangeeta: docs/PHASE-2-SANGEETA.md
- Phase 3 — Avatar: docs/PHASE-3-AVATAR.md
- Phase 4 — Music Engine: docs/PHASE-4-MUSIC-ENGINE.md
- Phase 5 — APK: docs/PHASE-5-APK.md
- Architecture: docs/ARCHITECTURE.md
- Changelog: CHANGELOG.md

## License

MIT — see LICENSE.


## Latest verification

GitHub Actions run 6 passed flutter analyze, flutter test, Android debug APK build, and APK artifact upload. The generated debug APK is available from the build artifact. Real-device runtime checks are still required before Phase 1 is marked COMPLETED.

## v0.1.1 rebuild

- Replaced the temporary splash icon with a vector-drawn Sangeeta logo.
- Added startup fallback so media-service initialization does not leave the app at a white screen.
- Android launcher icons are generated from the checked-in vector logo during CI.
- GitHub Actions run 17: analyze PASS, unit tests PASS, debug APK build PASS, artifact upload PASS.
- Real Android device behavior still requires physical-device verification.

## No-cloud design

Phases 1–4 are designed to run without a cloud database or cloud storage. Background audio uses Android media services, Sangeeta uses the device speech-recognition/TTS services, and the library/download state is stored locally in the app. Network access is used only for remote music/test URLs and future provider integrations where their terms permit.

## Phase 5 current implementation

Phase 5 is now actively implemented for the interactive Sangeeta avatar and private activation layer.

### Interactive Sangeeta player

- Full-body original Sangeeta avatar.
- Play: Sangeeta dances above the central control.
- Pause: Sangeeta uses a seated pose on the central control.
- Next: Sangeeta moves to the Next button.
- Previous: Sangeeta moves to the Previous button.
- Mini-player: a small Sangeeta follows play/pause state.
- Wardrobe presets: Casual, Party, Romantic, Traditional Odia, Gym/Chill, Resort swimwear, Elegant satin nightwear.
- Local Flutter avatar renderer; no external avatar service or remote animation file.

### Private activation

- Owner mode on the administrator phone.
- Owner can generate 7-day, 30-day, 365-day, or Ultimate Lifetime tokens.
- Tokens can be bound to a recipient phone number.
- Other phones enter the phone number and token to unlock the app until the token expires.

The current activation gate is for private distribution. Names, phone numbers, token records, and validity are stored only on the administrator phone. The app contains no payment gateway, checkout, subscription purchase, or in-app billing flow.


## Mobile-only architecture

- No Supabase.
- No Vercel.
- No cloud database.
- No cloud avatar runtime.
- No cloud analytics or user tracking.
- User registry, activation state, avatar settings, favorites, playlists and downloads stay on the device.
- GitHub is used only as the source-code repository and build automation; it is not an app runtime dependency.
- Internet access is used only when a music/artwork source itself is remote; local/downloaded files remain available offline.

## Free-only distribution

- No payment gateway is included.
- No subscription checkout is included.
- No money collection is performed by the app.
- 7-day, 30-day, 365-day and Ultimate are access-validity choices, not paid plans.
- QR generation uses the free open-source `qr_flutter` package and works offline. citeturn961158search0turn961158search1
- Flutter supports Android and iOS from the same codebase; iOS native build requires macOS/Xcode. citeturn135278search0turn135278search4


## Internet Music + Audio Quality

The app now has a direct Internet music catalog adapter using the Audius read-only API, plus the existing local library and background player. Audius provides REST endpoints for searching, trending, and streaming tracks; this app calls those endpoints directly from the phone and does not use Supabase or Vercel. citeturn542411search3

### Sound controls

- Sangeeta Auto EQ is enabled by default and chooses a local preset from song metadata.
- Manual EQ provides Balanced, Bass Boost, Vocal Clarity, Dance, Rock, Acoustic and Classical presets plus five adjustable bands.
- Android live EQ uses just_audio's Android audio-effect pipeline.
- Clean Audio works on a song already downloaded to the phone and creates a local FLAC with denoise, EQ and loudness normalization. It does not magically restore information that was never present in the source.
- Download is only offered when the source marks the track as downloadable.

The Android EQ pipeline uses just_audio's `AndroidEqualizer` / `AndroidLoudnessEnhancer` effects. citeturn542411search10turn542411search12 FFmpeg audio processing is provided by the maintained `ffmpeg_kit_flutter_new_audio` package, which supports Android and iOS among its supported platforms. citeturn542411search1

### Ad-free experience

LR's Sangeet_Duniya contains no advertising SDK or paid subscription flow in the app. It can provide an ad-free player interface for the sources we integrate directly. It does not bypass, remove, or defeat advertisements, paywalls, DRM, or access controls of third-party services.

The available catalog therefore depends on the source's rights and API. The app is designed to add additional direct, permitted music sources without adding a cloud backend.


## Optional Tailscale PC admin

The app can use a Windows/Linux/macOS PC as a self-hosted remote admin server. The PC keeps user and token data in local JSON files; Tailscale provides the network path.

- PC companion: `tools/tailscale_admin_server.py`
- Local PC API port: 40426
- Admin phone stores the PC ADMIN URL.
- App users receive only the USER URL.
- New owner-generated tokens are synchronized to the PC.
- Same-Wi-Fi phone registration remains supported.

Use **Tailscale Serve** when only your Tailscale-connected devices should access the service. Use **Tailscale Funnel** only when you intentionally want phones without Tailscale to reach the server; Funnel is public Internet exposure and has bandwidth limits. Tailscale currently lists a free Personal plan with up to 6 users and unlimited user devices; that 6-user limit is for Tailscale accounts, not LR's Sangeet_Duniya records. citeturn762669search0turn793466search1turn404717search1

Setup guide: docs/TAILSCALE-PC-ADMIN.md
