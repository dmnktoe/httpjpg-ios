#!/bin/sh
set -eu

build="$(git -C "$SRCROOT" rev-list --count HEAD)"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${build}" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
