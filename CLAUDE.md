# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

TinTin++ (WinTin++) scripting profiles for playing the *Nukefire* MUD on
Windows, plus a PowerShell launcher that tiles three Windows Terminal windows
(character sessions, live map, channel feeds). There is no application
runtime beyond TinTin++ itself and PowerShell — the "code" is `.tin` script
files (TinTin++'s own scripting language: `#alias`, `#action`, `#variable`,
etc.) and `.ps1` launcher/watch scripts. The npm package only exists to run
Markdown/secret linters; there is no JS application code.

**Critical constraint**: this repo must live at
`%APPDATA%\WinTin++\bin\nukefire` and must be named `nukefire`. TinTin's
`#read` statements are hardcoded with a `nukefire/...` prefix and resolve
relative to the WinTin++ `bin` folder, so the checkout location and directory
name are load-bearing, not cosmetic.

## Commands

```powershell
npm ci                # install devDependencies (markdownlint-cli only)
npm run lint          # markdownlint (README/CONTRIBUTING) + .tin header/section check
npm run lint:md       # markdownlint only
npm run lint:tin      # scripts/check_tin_headers.ps1 only (no Node needed)
npm run scan:secrets  # gitleaks detect --source . --config .gitleaks.toml --redact
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_linters.ps1  # same lint, no Node
pwsh -ExecutionPolicy Bypass -File .\nukefire.ps1   # launch the 3-window session
```

There is no test suite and no build step. "Testing" a change means running
the linters above and then manually launching a character (or the full
`nukefire.ps1` session) in WinTin++ to confirm the behavior. CI
(`.github/workflows/lint.yml`, `.github/workflows/gitleaks.yml`) runs the
lint and secret-scan commands on every push/PR — nothing else.

To lint a single `.tin` file, `scripts/check_tin_headers.ps1` checks the
whole tree; there's no per-file invocation, but you can eyeball a file
against the two rules it enforces (see below).

## Architecture

### Load order is the architecture

Everything hinges on one deterministic `#read` chain kicked off per
character tab. This is the thing to understand before touching almost any
file — reordering it silently breaks logins, class hooks, or logging:

```text
char/<name>.tin              sets $me, reads local_secrets.tin, sets $password/$class/etc.
  -> char_load.tin
       -> config/local_group.tin        sets $leader, $followers list
       -> derives $is_follower (${me} == ${leader} ? 0 : 1)
       -> generic modules, in order:
            looting -> travel -> tracking -> materials -> doors -> remort -> eq_mgmt -> group
       -> class/$class.tin               class-specific aliases + GMCP hooks
       -> follower.tin  OR  leader.tin   (role-specific; loaded last so they win)
       -> channels.tin, logging.tin      loaded last so class/role actions take priority
       -> autostart.tin
            -> gmcp.tin
            -> opens MUD session, logs in, splits terminal
            -> leader creates group + starts logging; followers auto-follow $leader
```

Each character `.tin` file (`char/*.tin`) is a thin entry point: set a
handful of variables, then `#read char_load.tin`. All shared behavior lives
in the generic modules and is never duplicated per-character.

### Class plugin contract

`class/*.tin` files are the extension point for per-character combat
behavior. `char_load.tin` defines default no-op hooks before reading the
class file, so every class **may** override:

- `_on_gmcp_vitals` — fires on every GMCP vitals update (auto-heal, buff checks)
- `_on_gmcp_group` — fires on every GMCP group update (group-heal logic)

A class that doesn't need a hook must still define it as `{#nop}` — there is
no fallback if it's omitted incorrectly. Reference implementations:
`class/gypsy.tin` (buffs/macros), `class/wolfman.tin` (melee),
`class/heretic.tin` (spellcaster), `class/headhunter.tin` (ranged/tracking).
`class/_archive/` holds retired classes kept only for reference — don't wire
them into `char_load.tin`.

### Leader/follower split

Every session is either the leader or a follower, decided by comparing `$me`
to `$leader` (set in `config/local_group.tin`, gitignored). Only the leader:
writes the live map data and group/stat logs, autosaves the map, and creates
the group. Followers auto-follow and mostly relay commands to the leader
(e.g., `report`/`o` broadcast patterns in `group.tin`). When adding a new
shared feature, check whether it needs a leader/follower branch — most
GMCP-driven logging explicitly guards on `!$is_follower` to avoid duplicate
writes (see the `group` GMCP handler in `gmcp.tin`).

### GMCP as the data backbone

`gmcp.tin` negotiates GMCP and populates the `$gmcp[...]` associative array
from server events (`char.vitals`, `char.status`, `group`, `room.info`,
etc.). Class hooks and the automapper are driven by these events firing, not
by polling — e.g. `_on_gmcp_vitals` fires per vitals push, `_map_on_room_info`
(in `map.tin`) fires per room-info push. New reactive behavior should hook
into these GMCP events rather than adding a `#ticker` poll loop (see the
CONTRIBUTING "DO" list: no polling ticker for group logic).

### Map subsystem

`scripts/map_watch.ps1` is a standalone watcher (not loaded by TinTin) that
tails the most-recently-modified `logs/nukefire_*.log`, parses the
`[ Local Map ]` blocks TinTin logs from GMCP `room.info`, and renders a
color-coded ASCII map plus pinned group stats in its own Windows Terminal
tab. The in-session half lives in `map.tin`, which builds TinTin++'s internal
map graph automatically from `room.info` events (autosave every 2 minutes,
plus on disconnect/`rec`) and exposes `map_on`/`map_off`/`map_show`/
`map_wipe`/`map_save`/`map_status`/`map_find`/`map_goto`/`map_debug_toggle`.
Only the leader session maps; follower sessions never write map data.

### Launcher (`nukefire.ps1`) window choreography

`nukefire.ps1` is a self-elevating PowerShell script (re-execs itself once
via `$env:NUKEFIRE_LAUNCHED` to avoid stale `Add-Type` state), then uses
P/Invoke (`user32.dll`/`dwmapi.dll`) to enumerate Windows Terminal windows by
class name, measure their DWM shadow insets, and position three `wt`
instances into a tiled layout (chars left, map top-right, comms
bottom-right). It clears the five comms log files at session start. Local
overrides (`NukeBin`, `NukeTinTinExe`, `NukeRepoRoot`, `NukeLogsPath`,
`NukeCharsWidthFraction`, `NukeStartDelaySeconds`) come from
`config/local_machine.ps1` (gitignored); character tabs come from
`config/local_chars.ps1` (gitignored). Window-position logic is timing- and
Windows-Terminal-version-sensitive (see the inline comments about
`SetWindowLong`/`SWP_FRAMECHANGED` avoiding WT's own restore logic) — treat
edits here as fragile and test by actually launching, not by inspection.

### Watch scripts (comms tabs)

`scripts/*_watch.ps1` (gossip, auction, telepath, group, broadcast, all) are
independent `Get-Content -Wait`-style tailers over the log files that
`channels.tin` writes, each with its own colorization/filtering (e.g.
`telepath_watch.ps1` filters out group-internal and leader traffic;
`broadcast_watch.ps1` uses `scripts/broadcast_config.ps1` for the
`(Skynet)`/`[GLORY]` pattern-to-color mapping). They're launched as tabs by
`nukefire.ps1` and have no other coupling to the TinTin side beyond the log
file format.

## Config and secrets model

Four files are gitignored and drive all machine/character-specific behavior;
everything else in the repo is shared/generic:

| File | Purpose |
| --- | --- |
| `config/local_machine.ps1` | `tt++.exe` path, launcher layout overrides |
| `config/local_secrets.tin` | character passwords |
| `config/local_group.tin` | `$leader` / `$followers` |
| `config/local_chars.ps1` | character tabs shown in the launcher |

Each has a tracked `.example` counterpart. **Any new local-only setting must
be added to the relevant `.example` file and documented in README.md** — this
is an explicit CONTRIBUTING.md rule, not a suggestion. `.gitleaks.toml`
allowlists only `config/local_secrets.tin.example` (placeholders); real
secrets files must never be staged.

## `.tin` file conventions (enforced by `npm run lint:tin`)

Every `.tin` file must have, checked by `scripts/check_tin_headers.ps1`:

1. A top-of-file header in the first 10 lines:
   ```tintin
   #nop =====================================================
   #nop MODULE TITLE (ALL CAPS)
   #nop Short description of the module
   #nop =====================================================
   ```
2. At least one section separator anywhere in the file:
   ```tintin
   #nop ------------------ SECTION NAME ------------------
   ```

Other conventions from CONTRIBUTING.md worth knowing before editing `.tin`
files:

- Comments are always `#nop` — never a bare `#` (that's Markdown syntax, not
  TinTin, and will be misparsed).
- Class files follow a canonical section order: COMBAT ALIASES, MACROS,
  SPELL/SKILL UTILITIES, AFX - BUFF MANAGEMENT, EXPERIENCE TRIGGERS,
  FALL-OFF HANDLERS, GMCP-BASED AUTOHEAL (or AUTOINVIG), AUTOHEAL CONTROL,
  LEVEL-UP ACTION.
- Utility files follow: ACTIONS, ALIASES, VARIABLES, CONTROL.
- Iterate followers with `#foreach {$followers[%*]} {follower} { ... }`, not
  a manual `#while` with index arithmetic.
- Initialize toggle variables explicitly at the top of class files (e.g.
  `#variable {autoheal_on} {1}`) so first-load behavior is defined.
- Group heal/invig logic belongs in `_on_gmcp_group`/`_on_gmcp_vitals`
  overrides, not a polling ticker.

## PR expectations (from CONTRIBUTING.md)

- Run `npm run lint` and `npm run scan:secrets` before opening a PR.
- Confirm none of the four gitignored config files (or `logs/`) are staged.
- If `char_load.tin`'s load order changed, explain why and include manual
  test steps — there's no automated test to catch a regression here.
- Prefer non-functional changes; functional changes need a description, test
  steps, and manual verification notes since nothing here is unit-testable.
