# Keyboard Cleaner

A tiny macOS app that locks your keyboard so you can wipe it without typing junk.
Click **Lock Keyboard**, clean, then click **Unlock** with your mouse or trackpad.

To clean the trackpad too, click **Lock Keyboard + Trackpad (30s)**. Everything is locked
and the pointer freezes. It unlocks by itself after 30 seconds, because nothing can click Unlock.

## Download

Get `KeyboardCleaner.zip` from [Releases](../../releases), unzip it, and move the app to Applications.

The app is not notarized by Apple, so the first time you open it:
right-click the app → **Open** → **Open**.
(On newer macOS: System Settings → Privacy & Security → **Open Anyway**.)

## Permissions

Locking the keyboard needs **Accessibility** access.
The first time you click Lock, macOS asks for it. Turn on Keyboard Cleaner in
System Settings → Privacy & Security → Accessibility, then click Lock again.

## What it blocks

- All normal keys, modifier keys (Cmd, Shift, etc.), media and brightness keys
- Trackpad mode: clicks, pointer movement, scrolling, and gestures (pinch, swipe, force click)

It can't block the power button or Touch ID.

## Build from source

Needs Xcode Command Line Tools (`xcode-select --install`).

```sh
./build.sh
unzip -o build/KeyboardCleaner.zip -d build && open "build/Keyboard Cleaner.app"
```

## License

MIT
