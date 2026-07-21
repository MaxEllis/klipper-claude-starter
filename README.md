# klipper-claude-starter

A template for letting [Claude Code](https://claude.com/claude-code) manage a Klipper printer's config, with git as the source of truth and the printer kept at arm's length.

The Pi's `printer_data/config` gets mirrored into this repo. Claude Code runs on any LAN machine with SSH access to the Pi, reads the rules in `CLAUDE.md`, and drives everything through short `just` commands. It starts in observer mode. Claude can read the printer and pull config into git. It cannot write anything back.

## What's in the box

- `Justfile` with the recipes `just status`, `just diff`, `just pull`, `just logs`, and `just restart`
- `CLAUDE.md`, the rules file Claude Code loads on startup
- `klipper/`, where printer.cfg, macros, and moonraker.conf live under version control
- a pre-commit hook that keeps `.gcode` and anything over 1 MB out of git

## Setup

Takes about ten minutes on a stock MainsailOS or KIAUH install. You need `just`, `rsync`, `jq`, and Claude Code on whichever machine runs this repo. A laptop is fine, though an always-on box is nicer.

1. Clone this repo, or copy the files into a fresh one.
2. Set up key-based SSH to the Pi:
   ```
   ssh-keygen -t ed25519
   ssh-copy-id pi@klipper.local
   ```
3. If the Pi has a different hostname or user, edit the three variables at the top of the `Justfile`.
4. Run `bash scripts/install-hooks.sh`, then `just doctor` to check that SSH and Moonraker both answer.
5. Run `just pull` to bring the live config into `klipper/`, and commit the result as your baseline.
6. Open Claude Code in the repo folder and start asking questions.

## Daily use

All of this is plain conversation with Claude inside the repo:

- "Run just diff and tell me if anything on the printer drifted from the repo"
- "Why is my pressure advance different from the value we set last month?"
- "Write a PRINT_START macro that heats the bed first, then homes, then does an adaptive mesh"
- "Grep the last 500 lines of the log and tell me why Klipper shut down"
- "Explain what max_accel_to_decel does before I change it"

## The safety model

Observer mode is the point of this template. Config flows one way, from the Pi into git, and `just push` exists only to exit with an error. Anything that moves or heats the machine needs an explicit yes from you, every single time; that rule lives in `CLAUDE.md`. Every adopted change is a commit, so the answer to "what changed and when" is one `git log` away, and rollback is a checkout.

Run it read-only for a few weeks before granting more. Nothing is lost by waiting, and you learn how the loop behaves before it can touch the machine.

## Enabling push

Once the loop has earned trust, replace the `push` recipe with the real thing:

```
push:
    @git diff --quiet klipper/ || (echo "klipper/ is dirty; commit first" && exit 1)
    rsync -av --delete klipper/ "{{pi}}:{{cfg_dir}}/"
    ssh {{pi}} "sudo systemctl restart klipper"
```

Update rule 2 in `CLAUDE.md` so the instructions match reality. Keep rule 3, the per-action confirmation for anything destructive, forever.

## Notes

Keep Moonraker on your LAN only. It trusts local clients without authentication by default, so never forward port 7125 (or the Pi at all) to the internet; use a VPN such as Tailscale or WireGuard if you want remote access.

Moonraker is a plain HTTP API on port 7125 and Claude is good at driving it. Live printer state is one curl away: `curl "http://klipper.local:7125/printer/objects/query?print_stats"`

Slicing is deliberately out of scope here, since config management is the safer place to start.

MIT licensed, so adapt it freely.
