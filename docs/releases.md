# Builds, signing and releases

`.github/workflows/build.yml` runs when you push to `main`, or when you start
it by hand (`gh workflow run build.yml`, or **Actions → Build APK → Run
workflow**). It:

1. runs `flutter pub get`, `flutter analyze` and `flutter test`,
2. builds a release APK, with the workflow's run number as Android's
   `versionCode`, so each build counts as newer than the last,
3. uploads the APK as a workflow artifact called `app-release`,
4. if the signing secrets are set and the run is on `main`, publishes the APK
   as a GitHub release tagged `build-<run number>`. Obtainium watches those.

| Signing secrets | Branch    | APK is signed with    | Release published? |
|-----------------|-----------|-----------------------|--------------------|
| set             | `main`    | your release key      | yes                |
| set             | any other | your release key      | no, artifact only  |
| not set         | any       | a throwaway debug key | no, artifact only  |

Without the secrets the APK is signed with a debug key the CI runner makes
on the spot, a different one each run. It installs, but no later build can
update it, so those builds are never released.

## Setting up signing

Do this once per app. You need `keytool`, which comes with Java:

- **Mac** with Android Studio:
  `"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"`
- **Termux** after running `tool/termux/setup.sh`: it's in the Debian
  container, so in the command below replace `keytool` with
  `proot-distro login debian --work-dir "$PWD" -- keytool`. Run it from a
  folder under your Termux home, which the container sees at the same path.

Make the key. It asks for a password (use a long one and save it in your
password manager) and for your name; the name ends up in the certificate
but nothing checks it.

```sh
keytool -genkeypair -v -keystore blerr-release.jks \
  -keyalg RSA -keysize 4096 -validity 10000 -alias blerr
```

Give it to the repo as secrets, from the repo folder. The last two commands
each prompt for the password: with a keystore made this way, the key
password and the store password are the same.

```sh
base64 < blerr-release.jks | gh secret set KEYSTORE_BASE64
gh secret set KEY_ALIAS --body blerr
gh secret set STORE_PASSWORD
gh secret set KEY_PASSWORD
```

Then move `blerr-release.jks` out of the repo folder (the `.gitignore` stops
`*.jks` files being committed, but don't rely on that) and back it up
somewhere safe with the password. If you lose it you can't ship an update
that installs over the existing app, and anyone who gets both can sign
updates as you.

## Trying a branch on the phone

A run on another branch builds and signs the APK but doesn't release it, so
Obtainium won't offer it. To try one:

```sh
gh workflow run build.yml --ref my-branch
gh run list --workflow build.yml --branch my-branch --limit 1   # shows the run's ID
gh run watch <ID>       # waits until it finishes
rm -f app-release.apk   # gh won't overwrite an older download
gh run download <ID> --name app-release
```

The run can take a few seconds to show up in the list. At the end there's an
`app-release.apk` in the current folder (git ignores it). It's signed with your
release key, so it installs over the release build and keeps the app's data.
(In Termux, `termux-open app-release.apk` opens the installer.) The next
release from `main` has a higher build number, so Obtainium updates over it
as usual.

## Debug builds

`flutter run` and `flutter build apk --debug` make a debug build: the app ID
gets `.debug` on the end and the launcher shows "App (debug)". It's a
separate app with its own data, so it installs next to the release instead
of failing over a signature mismatch.
