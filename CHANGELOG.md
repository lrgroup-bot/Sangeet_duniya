# Changelog

## 0.1.0

- Initialized LR's Sangeet_Duniya.
- Added master five-phase roadmap.
- Added premium black/gold Flutter UI.
- Added Home, Search, Library, Sangeeta placeholder and Player screens.
- Added mini-player.
- Added just_audio + audio_service background playback foundation.
- Added automated smoke test.
- Added CI workflow that generates Android platform files and builds a debug APK.

## 0.4.0

- Fixed Android media notification setup with a dedicated monochrome media icon and notification permission request.
- Media notification now exposes previous, play/pause and next controls.
- Persistent background audio configuration hardened for minimized playback.
- Added Sangeeta voice/chat companion with Odia-first Sweetheart mode and personality options.
- Added requested wake phrases and foreground wake listening.
- Added animated Dance Mode with Party/Romantic/Devotional performance presets.
- Added local favorites, history, playlists and offline downloads.
- Added local test lyrics and history-based recommendations.


## 0.5.0+6

### Added
- Interactive full-body Sangeeta avatar for player transport controls.
- Live avatar poses for dance, pause/sit, next and previous.
- Sangeeta wardrobe presets with a built-in animated renderer.
- Local Flutter avatar renderer; removed remote avatar source support.
- Private owner mode and time-limited activation tokens.
- License plans: 7 days, 30 days, 365 days, Ultimate Lifetime.
- Payment and checkout removed; all access-validity choices are free.
- Added local Admin Dashboard with active/expired/expiring counts and recipient records.
- Added free offline QR/download-link screen.
- Activation and license manager screens.

### Verification
- Added unit coverage for license token generation/validation and avatar presets.
- Real Android device verification remains required for animation performance and end-to-end activation behavior.


## 0.5.1+7
- Removed the Rive network avatar path.
- Removed the Rive package dependency and startup initialization.
- Sangeeta avatar now runs locally on the phone.
- Explicitly kept Supabase and Vercel out of the application runtime.
- Admin records remain local to the owner device.


## 0.6.0+8
- Added direct Internet music search/trending adapter using Audius read-only APIs.
- Expanded local library persistence so searched tracks remain available for favorites, playlists, history and downloads.
- Added Sangeeta Auto EQ with local metadata-based recommendations.
- Added Manual EQ presets and five-band controls.
- Added Android live EQ/loudness effects through just_audio.
- Added local Clean Audio processing to produce a denoised FLAC copy with EQ and loudness normalization.
- Download controls now respect the source's downloadable flag.
- Kept the application free of ads, subscriptions, payments, Supabase and Vercel runtime services.
