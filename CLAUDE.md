# CLAUDE.md — rules for Claude working in this repo

## What this repo is

Source of truth for my Klipper printer config. The Pi (`pi@klipper.local`,
Moonraker on :7125) holds the live config at `/home/pi/printer_data/config/`;
the `klipper/` folder here mirrors it. Drift is made visible with `just status`
and `just diff`, and adopted into git with `just pull`.

## Rules (load-bearing)

1. **Always run `just status` before any mutation.** Prefer the Justfile
   recipes; prefer the smallest change that does the job (one file over a
   wholesale rsync, a service restart over a reboot).
2. **`just push` is disabled.** This repo runs observer-only: read the Pi,
   pull config into git, never write config back. If a change needs to land
   on the printer, propose it and wait for me to apply it or to enable push.
3. **Destructive operations need my explicit confirmation every time** —
   restarting Klipper, starting or cancelling a print, setting temperatures,
   anything that moves the machine or heats it. No batching confirmations.
4. **Never commit `.gcode` files or anything over 1 MB.** The pre-commit hook
   rejects them; do not bypass it with `--no-verify`.
5. **Commit message convention:** `adopt: ...` for config pulled from the Pi,
   `doc: ...` for docs, `chore: ...` for tooling.

## Useful facts

- Live printer state: `curl http://klipper.local:7125/printer/objects/query?extruder&heater_bed&print_stats`
- Klipper log: `just logs` (or more lines with `just logs 500`)
- Klipper config reference: https://www.klipper3d.org/Config_Reference.html
