# Hand-laid boards: tile grids and boards whose copper is the schematic

Read this when laying out a board of small hand-placed cells (the AMOD / RF-MOD / PhMOD tile
boards: a 100 x 100 mm grid of 20 mm cells, every cell a circuit between two SMA jacks, the
silkscreen the schematic), or a teaching board whose copper follows its drawn schematic (the
op-amp board, the PID motor board). The silkscreen side of these boards is in the pcb-silkscreen
skill.

## Get the geometry right before placing

- **Get the geometry from KiCad, not from memory** (AMOD, §17). Dump every footprint's courtyard
  and pad bounding boxes with pcbnew (`FootprintLoad`, `GetCourtyard`, `GetBoundingBox`) before
  placing by hand; the SOT-23-5 pin-one triangle pokes 0.09 mm past its courtyard, the SOIC pads are
  0.6 wide at 1.27 mm so nothing passes between them, the 0402 is the only passive whose body fits a
  1.27 mm pin pitch. Every hand placement budgeted against those numbers passed DRC first time;
  every one from recalled numbers did not.
- **Place against courtyards before the first DRC** (AMOD-C/M/B, §26). A part placed by its pads
  alone collides with a neighbour's courtyard, a jack's legs or a slot one DRC round at a time.
  Print each footprint's pads and courtyard box (a small script over the `.kicad_mod`), place
  against those, and check the boxes in the generator before running KiCad.
- **Read the jack legs' real pad radius before threading a trace between them** (§20). The SMA legs
  are 1.1 mm in radius, more than the drawing suggests; a 0.35 mm line 1.2 mm from a leg's centre
  shorts to it.

## The cell's budget

- **The 20 mm cell has a budget, and a switch and a FET take a third of it** (§17). A powered tile
  with a slide switch (MSK12C02, 9 x 4.5 mm courtyard) along its left edge and a SOT-23 FET at its
  foot leaves 14 x 9 mm under the jacks for the circuit: one SOT-23-5 op amp and six passives, or one
  SOIC-16 and six 0402s. Anything bigger (a DIP switch beside a SOIC, a second op amp, a loop with a
  label) goes, and the plan must say so before the layout starts.
- **Two-port jacks in a checkerboard** (IN top-left, OUT bottom-right) keep a 20 mm grid's closest
  pair at 14.85 mm (one cell's diagonal; 15.2 across a gutter) instead of 10.5. Decide it before the
  first tile: changing it later re-lays every tile (§18, §19: twenty finished tiles were re-laid
  because their jacks stood 10.5 mm apart in rows; afterwards every pair on all three boards was
  14.85 mm or more).
- **The checkerboard leaves each cell two quarters, not a half** (§19). With jacks at the top-left
  and bottom-right (6.5 mm bodies, 7.1 mm courtyards) the circuit gets the top-right quarter (about
  10.8 mm square) and the bottom-left one, which a powered tile's switch and FET mostly fill. The
  signal runs on the anti-diagonal. Plan every tile's parts against those two squares before
  choosing packages.
- **Choose the small package first, and look for it under every name** (§19). A SOIC-16 (10.5 mm
  courtyard) and a SOIC-8 op amp did not fit beside both jacks; the TSSOP-16 and the SOT-23-6 did.
  TI's TSSOP 4046 had 21 in stock, but Nexperia's automotive grade (74HC4046APW-Q100J) had 234:
  search the "-Q100" and other vendors' parts before giving up on a package. Read the small
  package's pinout from the datasheet; the SOT-23-6 OPA847 moves the pins.
- **A dual op amp in SOIC-8 rarely fits a cell's quarter; two SOT-23-5 singles usually do** (§20).
  The dual's eight pins on two sides force its four signal nets to cross; two singles can each face
  their own jack.
- **A long part between diagonal jacks stands at 45 degrees** (§19). An HC-49S crystal (11 mm
  courtyard) fits on the diagonal with the jacks 0.5 mm further out; a ceramic resonator likewise.
  JLCPCB places any angle; say so in the assembler's notes so nobody "corrects" it.
- **A part 4.4 x 5.4 mm cannot sit on the diagonal between a cell's two jacks** (§23). Anything
  wider than about 3.5 mm goes in the top-right or bottom-left quarter.
- **A hand-soldered part must fit before it is offered** (§22). A polyvaricon with its dial is
  about 20 mm square, a whole cell beside a jack. The answer was a 2-way screw terminal beside the
  coil's, in parallel with the switched capacitors, for an external capacitor with a big knob.
- **A DIP switch laid out at rot 90** turns its two rows into two columns: one side for the common
  node, the other for the switched parts (§20; it is rated tens of milliamps: switch a reference
  resistor or a coupling capacitor, never a current shunt).

## Laying the tiles

- **One hand-laid geometry per circuit kind, reused with an offset** (§17). The non-inverting
  op-amp stage was laid once (`opa_tile`) and used by five tiles; a double tile uses it with
  x + 21.5. The hours go into the first instance; the rest are free and DRC-clean.
- **Plan each tile's crossings before its coordinates** (§20). Write the nets that must meet (the
  tank node, the switch, the buffer input), find the planar order, then pick each part's rotation
  so its pins face where their nets arrive. A SOT-23-5 op amp at rot 270 has +IN, V- and OUT along
  the top and -IN and V+ along the bottom; rot 0 puts OUT, V- and +IN down the left. Most of the
  night's rework came from choosing a rotation first and discovering the crossing in DRC.
- **A SOIC across a cell** (§17): the pin rows face the jacks and the board's edge, the gap between
  the rows is the only corridor (3 mm: three 0.35 mm wires), and the ends of the rows are the only
  pins that can leave sideways. Pins between other pins leave only outward. NC pins are passages
  for a wire of the node next to them (declare them passive in the symbol so ERC agrees; the
  datasheet must say "no internal connection").
- **Hop a low-impedance or slow net, never a high-impedance node** (§20). An op amp's output, a DC
  bias, a 5 V feed and a Pmod line may run on the back between two vias; a resonator's node or a
  summing junction may not. An output may travel the length of the tile to its jack; put the buffer
  by the node it reads.
- **Keep a corridor for the board's long lines before the tiles are laid** (§17). The Pmod lines
  down the back of two tiles needed a 2.5 mm strip clear of sockets and jacks; it moved twice
  because the tiles had not reserved it. Reserve it in the plan, in board coordinates, and tell
  every tile.
- **Moving a jack moves what was behind it** (§19). The back's QR code, the board's long back wires
  (the Pmod lines), the gutter labels of the tiles above and below, and a neighbour's ground symbol
  all met the moved jacks. Each was caught by a check (the QR-over-hole check, DRC's silk rules), so
  run the full build after every tile, not at the end.
- **Render one tile at a time while laying it out** (§19). `kicad-cli pcb export svg` of F.Cu,
  F.Silkscreen and F.Courtyard, cropped to the cell with Inkscape's `--export-area`, shows a tile at
  35 px/mm in seconds; most mistakes are visible before DRC runs.
- **A board's fixed furniture must yield to its parts** (§20). The fiducials were hard-coded; one
  landed on a screw terminal in the corner margin. `FIDUCIALS` (and `FEET`) are now per board;
  check them against every margin part, and keep a stick-on foot's 8 mm circle off any through-hole
  joint.
- **A wire end dropped at a pad's edge is a via in the pad** (AMOD/RF-MOD pre-order, §29). The tile
  generator puts a via at every back-side wire end and every ground stub's point. Ten landed with
  their holes in or across SMD lead pads (an 0402, two SOIC-8 pins, four SOT-23 pins, two 0805 LEDs,
  an 0805 capacitor), and four more 0.02-0.03 mm inside a pad. DRC passes them: same net. The vias
  are tented and JLCPCB's economic assembly does not fill them, so a hole in a pad's mask opening
  drinks its solder: a starved joint or a tombstone. The gate: no hole's edge inside an SMD pad's
  copper, exposed pads and tabs aside (a pad of at least 2.5 times its footprint's median area;
  paste-only apertures, which have no number, skipped). AMOD `scripts/check_layout.py`. Print the
  holes within 0.05 mm (mask registration).

## Boards whose copper is the schematic (op-amp board, PID motor board)

- **Copper follows the drawn wire** (op-amp board, 2026-10-24). On a board whose silkscreen is the
  schematic, the generator takes one list of wires (net, points, width) and draws each both as F.Cu
  track and as F.SilkS line, so the picture *is* the netlist. Crossings are "hops": the crossing
  track dives to B.Cu between two vias and the silkscreen draws a half-circle arc over the other
  wire, as a textbook draws a jump. No front pour: fill would bury the drawing, and a 2-layer board
  with a solid back ground plane needs none. Three hops on a 100 x 100 mm six-transistor board; plan
  the floorplan (inputs left, output right, rails top and bottom as lines) to keep it there.
- **SOT-23 geometry decides the transistor's rotation** (op-amp board, 2026-10-24). KiCad's SOT-23
  pads are 1.475 x 0.6 mm with a 0.4 mm gap between the rows, so nothing routes under the body
  between them, but the lone pad (3, collector) faces a 1.3 mm gap between the two same-side pads
  (1 base, 2 emitter). To draw a transistor the way the schematic does, place it at rotation 90
  (collector up, base lower-left, emitter lower-right) and run the collector wire straight up
  between nothing; mirror to rotation 270 when the base arrives from the right (the + input's Q2,
  the sink's Q6 with its divider on the right). Every wire then leaves a pad in the symbol's own
  direction and the silkscreen emitter arrow can be derived from the real emitter wire.
- **An op-amp in SOT-23-5 is drawn + on top** (PID motor board). Pin 1 (+IN) is the upper-left pad,
  pin 3 (−IN) the lower-left, so a triangle round the package has + above − whatever the book does;
  feed the − network from below and put the feedback row under the triangle.
- **V− of a SOT-23-5 is trapped.** Pin 2 sits between the two inputs; no front copper can leave the
  triangle from it. Take it to the back through a via *inside* the triangle, surface it just under
  the triangle's bottom edge as a "−15 V" flag with the bypass capacitor hanging from it, and join
  the flags with a back trunk. The sheet draws a power symbol at each op-amp; the board can too.
  Draw the hairline from pad 2 to the via dashed.
- **A signal that must cross every stage goes on the back as a dashed line** (POSITION from the
  plant terminal back to the LOOP switch): a net label with a route. Everything else stays a drawn
  front wire.
- **A three-pin slide switch with the pins on one edge (MSK12C02) traps its common pin.** Pin 2 sits
  between 1 and 3 on the same edge: with the body horizontal (rot 0/180) the two outer wires go up
  and turn away left and right and the common goes straight up between them; with the body vertical
  the outer wires must leave up and down. So choose the schematic's pole assignment for the board:
  pole 3 (the upper pin at rot 90) = "into the sum", pole 1 (lower) = "off"; and put the D-capacitor
  selector *before* its two capacitors so its common faces the ERROR column. (Which travel closes
  which pole: the drawing shows the slider toward pin 1 closes pin 1; still an ohmmeter check on the
  first board, see the pcb-bringup skill.)
- **An NPN/PNP push-pull in one unmirrorable package needs one crossing.** Turning the PNP 180°
  keeps its B, C, E in the same cyclic order as the NPN's, while the schematic's PNP is mirrored, so
  the wire from BASES to the PNP's base must cross the PNP's emitter wire or go round its collector
  pour. With big pours, plan one hop under the emitter wire beside the emitter resistor and leave
  room for its two vias.
- **Back runs box the ground plane:** test every ground via against the filled plane after the fill
  (power-and-pours.md).
- **Probe-ability beats the PCB price on a low-volume board.** The user, on 170 x 120 mm against the
  100 x 100 discount: "I'd rather keep the ability to probe than save a few dollars. Not every
  student needs one of these boards, whereas every student needs an op-amp board." Shrink a board
  every student gets; let a lab-station board be big.
