# Nukefire Tintin Style Guide

Purpose

- Describe the canonical header / comment style used across `.tin`
  files and how to add section separators.
- Document contributor rules for local-only machine settings.

Machine-specific config policy

- Do not hardcode local paths, usernames, or workstation-only values in tracked
  scripts.
- Put machine-local launcher settings in `config/local_machine.ps1`
  (gitignored), using
  `config/local_machine.ps1.example` as the template.
- Keep secrets in `config/local_secrets.tin` (gitignored), using
  `config/local_secrets.tin.example` as the template.
- If you introduce a new local-only setting, add it to the relevant `.example`
  file and document it in `README.md`.

Top-of-file header

- Use Tintin comments (`#nop`) only in `.tin` files.
- Use the following pattern at the top of each module:

```tintin
#nop =====================================================
#nop MODULE TITLE (ALL CAPS)
#nop Short description of the module
#nop =====================================================
```

Section separators

- For major blocks, use:

```tintin
#nop ------------------ SECTION NAME ------------------
```

- Typical sections for class files (in order):
  - `CORE: STATE & HELPERS`
  - `SPELL / SKILL UTILITIES`
  - `AFX: SPELL LISTENERS & TIMER`
  - `FALL-OFF HANDLERS`
  - `LEVEL-DRIVEN ACTIONS`
  - `GMCP GROUP AUTOHEAL` (or `GMCP GROUP AUTOINVIG` for MV-only classes)
  - `AUTOHEAL CONTROL`
  - `LEVEL-UP ACTION`
- Typical sections for utility files:
  - `ACTIONS`
  - `ALIASES`
  - `VARIABLES`
  - `CONTROL`

Inline comments

- Use `#nop` for non-functional comments and notes.
- Keep comments short and descriptive.

Load order note

- The `char_load.tin` file contains module `#read` statements that define startup
  order. Do not reorder these reads unless you understand the dependencies. Re-
  ordering can break initialization.

Linter

- A basic PowerShell linter is available at `scripts/check_tin_headers.ps1`.
- Run it from the `nukefire` directory:

```powershell
PS> .\scripts\check_tin_headers.ps1
```

- The linter checks that each `.tin` file has a top `#nop ===` header.
- It also checks for at least one `#nop ------------------` section separator.
- The linter prints warnings and exits non-zero when issues are found.

Local CI (run the same checks locally)

- Option A (npm):

```powershell
# install dev deps once
npm ci

# run both linters (Markdown + Tintin headers)
npm run lint
```

- Option B (PowerShell wrapper):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ci_linters.ps1
```

These run the same checks as CI and will exit non-zero if any
warnings or errors are found.

Do/don't

- DO: add `#nop` headers and section separators to improve readability.
- DO: avoid changing functional code. Only add comments or separators
  unless explicitly requested.
- DO: externalize machine-local paths/settings to `config/local_machine.ps1`.
- DON'T: use plain `#` comments in `.tin` files (these are for Markdown).
- DON'T: commit `config/local_machine.ps1` or `config/local_secrets.tin`.
- DO: use `set_combo <moves>` (defined in `group.tin`) in level-up actions
  instead of the three-line `combo` / `#var group_combo` / `groupassist_group`
  pattern.
- DO: use `#foreach {$followers[%*]} {follower} { ... }` for iterating
  followers instead of a manual `#while` loop with index arithmetic.
- DO: implement group heal/invig via `_on_gmcp_group` (override the default
  `#nop` set in `char_load.tin`). Do not use a polling ticker with `gr`.
- DO: initialize all toggle variables explicitly at the top of the class file
  (e.g., `#variable {autoheal_on} {1}`) so behaviour on first load is defined.

If you'd like a stricter linter or automatic formatter, I can extend the
script to enforce more rules or fail CI when headers are missing.

---

## Contributor checklist

Before opening a pull request:

- Run the linter and fix warnings:

```powershell
PS> npm run lint
```

- Run secret scanning and fix findings:

```powershell
# install once (Windows)
PS> winget install gitleaks.gitleaks

PS> npm run scan:secrets
```

- Ensure machine-specific changes are in `config/local_machine.ps1.example` documentation,
  not in tracked runtime config files.
- Ensure no local-only files are staged (`config/local_machine.ps1`,
  `config/local_secrets.tin`, logs).

- Verify you did not accidentally change `char_load.tin` `#read` order.
  If a load-order change is required, explain why in your PR and include
  manual test steps.
- Keep changes non-functional when possible. When making functional
  changes, include a clear description, test steps, and any manual
  verification notes.
- Do not commit local secrets. Use `config/local_secrets.tin` in your local
  environment only.

## File-specific suggestions

- Class files (`class/*.tin`): follow the canonical section order listed above.
  Use `GMCP GROUP AUTOHEAL` (not a polling ticker) for group heal/invig logic.
  Use `AUTOHEAL CONTROL` for the `autoheal_on` / `autoheal_off` / `autoheal` toggle.
- Utility files (root `.tin`): include top header + sections such as:
  - `ACTIONS`
  - `ALIASES`
  - `LISTENERS`
  - `VARIABLES`
  - `CONTROL`

## Examples

Top header (required):

```tintin
#nop =====================================================
#nop MODULE TITLE (ALL CAPS)
#nop Short description of the module
#nop =====================================================
```

Section separator example:

```tintin
#nop ------------------ ACTIONS ------------------
```

## Linter / CI

The repository includes a small PowerShell linter at
`scripts/check_tin_headers.ps1` which verifies headers and
section separators.

`package.json` also defines:

- `npm run lint:md`
- `npm run lint:tin`
- `npm run lint`

To integrate into CI, add a job that runs the script and fails
when it returns non-zero.

A GitHub Actions workflow runs these linters on pushes and pull requests and
will fail the check if any warnings or errors are found. See
`.github/workflows/lint.yml` for details.
