# Nukefire TinTin Profiles

A set of TinTin++ profiles and helper scripts for running the
Nukefire characters.

## Overview

- Purpose: convenience profiles for multiple characters (`Mutiny`,
  `Haenym`, etc.).
- Includes autostart, logging, autoloot, travel/tracking shortcuts,
  equipment management, and follower/group helpers.
- Platform: Windows (the included `nukefire.bat` launches Windows Terminal tabs).

## Files

- `nukefire.bat` — Launcher script.
  Edit `BIN`, `COLS`, and `LINES` to match your environment and
  terminal size. By default it uses `wt` (Windows Terminal) to open
  tabs running `t++.exe` with profile files.
- `*.tin` — TinTin++ profile modules:
  - Character profiles are stored in `char/` (e.g., `char/*.tin`).
  - Class and role modules are stored in `class/` (e.g., `class/*.tin`).
  - Utility modules live at the repository root (e.g., `remort.tin`, `leader.tin`).
  - Utilities & features:
    - `char_load.tin` — Generic loader for common and class modules.
    - `autostart.tin` — Autostart session mappings and login hooks.
    - `autoloot.tin`, `logging.tin`, `tracking.tin`, `travel.tin`,
      `looting.tin`, `materials.tin`, `eq_mgmt.tin`, `follower.tin`,
      `group.tin`, `channels.tin`, `doors.tin`, `sleep.tin` —
      utility modules and aliases.
  - `local_secrets.tin` — Local passwords and secrets file
    (gitignored).
  - `local_secrets.tin.example` — Template to copy when creating
    `local_secrets.tin`.
- `.gitignore` — ensures `local_secrets.tin` and the `logs/` folder are not committed.

## Setup

1. Install TinTin++ (t++.exe) and ensure it's available.
1. Edit `nukefire.bat` to point `BIN` at the folder containing
   `t++.exe`. Example:

   ```bat
   set "BIN=C:\Users\YourName\AppData\Roaming\WinTin++\bin"
   ```

1. Create or edit `local_secrets.tin` to include your character
   passwords. This file is intentionally ignored by git (see
   `.gitignore`). Example contents:

   ```tintin
   #VARIABLE {mutiny_password} {your_mutiny_password_here}
   #VARIABLE {haenym_password} {your_haenym_password_here}
   ```

1. (Optional) Adjust terminal width and height in `nukefire.bat`
   by changing `COLS` and `LINES`.

1. Launch the batch script (double-click or run it from cmd). It
   will open Windows Terminal tabs and start TinTin++ with the
   configured profiles.

If you prefer not to use `wt`, you can run TinTin++ directly
from a command prompt:

```cmd
%BIN%\t++.exe -r "nukefire\char\mutiny.tin"
```

## Important Configuration Notes

- `local_secrets.tin` holds plaintext passwords and is Git-ignored —
  do not commit this file.
- `nukefire.bat` controls how profiles are launched; uncomment or add
  additional `wt` tabs to run more characters.
- Logs are written to `nukefire/logs/`. They use the filename pattern
  `nukefire_${me}_${LOGTIME}.log` when `logging_on` is executed.

## Common Commands & Aliases

- Auto-loot: `aloot` toggles autoloot on/off (`aloot_on` / `aloot_off`).
- Logging: `logging` toggles logging on/off (`logging_on` / `logging_off`).
- Tracking: `tracking` toggles tracking on/off; use `trk <name>` to
  track a target.
- Travel/GPS: `gs <n>` sets GPS, `gf <name>` finds GPS, and `rd` runs
  the current destination. Location aliases exist (e.g., `ama`,
  `crim`, `nuc`).
- Looting: `gall`, `gc`, `ret` and container shortcuts (`ls`, `gg`,
  `ps`).
- Group/follower helpers: auto-following; use `rep` to report.
  Aliases: `sl` / `slw` / `wa` for sleep/wake actions.

## Autostart Notes

- `autostart.tin` contains `#session` and `#action` mappings to
  respond to the MUD's login prompts automatically. This includes
  name/password prompts and initial menu choices. Adjust if your MUD
  uses different prompts or flows.

## Security & Privacy

- Keep `local_secrets.tin` private. The repository already ignores
  this file.
- Logs may contain sensitive session data — the `logs/` folder is
  ignored by git. Rotate or remove logs as needed.

## Troubleshooting

- If `wt` is not found, ensure Windows Terminal is installed and
  available in PATH, or change `nukefire.bat` to run the client
  directly, for example:

  `cmd /k "%BIN%\t++.exe" -r "nukefire\char\mutiny.tin"`.
- If aliases or modules don't load, confirm `BIN` paths.
  Also confirm `local_secrets.tin` exists and has your password
  variables defined.

## Quickstart checklist ✅

Follow this short checklist to get the repository ready and start a session:

1. Copy the example secrets file and edit it with your passwords:

   ```bat
   copy local_secrets.tin.example local_secrets.tin
   ```

2. Edit `nukefire.bat` to set `BIN` to the folder containing `t++.exe`.

3. (Optional) Adjust terminal width and height in
   `nukefire.bat` by changing `COLS` and `LINES`.

4. Launch the launcher (double-click or run from cmd):

   ```bat
   nukefire.bat
   ```

5. Verify logs are created in the `logs/` folder and that
   `local_secrets.tin` is not committed to git.

---

If you want, I can add more examples for class modules or a brief
troubleshooting checklist.
