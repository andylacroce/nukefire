# Nukefire TinTin Profiles

TinTin++ character profiles, class modules, and launcher/watch scripts for
playing the Nukefire MUD on Windows with a multi-window layout.

The launcher opens three tiled Windows Terminal windows: one for your
character sessions (one tab per character), one for the live map, and one
for the channel feeds (Gos, Auc, Tel, Yay, GSay).

---

## Table of Contents

- [Setup](#setup)
- [Adapting for Your Characters](#adapting-for-your-characters)
  - [1. Create a character profile](#1-create-a-character-profile)
  - [2. Create a class module](#2-create-a-class-module)
  - [3. Add passwords to local_secrets.tin](#3-add-passwords-to-local_secretstin)
  - [4. Register characters in the launcher](#4-register-characters-in-the-launcher)
  - [5. Configure the group (multi-char only)](#5-configure-the-group-multi-char-only)
- [Understanding How Everything Loads](#understanding-how-everything-loads)
- [Watch Windows](#watch-windows)
- [Local Lint / CI](#local-lint--ci)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Setup

### Step 1 — Install the required tools

#### WinTin++ (TinTin++ for Windows)

[Download the installer](https://tintin.mudhalla.net/download.php) and run
it. Use the default install location — it puts `tt++.exe` at:

```text
C:\Users\<YourName>\AppData\Roaming\WinTin++\bin\tt++.exe
```

#### Windows Terminal

The launcher uses `wt` to open multi-tab windows:

```powershell
winget install Microsoft.WindowsTerminal
```

Open a fresh PowerShell window after installing so `wt` is on your `PATH`.

#### PowerShell 7+ (recommended — Windows 5.1 also works)

```powershell
winget install Microsoft.PowerShell
```

### Step 2 — Clone the repo into the WinTin++ bin folder

> TinTin resolves all `#read` paths relative to the WinTin++ `bin` folder.
> The repo **must be cloned into that folder** and **must be named
> `nukefire`**, or every `#read` will fail at runtime.

```powershell
cd "$env:APPDATA\WinTin++\bin"
git clone https://github.com/andylacroce/nukefire-profiles nukefire
cd nukefire
```

### Step 3 — Copy the config templates

```powershell
Copy-Item .\config\local_machine.ps1.example .\config\local_machine.ps1
Copy-Item .\config\local_secrets.tin.example .\config\local_secrets.tin
Copy-Item .\config\local_group.tin.example   .\config\local_group.tin
Copy-Item .\config\local_chars.ps1.example   .\config\local_chars.ps1
```

These four files are gitignored — they hold your local paths, passwords, and
character setup and are never committed.

### Step 4 — Edit `config/local_machine.ps1`

One required line — replace `YourName` with your Windows username:

```powershell
$NukeTinTinExe = "C:\Users\YourName\AppData\Roaming\WinTin++\bin\tt++.exe"
```

Nothing else needs to change for a standard install.

### Step 5 — Edit `config/local_secrets.tin`

Add a password variable for each character you play. The variable name must
match what the character profile reads (see
[Adapting for Your Characters](#adapting-for-your-characters)):

```tintin
#VARIABLE {yourchar_password} {YourRealPassword}
```

### Step 6 — Edit `config/local_chars.ps1`

List the characters that should appear as tabs in the launcher. One entry
per character:

```powershell
$NukeCharacters = @(
    @{ Name = "YourChar"; Tin = "char\yourchar.tin"; Color = "#4A6B3D" }
)
```

`Name` is the tab label, `Tin` is the profile path relative to the repo
root, `Color` is the tab highlight as `#RRGGBB`.

### Step 7 — Edit `config/local_group.tin` (optional — multi-char only)

Skip this step if you are playing a single character.

Set the leader and the characters that should auto-follow them on login:

```tintin
#VARIABLE {leader} {YourLeader}
#list {followers} {create} {AltChar1} {AltChar2}
```

The leader creates the group and whose session log the map window reads. The
leader should **not** appear in the followers list. For a single character,
leave `config/local_group.tin` as-is — the defaults have no effect when only
one character is running.

### Step 8 — Set the MUD prompt (one time, per character)

After logging in for the first time on each character, type this in-game:

```text
prompt all
```

This tells the MUD to include all values (HP, mana, moves, etc.) in the
prompt line. It persists server-side and only needs to be done once per
character. TinTin `#action` triggers match against the prompt line to detect
events — without this set, those triggers will not fire correctly.

### Step 9 — Launch

```powershell
pwsh -ExecutionPolicy Bypass -File .\nukefire.ps1
```

(Use `powershell` instead of `pwsh` if you are still on PowerShell 5.1.)

When the launcher runs successfully, three Windows Terminal windows open and
tile automatically:

- **Left (full height)** — Character window, one tab per character. Each tab
  connects to the MUD and logs in automatically. After login TinTin splits
  the terminal to show a status bar at the bottom.
- **Top-right** — Map window. Parses the live map from the leader's session
  log and updates as you move. For a solo character it watches that
  character's log. Group member stats (HP/MN/MV/TNL) are pinned to the
  bottom of this window and refresh automatically.
- **Bottom-right** — Comms window with five tabs: Gos, Auc, Tel, Yay, GSay.

If a window does not appear, see [Troubleshooting](#troubleshooting).

---

## Adapting for Your Characters

Follow these steps to replace (or add to) the default characters with your
own. You do not need to touch any of the core `.tin` files except `char/` and
`class/` — everything else is driven by the gitignored config files.

### 1. Create a character profile

Copy an existing profile as a starting point:

```powershell
Copy-Item .\char\mutiny.tin .\char\yourchar.tin
```

Open `char/yourchar.tin` and update the variables at the top:

```tintin
#VARIABLE {me}          {YourCharName}    ; exact in-game name, case-sensitive
#read {nukefire/config/local_secrets.tin}
#VARIABLE {password}    {$yourchar_password}  ; must match a variable in local_secrets.tin
#VARIABLE {container}   {bag}             ; keyword for your loot container
#VARIABLE {remort_num}  {0}               ; your character's remort count
#VARIABLE {tracking_on} {1}               ; 1 = enable auto-track, 0 = disable
#VARIABLE {class}       {yourclass}       ; filename of class module (without .tin)

#read {nukefire/char_load.tin}
```

The `#read {nukefire/config/local_secrets.tin}` line must come _before_
`#VARIABLE {password}` so the password variable is available. Do not remove
the `#read {nukefire/char_load.tin}` at the end — it loads all shared modules.

> **MUD connection**: `autostart.tin` connects to `tdome.nukefire.org 4000`.
> This is fixed for the Nukefire MUD. The login sequence expects the standard
> Nukefire prompts (`What's your name?`, `Password:`, etc.).

### 2. Create a class module

Copy the class closest to your character's combat style:

```powershell
Copy-Item .\class\wolfman.tin .\class\yourclass.tin
```

Open `class/yourclass.tin` and implement (or stub out) these two hooks that
`char_load.tin` expects:

```tintin
#nop Called on every GMCP vitals update. Use for auto-heal, buff checks, etc.
#alias {_on_gmcp_vitals} {#nop}

#nop Called on every GMCP group update. Use for group-heal logic.
#alias {_on_gmcp_group} {#nop}
```

If your class does not need these hooks, define them as `{#nop}` (no-op) as
shown. The filename without `.tin` must match the `$class` variable you set
in the character profile.

Refer to the existing classes for examples:

- `class/gypsy.tin` — combat aliases, macros, spell buffs, GMCP vitals
- `class/wolfman.tin` — melee/combat focus
- `class/heretic.tin` — spellcaster pattern
- `class/headhunter.tin` — ranged/tracking pattern
- `class/_archive/` — older classes kept for reference

### 3. Add passwords to local_secrets.tin

Open `config/local_secrets.tin` and add a line for each new character:

```tintin
#VARIABLE {yourchar_password} {your_password_here}
```

The variable name must match what you used in the character's
`#VARIABLE {password}` line (e.g., `$yourchar_password`).

Also update `config/local_secrets.tin.example` (without the real password)
so others cloning the repo know what variables to create:

```tintin
#VARIABLE {yourchar_password} {your_yourchar_password_here}
```

### 4. Register characters in the launcher

Open `config/local_chars.ps1` and add your character:

```powershell
$NukeCharacters = @(
    @{ Name = "YourChar"; Tin = "char\yourchar.tin"; Color = "#4A6B3D" }
)
```

Each entry becomes one tab in the character window.

- **Name** — tab label in Windows Terminal
- **Tin** — path to the `.tin` profile, relative to the repo root
- **Color** — tab highlight color as `#RRGGBB`

The map window automatically watches the most recently updated session log,
so it will follow whoever is most active (typically your leader).

### 5. Configure the group (multi-char only)

Skip this step if you are playing a single character — the defaults in
`config/local_group.tin` have no effect when only one character is running.

Open `config/local_group.tin` and set your leader and followers:

```tintin
#VARIABLE {leader} {YourLeader}
#list {followers} {create} {AltChar1} {AltChar2}
```

- The **leader** creates the group, starts logging, and whose session log
  the map window reads.
- **Followers** auto-follow the leader on login. The leader should _not_
  appear in this list.

---

## Understanding How Everything Loads

When you launch a character tab, this is the load order:

```text
char/yourchar.tin
  └─ sets $me, reads local_secrets.tin, sets $password, $class, etc.
  └─ reads char_load.tin
       └─ reads config/local_group.tin  → sets $leader, $followers list
       └─ determines is_follower (1/0) based on $me vs $leader
       └─ reads all shared modules:
            looting, travel, tracking, materials, doors,
            remort, eq_mgmt, channels, group, logging
       └─ reads class/$class.tin        → class-specific aliases and hooks
       └─ reads leader.tin  OR  follower.tin  (based on is_follower)
       └─ reads autostart.tin
            └─ reads gmcp.tin
            └─ opens MUD session, logs in, splits terminal
            └─ after login: leader creates group + starts logging
                            followers auto-follow $leader
```

Key points:

- `$me` must be set before `char_load.tin` is read.
- `$class` must match an existing file in `class/` (e.g., `$class = gypsy`
  → `class/gypsy.tin`).
- `local_secrets.tin` is read inside `char/yourchar.tin`, _before_
  `char_load.tin`, so passwords are available when the login actions fire.
- `autostart.tin` calls `afx`, `snapeq`, and `sc` after login. `afx` and
  `snapeq` are MUD commands passed through directly. `sc` is a leader alias
  (group DPS/score); followers just send it as a raw MUD command.

---

## Watch Windows

### Map window

Reads the most recently modified `nukefire_*.log` file in the `logs/`
directory and parses the `[ Local Map ]` blocks that TinTin++ logs from GMCP.
It auto-detects when a new session log starts and follows it.

The leader session now includes a GMCP-driven automapper: `room.info` events
are used to create rooms and exits automatically in TinTin++'s internal map,
so the map builds itself as you move. Followers do not map, only the leader
writes the live map data.

The automapper now autosaves the map file every 2 minutes while enabled and
also saves on disconnect from the leader session. Leaders also run `map_save`
when using `rec`, so the map is written before recall whenever possible.

Note that abruptly closing the window may not trigger a clean disconnect
event, so `map_save` or the autosave interval are the safest ways to preserve
the map.

Map symbols are color-coded: `@` (you), `■` (room), `*` (GPS), `X`
(destination), `!` (locked door), `=`/`:`/`/` (closed door), `|`/`-`
(corridor link).

The map module exposes a few useful commands from the leader session:

- `map_on` / `map_off` — enable or disable automapping
- `map_show` — display the current map followed by the terrain color key
- `map_key` — print the terrain color/symbol legend on its own
- `map_wipe` — erase the stored map and rebuild from the next room
- `map_save` — write the current map graph to `nukefire/maps/nukefire.map`
- `map_status` — show current automapper and map load state
- `map_find`, `map_info`, `map_goto` — helper navigation/debug commands
- `map_debug_toggle` — toggle detailed mapping debug output

Group stats are displayed at the bottom of the map window, pinned to the last
rows regardless of map height. Each member shows level, HP/MN/MV (current and
max), and TNL (time-to-next-level or "Remort" when ready). Values below 50%
of max are highlighted in red. Stats refresh automatically when GMCP group
data updates (at most once every 3 seconds). Only the leader's session writes
stats — followers' sessions are excluded to prevent duplicates.

### Comms window tabs

Each watch script tails the corresponding log file in `logs/` and colorizes
entries. All tabs ring a bell on new messages.

| Tab | Log file | Content |
| --- | -------- | ------- |
| Gos | `gossip.log` | Global gossip channel |
| Auc | `auction.log` | Auction channel |
| Tel | `telepath.log` | Telepath (filters out group-internal and leader traffic) |
| Yay | `broadcast.log` | `(Skynet)` announcements (cyan) and `[GLORY]` kill milestones (yellow) |
| GSay | `group.log` | Group-say channel |

Log files are written by `channels.tin` (part of the shared module set).

---

## Local Lint / CI

Install dev dependencies once:

```powershell
npm ci
```

Run all linters:

```powershell
npm run lint
```

Or use the PowerShell wrapper directly (no Node required):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_linters.ps1
```

Checks include:

- Markdown lint (`README.md`, `CONTRIBUTING.md`)
- TinTin header/section checks (`scripts/check_tin_headers.ps1`) — every
  `.tin` file must start with a `#nop ===...===` header and contain at least
  one `#nop ---...---` section separator.

### Secret scanning

The repo includes a [gitleaks](https://github.com/gitleaks/gitleaks) setup to
prevent credentials from being committed:

```powershell
npm run scan:secrets
```

Install gitleaks if not present:

```powershell
winget install gitleaks.gitleaks
```

CI runs both linters and secret scanning on every push and pull request.

---

## Troubleshooting

**`TinTin executable not found`**
Update `$NukeTinTinExe` in `config/local_machine.ps1` to the full path of
`tt++.exe` on your machine.

**`wt` is not recognized**
Install Windows Terminal from the Microsoft Store or via
`winget install Microsoft.WindowsTerminal`, then open a fresh PowerShell
window so the updated `PATH` is picked up.

**Login fails / wrong password**
Verify that the variable name in `config/local_secrets.tin` matches exactly
what `char/yourchar.tin` references. For example, if the profile reads
`#VARIABLE {password} {$mutiny_password}`, the secrets file needs
`#VARIABLE {mutiny_password} {...}`.

**`#read` file not found errors in TinTin**
The most common cause is that the repo is not in the WinTin++ `bin` folder or
is not named `nukefire`. See [Step 2](#setup) in the setup guide.

**Map window shows nothing / stays blank**
The map window needs a session log to exist before it can display anything.
Launch a character, log in, and move around — TinTin writes the log on first
movement. The map window will pick it up automatically once the log exists.

If the automapper is not building a map, confirm GMCP is negotiated by the
MUD and that the leader session has `room.info` updates enabled.

**Prompt-based triggers not firing**
The MUD prompt must be set to show all values so TinTin actions can match
against it. Log in and type this once — it persists server-side:

```text
prompt all
```

---

## Contributing

Style rules, section header requirements, and the full contributor workflow
are documented in `CONTRIBUTING.md`.
