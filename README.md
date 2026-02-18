# Parallax

Parallax is a macOS menu bar app for fast, isolated task workspaces from your local git repos.

It is built for people who jump between many projects and want clean context per task without manual setup.

## How it works

1. Parallax scans your configured project folders for git repositories.
2. You pick a repo and enter a task name.
3. Parallax creates a full copy workspace at:
   - `<workspace_root>/<repo>__<task-slug>`
4. It creates and checks out:
   - `agent/<task-slug>`
5. It opens that workspace in your preferred editor.

When you are ready, you can merge back by fetching the workspace branch into the source repo.

## Why full-copy workspaces

Parallax uses full filesystem copies by design:

- Strong isolation between tasks.
- No shared `.git` internals between source and workspace.
- Simple mental model: each workspace is a standalone repo copy.

## Keyboard shortcuts

- `Cmd+P`: toggle Parallax panel
- `Cmd+,`: open Settings
- `Cmd+B`: merge selected workspace back to source
- `Shift+Delete`: delete selected workspace
- Arrow keys + Enter: navigate/open/create

## Data files

Parallax stores local app data in:

- `~/Library/Application Support/Parallax/settings.json`
- `~/Library/Application Support/Parallax/history.json`
- `~/Library/Application Support/Parallax/workspaces.json`

`workspaces.json` maps each workspace path to its source repo path and branch for safe merge-back targeting.

## Install and run

Download the latest app bundle from GitHub Releases, unzip, and launch `Parallax.app`.

Note: release artifacts are currently unsigned. On first launch, macOS may require approval in Privacy & Security.

## Build from source (CLI)

Prerequisites:

- Xcode
- Xcode command line tools
- XcodeGen (`brew install xcodegen`)

From a fresh clone:

```bash
xcodegen generate
```

Debug build + run:

```bash
xcodebuild -project Parallax.xcodeproj -scheme Parallax -configuration Debug -derivedDataPath build/DerivedData build
open build/DerivedData/Build/Products/Debug/Parallax.app
```

Release build + run:

```bash
xcodebuild -project Parallax.xcodeproj -scheme Parallax -configuration Release -derivedDataPath build/DerivedData clean build
open build/DerivedData/Build/Products/Release/Parallax.app
```

Regenerate app icons (optional):

```bash
swift scripts/generate_app_icon.swift Parallax/Resources/Assets.xcassets/AppIcon.appiconset
```

`project.yml` is the source of truth for project generation.
