#!/bin/sh
# Turns a fresh copy of the template into your app. Run it once, from the
# repo root, right after creating the repo:
#
#   tool/rename.sh blerr "Blerr" io.github.gsilvers.blerr
#
# The arguments are the Dart package name (lowercase letters, digits and _),
# the name shown on the phone, and the Android application ID.
set -eu

if [ $# -ne 3 ]; then
  sed -n '2,8s/^# \{0,1\}//p' "$0" >&2
  exit 1
fi
name=$1
label=$2
id=$3

old_name=err_template
old_label='Err Template'
old_id=io.github.gsilvers.err_template
old_kotlin_dir=android/app/src/main/kotlin/io/github/gsilvers/err_template

fail() {
  echo "rename.sh: $*" >&2
  exit 1
}

echo "$name" | grep -Eq '^[a-z][a-z0-9_]*$' ||
  fail "the package name must be lowercase letters, digits and _, starting with a letter"
echo "$id" | grep -Eq '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$' ||
  fail "the application ID must look like io.github.you.appname (lowercase, dot-separated)"
case $label in
  *[\"\\\$\'/\&\`]*) fail "keep the label to letters, digits, spaces and simple punctuation" ;;
esac
[ -f "$old_kotlin_dir/MainActivity.kt" ] ||
  fail "run this from the root of a fresh copy of the template"

# The application ID contains the package name, so it is replaced first.
for f in pubspec.yaml lib/main.dart test/widget_test.dart AGENTS.md \
  android/app/build.gradle.kts "$old_kotlin_dir/MainActivity.kt"; do
  sed -e "s/$(echo "$old_id" | sed 's/\./\\./g')/$id/g" \
    -e "s/$old_label/$label/g" \
    -e "s/$old_name/$name/g" "$f" > "$f.tmp"
  mv "$f.tmp" "$f"
done

new_kotlin_dir=android/app/src/main/kotlin/$(echo "$id" | tr . /)
mkdir -p "$new_kotlin_dir"
mv "$old_kotlin_dir/MainActivity.kt" "$new_kotlin_dir/MainActivity.kt"
rmdir -p "$old_kotlin_dir" 2> /dev/null || true

# The template's README is about the template; start the app's own.
cat > README.md <<EOF
# $label

What $label does, in a sentence or two.

## Getting it onto your phone

Every push to \`main\` builds a signed APK and publishes it as a GitHub
release. Point [Obtainium](https://github.com/ImranR98/Obtainium) at this
repo to install it and get updates.

## Developing

- [docs/macos.md](docs/macos.md): set up and build on a Mac
- [docs/termux.md](docs/termux.md): set up and build on the phone, in Termux
- [docs/releases.md](docs/releases.md): how CI builds, signs and releases
EOF

echo "Renamed to $name ($label, $id)."
echo "Check 'git status' and 'git diff', then commit."
