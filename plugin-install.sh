#!/usr/bin/env bash
# Install (or uninstall) the pcb-design plugin for Claude Code and/or Codex.
#
#   plugin-install.sh setup        put this script on PATH (~/.local/bin/plugin-install.sh)
#   plugin-install.sh [targets]    install into the current directory (the default)
#   plugin-install.sh --user       install for the user, in every directory
#
# Where it goes, per target and scope:
#
#   Claude Code, project/local   the plugin is enabled in ./.claude/settings.json
#                                (local: ./.claude/settings.local.json) and loaded in place
#                                from this repository: edits here take effect at the next
#                                session start (or /reload-plugins).
#   Claude Code, user            the same, in the user's settings.
#   Codex, project/local         the skills are copied into ./.agents/skills/ (Codex has no
#                                project-scoped plugins; it reads repo skills from there).
#   Codex, user                  the plugin is installed through Codex's marketplace, which
#                                copies it into $CODEX_HOME/plugins/cache.
#
# Codex always uses a copy: run this script again after editing the skills.
# Safe to run again: it re-adds the marketplace and reinstalls the plugin.
# (Inside a function called with ||, set -e is off, so each step says '|| return 1'.)

set -euo pipefail

PLUGIN=pcb-design
MARKETPLACE=pcb-design
SCRIPT_NAME=plugin-install.sh
# Resolve the symlink that 'setup' puts on PATH, so the plugin is found from anywhere.
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PLUGIN_DIR="$(dirname "$SCRIPT_PATH")"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
# Marks a Codex project skill as ours, so we never overwrite or delete anyone else's.
CODEX_MARKER=".installed-by-$PLUGIN"

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME setup [--uninstall]
       $SCRIPT_NAME [claude] [codex] [options]

Install the $PLUGIN plugin from $PLUGIN_DIR.

Commands:
  setup               Link this script into $BIN_DIR, so that
                      '$SCRIPT_NAME' works from any directory.
                      'setup --uninstall' removes the link.

Targets (default: every one whose CLI is on PATH):
  claude, --claude    Claude Code (the 'claude' CLI)
  codex,  --codex     Codex (the 'codex' CLI)

Scope (default: project, i.e. the current directory):
  --user, --global    Install for the user, available in every directory
  --scope SCOPE       project (default), local or user
                        project  Claude: ./.claude/settings.json
                                 Codex:  skills copied into ./.agents/skills/
                        local    Claude: ./.claude/settings.local.json (not committed)
                                 Codex:  same as project
                        user     Claude: user settings; Codex: marketplace plugin

Options:
  --uninstall         Remove the plugin (from the same scope) instead
  -h, --help          Show this help

Examples:
  ./$SCRIPT_NAME setup                 # once, from the plugin's repository
  cd ~/my-board && $SCRIPT_NAME        # this directory, every CLI found
  $SCRIPT_NAME claude                  # this directory, Claude Code only
  $SCRIPT_NAME codex --user            # Codex, for the user
  $SCRIPT_NAME claude --uninstall      # remove it from this directory

Environment: CLAUDE_CONFIG_DIR and CODEX_HOME are honoured, as by the CLIs;
XDG_BIN_HOME overrides the setup directory.
EOF
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- setup

do_setup() {
    local remove=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall) remove=1 ;;
            -h|--help) usage; exit 0 ;;
            *) echo "error: unknown option for setup: $1" >&2; exit 2 ;;
        esac
        shift
    done

    local link="$BIN_DIR/$SCRIPT_NAME"
    if [[ $remove -eq 1 ]]; then
        if [[ -L "$link" ]]; then
            rm "$link"
            echo "Removed $link"
        elif [[ -e "$link" ]]; then
            echo "error: $link is not a link made by setup; leaving it alone" >&2
            exit 1
        else
            echo "$link is not installed"
        fi
        return
    fi

    mkdir -p "$BIN_DIR"
    if [[ -e "$link" && ! -L "$link" ]]; then
        echo "error: $link exists and is not a link; move it away first" >&2
        exit 1
    fi
    # A link, not a copy: the script finds the plugin through it, and stays current.
    ln -sfn "$SCRIPT_PATH" "$link"
    echo "Linked $link -> $SCRIPT_PATH"
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) echo "note: $BIN_DIR is not on PATH; add it, e.g. in ~/.bashrc:"
           echo "      export PATH=\"$BIN_DIR:\$PATH\"" ;;
    esac
    echo "Keep the repository at $PLUGIN_DIR: the link and Claude Code installs point there."
}

if [[ "${1:-}" == setup ]]; then
    shift
    do_setup "$@"
    exit 0
fi

# ---------------------------------------------------------------- install

want_claude=0
want_codex=0
uninstall=0
scope=project

while [[ $# -gt 0 ]]; do
    case "$1" in
        claude|--claude) want_claude=1 ;;
        codex|--codex) want_codex=1 ;;
        --uninstall) uninstall=1 ;;
        --user|--global) scope=user ;;
        --scope)
            [[ $# -ge 2 ]] || { echo "error: --scope needs a value" >&2; exit 2; }
            scope="$2"; shift ;;
        --scope=*) scope="${1#--scope=}" ;;
        -h|--help) usage; exit 0 ;;
        *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

case "$scope" in
    user|project|local) ;;
    *) echo "error: --scope must be project, local or user (got '$scope')" >&2; exit 2 ;;
esac

# In the home directory, ./.claude/settings.json IS the user settings file.
if [[ "$scope" != user && "$(pwd -P)" == "$(cd "$HOME" && pwd -P)" ]]; then
    echo "error: the current directory is your home directory; cd into a project," >&2
    echo "       or pass --user to install for every directory" >&2
    exit 2
fi

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

where() {
    if [[ "$scope" == user ]]; then echo "user"; else echo "$scope: $PWD"; fi
}

# Codex prints a harmless warning about temp dirs on some systems; hide only that.
codex_q() { codex "$@" 2> >(grep -v 'failed to clean up stale arg0 temp dirs' >&2); }

failed=0

claude_install() {
    have claude || { echo "error: 'claude' is not on PATH" >&2; return 1; }
    echo "==> Claude Code ($(where))"
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
    echo "==> Claude Code ($(where))"
    claude plugin uninstall --scope "$scope" "$PLUGIN@$MARKETPLACE" \
        || echo "    (plugin was not installed)"
    claude plugin marketplace remove --scope "$scope" "$MARKETPLACE" \
        || echo "    (marketplace was not configured)"
}

codex_user_install() {
    have codex || { echo "error: 'codex' is not on PATH" >&2; return 1; }
    echo "==> Codex (user)"
    codex_q plugin marketplace add "$PLUGIN_DIR" || return 1
    # Re-adding refreshes the cached copy.
    codex_q plugin add "$PLUGIN@$MARKETPLACE" || return 1
    echo "    Codex uses a copy: run this script again after editing the skills."
}

codex_user_uninstall() {
    have codex || { echo "error: 'codex' is not on PATH" >&2; return 1; }
    echo "==> Codex (user)"
    codex_q plugin remove "$PLUGIN@$MARKETPLACE" \
        || echo "    (plugin was not installed)"
    codex_q plugin marketplace remove "$MARKETPLACE" \
        || echo "    (marketplace was not configured)"
}

# Project scope for Codex: copy each skill into ./.agents/skills/<name>/.
codex_project_install() {
    echo "==> Codex ($(where))"
    local dest="$PWD/.agents/skills" src name n=0
    if [[ "$(cd "$PLUGIN_DIR" && pwd -P)" == "$(pwd -P)" ]]; then
        echo "error: this is the plugin's own repository; cd into a project first" >&2
        return 1
    fi
    mkdir -p "$dest" || return 1
    for src in "$PLUGIN_DIR"/skills/*/; do
        name="$(basename "$src")"
        if [[ -e "$dest/$name" && ! -e "$dest/$name/$CODEX_MARKER" ]]; then
            echo "    skip $name: $dest/$name exists and was not installed by this script" >&2
            failed=1
            continue
        fi
        rm -rf "${dest:?}/$name" || return 1
        cp -R "$src" "$dest/$name" || return 1
        echo "$PLUGIN_DIR" > "$dest/$name/$CODEX_MARKER"
        n=$((n + 1))
    done
    echo "    Copied $n skills into $dest"
    echo "    Codex uses a copy: run this script again after editing the skills."
}

codex_project_uninstall() {
    echo "==> Codex ($(where))"
    local dest="$PWD/.agents/skills" d n=0
    if [[ -d "$dest" ]]; then
        for d in "$dest"/*/; do
            [[ -e "$d$CODEX_MARKER" ]] || continue
            rm -rf "$d" || return 1
            n=$((n + 1))
        done
        rmdir "$dest" "$PWD/.agents" 2>/dev/null || true
    fi
    if [[ $n -eq 0 ]]; then echo "    (no skills were installed here)"; else echo "    Removed $n skills from $dest"; fi
}

if [[ $uninstall -eq 1 ]]; then
    [[ $want_claude -eq 1 ]] && { claude_uninstall || failed=1; }
    if [[ $want_codex -eq 1 ]]; then
        if [[ "$scope" == user ]]; then codex_user_uninstall || failed=1
        else codex_project_uninstall || failed=1; fi
    fi
else
    [[ $want_claude -eq 1 ]] && { claude_install || failed=1; }
    if [[ $want_codex -eq 1 ]]; then
        if [[ "$scope" == user ]]; then codex_user_install || failed=1
        else codex_project_install || failed=1; fi
    fi
fi

exit $failed
