# Agent Guide for Err Template

## Project Overview

Err Template is a small offline Flutter app for Android. Describe what it
does here; `README.md` has the user-facing summary.

## Tech Stack

- **Language:** Dart
- **Framework:** Flutter (stable channel); the Dart SDK range is in `pubspec.yaml`
- **Platforms:** Android only. The phone it is built for runs GrapheneOS,
  so there are no Google Play services: don't add Firebase or anything
  else that needs them.
- **Key packages:** none yet. List them here as you add them.

## Project Structure

```
lib/main.dart                # App root and home screen
test/                        # flutter_test unit and widget tests
android/                     # Android host project (Gradle, manifest)
tool/rename.sh               # One-time rename from the template
tool/termux/                 # Phone (Termux) setup and flutter wrapper
docs/                        # macOS, Termux and release docs
.github/workflows/build.yml  # CI: analyze, test, build and release the APK
```

## Building & Testing

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release   # debug-signed unless KEYSTORE_PATH is set
```

CI runs on pushes to `main` and via manual dispatch: analyze, test, build a
release APK, and publish it as a GitHub release for Obtainium. It signs with
the release keystore when the `KEYSTORE_BASE64` secret is set. Without it,
or on a branch other than `main`, it uploads the APK as a workflow artifact
and publishes nothing. See `docs/releases.md`.

Things worth knowing:

- Debug builds use the app ID with `.debug` on the end and a "(debug)"
  label, so they install next to the release build instead of clashing
  with its signature.
- Don't change `applicationId` after the first release: Android would treat
  it as a different app.
- On the phone (Termux), release builds don't work, only debug ones; see
  `docs/termux.md`.

## Key Principles to Respect

- **Offline and private.** No analytics, telemetry, crash reporters, or
  network calls that send user data anywhere without explicit user action.
- **Simplicity.** Prefer leaving a feature out over adding a mode nobody
  asked for.
- **Data is the user's.** Keep exports in simple, open formats.
