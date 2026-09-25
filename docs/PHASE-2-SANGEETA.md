# Phase 2 — Sangeeta

## Implemented

- [x] Sangeeta is the single assistant identity.
- [x] Sweetheart personality is the default.
- [x] Friendly, Funny and Music Expert modes.
- [x] Odia-first voice responses with Hindi/English language options.
- [x] Voice input using the device speech recognizer.
- [x] Local text-to-speech using the device TTS engine.
- [x] TTS word-progress callbacks drive local lip shapes, so the avatar mouth follows real spoken-word timing instead of a blind loop.
- [x] Lightweight English/Hindi/Odia viseme approximation (open/wide/rounded/closed) with no cloud dependency.
- [x] Wake phrase parsing for:
  - Hey Sangeeta
  - Hi Sangeeta
  - Hello Sangeeta
  - Hey Sweetheart
  - Hi Sweetheart
  - Hello Sweetheart
  - Hey Baby
  - Hi Baby
  - Hello Baby
  - Hey Darling
  - Hi Darling
  - Hello Darling
  - Sangeeta / Sweetheart / Baby / Darling
- [x] Music commands: play, pause, resume, next, previous.
- [x] Voice command path is local-first; no cloud AI is required.

## Limitation

The current wake mode is foreground and session-based because the speech_to_text package is designed for commands and short phrases rather than guaranteed always-on background hotword detection. citeturn291673search5turn336295search0

## Acceptance

- [x] Code analysis passes on CI.
- [x] Unit test suite passes on CI.
- [ ] Real-device microphone + Odia recognition/TTS regression test.

Status: IMPLEMENTED — DEVICE VOICE + VISUAL LIP-SYNC TEST PENDING
