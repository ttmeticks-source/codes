# OceanForge

An original 3D ship-and-ocean sandbox for macOS, built with Swift, SceneKit and AppKit.

## System requirements

- macOS 11.0 (Big Sur) or later.
- Apple's standalone **Command Line Tools** with Swift.
- Internet access for downloading the source.
- No Xcode.app, Xcode project, or Xcode installation is required.

## Install using Terminal

Copy and paste this single command:

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/codes/main/install.sh | bash
```

The installer:
1. Confirms the Mac is running macOS 11.0 or newer.
2. Uses the standalone Command Line Tools toolchain at `/Library/Developer/CommandLineTools`.
3. Downloads the source archive directly from GitHub (it does not use the GitHub Releases API).
4. Builds the app with Swift Package Manager.
5. Creates and ad-hoc signs `OceanForge.app`.
6. Installs it in `/Applications`, or `~/Applications` if the system Applications folder is not writable.

If Command Line Tools are missing, install them with:

```bash
xcode-select --install
```

That command installs Apple's command-line developer tools only; you do not need to install or open the Xcode app. After the installation finishes, run the OceanForge install command again.

## Build manually

From a clone of this repository:

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
```

The app bundle is created at `build/OceanForge.app`.

## Compatibility

The installer blocks macOS versions older than 11.0. The app bundle also declares `LSMinimumSystemVersion=11.0`.

OceanForge is an original project inspired by the ship-and-water sandbox genre. It does not contain Floating Sandbox's proprietary code or assets.
