# Schematic lessons from later boards

Read when a generator numbers references, draws filters by hand, builds tiles or blocks
from shared helpers, or checks symbols against distributor data.

## CostasLink (Prompt 31)

- **Draw a part added late at the END of its sheet.** The generators number references
  in drawing order, and the board's hand anchors are by reference: a DNP pull-up drawn
  beside the TCXO renumbered R220-R227 and the anchors then placed the wrong parts (a
  49.9 ohm into a jack's leg, a DRC fault). The balun's DC blocks and the TCXO's pull-up
  are drawn last, after the sheet's other parts, and the build's netlist is diffed
  against the last commit's for the sheet's references.
- **A filter drawn by hand is checked by its nets, not its picture.** Both ADS1115
  "10 k / 100 nF" input filters had the capacitor hanging from the SOURCE end of the
  line, so 100 nF sat on the fast arms' outputs; the blue box said 160 Hz and five
  reviewers read the box. For every RC at a chip's pin, assert in the netlist that the
  capacitor is on the pin's net and the resistor between the pin and the source
  (`tools/net_check.py` can walk it); a fresh-eyes review with the netlist as ground
  truth found it in an hour.

## Tile boards: AMOD, RF-MOD (2026-10-25 to 2026-10-28)

- **The generic schematic block** (a label on every pin, parts in rows) wants: adjacent
  same-net pins joined under one label, the passive rows spaced by the longest net name,
  the rows started under the tallest chip symbol, the notes shrunk when the drawing needs
  the room. Its layout check (text boxes against each other) catches all of this before
  KiCad does (§17).
- **A single-cell tile's schematic block is small.** A part-heavy tile (a 16-pin bridge
  driver, a buffer, two diodes, two terminals) left no room for four lines of notes; the
  overlap check failed until the notes were one line. Put the long explanation in the
  docstring and the handbook (§20).
- **A tile's local net names share a namespace with its helpers'.** The power header
  names its FET's gate `G`; a laser driver's own gate net, also `G`, merged with it. The
  merge is legal, so ERC and the netlist check were silent; DRC found it only as one
  unconnected pad. Give FET nodes distinctive names (`GQ`, `SQ`), and grep a helper's
  nets before reusing a short name (§20).
- **A net that leaves its tile needs a board-wide name.** "DO" inside one tile is that
  tile's local net; the same name in the tile that reads it is a different net, and ERC
  is happy with both. Name cross-tile nets globally from the start (`/ENC_DO`) (§26).
- **Compare every symbol's pins with the distributor's drawing.** AMOD-and-RFMOD's
  `scripts/check_pinouts.py` reads the pin names of each LCSC code from EasyEDA and sets
  them beside the schematic symbol's: on AMOD-C it found a dual transistor whose pins
  were another part's order and a SAW filter whose output was on a ground pad. The rest
  of its differences are naming ("+" against IN+); read each against the maker's table
  and say so in the board's DOA list (§26). The JLCPCB-side caveats of this check
  (skipped polarised parts, blank pin names, `c_spicepin`) are in the jlcpcb-order skill.
- **A push-pull output cannot share a bus.** The MT6701's DO drives whether or not its
  chip is selected; a 74LVC1G125 enabled by its chip select lets it share MISO with an
  IMU. Read "high impedance when deselected" in the datasheet before sharing any SPI
  output (§26).

## PID motor board (Lab 10L, 2026-10-24/26)

- **KiCad symbol coordinates have y up.** The SW_SPDT's pin 1 at (5.08, 2.54) is the
  *upper* right pin on the sheet; `mirror x` puts pole 3 on top. Check a pin's sheet
  position before deciding which pole is "upper".
- **Choose a switch's pole assignment on the schematic for the board** when the part's
  pin geometry traps the common (MSK12C02): see the pcb-silkscreen skill's
  `references/teaching-boards.md`.
- **Grounds pointing up are allowed when the geometry forces it:** the difference
  amplifier's 100k from the + input to ground has no room below the + row (the − row is
  6 mm under it), so it stands above with its symbol up, like the −15 V decoupling
  exception (grounds otherwise point down; op-amp board).
