# Fabric2Fit

*From Your Fabric to Your Perfect Fit*

A cross-platform Flutter app (Android, iOS, web) that turns unstitched fabric into outfit ideas:

**Upload fabric → Analyse → Matching designs → Select design → See your fabric on it → Save**

## Features (MVP)

- **Upload / capture** a fabric photo (camera or gallery), or try a built-in sample swatch.
- **On-device fabric analysis** – k-means colour palette, colour family, pattern (solid, stripes, checks, polka, floral…), texture and a fabric-type guess. Every attribute is editable.
- **Rule-based recommendations** – scores ~60 seed designs on colour, pattern, texture, fabric type, occasion, garment category and style, with human-readable reasons and occasion/category filters.
- **Fabric-to-design visualisation** – the actual fabric image is tiled into the garment silhouette with drape shading; adjustable print size and direction, side-by-side compare.
- **Favorites** – save looks (fabric + design + print settings) and reopen them.
- **Profile** – guest mode, email sign-up/sign-in, editable name.

## Architecture

Feature-based clean architecture with Riverpod:

```
lib/
  core/            theme, router (go_router), shared widgets, config
  features/
    fabric/        domain (attributes, analysis) · data (analyzer, samples) · presentation
    designs/       domain (GarmentDesign, RecommendationEngine) · data (seed, local, Firestore) · presentation
    visualization/ garment shapes + painter, visualisation screen
    favorites/     SavedLook · local (SharedPreferences) + Firebase repos · presentation
    profile/       AppUser/AuthRepository · local + Firebase Auth repos · presentation
    onboarding/, home/
```

Each repository has an interface in `domain/`, so the AI analyzer or a larger catalogue (500+ designs in Firestore) can be swapped in without touching the UI.

## Running

```bash
flutter pub get
flutter run                 # local mode: data stays on the device
flutter test
```

### Enabling Firebase (Auth, Firestore, Storage)

1. Create a Firebase project and enable Anonymous + Email/Password auth, Firestore and Storage.
2. `dart pub global activate flutterfire_cli && flutterfire configure` (overwrites `lib/firebase_options.dart`).
3. Run with `flutter run --dart-define=USE_FIREBASE=true`.

On first launch the `designs` collection is seeded from the built-in catalogue. Looks are stored at `users/{uid}/looks/{lookId}` with fabric images in Storage at `users/{uid}/fabrics/{lookId}.jpg`.

## Roadmap

- ML fabric recognition (fabric type, print classification) behind `FabricAnalyzer`.
- Catalogue growth to 500+ designs with photography and admin tooling.
- Realistic AI garment rendering (warping, lighting, drape) of the user's actual fabric.
