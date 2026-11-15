---
name: pcb-schematic
description: Drawing and checking schematics to the Art of Electronics standard - signal flow, notes at the node, labels, symbols, decoupling, net names, pin checks against datasheets, and the netlist checks every schematic gets (one-pin nets, rails, fuses, straps, op-amp ranges, design equations). Use when generating, drawing, reviewing or checking a KiCad schematic, a schematic generator, its overlap checker, symbols, net labels or netlist assertions.
---

# Schematics: the Art of Electronics standard

The user worked with Paul Horowitz. The bar is a schematic drawn so that every question a
reader would ask is answered at the place they would ask it (GPSDO P7, ECP5 P1).

Reference files (read when the task touches them):
- `references/text-and-overlap.md`: KiCad's real text extents, the overlap checker, the
  PDF check, and how GPSDO's checker passed for weeks with four faults. Read before
  writing or trusting any overlap check.
- `references/netlist-checks.md`: the full Rosenberg checklist with its board stories
  (fuses, ORing, straps, safe idle states, op-amp ranges, equation inputs). Read when
  writing or running the build's netlist checks, or reviewing power, protection and
  control lines.
- `references/dated-lessons.md`: later lessons from CostasLink, the tile boards (AMOD,
  RF-MOD) and the PID motor board: late-added parts, hand-drawn filters, tile net
  namespaces, generic blocks, distributor pin checks, shared SPI outputs, KiCad's y-up
  symbol coordinates.

For a board whose silkscreen *is* the schematic (teaching boards), see the
pcb-silkscreen skill's `references/teaching-boards.md`.

## Flow and sheets

- **Flow.**
  - Signals go left to right and power comes from the top.
  - Series parts are horizontal on the signal line; shunts are vertical, hanging off
    the node.
  - Draw it as the circuit is understood, not as the netlist happens to connect.
- **No disappearing labels.** A label that vanishes and reappears elsewhere is allowed
  only for power and ground. Wire it if you can (Icepi P27: "connect it with a wire
  rather than a label").
- **Sheets.** The user almost never prints: a big sheet that keeps a long signal path and
  its parallel copies together beats several small ones, and a net label that goes off
  to some other page ("possibly more than one -- who can tell?") is what the user
  dislikes most (ECP5 P26). Keep every drawing inside the page's border and out of the
  title block's corner; the generator's margin check fails on either.
- **The drawing:** few wire crossings, sheets in order from input to output, and a
  block diagram first when there are many sheets. Rosenberg allows labels for buses
  and MCU I/O; the user's rule (wires, not labels) stands.
- **Repeated blocks** are identical pages or identical tiles, differing only in names, so
  paging through the PDF shows the pattern. A missing 13th copy leaves a blank in the
  same place (GPSDO P4).

## Notes on the sheet

- **Notes at the node.**
  - Put voltage ranges, frequencies, rise times and impedances **right at the node**
    they describe, in small boxes with small arrows to the probe point (GPSDO P6, P7).
  - Notes are short columns broken at logical places (after a sentence, before a
    formula), 50-70 characters wide like a newspaper column, never one long line across
    the top of a sheet that needs zooming and dragging to read (GPSDO P7, P8, ECP5 P26).
    Size the box to the text: a box narrower than its longest line re-wraps the line
    ends and strands a word ("to") on a line of its own.
  - Prefer "just in time" notes beside the block they describe over one essay at the
    top: the gain and noise list under the pair of amplifiers it describes, "THS4521
    fully-differential driver at gain 1" right above its block, block titles centred
    on their block (ECP5 P26).
  - A comment that says which of two chips a series resistor belongs beside goes next
    to the resistor, sideways if need be: "I can read small amounts of sideways text".
- **Why boxes.** Explain why a part was chosen ("74LVC1GU04: U = unbuffered; LVC =
  5.5 V tolerant at 3.3 V"), and when to fit each jumper ("50 Ω: fit for all but the
  ZED-F9T").
- **Limits at every connector:** maximum DC, Vpp before clipping, Vpp before damage,
  and output ranges (Icepi P15, GPSDO P21).
- **Every IC's box opens with what the part is**: "PE43711, RF digital step attenuator: 0
  to -31.75 dB in 0.25 dB steps", "THS4541, fully differential amplifier", "MAX2871, PLL
  frequency synthesizer (23.5 MHz to 6.0 GHz)", then the detail of its use. A student
  reads the function before the part number (the user, CostasLink Prompt 35). A sheet carries no
  record of the designer's mistakes ("the OPA2187 first drawn here needed 4.5 V..."):
  that is the chat log's job.
- **Comments must not go stale.** A note that names "U112", or a part that is no longer
  there, is a bug. Say "the LM27761 here", and regenerate notes from data (Icepi P27,
  GPSDO r28 #9).
- **Characters:** KiCad's stroke font has ± (U+00B1); write "±13 V", not "+/-13 V", on the
  sheet and on the board (op-amp board).

## Labels, text and overlap

- **Labels in a row stand alike** (CostasLink Response 15; the user, of the board's SMAs:
  "their labels should all be in the same relative orientation: for example, all above and
  closest to the thing they refer to or all Southwest and closest to the thing they label.
  This consistency requirement needs to be enforced"). It holds on the sheet as on the
  board.
  - Parts drawn in a row or a column (jacks, taps, test pads, jumpers, the four copies of
    a channel) carry their names, limits and notes in one relation to each part: the same
    side, the same offset, nearest their own part, never between two of them.
  - Draw every copy with one function, so the relation is the same by construction, and
    have the overlap check report a label nearer another member of the row than its own.
- **Nothing overlaps anything.** No text, reference or value overlaps a symbol, wire,
  box or other text, and everything stays inside the page border.
  - Check it in code and by looking at the exported PDF (Lorenz P1, GPSDO P5, P6).
  - The usual offenders: references on vertical R/C, GND flags on decoupling caps,
    notes next to GND symbols.
  - Model a text's real extent, not its anchor; test wires against text boxes and text
    against symbol bodies, not only text against text; then check the exported PDF's
    word boxes. Numbers and the checker's pitfalls: `references/text-and-overlap.md`.
  - **A checker that passes is only as good as its model of KiCad** (GPSDO,
    2026-10-10). Calibrate the model against a render whenever the eye sees what the
    check does not.
  - Hide every field but reference and value: a footprint suffix ("K1A2") printed in the
    middle of a BAV99 is a question the user will ask (ECP5 P26).
- **Net names.** Sensible, especially on long runs and anything leaving a page. Avoid
  names that read like other buses (`FPGA_SCLK_OUT` looked like I²C's SCL, Icepi P16).
  Never name a node after a part that exists ("C2" for a collector node beside a
  bypass C2): name it by part and pin, "Q2 C" (op-amp board; see pcb-silkscreen).
  A net that leaves its tile or block needs a board-wide name from the start
  (`/ENC_DO`); short local names (`G`) merge silently with a helper's
  (`references/dated-lessons.md`).

## Symbols

- **Symbols the right way up.** No upside-down GND flags or `+3V3` arrows pointing down
  with upside-down text. No PWR_FLAG left floating in a corner (GPSDO P8, Icepi P15,
  P29). Grounds point down, except where ground really is above (the -15 V decoupling)
  or the geometry forces it (op-amp and PID boards).
- **Hierarchical and global arrows** are justified so they do not overlap boxes. They
  point the way the signal goes (bidirectional only when it is), and their names say
  where they go ("…_FPGA") (Icepi P14, P15, GPSDO P10).
- **A sheet pin's name reads inside its sheet box**, as KiCad draws its own (a left pin's
  text runs right). kisch had them outside, so a net label on the wire beside the pin
  printed the name twice ("double labels", CostasLink Prompt 35).
- **A coaxial jack's pin faces the line.** Conn_Coaxial has its pin on the left and its
  shield below: an input drawn at rot 0 puts its body under the first series part ("C101
  right on top of the SMA connector"), an output at rot 180 puts the ground on top. Draw
  an input mirrored (pin on the right, the jack first on the line), an output at rot 0, a
  monitor jack upright with the ground below (CostasLink Prompt 35).
- **Do not split ICs into many sub-symbols.**
  - The power pins stay on the IC; never a separate rectangle that looks like another
    chip (Icepi P15, P16).
  - Big multi-function parts are the exception. The ADC/DAC is drawn as one trapezoid
    per channel plus a common box, with a dashed box around all of them, and so are
    multi-unit symbols such as the PHY and the FTDI (ECP5 P2).
  - When a chip is split (dual op amps), its units get a dashed box, and the power unit
    sits under the gap between the two amplifier units with room round it: nothing
    else inside the box, no wire through it (ECP5 P26: a tap's ground sat on an
    OPA1612's power unit, a wire ran through another).
  - A converter is drawn like a MUX: the long side of the trapezoid is the digital
    bus, the short side the analog signal, and the clock comes in from below and turns
    up into the bottom edge like a flip-flop's clock. Control lines (WRT, CLK) come
    from the left, lower than the trapezoid, and turn up into it (ECP5 P26).
  - Each amplifier keeps its "entourage of passives" (feedback, gain, compensation)
    drawn around it, and placed around it on the board.
- **Decoupling.** One capacitor per supply pin, drawn **at that pin**, never bunched off
  to the side. The PCB then places each one at its pin (Icepi P28, P29).
- **No four-way junctions.** Fix the ERC warnings that matter, refresh cached symbols,
  and save in KiCad 10's own format (`kicad-cli sch upgrade`) so opening the file asks
  nothing (Icepi P16).

## Pins and paths

- **Pins.** Check every pin of every generated symbol against the datasheet's pin
  **figure**. ECP5 found, all with checks passing:
  - an FDA's output pair swapped, making positive feedback;
  - a mini-HDMI with type-A numbering;
  - a SOT-23-6 EEPROM numbered like a SOIC;
  - a bit-reversed DAC port;
  - a TCXO's ground drawn as an enable;
  - a photodiode whose LCSC footprint has pad 1 = anode where KiCad's symbol has pin 1 =
    cathode;
  - three header pin-name lists printed in reverse;
  - a three-die LED (HL-AF-5060S22OC) whose generated symbol called pins 4-6 the anodes:
    the datasheet's circuit and JLCPCB's drawing ("+" at pins 1-3) both say 1-3, and the
    pumpkins would never have lit (OWLternating Current). Check every diode's anode
    against the datasheet **and** JLCPCB's drawing of the LCSC part.
  - Also compare every symbol's pin names with the distributor's (EasyEDA) drawing of
    its LCSC code (AMOD-C; `references/dated-lessons.md`; JLCPCB-side checks in the
    jlcpcb-order skill).
- **Trace every path** with a netlist walk (`trace_paths.py`): signal paths end to end,
  power from the input to every pin, every configuration and strap pin, every clock.
- **A filter drawn by hand is checked by its nets, not its picture** (CostasLink
  Prompt 31): assert in the netlist that each RC's capacitor is on the chip pin's net
  and the resistor between the pin and the source (`references/dated-lessons.md`).
- **Draw a part added late at the END of its sheet** so references drawn earlier keep
  their numbers (CostasLink Prompt 31; `references/dated-lessons.md`).

## The checks every schematic gets (Rosenberg)

Run them from the netlist in the build (pcb-workflow skill, gates 13-14), and read their
lists. Details, numbers and stories: `references/netlist-checks.md`.

- **One-pin nets** fail, except a deliberate test pad: a label typed once is an
  unconnected pin.
- **One name per rail.** "VCC" and "+5V", or "GND", "DGND" and "AGND", are nets that look
  like one. Print every power net with its pin count and the sheets it appears on.
- **One ground net, poured as one plane,** even when a datasheet draws AGND and DGND
  apart; the exception is real galvanic isolation (the Lorenz board's isolated DC/DC).
- **Copied blocks** bring their net names with them; a repeated name silently merges
  two nets.
- **Inductive loads** each have a path for their current when the switch opens
  (component-selection skill, §15).
- **A fuse** (or PTC, or eFuse) on every input that can deliver more than the board's
  copper and connectors survive; rate everything in series with it for the fuse's
  **hold current**, not the board's draw.
- **Two supplies, two blocking elements**; and **trace a two-supply ORing in BOTH
  directions, with each FET's gate written out.**
- **Straps against an FPGA that is still configuring** get external resistors (4.7 k).
- **A control whose idle must be safe rests where an absent host leaves it**: active-high,
  with a pull-down (1 k) that beats configuration pull-ups.
- **Every op amp's supply range and input common-mode range against its rail**,
  asserted by the generator from datasheet numbers.
- **A comparator or logic input on a connector** gets a series resistor sized to the
  input clamp's current limit.
- **Polarized parts** the right way round; every capacitor rated above the worst-case
  voltage across it, with margin.
- **Coupled windings:** transformer and coupled-inductor dots; common-mode chokes wired
  common-mode.
- **No floating inputs:** unused logic inputs, op-amp sections (grounded followers) and
  ADC channels go to a defined level.
- **Values.** Assert each design equation against the values the netlist really carries
  ("10" typed for "10k" is a classic); the Lorenz board has 147 assertions.
- **Each equation's inputs: the guaranteed figure, at the operating point, through what
  the next stage really sees.**
- **Ratings:** every part within its voltage, current and power at the worst-case input
  and temperature (component-selection skill, §12).
- **Options where unsure:** an empty footprint for the alternative, and a configuration
  that software can set rather than a jumper (pcb-bringup "Remote first"; pcb-workflow
  "Think five steps ahead").
- **A push-pull output cannot share a bus**: read "high impedance when deselected" in the
  datasheet before sharing any SPI output (AMOD-B).
