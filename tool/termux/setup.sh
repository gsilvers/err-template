#!/data/data/com.termux/files/usr/bin/bash
# Sets up Flutter on this phone so you can test and build debug APKs in Termux.
#
# Flutter's SDK only runs on regular (glibc) Linux, so this installs a Debian
# container with proot-distro and puts Flutter and the Android SDK inside it.
# It then installs a `flutter` command in Termux that runs inside the
# container, in whatever folder you are in.
#
# Run it from Termux, from the repo root:  bash tool/termux/setup.sh
# With the first build it downloads about 2 GB and takes up about 5 GB.
# Re-running it is safe, and is how you update the container after
# `flutter upgrade`.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)

pkg install -y proot-distro aapt2

if ! proot-distro list -q | grep -qx debian; then
  proot-distro install debian:trixie
fi

proot-distro login debian -- bash "$here/setup-debian.sh"

install -m 755 "$here/flutter" "$PREFIX/bin/flutter"
[ -e "$PREFIX/bin/dart" ] || ln -s flutter "$PREFIX/bin/dart"

echo
echo "Done. Try:  flutter test"
echo "       and: flutter build apk --debug --target-platform android-arm64"
