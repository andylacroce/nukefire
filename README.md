# Nukefire TinTin Profiles

TinTin++ profiles, class modules, and launcher/watch scripts for running the
Nukefire character set on Windows.

## Overview

- Main launcher: `nukefire.ps1` (PowerShell)
- Character profiles: `char/*.tin`
- Class modules: `class/*.tin`
- Shared modules: root `*.tin` files (for logging, travel, group/follower,
  channels, etc.)
- Watch tools: `scripts/map_watch.ps1`, `scripts/gossip_watch.ps1`,
  `scripts/telepath_watch.ps1`, `scripts/auction_watch.ps1`
- CI/local lint scripts: `scripts/check_tin_headers.ps1`,
  `scripts/run_ci_linters.ps1`, and `npm run lint`

## Local Config Files

Two files are intentionally local-only and gitignored:

- `config/local_secrets.tin`: passwords and other sensitive TinTin variables
- `config/local_machine.ps1`: machine-specific launcher settings (paths/layout)

Templates are provided:

- `config/local_secrets.tin.example`
- `config/local_machine.ps1.example`

## Setup

1. Install prerequisites:
   - TinTin++ (`tt++.exe`)
   - Windows Terminal (`wt`)
   - PowerShell
1. Create your local secrets file:

   ```powershell
   Copy-Item .\config\local_secrets.tin.example .\config\local_secrets.tin
   ```

1. Create your local machine config:

   ```powershell
   Copy-Item .\config\local_machine.ps1.example .\config\local_machine.ps1
   ```

1. Edit `config/local_machine.ps1` and set at least:
   - `$NukeBin` (WinTin++ bin folder)
   - `$NukeTinTinExe` (full path to `tt++.exe`)

1. Launch:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\nukefire.ps1
   ```

## What the Launcher Opens

`nukefire.ps1` opens three Windows Terminal windows:

- Character window with tabs for Mutiny, Haenym, Prodigy, and Rancor
- Map window running `scripts/map_watch.ps1`
- Comms window running gossip/telepath/auction watcher tabs

It also tiles the windows on screen and focuses the character window at the
end.

## Local Lint / CI

Install dev dependencies once:

```powershell
npm ci
```

Run all linters:

```powershell
npm run lint
```

Or run the PowerShell wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_linters.ps1
```

Checks currently include:

- Markdown lint (`README.md`, `CONTRIBUTING.md`)
- TinTin header/section checks (`scripts/check_tin_headers.ps1`)

## Troubleshooting

- If the launcher throws `TinTin executable not found`, update
   `$NukeTinTinExe` in `config/local_machine.ps1`.
- If `wt` is not found, install Windows Terminal and ensure `wt` is in PATH.
- If login automation fails, verify your `config/local_secrets.tin` variables match
  what your `char/*.tin` profiles expect.

## Contributing

Style rules and contributor workflow are documented in `CONTRIBUTING.md`.
