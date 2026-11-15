# Generated schematics and symbols in KiCad 10

What a schematic must show is in `pcb-schematic`; this file is how a generator gets KiCad
to draw it, and the checks that keep a generated sheet honest.

## KiCad schematic quirks

- A field's justification is mirrored when the symbol's rotation plus the field's angle
  is 180.
- A footprint field's angle is **absolute**.
- Pins that touch a wire's interior do not connect.
- Text bounding boxes are about 2.0x the text size high, not 1.6x.
- A field's glyphs sit in a measured band about the anchor (reference: -0.76 to +0.23 x
  size; value: +0.38 to +1.37 x size), and the anchor snaps to 1.27 mm.
- **KiCad symbol coordinates have y up** (PID motor board, 2026-10-24). The SW_SPDT's pin 1
  at (5.08, 2.54) is the *upper* right pin on the sheet; `mirror x` puts pole 3 on top.
  Check a pin's sheet position before deciding which pole is "upper".
- **Power symbols need numbers**: seventy all referenced "#PWR" make `kicad-cli sch export
  netlist` warn "schematic has annotation errors". Number them `#PWR0001`... across the
  sheets of one run.
- **Bus aliases live in the project file.** KiCad 10 keeps them in `.kicad_pro` as
  `schematic.bus_aliases: {"NAME": ["A[12..0]", "B", ...]}` (an object of member lists; a
  `{"members": [...]}` shape is ignored), and `kicad-cli sch upgrade` drops any
  `(bus_alias ...)` from a sheet wherever it is placed. A generator that writes the alias
  only into the sheet passes ERC until the first upgrade, then every wire into the
  `{NAME}` bus is "not a member" (ECP5 build 28: 26 warnings, found by the build, not by
  the manual ERC that ran before the upgrade). Write aliases into the project file; the
  inline form `{A[12..0] B C}` needs no alias but is 90 mm of text.
- **Pin names with spaces come out with underscores** in KiCad 10's symbols: "FC TX -> GPS
  RX" printed "FC_TX_->_GPS_RX". Use hyphens.
- **Local labels name a net with the sheet's path** ("/TX_FC_TO_GPS"); power symbols do
  not. A local label and a power symbol of the same name join under the power symbol's
  name. A board generator that looks nets up by name must try both.
- **kisch mirrored the field justification both ways for a mirrored symbol**, so a
  connector mirrored to face right had its value drawn inside its own box. A mirror about
  the vertical axis swaps left and right only (fixed in the GPS adapters' copy of
  `kisch.py`).
- **Hash every UUID the generator writes** (PID motor board). The schematic's rectangles
  wrote their key ("box/fuse") as the UUID; `kicad-cli sch upgrade` replaced the invalid
  strings with random ones, so the sheet changed on every build. `uid(key)` (uuid5)
  everywhere.

## Net names in generated blocks

- **A tile's local net names share a namespace with its helpers'** (AMOD-2/RF-MOD-2,
  2026-10-25). The power header names its FET's gate `G`; a laser driver's own gate net,
  also `G`, merged with it. The merge is legal, so ERC and the netlist check were silent;
  DRC found it only as one unconnected pad. Give FET nodes distinctive names (`GQ`, `SQ`),
  and grep a helper's nets before reusing a short name.
- **A net that leaves its tile needs a board-wide name** (AMOD-C/M/B, 2026-10-28). "DO"
  inside one tile is that tile's local net; the same name in the tile that reads it is a
  different net, and ERC is happy with both. Name cross-tile nets globally from the start
  (`/ENC_DO`).

## Generated symbols

- **Every pin on the 1.27 mm grid** (CostasLink, 2026-10-09). KiCad connects wires and pins
  only where they coincide on the 50-mil grid. A box symbol that centres an even number of
  3.81 mm-pitch pins puts them at odd multiples of 1.905 mm; the generator's grid-snapped
  wires then miss them by 0.6 mm, and ERC reports 35 "unconnected wire endpoint" stubs of
  0.03 mm and every ground pin "not connected". Round each pin's position to a multiple of
  1.27 when the symbol is drawn (the pitch stays; the row shifts by 0.635).
- **A box symbol's rows are not centred on its anchor.** Place a chip by the pin that must
  sit on a line (`part_at_pin(key, ref, pin, x, y)`: compute the pin's offset from the
  symbol and place the anchor accordingly), or every RF line into it bends by a row.
- **Vertical chokes on adjacent output pins need 15 mm of row pitch**: an RF chip's
  differential outputs at 2.54 mm pitch cannot each carry an inductor standing up to a rail
  flag (the second pin's choke and flag text land on the first pin's line, whatever the
  lines' detours). Give the symbol empty rows instead.
- **`extends` chains.** A KiCad 10 stock symbol may extend a parent that extends another
  (`OPA2189xDGK` -> `OPA2196xDGK` -> ...); flattening one level yields a symbol with no
  pins. Resolve the chain recursively, and rename every `NAME_u_s` sub-symbol whatever its
  prefix.
- **Adding the pins a symbol lacked must not widen it**: a box symbol widened to take nine
  ground pins on its bottom row moved every block drawn to its right by 25 mm and a monitor
  jack off the page. Put extra ground pins down a side and join them with one bar to one
  ground (sch_blocks.side_gnd).
- **A generated symbol can be incomplete, and every existing check passes** (CostasLink,
  2026-10-09, Response 8: the pin audit found nine of the PE43711's grounds, the HMC536's
  paddle and the SMA's centre pin without a net; ERC, the netlist walk and the sign-off
  renders all said fine). The gate that catches it: for every component, every pad of its
  library footprint must carry a net or a no-connect flag (tools/net_check.py). A vendored
  connector footprint numbered unlike its symbol (JLCPCB's SMA: legs 1-4, centre 5;
  KiCad's Conn_Coaxial: 1 centre, 2 shield) is the same fault: renumber the footprint's
  pads to the symbol's pins in the generator.

## Checking and placing on the sheet

- **Make the schematic checker say which line drew the wire.** Record `file:line` of the
  caller for every wire segment (`inspect.stack()`), and print it beside each touch/overlap
  message; with a `sch_where.py SHEET X Y` that lists the parts and wires near a point, a
  collision takes one look instead of a page of arithmetic (CostasLink: 108 problems to 0
  in an hour).
- **Place, then check, then look** (CostasLink, 2026-10-09; the user: "The text boxes in
  your schematics are overlapping with each other and with components in many cases...
  Look visually if nothing else"). A checker that reports overlaps is half the job; the
  generator must also PLACE: notes are deferred until the sheet is drawn, then each is put
  at the nearest clear spot against the checker's own geometry (texts, symbol bodies incl.
  their fields, wires, the page) within a small radius of where it was asked for
  (sch_util.flush_notes), and the report names what could not be cleared. Part labels have
  fixed offsets, so their collisions are geometry: capacitor rows need 10.16 mm, not 7.62;
  two parts on one node line need their texts on opposite sides; a pull-up next to a supply
  bar's flag is a resistor up to the bar, not a second flag; KiCad's diode symbols lie down
  (rotate them up, cathode where the rail is). Then render every sheet and zoomed crops of
  each flagged spot and look, because the numbers miss a label 0.4 mm into a ground symbol
  and a switch drawn with its signal through its own body.
- **A shunt hanging down from the upper of two stacked rows runs through the lower row**
  (CostasLink, 2026-10-09, Response 8: a 300 dpi crop showed the IN- line through the body
  of the IN+ summing node's shunt resistor; the touch checker tests pins, not bodies, and
  the earlier look at the sheet was too coarse to see it). Stand such a part on a loop
  ABOVE its row (up 5.08, the resistor lying along the top, its ground hanging from the far
  end), and crop the PDF at 300 dpi round every two-row block before calling a sheet clean:
  a 4000-pixel render of an A2 sheet is 7 pixels per millimetre.
- **A root sheet's wiring columns must stay clear of the sheet boxes, and the sheets' pin
  rows must not share a y with another sheet's pin rows that the same wires cross**
  (CostasLink, 2026-10-09). Adding five signals pushed the pwr-to-sheet columns past a
  sheet's left edge and put two pwr rows on the transmitter's rows: three silent shorts
  that only the net walk and ERC caught. Compute the columns' extent and the row
  coincidences in the generator and assert them; route the far sheet through a corridor
  below the others.
- **The generic schematic block** (a label on every pin, parts in rows; AMOD, 2026-10-25)
  wants: adjacent same-net pins joined under one label, the passive rows spaced by the
  longest net name, the rows started under the tallest chip symbol, the notes shrunk when
  the drawing needs the room. Its layout check (text boxes against each other) catches all
  of this before KiCad does.
- **A single-cell tile's schematic block is small** (AMOD-2, 2026-10-25). A part-heavy tile
  (a 16-pin bridge driver, a buffer, two diodes, two terminals) left no room for four lines
  of notes; the overlap check failed until the notes were one line. Put the long
  explanation in the docstring and the handbook.
- **A crash in the schematic generator must exit with a code the build does not accept as
  "overlaps".**

## Annotated wires and block diagrams (CostasLink, 2026-10-09)

- **Every wire states what is on it** (the user's Prompt 3: "looking at the schematic, one
  can instantly see what the levels, DC offset, frequency, and bandwidth are at every wire
  or pair of wires"). A distinct colour of note (blue, sch_util.sig) beside every signal
  wire: frequency | level in dBm and mV | bandwidth | DC offset or common mode, for the
  stated operating point (the bench link); the strings come from one module
  (gen/levels.py) fed by the budget's JSON, which the block diagrams also read, so sheets,
  diagrams and plan never disagree. Yellow stays for explanation. Place the boxes last and
  run the overlap checker filtered to them: a box across a supply cap's ground or a monitor
  jack is the usual miss.
- **Block diagrams are generated, annotated and pedagogical** (the user's request). Once
  the design is settled, draw it as block diagrams whose block titles read at a glance and
  whose EVERY arrow carries a box with the signal's level (dBm and mV), centre frequency,
  bandwidth and DC offset, plus a thumbnail of the signal in time or frequency, and a "how
  to read this" paragraph for the students. Make them from the budget's JSON
  (docs/blockdiagram.py -> docs/images/block_*.svg, text kept as text so it zooms) so the
  numbers cannot drift from the design; a PNG for the README. A stray `%` in a formatted
  matplotlib string is the usual crash.
- **A comparator has a floor; put it in the budget** (Response 6). A fast comparator
  decides nothing below about twice its offset plus hysteresis (20 mV for a TLV3601). Refer
  that to the antenna through the chain's gain and compare it with the noise-limited
  threshold: the CostasLink receiver as first drawn was deaf 17 dB above its noise. Balance
  the two with RF gain (a second gain block is 0.3 ns) and give a sensitive path its own
  baseband gain; then every range table takes the shorter of the noise limit and the
  floor. (The budget is the source the annotations read; see `rf-design`.)
