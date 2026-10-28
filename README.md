# Quick Space Switch

Quick Space Switch is a macOS menu bar app that switches Spaces with no slide animation. It works from the trackpad, from keyboard shortcuts, and from Logitech mouse gestures.

Quick Space Switch is a fork of [InstantSpaceSwitcher](https://github.com/jurplel/InstantSpaceSwitcher) by jurplel. The instant switch is jurplel's work. This fork adds instant Control+Arrow switching, removes the app's event taps when macOS revokes its Accessibility permission, and ships a signed and notarized build.

## What it does

- Switches Spaces instantly from a horizontal trackpad swipe, if you turn on "Override swipe gesture".
- Switches Spaces instantly from Control+Left Arrow and Control+Right Arrow. This is on by default.
- Switches to a numbered Space, the last Space, or the next Space with configurable keyboard shortcuts.
- Shows the current Space number in the menu bar.
- Uses the native macOS Spaces and does not require you to disable System Integrity Protection.

## Logitech mouse gestures

Logi Options+ can map a mouse gesture, such as a middle-button drag on an MX Anywhere, to "Switch between desktops". Logi Options+ sends that gesture as a Control+Arrow key press, so macOS plays the slide animation.

With "Make Control+Arrow switching instant (Logitech gestures and keyboard)" turned on in Settings > General, Quick Space Switch catches the Control+Arrow press and switches instantly. The setting also applies to Control+Arrow on a physical keyboard. Control+Arrow with Command, Option, or Shift held passes through unchanged.

## Install

1. Download the latest `QuickSpaceSwitch-<version>.dmg` from [GitHub Releases](https://github.com/rav4nn/QuickSpaceSwitch/releases).
2. Open the DMG and drag Quick Space Switch to the Applications folder.
3. Open Quick Space Switch from the Applications folder.
4. When macOS asks, allow Quick Space Switch in System Settings > Privacy & Security > Accessibility.

The release build is signed with a Developer ID and notarized by Apple, so it opens without a Gatekeeper warning.

## Accessibility permission

Quick Space Switch needs the Accessibility permission to read trackpad gestures and shortcut keys, and to post the switch.

If you turn the permission off while the app runs, Quick Space Switch removes its event taps within a second. Your keyboard keeps working. When you turn the permission back on, the app installs the taps again without a restart.

## Command-line tool

The app bundle includes a command-line tool:

```sh
/Applications/QuickSpaceSwitch.app/Contents/MacOS/QSSCli right
/Applications/QuickSpaceSwitch.app/Contents/MacOS/QSSCli left
/Applications/QuickSpaceSwitch.app/Contents/MacOS/QSSCli index 3
```

The terminal app that runs `QSSCli` needs the Accessibility permission.

## Build from source

You need Xcode or the Xcode Command Line Tools on macOS 13 or later.

```sh
git clone https://github.com/rav4nn/QuickSpaceSwitch
cd QuickSpaceSwitch
./dist/build.sh
open ./build/QuickSpaceSwitch.app
```

`dist/build.sh` builds a universal app for Apple silicon and Intel with an ad-hoc signature. macOS ties the Accessibility permission to the signature, so after each rebuild you may have to remove the old entry in System Settings and allow the app again.

To run the tests:

```sh
swift test
```

### Signed release

`dist/release.sh` builds the app, signs it with a Developer ID, makes a DMG, notarizes the DMG, and staples the ticket. It needs a Developer ID Application certificate and a stored notarytool profile:

```sh
xcrun notarytool store-credentials <profile>
SIGN="Developer ID Application: <Name> (<Team ID>)" NOTARY_PROFILE=<profile> ./dist/release.sh
```

## How the instant switch works

macOS has no setting to turn off the Space switch animation. InstantSpaceSwitcher posts a synthetic trackpad swipe with a very high velocity, and the Dock completes the switch without the slide. Quick Space Switch uses the same method for trackpad swipes, keyboard shortcuts, and Control+Arrow.

## License

MIT. See [LICENSE](LICENSE). The original code is copyright jurplel. The changes in this fork are copyright Hardeep Singh.
