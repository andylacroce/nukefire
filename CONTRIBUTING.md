# Nukefire TinTin Style Guide

## Purpose

- Describe the canonical header and comment style used across `.tin` files.
- Document contributor rules for local-only config files.

---

## Machine-specific config policy

Never hardcode local paths, usernames, or workstation-only values in tracked
files. The following files are gitignored and must be created locally from
their `.example` templates:

Each has a corresponding `.example` template to copy from:

- `config/local_machine.ps1` — path to `tt++.exe` and optional layout
  overrides
- `config/local_secrets.tin` — character passwords
- `config/local_group.tin` — leader name and followers list
- `config/local_chars.ps1` — character tabs in the launcher

If you introduce a new local-only setting, add it to the relevant `.example`
file and document it in `README.md`.

---

## TinTin file style

### Top-of-file header (required)

Every `.tin` file must start with:

```tintin
#nop =====================================================
#nop MODULE TITLE (ALL CAPS)
#nop Short description of the module
#nop =====================================================
```

### Section separators (required)

Every `.tin` file must have at least one section separator:

```tintin
#nop ------------------ SECTION NAME ------------------
```

Typical section order for **class files**:

- `COMBAT ALIASES`
- `MACROS`
- `SPELL / SKILL UTILITIES`
- `AFX - BUFF MANAGEMENT`
- `EXPERIENCE TRIGGERS`
- `FALL-OFF HANDLERS`
- `GMCP-BASED AUTOHEAL` (or `GMCP-BASED AUTOINVIG` for MV-only classes)
- `AUTOHEAL CONTROL`
- `LEVEL-UP ACTION`

Typical section order for **utility files**:

- `ACTIONS`
- `ALIASES`
- `VARIABLES`
- `CONTROL`

### Inline comments

Use `#nop` for all non-functional comments. Do not use bare `#` (that is
Markdown syntax, not TinTin).

---

## Load order

`char_load.tin` controls the module load sequence. Do not reorder its
`#read` statements unless you understand the dependencies — order matters.

Current load sequence in `char_load.tin`:

1. `config/local_group.tin` — sets `$leader` and `$followers` list
2. Generic shared modules (looting, travel, tracking, etc.)
3. `class/$class.tin` — class-specific aliases and GMCP hooks
4. `leader.tin` or `follower.tin` — role-specific logic
5. `autostart.tin` — MUD connection and login

---

## Do / don't

- **DO** use `_on_gmcp_group` (override the default `#nop` in `char_load.tin`)
  for group heal/invig logic. Do not use a polling ticker with `gr`.
- **DO** use `set_combo <moves>` (defined in `group.tin`) in level-up actions.
- **DO** use `#foreach {$followers[%*]} {follower} { ... }` for iterating
  followers — not a manual `#while` loop with index arithmetic.
- **DO** initialize all toggle variables explicitly at the top of the class
  file (e.g., `#variable {autoheal_on} {1}`) so behaviour on first load is
  defined.
- **DO** put leader/follower group configuration in `config/local_group.tin`,
  not hardcoded in `char_load.tin`.
- **DON'T** commit any of the four gitignored config files listed above.
- **DON'T** use bare `#` comments in `.tin` files.

---

## Linting

A PowerShell linter at `scripts/check_tin_headers.ps1` verifies that every
`.tin` file has a header and at least one section separator. Run it from the
repo root:

```powershell
npm run lint
```

Or without Node:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_linters.ps1
```

`npm run lint` runs both Markdown lint and the TinTin header check. A GitHub
Actions workflow runs the same checks on every push and pull request.

---

## Contributor checklist

Before opening a pull request:

- Run the linter and fix all warnings:

  ```powershell
  npm run lint
  ```

- Run secret scanning and fix any findings:

  ```powershell
  winget install gitleaks.gitleaks   # install once
  npm run scan:secrets
  ```

- Confirm none of the gitignored config files are staged:
  `config/local_machine.ps1`, `config/local_secrets.tin`,
  `config/local_group.tin`, `config/local_chars.ps1`, `logs/`.

- If `char_load.tin` load order changed, explain why in the PR and include
  manual test steps.

- Keep changes non-functional where possible. Functional changes must include
  a description, test steps, and manual verification notes.
