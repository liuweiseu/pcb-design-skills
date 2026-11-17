---
name: record-lesson
description: Turn a user request or a found fault into a permanent PCB design rule, written with its reason and citation into the right skill of the pcb-design plugin, in the house style. Use whenever the user asks for something on a board that should hold for every board ("from now on", "always", "never", "next time", "put this in the lessons"), corrects a design, or when a fab, preview, reviewer, DRC/ERC, simulation or the bench finds a fault.
---

# Record a lesson

**Every request is a lesson.** When the user asks for something on one board it goes into the
rules at once, as a rule with its reason, so the user never asks for it again on the next board
(ECP5 P26, the user: "Put this requirement and lessons on how to do it in CLAUDE_PCB.md. Do that
for all such requests and lessons"). The same goes for every fault a fab, a preview, a reviewer,
a check or a working board found. The rules exist because of exactly these: "Every rule here is
something the user had to ask for, or a fault that a fab, a reviewer or a working board found."

## When

- At once, in the same session as the request or the finding; not at the end of the board.
- For a request: when it is general (it would apply to the next board), not a one-off choice
  about this board's content.
- For a fault: when it was found by DRC/ERC, a check, the eye on a render, JLCPCB's preview, a
  reviewer, a simulation or the bench, and a rule or a check would have caught it earlier.
- Also fix it on this board, and **grep every board that copies the part or the function it
  names, the same day** (pcb-workflow skill, "A fix found on one board goes to every board").

## Where: by topic, never in a dated log

Put the lesson beside the rules on the same topic, in the skill that covers it. Do not append
it to a "lessons from <board> (<date>)" list: a dated log is read by nobody choosing a rule for
the topic at hand. The date and board go in the citation instead.

| skill | topic: put a lesson here when it is about |
|---|---|
| `pcb-workflow` | how the user works (logging, questions, rev A, git, licence, minimising the user's steps, the agent's own background processes); the build system, relative paths, single sources of truth, generators, scripted edits, renames, determinism; generated documents and fitted pages; the verification gates, including the power-pin, pair-polarity and standard-connector checks |
| `pcb-design-review` | outside LLM reviews: `design_reviews/` layout, the brief, the report, reconciling, rounds |
| `record-lesson` | how lessons themselves are recorded (this skill) |
| `pcb-schematic` | schematics to the Art of Electronics standard: drawing, symbols, values and design equations, netlist checks |
| `pcb-silkscreen` | the board explains itself: labels, boxes, text sizes, the back as a manual, drawn symbols on copper |
| `pcb-layout` | placement, routing, pours, vias, courtyards; mechanical: connectors, cables, enclosure |
| `jlcpcb-order` | parts and sourcing, LCSC codes, stock, the manufacturing package, CPL rotations and JLCPCB's preview, the order page |
| `pcb-bringup` | bring-up plans, test points, debuggability, what to measure first |
| `component-selection` | choosing real components; power, current capacity, heat, magnetics, fuses |
| `boards-for-children` | toy safety and boards for children |
| `kicad-scripting` | KiCad 10, pcbnew Python, kicad-cli, ngspice, and tooling quirks |
| `highspeed-digital` | fast digital: clocks, memory, differential pairs, escape routing |
| `rf-design` | RF: lines, launches, matching, decoupling at RF, stitching, simulation as laid out |
| `analog-signals` | accurate analog signals: ADC/DAC paths, references, tuning voltages, loop filters, high-impedance nodes; ground under them, amplifier slew across the band |

- Choose by the lesson's **primary** topic: what a reader would be doing when they need it. A
  silk clearance learned on an RF board goes to `pcb-silkscreen`.
- If it truly spans two, write it once in the main skill and add a one-line pointer in the
  other ("see the jlcpcb-order skill, ...").
- A general rule in `highspeed-digital`, `rf-design`, `analog-signals`, `component-selection` or
  `boards-for-children` that a board has now taught the hard way: rewrite it beside the others
  in that skill with the board's citation.
- **SKILL.md or references/?** The rule itself (one bold-lead bullet) goes in the skill's
  `SKILL.md` under the right heading. A long worked example, a table, numbers from one board, or
  a recipe goes in that skill's `references/*.md`, with the rule in SKILL.md pointing to it. Keep
  SKILL.md under about 350 lines; if it would pass that, move detail out, not rules.
- Before adding, search the skill (and the plugin) for the topic. If a rule already says it,
  sharpen that rule and add the new citation instead of writing a second one. If the new lesson
  contradicts an old one, rewrite the old one and say what changed.

## How: the house style

- **A bold lead that is the rule, in the imperative or as a plain statement of fact.** Then the
  reason, then the evidence, then how to check it. Example shape:
  `- **Count pads, not pad numbers.** Four BNC posts numbered "2" collapsed to one in a dict
  keyed by number: 9 joints a board went missing from the cost.`
- **The reason is required.** A rule without its reason is not followed when it is
  inconvenient. Give the failure it prevents, with the real numbers (mm, mA, W, dB, °C, part
  codes, tool versions).
- **The citation is required**: board and prompt or round ("(Lorenz P3)", "(GPSDO r29)",
  "(ECP5 P31)"), or board and date ("(op-amp, 2026-10-24)"), or the source ("(Rosenberg)"). When
  the user asked for it, quote the user's words verbatim, attributed to "the user", with the
  prompt or date.
- **Make it checkable.** Say what the build or a script asserts, and name the check that now
  does (`scripts/check_overlay.py`, `tools/doc_check.py`). If no check exists, say how to check
  it by eye or by hand. A rule that a check enforces is worth more than one that must be
  remembered.
- **Generic, not personal.** Write "the user", not a name; no absolute local paths, no personal
  or family details; relative paths and public URLs only.
- Plain English, short sentences, numbers with units. Sub-bullets for lists of cases. No
  emojis.
- Name tools and files as they are in the board's project, so a reader can find them.

## Then

- Tell the user in the response which skill and file the lesson went into, and quote the rule.
- If the lesson changes a verification gate, update `pcb-workflow`'s
  `references/verification-gates.md` and the gate summary in its SKILL.md.
- Log it in the board's `CLAUDE_CODE_CHAT.md` as part of the response (pcb-workflow skill).
