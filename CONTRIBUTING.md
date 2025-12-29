# Nukefire Tintin Style Guide

Purpose

- Describe the canonical header / comment style used across `.tin`
  files and how to add section separators.

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

- Typical sections include:
  - `ACTIONS`
  - `ALIASES`
  - `AFX - BUFF MANAGEMENT`
  - `AUTO-CAST / TIMER`
  - `TOGGLES`
  - `AUTOHEAL CONTROL`

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
- DON'T: use plain `#` comments in `.tin` files (these are for Markdown).

If you'd like a stricter linter or automatic formatter, I can extend the
script to enforce more rules or fail CI when headers are missing.

---

## Contributor checklist

Before opening a pull request:

- Run the linter and fix warnings:

```powershell
PS> .\scripts\check_tin_headers.ps1
```

- Verify you did not accidentally change `char_load.tin` `#read` order.
  If a load-order change is required, explain why in your PR and include
  manual test steps.
- Keep changes non-functional when possible. When making functional
  changes, include a clear description, test steps, and any manual
  verification notes.
- Do not commit local secrets. Use `local_secrets.tin` in your local
  environment only.

## File-specific suggestions

- Class files (`class/*.tin`): include:
  - `ACTIONS`
  - `ALIASES`
  - `AFX` / `AUTO-CAST / TIMER`
  Consider also `AUTOHEAL CONTROL` and `GROUPCHECK CONTROL` where relevant.
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

To integrate into CI, add a job that runs the script and fails
when it returns non-zero.

A GitHub Actions workflow runs these linters on pushes and pull requests and
will fail the check if any warnings or errors are found. See
`.github/workflows/lint.yml` for details.
