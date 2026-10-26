# Developing on a Mac

This sets up Flutter and the Android tools, then covers testing, running the
app in the emulator or on your phone, and building APKs. The examples use an
app called *blerr*; use your repo's name.

## Install the tools (once)

With [Homebrew](https://brew.sh):

```sh
brew install --cask flutter android-studio
brew install gh
```

Open Android Studio once and go through its setup wizard with the
**Standard** options. That downloads the Android SDK (into
`~/Library/Android/sdk`), the emulator and an emulator system image. Then add
the one piece Flutter needs that the wizard skips: on the welcome screen,
**More Actions → SDK Manager → SDK Tools**, tick **Android SDK Command-line
Tools (latest)** and click **Apply**.

Accept the SDK licences and check the setup:

```sh
flutter doctor --android-licenses
flutter doctor
```

The **Android toolchain** and **Android Studio** lines should have a tick.
Ignore Xcode, Chrome and the other platforms: this template only builds for
Android.

<details>
<summary>Without Android Studio</summary>

If you don't want the emulator or Android Studio, the command-line tools are
enough to test and build:

```sh
brew install --cask flutter android-commandlinetools temurin@21
sdkmanager --licenses   # read each licence and accept it with y
sdkmanager platform-tools
flutter config --android-sdk "$(brew --prefix)/share/android-commandlinetools"
flutter doctor
```

The first build downloads the rest of the SDK it needs.

You can still run the app on your phone over USB, as described below.
</details>

## Get the code

```sh
gh repo clone gsilvers/blerr
cd blerr
flutter pub get
```

## Check and test

```sh
flutter analyze   # static checks and lints
flutter test      # the tests in test/
```

CI runs the same two commands, and a failure there stops the release.

## Run it

`flutter run` builds a debug version and starts it on the emulator or phone.
While it runs, press `r` to hot-reload your code changes, `R` to restart the
app, and `q` to quit.

### In the emulator

In Android Studio, **More Actions → Virtual Device Manager → Create Virtual
Device**: pick a Pixel with a recent system image (on an Apple Silicon Mac
it's an arm64 one, which is the default). After that you can start it
without opening Android Studio:

```sh
flutter emulators                  # lists them
flutter emulators --launch <id>
flutter run
```

### On your phone, over USB

On the phone: **Settings → About phone**, tap **Build number** seven times,
then **Settings → System → Developer options → USB debugging**. Plug it in
and allow the computer when the phone asks. Then:

```sh
flutter devices   # the phone should be listed
flutter run
```

That installs the debug build, which shows up as "Blerr (debug)" next to the
release build from Obtainium. Each has its own data.

Don't use `flutter run --release` on a phone that has the release build
installed: a local release build is signed with your Mac's debug key, not
your release key, and when the signatures don't match Flutter uninstalls
the existing app first, taking its data with it.

## Build APKs

```sh
flutter build apk --debug
```

The APK is `build/app/outputs/flutter-apk/app-debug.apk`. Copy it to the
phone and tap it to install (allow your file manager to install unknown apps
when asked).

`flutter build apk --release` works too, but locally it's signed with the
debug key, for the reason above. Release builds for the phone come from CI;
see [releases.md](releases.md).
