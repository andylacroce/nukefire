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

## Using Your Own Characters and Classes

### 1. Create a character profile

Copy an existing profile as a starting point:

```powershell
Copy-Item .\char\mutiny.tin .\char\yourchar.tin
```

Edit `char/yourchar.tin` and set these variables at the top:

```tintin
#VARIABLE {me}          {YourCharName}
#VARIABLE {password}    {$yourchar_password}
#VARIABLE {container}   {bag}        ; loot container keyword
#VARIABLE {remort_num}  {0}          ; your character's remort number
#VARIABLE {tracking_on} {1}          ; 1 = auto-track on, 0 = off
#VARIABLE {class}       {yourclass}  ; matches class/<yourclass>.tin (no extension)
```

The file must end with:

```tintin
#read {nukefire/config/local_secrets.tin}
#VARIABLE {password} {$yourchar_password}
...
#read {nukefire/char_load.tin}
```

`char_load.tin` handles all module loading automatically once `$me` and `$class`
are set.

### 2. Create a class module

Copy the closest existing class as a template:

```powershell
Copy-Item .\class\wolfman.tin .\class\yourclass.tin
```

Edit `class/yourclass.tin`. Key hooks that `char_load.tin` expects:

- `_on_gmcp_vitals` — called on every GMCP vitals update (HP/mana checks,
  auto-heal). Define as `#alias {_on_gmcp_vitals} {#nop}` if unused.
- `_on_gmcp_group` — called on every GMCP group update (healer logic). Define
  as `#alias {_on_gmcp_group} {#nop}` if unused.

The filename (without `.tin`) must match the `$class` variable you set in the
character profile.

### 3. Add a password variable

Open `config/local_secrets.tin` and add a line for your new character:

```tintin
#VARIABLE {yourchar_password} {your_password_here}
```

Also add it to `config/local_secrets.tin.example` (without the real password)
so the template stays current.

### 4. Add the character to the launcher

Open `nukefire.ps1` and follow the existing pattern for each character:

```powershell
# Near the top — define the .tin path
$yourcharTin = Join-Path $NUKE "char\yourchar.tin"

# In the $charsArgs block — add a new tab
" ; new-tab --title YourChar --tabColor `"#RRGGBB`" -d `"$BIN`" $ShellExe -NoExit -File `"$CHARS`" -tin `"$yourcharTin`" -ttExe `"$TTExe`" -delay $startDelaySeconds"
```

### 5. Update the group list in `char_load.tin` (optional)

If your character should be part of the auto-follow group, add it to the
`followers` list near the top of `char_load.tin`:

```tintin
#list {followers} {create} {Mutiny} {Haenym} {Prodigy} {Rancor} {YourCharName}
```

To make a different character the group leader, change:

```tintin
#VARIABLE {leader} {YourLeaderName}
```

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

## Secret Scanning

This repo includes gitleaks setup for secret scanning:

- CI workflow: `.github/workflows/gitleaks.yml`
- Local config: `.gitleaks.toml`

Run it locally (if `gitleaks` is installed):

```powershell
npm run scan:secrets
```

If `gitleaks` is not installed, install it first (Windows):

```powershell
winget install gitleaks.gitleaks
```

## Troubleshooting

- If the launcher throws `TinTin executable not found`, update
   `$NukeTinTinExe` in `config/local_machine.ps1`.
- If `wt` is not found, install Windows Terminal and ensure `wt` is in PATH.
- If login automation fails, verify your `config/local_secrets.tin` variables match
  what your `char/*.tin` profiles expect.

## Contributing

Style rules and contributor workflow are documented in `CONTRIBUTING.md`.
