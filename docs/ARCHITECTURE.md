# LR's Sangeet_Duniya v2.2 Architecture

## Principles

- Local-first app state.
- Windows PC is the activation/admin authority.
- No Supabase.
- No Vercel.
- No cloud database.
- No embedded mobile owner secret.
- Same-Wi-Fi and Tailscale use the same HTTP client contract.
- Source downloads are offered only where the source permits downloading.

## Flutter application

### Presentation

`lib/screens` and `lib/widgets` contain the music surfaces, Sangeeta surface, wardrobe studio, player, library, activation UI and PC-sync status.

### Audio

`MusicAudioHandler` owns playback, queue navigation, seek, volume, Android EQ and media-session state.

Flow:

```text
UI / Sangeeta command
  -> MusicAudioHandler
  -> just_audio
  -> audio_service
  -> Android notification / lock screen / iOS media controls
```

Audio-session interruption handling pauses or ducks playback. Sleep timer is local.

### Library

`LibraryStore` persists known tracks, favorites, downloaded paths, play history and playlists in local app storage. Album and artist views are derived locally from known track metadata.

### Sangeeta

Speech recognition feeds `SangeetaCommandParser`. In wake mode, a voice command is ignored unless it begins with the Sangeeta wake phrase. Commands route to the audio handler or navigation. TTS completion controls the speaking avatar state.

### Avatar / wardrobe

The character is rendered locally. The wardrobe profile stores category, hairstyle, earrings, shoes, accessories, favorites and automatic mood selection in SharedPreferences.

## Activation

The mobile app has no code-generation secret.

```text
Phone
  -> POST /api/activate
  -> Windows PC
  -> SQLite activation_codes + devices
  <- device-specific activation lease

Phone startup
  -> valid cached lease permits local-first use
  -> GET /api/status when PC is reachable
  <- active / expired / revoked status
```

The app stores a random local device ID and a device-specific activation ID returned by the PC. A six-digit code can enroll multiple devices up to the PC-configured limit.

## Windows PC Admin Server

`admin_server/server.py` uses only Python standard-library components:

- ThreadingHTTPServer
- SQLite
- cryptographically secure random code/activation identifiers
- per-IP activation attempt throttling
- admin-token authenticated dashboard
- token/device revocation
- expiry calculations
- local dashboard HTML

Validity begins on the first successful activation, and subsequent phones on the same code share the same expiry window.

## Network

Port: `40425`.

Same Wi-Fi can use the PC LAN IPv4. Tailscale can use the PC Tailscale IPv4. Tailscale traffic is encrypted between peers. Plain local HTTP should only be used on a trusted LAN.

## Release

GitHub Actions regenerates platform folders, applies platform patches, analyzes/tests Flutter, tests the Python admin server, builds Android and verifies an iOS no-codesign release build.

Production Android signing is injected only from GitHub repository secrets. The release key is never stored in source.
