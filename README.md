> Source: these skills are adapted from [`CLAUDE_PCB.md`](https://github.com/gallicchio/GPiBridge/blob/main/CLAUDE_PCB.md) in [gallicchio/GPiBridge](https://github.com/gallicchio/GPiBridge). All credit for the rules and lessons goes to its original author.

# pcb-design

A Claude Code plugin: the PCB design lessons of `CLAUDE_PCB.md`
(github.com/gallicchio/GPiBridge), split into skills that load only when a task needs them.

| skill | covers (CLAUDE_PCB.md) |
|---|---|
| `pcb-workflow` | entry point: how to work, build system, verification gates (§1, §2, §10) |
| `pcb-design-review` | outside LLM reviews: the `design_reviews/` layout and brief (§1) |
| `record-lesson` | turning a new request or fault into a rule in the right skill |
| `pcb-schematic` | schematics to the Art of Electronics standard (§4) |
| `pcb-silkscreen` | the board explains itself (§6) |
| `pcb-layout` | placement, routing, mechanical (§5, §7) |
| `jlcpcb-order` | parts, sourcing, manufacturing package, CPL rotations (§3, §8) |
| `pcb-bringup` | bring-up and debuggability (§9) |
| `component-selection` | real components, power, current, magnetics (§12, §15) |
| `boards-for-children` | toy-safety rules (§16) |
| `kicad-scripting` | KiCad 10, pcbnew Python, ngspice and tooling quirks (§11) |
| `highspeed-digital` | fast digital (§13) |
| `rf-design` | RF (§14) |

The dated lessons (§17-29, and the PID motor board's lessons in §6) are filed under
the skill they belong to.

## Install

`plugin-install.sh` installs the plugin for Claude Code and Codex. Both CLIs read this
directory as a local marketplace (`.claude-plugin/marketplace.json`).

```sh
./plugin-install.sh                  # every CLI found on PATH (claude, codex)
./plugin-install.sh --claude         # Claude Code only
./plugin-install.sh --codex          # Codex only
./plugin-install.sh --claude --scope project   # Claude Code, this project only
./plugin-install.sh --uninstall      # remove it again (combine with --claude/--codex)
```

- **Claude Code** loads the plugin in place: edits to the skills take effect at the next
  session start, or after `/reload-plugins`.
- **Codex** installs a copy under `$CODEX_HOME/plugins/cache/`: run the script again after
  editing the skills.
- Running it again is safe; it re-adds the marketplace and reinstalls.

By hand, the same thing is:

```sh
claude plugin marketplace add /path/to/pcb-design && claude plugin install pcb-design@pcb-design
codex plugin marketplace add /path/to/pcb-design && codex plugin add pcb-design@pcb-design
```

To try it for one Claude Code session without installing: `claude --plugin-dir /path/to/pcb-design`.
