#!/bin/sh
# Builds "Keyboard Cleaner.app" into ./build and zips it for release.
set -e
APP="build/Keyboard Cleaner.app"
rm -rf build && mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp cat.png lock.gif AppIcon.icns "$APP/Contents/Resources/"
swiftc -O main.swift -o "$APP/Contents/MacOS/KeyboardCleaner"
codesign --force -s - "$APP"
(cd build && ditto -c -k --keepParent "Keyboard Cleaner.app" KeyboardCleaner.zip)
# Drop the unzipped app so Spotlight does not list a second copy.
rm -rf "$APP"
echo "Built build/KeyboardCleaner.zip"
