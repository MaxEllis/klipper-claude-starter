# Claude-managed Klipper config — observer-mode Justfile.
# Requires: just, ssh key auth to the Pi, curl, jq, rsync.
set shell := ["bash", "-euo", "pipefail", "-c"]

pi      := "pi@klipper.local"
mr      := "http://klipper.local:7125"
cfg_dir := "/home/pi/printer_data/config"
log     := "/home/pi/printer_data/logs/klippy.log"

# Show the available recipes.
default:
    @just --list --unsorted

# Health check. Run once after setup and after any Justfile change.
doctor:
    @ssh -o ConnectTimeout=3 -o BatchMode=yes {{pi}} true 2>/dev/null || (echo "SSH to {{pi}} failed — is the Pi on the LAN and mDNS resolving?" && exit 1)
    @curl -sS --max-time 3 "{{mr}}/server/info" >/dev/null || (echo "Moonraker unreachable at {{mr}}" && exit 1)
    @echo "OK"

# git status + live printer state.
status:
    @git status --short
    @echo "--"
    @curl -sS --max-time 3 "{{mr}}/printer/info" | jq -r '.result | "state=\(.state) klipper=\(.software_version)"' 2>/dev/null || echo "(printer unreachable — check LAN + mDNS)"

# Drift preview, read-only: what differs between the Pi and the repo.
diff:
    @echo "=== would PULL (Pi -> repo) ==="
    rsync -avn --delete "{{pi}}:{{cfg_dir}}/" klipper/ | sed '/^receiving /d;/^sent /d;/^total /d;/^$/d'

# Pull the live config from the Pi into klipper/. Fails if klipper/ is dirty.
pull:
    @git diff --quiet klipper/ || (echo "klipper/ is dirty — commit or stash first" && exit 1)
    rsync -av --delete "{{pi}}:{{cfg_dir}}/" klipper/
    @git status klipper/

# Tail the Klipper log from the Pi. `just logs` = 200 lines; `just logs 500` bumps it.
logs n="200":
    ssh {{pi}} "tail -n {{n}} {{log}}"

# Restart Klipper via Moonraker.
restart:
    curl -sS -X POST "{{mr}}/machine/services/restart?service=klipper" | jq .

# Observer mode: pushing config TO the Pi is deliberately disabled.
# Enable it only after you have run read-only for a while and trust the loop.
push:
    @echo "push is disabled in observer mode. See README.md#enabling-push." && exit 2
