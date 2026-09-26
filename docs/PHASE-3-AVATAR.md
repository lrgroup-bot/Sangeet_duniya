# Phase 3 — Sangeeta Avatar

## Production implementation

- [x] One canonical Sangeeta visual identity across player, companion and wardrobe surfaces.
- [x] Project-owner supplied photographs distilled into a local appearance profile.
- [x] Raw reference photographs are **not** bundled in the public repository or APK.
- [x] Long, voluminous dark wavy hair is the default identity.
- [x] Soft oval face, dark almond eyes, warm medium complexion and natural rose lips.
- [x] Stable adult fashion silhouette across all outfits and animation states.
- [x] Breathing, blinking, greeting, listening, speaking, sitting and dance motion.
- [x] Speech animation keeps the mouth moving while TTS is in the speaking state.
- [x] Ten wardrobe categories:
  - Casual
  - Party
  - Romantic
  - Traditional Odia
  - DJ Stage Outfit
  - Gym Wear
  - Beach / Resort Wear
  - Night Wear
  - Festival Collection
  - Winter Collection
- [x] Hair, earrings, shoes and accessories can be changed independently.
- [x] Wardrobe favorites and song-mood auto switching remain local-first.
- [x] Mini/full avatar surfaces use the same identity profile.

## Reference-lock rules

The face, skin palette, eye placement, hair identity and core body proportions do
not change when clothing changes. Wardrobe layers are allowed to change clothing,
hair styling and accessories, but they must not create a different Sangeeta face.

Canonical code:
- `lib/models/sangeeta_likeness.dart`
- `lib/widgets/sangeeta_avatar.dart`
- `lib/widgets/avatar_accessory_overlay.dart`
- `lib/widgets/rive_avatar_stage.dart`

The appearance revision is `reference-v1-2026-09-26`.

## 3D engine research

Two free/open-source implementations were checked before this revision:

1. **m-r-davari/flutter_3d_controller** — MIT licensed. It is a mature Flutter
   GLB/GLTF/OBJ renderer with animation, texture and camera control.
2. **PKS-KenWakabayashi/VRM1Flutter** — MIT licensed. It supports VRM 1.0,
   humanoid skeletons, expressions, morph targets and look-at, but currently
   depends on Flutter's preview `flutter_gpu` path and CPU skinning.

The production v2.2 build does **not** pull either repository into the app yet.
There is no production rigged Sangeeta GLB/VRM asset in this repository, so adding
a 3D runtime now would increase app size and risk without improving the visible
avatar. The local vector renderer is therefore the production renderer.

`SangeetaLikeness.requiredMotionClips` and
`SangeetaLikeness.requiredFaceExpressions` define the contract for a future
rigged model. Once a rigged Sangeeta asset exists, a 3D backend can replace the
vector renderer behind the same avatar stage without changing the voice/player
state machine.

## Acceptance

- [x] One stable reference-inspired identity in source.
- [x] All 10 wardrobe categories render locally.
- [x] Greeting/listening/speaking/dance states are wired.
- [x] Source photos excluded from public package.
- [ ] Real-device visual/performance regression check on target Android phone.
- [ ] Optional future rigged GLB/VRM asset production.

Status: **IMPLEMENTED — REAL-DEVICE VISUAL CHECK PENDING**
