#!/bin/bash
# The part of setup.sh that runs inside the Debian container, as its root user.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl git unzip xz-utils openjdk-21-jdk-headless llvm

# Flutter, stable channel, like CI.
if [ ! -d /opt/flutter ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /opt/flutter
fi
ln -sf /opt/flutter/bin/flutter /opt/flutter/bin/dart /usr/local/bin/
flutter --disable-analytics
flutter --version

# Android SDK. Command-line tools 23 and later swapped the Java sdkmanager for
# an x86-64-only program, so stay on 22.0, the last Java one.
sdk=/opt/android-sdk
if [ ! -x "$sdk/cmdline-tools/latest/bin/sdkmanager" ]; then
  curl -fsSL -o /tmp/cmdline-tools.zip \
    https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip
  echo "040d3996a65543d22ec4bf73e4c37aa37a8d4af4  /tmp/cmdline-tools.zip" | sha1sum -c -
  rm -rf /tmp/cmdline-tools
  unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools
  mkdir -p "$sdk/cmdline-tools"
  mv /tmp/cmdline-tools/cmdline-tools "$sdk/cmdline-tools/latest"
  rm -rf /tmp/cmdline-tools /tmp/cmdline-tools.zip
fi
yes | "$sdk/cmdline-tools/latest/bin/sdkmanager" --licenses > /dev/null || true
flutter config --android-sdk "$sdk"

# Flutter always installs the NDK, only to strip debug symbols from its
# libraries, and Google ships the NDK for x86-64 only. Give it a stand-in
# that holds just a native llvm-strip, instead of a 2 GB download that
# can't run here. (Plugins that compile C/C++ need the real NDK, so apps
# using them only build in CI.)
flutter_ext=/opt/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt
ndk_version=$(sed -n 's/.*val ndkVersion: String = "\(.*\)".*/\1/p' "$flutter_ext")
if [ -z "$ndk_version" ]; then
  echo "Couldn't find Flutter's NDK version in $flutter_ext" >&2
  exit 1
fi
ndk=$sdk/ndk/$ndk_version
if [ ! -L "$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" ]; then
  rm -rf "$ndk"
  mkdir -p "$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin"
  printf 'Pkg.Desc = Android NDK (stand-in)\nPkg.Revision = %s\n' "$ndk_version" \
    > "$ndk/source.properties"
  ln -s /usr/bin/llvm-strip "$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"
fi

# The Android Gradle Plugin fetches an x86-64 aapt2; use Termux's instead
# (proot-distro makes Termux's files visible in the container). Debian's
# aapt2 is too old to read current Android platforms. Also cap Gradle's
# memory well below the 8 GB the project asks for on a desktop.
aapt2=/data/data/com.termux/files/usr/bin/aapt2
if ! "$aapt2" version; then
  echo "Termux's aapt2 doesn't run in the container; the build would fail." >&2
  exit 1
fi
mkdir -p ~/.gradle
cat > ~/.gradle/gradle.properties <<EOF
android.aapt2FromMavenOverride=$aapt2
org.gradle.jvmargs=-Xmx3g -XX:MaxMetaspaceSize=1g
EOF
