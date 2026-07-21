#!/usr/bin/env bash
# Install the pre-commit hook that blocks .gcode and files over 1 MB.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
cat > .git/hooks/pre-commit <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
fail=0
while IFS= read -r f; do
  case "$f" in
    *.gcode|*.3mf) echo "blocked: $f (print files do not belong in git)"; fail=1 ;;
  esac
  if [ -f "$f" ] && [ "$(wc -c < "$f")" -gt 1048576 ]; then
    echo "blocked: $f (over 1 MB)"; fail=1
  fi
done < <(git diff --cached --name-only --diff-filter=ACM)
exit $fail
HOOK
chmod +x .git/hooks/pre-commit
echo "pre-commit hook installed"
