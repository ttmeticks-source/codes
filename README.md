# OceanForge

An original 3D ship-and-ocean sandbox for macOS, built with Swift, SceneKit and AppKit.

## Download the app

**No compiler, Xcode, Command Line Tools, or Terminal build is needed.**

Download the ready-made app bundle:

[Download OceanForge for macOS](https://github.com/ttmeticks-source/codes/releases/download/latest/OceanForge-macOS.zip)

1. Open the downloaded ZIP.
2. Drag `OceanForge.app` into Applications.
3. Open OceanForge.

Requires macOS 11.0 (Big Sur) or later. The downloadable app is built by GitHub Actions on a macOS runner and targets macOS 11.0.

## Build from source (optional)

Only needed if you want to compile the project yourself:

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
```

The app bundle is created at `build/OceanForge.app`.

## Compatibility

The app bundle declares `LSMinimumSystemVersion=11.0`.

OceanForge is an original project inspired by the ship-and-water sandbox genre. It does not contain Floating Sandbox's proprietary code or assets.
