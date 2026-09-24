# Architecture

## Layers

UI
- Screens, navigation, player controls and reusable widgets.

Domain
- Song model and future Sangeeta command models.

Services
- Background audio service.
- Future speech, AI, lyrics, downloads and source adapters.

Data
- Demo catalog in Phase 1.
- Local persistence will be introduced in later phases.

## Audio flow

UI action → MusicAudioHandler → just_audio → audio_service media controls.

The handler exposes media item, playback state, position and duration streams to the UI.

## Licensing principle

The app will use independently authored code and documented open-source dependencies. Music source integrations will be added only where their APIs and terms permit the intended use.
