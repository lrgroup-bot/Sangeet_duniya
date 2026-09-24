# LR's Sangeet_Duniya 🎵

A free, Android-first Flutter music application with a premium black-and-gold interface, background playback, local library support, and the future Sangeeta voice companion.

Development rule: A phase is marked COMPLETED only after code is implemented and the automated/device tests for that phase pass.

## Current status

| Phase | Scope | Status | Testing |
|---|---|---|---|
| 1 | Foundation: UI + player + background audio | IN PROGRESS | Pending |
| 2 | Sangeeta voice/chat assistant | NOT STARTED | Pending |
| 3 | Sangeeta dancing avatar + wardrobe | NOT STARTED | Pending |
| 4 | Music engine: downloads, lyrics, playlists, smart library | NOT STARTED | Pending |
| 5 | APK build, optimization, release | NOT STARTED | Pending |

## Phase 1 — Foundation

Target features:

- Premium black-and-gold AMOLED UI.
- Splash screen and app branding.
- Home, Search, Library, and Player screens.
- Demo streaming playback as the test transport.
- Background playback through audio_service + just_audio.
- Android media notification and lock-screen controls.
- Mini-player UI.
- Clean project structure ready for later Sangeeta integration.

### Phase 1 acceptance tests

- [ ] flutter analyze passes.
- [ ] flutter test passes.
- [ ] Android debug APK builds successfully.
- [ ] App launches without a crash.
- [ ] Demo track can play and pause.
- [ ] Playback continues when the app is minimized.
- [ ] Android notification controls work.
- [ ] Lock-screen media controls work.

Phase 1 is not marked complete until the relevant tests above pass.

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
