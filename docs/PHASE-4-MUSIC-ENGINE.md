# Phase 4 — Music Engine

## Implemented

- [x] Local favorites.
- [x] Recently played history.
- [x] Playlists: create, delete, add songs.
- [x] Local downloads/cache using the app data directory.
- [x] Offline playback automatically uses the downloaded file when present.
- [x] Download/remove controls from song cards and the player.
- [x] Lyrics UI entry point in the player.
- [x] Local-first architecture with documented licensing boundaries.
- [x] No cloud database is required for these Phase 4 features.

## Source safety

The demo catalog uses public test audio URLs for development. Production catalog/source integrations must be added only where the provider's API and content terms permit the intended use.

## Acceptance

- [x] Code analysis passes on CI.
- [x] Unit test suite passes on CI.
- [x] Debug APK build passes on CI.
- [ ] Real-device offline download/playback regression test.

Status: IMPLEMENTED — DEVICE OFFLINE TEST PENDING
