# LR's Sangeet_Duniya v2.2

A local-first Flutter music app for Android and iOS with the Sangeeta voice/avatar companion and a Windows PC activation/admin server.

## v2.2 architecture

```text
Android / iOS app
  ├─ local library, favorites, playlists, downloads, history
  ├─ just_audio + audio_service background playback
  ├─ Sangeeta voice commands + TTS + animated avatar
  ├─ local wardrobe profile
  └─ activation client
          │
          ├─ same Wi-Fi
          └─ Tailscale
                │
Windows PC Admin Server :40425
  ├─ six-digit activation codes
  ├─ local SQLite database
  ├─ device registry / multi-phone activation
  ├─ validity countdown / revocation
  └─ local web dashboard
```

There is no Supabase, Vercel, cloud database, payment gateway or ad SDK in the application runtime.

## Sangeeta avatar

- Wake phrase: **Hey Sangeeta**.
- Odia, Hindi and English voice selection.
- Listening, speaking, greeting and music-reactive dance states.
- Speaking state stays active through TTS completion so the mouth animation tracks the spoken response.
- Mini Sangeeta appears in the player; Android media notification uses the Sangeeta monochrome notification icon.
- Wardrobe categories: Casual, Party, Romantic, Traditional Odia, DJ Stage Outfit, Gym Wear, Beach / Resort Wear, Night Wear, Festival Collection and Winter Collection.
- Persisted hairstyle, earrings, shoes, accessories, favorite outfits and automatic mood-based outfit changes.

Wake listening is implemented while the Sangeeta voice surface is active. Android/iOS background hotword detection is intentionally not implemented as a permanent microphone service.

## Music player

- Background playback and media notification / lock-screen controls.
- Search and trending source adapter plus local/offline library.
- Favorites, recently played, playlists, albums, artists and live queue.
- LRC-style synchronized lyrics when timed lyrics are available; plain lyrics remain readable.
- Equalizer and Android loudness controls.
- Offline downloads only when the source marks a track downloadable.
- Sleep timer.
- Mini player.
- Local Clean Audio workflow for downloaded files.

The app does not bypass third-party advertising, DRM, paywalls or source access controls.

## Voice commands

Typed commands work directly. Voice commands in wake mode require **Hey Sangeeta** first.

Supported actions include Play Song, Pause Music, Resume Music, Next Song, Previous Song, Volume Up, Volume Down, Open Playlist, Download Song and Search Song.

## Windows PC activation server

Start:

```powershell
admin_server\start_admin_server.bat
```

or:

```powershell
py -3 admin_server\server.py --host 0.0.0.0 --port 40425
```

Open `http://127.0.0.1:40425/` on the PC and log in with the admin token printed by the server. The server generates six-digit activation codes for:

- 7 days
- 14 days
- 30 days
- 90 days
- 180 days
- 365 days
- Lifetime

A validity window starts on first activation. Each code can allow multiple phones up to the device limit selected in the PC dashboard. The phone caches a valid lease for local-first use and synchronizes revocation/expiry when the PC is reachable.

Use the PC LAN IPv4 on the same Wi-Fi or its Tailscale IPv4 from remote networks. See `admin_server/README.md`.

## Android build and release

Version: **2.2.0+22**.

GitHub Actions verifies Flutter analysis/tests, the Windows admin server tests, an Android debug APK and an iOS no-codesign build. When Android signing secrets are configured, a main-branch build also:

1. builds the release APK,
2. verifies its APK signature,
3. uploads the signed artifact and SHA-256 file,
4. creates/updates the matching GitHub Release automatically.

Required repository secrets:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
ANDROID_STORE_PASSWORD
```

The signing key is deliberately not committed to the repository. This preserves Android update compatibility and keeps the private release key private.

The release asset name is:

```text
LRs-Sangeet-Duniya-v2.2.0.apk
```

After the v2.2 release exists, the direct latest-release URL used by the app points to that APK asset.

## Local development

```bash
flutter pub get
flutter analyze
flutter test
```

Android:

```bash
flutter create --platforms=android --org com.lrs.sangeet .
python3 tool/prepare_android.py
flutter build apk --debug
```

iOS on macOS:

```bash
flutter create --platforms=ios --org com.lrs.sangeet .
python3 tool/prepare_ios.py
flutter build ios --release --no-codesign
```

## License

MIT — see `LICENSE`.
