# Developing on the phone, in Termux

You can edit, test and build debug APKs on the phone itself. Release APKs
have to come from CI.

| On the phone                                        | Where      |
|-----------------------------------------------------|------------|
| `flutter pub get`, `flutter analyze`, `flutter test` | Termux     |
| `flutter build apk --debug`                         | Termux     |
| Release APK, signed with your key                   | CI, started from Termux |
| `flutter run` with hot reload                       | not set up |

Why no release builds: Flutter compiles release builds ahead of time with a
tool called `gen_snapshot`, and Google only publishes it for x86-64 Linux,
macOS and Windows. Debug builds don't use it, so they work on an ARM phone.

## How it works

The Flutter SDK only runs on regular desktop Linux, which Termux isn't. So
`tool/termux/setup.sh` uses **proot-distro** to install a Debian container
inside Termux, and puts Flutter, Java and the Android SDK in it. It then
installs a small `flutter` command in Termux that runs the real one inside
the container, in your current folder. The container sees your Termux home
folder at the same path, so your code stays in Termux, where you edit it
and use git.

A few Android SDK tools come only as x86-64 programs, so the script swaps in
ARM versions:

- **aapt2**, which compiles the app's resources: Termux's own `aapt2` package.
- **llvm-strip**, which Flutter uses to shrink its libraries: Debian's. Flutter
  insists on the 2 GB Android NDK just for this, so the script gives it a
  stand-in folder holding only that one tool.
- **sdkmanager**: version 22.0 of Google's command-line tools, the last one
  written in Java.

## What you need

- Termux from [F-Droid](https://f-droid.org/packages/com.termux/) or its
  [GitHub releases](https://github.com/termux/termux-app/releases). The Play
  Store version is a different build.
- About 6 GB of free space, and Wi-Fi: setup and the first build download
  about 2 GB and take up about 5 GB.

## Set up (once)

```sh
pkg upgrade
pkg install git gh
gh auth login
gh repo clone gsilvers/blerr ~/blerr
cd ~/blerr
bash tool/termux/setup.sh
```

`setup.sh` is in every app made from the template, and it's the same in
each, so run it from any of them. Running it again is safe; it skips what's
already done.

## Everyday use

From the app's folder:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm64
termux-open build/app/outputs/flutter-apk/app-debug.apk
```

`--target-platform android-arm64` builds only for the phone's kind of CPU,
which halves the APK's size (to about 75 MB). `termux-open` hands the APK to
Android's installer; the first time, Android asks you to let Termux install
apps. The debug build installs as "Blerr (debug)" next to the release from
Obtainium, with its own data.

The first build takes several minutes while Gradle downloads its
dependencies. Later builds are quicker, but each `flutter` command starts
Gradle afresh, because the container is shut down when the command ends.
That also means nothing keeps running in the background.

To run other tools inside the container, use `proot-distro login debian`
for a shell, or `proot-distro login debian --work-dir "$PWD" -- <command>`
for a single command.

## Release builds

Push your branch and have CI build it:

```sh
git push -u origin my-branch
gh workflow run build.yml --ref my-branch
gh run list --workflow build.yml --branch my-branch --limit 1   # shows the run's ID
gh run watch <ID>
rm -f app-release.apk
gh run download <ID> --name app-release
termux-open app-release.apk
```

That's signed with your release key, so it installs over the Obtainium
version. Merging to `main` publishes a release as usual. More in
[releases.md](releases.md).

## Keeping it up to date

- Termux packages: `pkg upgrade`
- Flutter: `flutter upgrade`, then run `bash tool/termux/setup.sh` again, in
  case the new Flutter wants a different NDK version.
- Debian packages:
  `proot-distro login debian -- sh -c "apt-get update && apt-get upgrade -y"`

To remove it all: `proot-distro remove debian`, then
`rm $PREFIX/bin/flutter $PREFIX/bin/dart`.

## When things go wrong

- **`pkg` fails with "unmet dependencies"**: the Termux mirror it picked is
  out of date. Run `termux-change-repo`, choose the default mirror, then
  `pkg upgrade` and try again.
- **`Failed to find ".../linux-arm64/gen_snapshot"`**: that's a release
  build, which can't be done on the phone. Use `--debug`, or CI.
- **A plugin's native code fails to build** (errors mentioning CMake,
  `clang` or the NDK): some plugins compile C or C++, which needs the real
  NDK, so apps using them only build in CI.
- **The build stops with `[Process completed (signal 9)]`**: Android killed
  it, usually for memory or for running too many processes. Close other
  apps and try again. If it keeps happening, turn on **Settings → System →
  Developer options → Disable child process restrictions**.
- **Termux gets killed when you switch away**: run `termux-wake-lock` before
  a long build, and `termux-wake-unlock` after.
