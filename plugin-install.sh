#!/usr/bin/env bash
# Install (or uninstall) the pcb-design plugin for Claude Code and/or Codex.
#
# Both CLIs read this directory as a local marketplace through
# .claude-plugin/marketplace.json, and the plugin through .claude-plugin/plugin.json.
#
#   Claude Code loads the plugin in place: edits here take effect at the next
#   session start (or /reload-plugins).
#   Codex copies a snapshot into $CODEX_HOME/plugins/cache: run this script again
#   after editing the skills.
#
# Safe to run again: it re-adds the marketplace and reinstalls the plugin.
# (Inside a function called with ||, set -e is off, so each step says '|| return 1'.)

set -euo pipefail

PLUGIN=pcb-design
MARKETPLACE=pcb-design
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Install the $PLUGIN plugin from $PLUGIN_DIR.

Targets (default: every one whose CLI is on PATH):
  --claude            Claude Code (the 'claude' CLI)
  --codex             Codex (the 'codex' CLI)

Options:
  --uninstall         Remove the plugin and its marketplace instead
  --scope SCOPE       Claude Code scope: user (default), project or local.
                      project/local write to .claude/ in the current directory.
                      Codex has no scopes; it always installs for the user.
  -h, --help          Show this help

Environment: CLAUDE_CONFIG_DIR and CODEX_HOME are honoured, as by the CLIs.
EOF
}

want_claude=0
want_codex=0
uninstall=0
scope=user

while [[ $# -gt 0 ]]; do
    case "$1" in
        --claude) want_claude=1 ;;
        --codex) want_codex=1 ;;
        --uninstall) uninstall=1 ;;
        --scope)
            [[ $# -ge 2 ]] || { echo "error: --scope needs a value" >&2; exit 2; }
            scope="$2"; shift ;;
        --scope=*) scope="${1#--scope=}" ;;
        -h|--help) usage; exit 0 ;;
        *) echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

case "$scope" in
    user|project|local) ;;
    *) echo "error: --scope must be user, project or local (got '$scope')" >&2; exit 2 ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }

# No target named: take every CLI that is installed.
if [[ $want_claude -eq 0 && $want_codex -eq 0 ]]; then
    have claude && want_claude=1
    have codex && want_codex=1
    if [[ $want_claude -eq 0 && $want_codex -eq 0 ]]; then
        echo "error: neither 'claude' nor 'codex' is on PATH" >&2
        exit 1
    fi
fi

for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
    [[ -f "$PLUGIN_DIR/$f" ]] || { echo "error: missing $PLUGIN_DIR/$f" >&2; exit 1; }
done

# Codex prints a harmless warning about temp dirs on some systems; hide only that.
codex_q() { codex "$@" 2> >(grep -v 'failed to clean up stale arg0 temp dirs' >&2); }

failed=0

claude_install() {
    have claude || { echo "error: 'claude' is not on PATH" >&2; return 1; }
    echo "==> Claude Code ($scope scope)"
    claude plugin validate "$PLUGIN_DIR" >/dev/null || {
        echo "error: plugin validation failed; run: claude plugin validate $PLUGIN_DIR" >&2
        return 1
    }
    claude plugin marketplace add --scope "$scope" "$PLUGIN_DIR" || return 1
    # Picks up a changed manifest (a new version) when re-run.
    claude plugin marketplace update "$MARKETPLACE" >/dev/null || return 1
    claude plugin install --scope "$scope" "$PLUGIN@$MARKETPLACE" || return 1
    echo "    Start a new session (or run /reload-plugins) to load the skills."
}

claude_uninstall() {
    have claude || { echo "error: 'claude' is not on PATH" >&2; return 1; }
    echo "==> Claude Code ($scope scope)"
    claude plugin uninstall --scope "$scope" "$PLUGIN@$MARKETPLACE" \
        || echo "    (plugin was not installed)"
    claude plugin marketplace remove "$MARKETPLACE" \
        || echo "    (marketplace was not configured)"
}

codex_install() {
    have codex || { echo "error: 'codex' is not on PATH" >&2; return 1; }
    echo "==> Codex"
    [[ "$scope" == user ]] || echo "    note: Codex has no install scopes; installing for the user."
    codex_q plugin marketplace add "$PLUGIN_DIR" || return 1
    # Re-adding refreshes the cached copy.
    codex_q plugin add "$PLUGIN@$MARKETPLACE" || return 1
    echo "    Codex uses a copy: run this script again after editing the skills."
}

codex_uninstall() {
    have codex || { echo "error: 'codex' is not on PATH" >&2; return 1; }
    echo "==> Codex"
    codex_q plugin remove "$PLUGIN@$MARKETPLACE" \
        || echo "    (plugin was not installed)"
    codex_q plugin marketplace remove "$MARKETPLACE" \
        || echo "    (marketplace was not configured)"
}

if [[ $uninstall -eq 1 ]]; then
    [[ $want_claude -eq 1 ]] && { claude_uninstall || failed=1; }
    [[ $want_codex -eq 1 ]] && { codex_uninstall || failed=1; }
else
    [[ $want_claude -eq 1 ]] && { claude_install || failed=1; }
    [[ $want_codex -eq 1 ]] && { codex_install || failed=1; }
fi

exit $failed
