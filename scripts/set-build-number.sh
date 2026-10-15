#!/bin/sh
# Stamps the built Info.plist with the repository's commit count, so every
# commit gets its own CFBundleVersion without a bot commit bumping a file.
set -eu

plist="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

if ! git -C "$SRCROOT" rev-parse --git-dir >/dev/null 2>&1; then
  echo "warning: no git checkout; CFBundleVersion stays ${CURRENT_PROJECT_VERSION}"
  exit 0
fi

# A shallow clone counts only the fetched commits, which would hand out a
# number lower than earlier builds.
if [ "$(git -C "$SRCROOT" rev-parse --is-shallow-repository)" = "true" ]; then
  echo "warning: shallow clone; CFBundleVersion stays ${CURRENT_PROJECT_VERSION}"
  exit 0
fi

build="$(git -C "$SRCROOT" rev-list --count HEAD)"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${build}" "$plist"
echo "CFBundleVersion = ${build}"
