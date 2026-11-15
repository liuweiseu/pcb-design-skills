---
name: pcb-layout
description: PCB placement, routing and mechanical rules - floorplan, part orientation, decoupling, stack-up and layer assignment, ground and power pours, fine-pitch QFN fan-out, writing or running a (maze) router, post-route checks, connector edges, mounting holes, enclosures and screws. Use when placing parts, routing copper, drawing zones or planes, debugging nets left unconnected, generating a board from a script, or fitting a board to a connector, cable or housing.
---

# PCB layout: placement, routing, mechanical

The rules for putting parts on a board, joining them in copper and fitting the board to the
world. The long stories behind the generated-board lessons are in `references/`; read the one
that matches the task:

- `references/generated-placement.md`: a script places the parts (rule placer, hand anchors,
  placement variants, connector flips and courtyards). Read before writing or changing a placer.
- `references/router.md`: a script routes the board (planned copper, rip-up, terminal protection,
  short connections first, joining copper so KiCad agrees, late pin assignment by river routing).
  Read when nets stay in pieces, or before binding swappable pins.
- `references/fine-pitch-fanout.md`: the fan-out procedure for QFN/LGA/fine LQFP pins, fine net
  classes. Read before routing from any 0.5 mm pitch or finer chip.
- `references/power-and-pours.md`: rail drop and width, plane nets, inner and outer pours, islands.
  Read when laying out supplies or zones, or when DRC reports islands or starved thermals.
- `references/connector-routing.md`: order reversals, two headers on one side, Pmod rows and
  numbering. Read when lines run between a chip and a connector or between headers.
- `references/tile-and-drawn-boards.md`: hand-laid cell boards (AMOD, RF-MOD) and boards whose
  copper follows the drawn schematic (op-amp, PID motor board). Read for any hand-placed small-cell
  or teaching board.
- `references/post-route-checks.md`: what to measure after every routed build (clock and RF net
  lengths, the per-build list). Read after each routing run.
- `references/enclosure.md`: housings, vendor 3D models, screw stacks, engraved text.

Related skills: the rf-design skill (CPWG lines, launches, via fences, "simulate the circuit the
copper makes"), the highspeed-digital skill, the pcb-silkscreen skill (labels and boxes), the
kicad-scripting skill (pcbnew API quirks), the jlcpcb-order skill (CPL rotations, assembler
spacing), the component-selection skill (current, DC resistance budgets).

## Floorplan and placement

- **Floorplan first.**
  - Decide where the connectors and blocks go.
  - Run each signal path through its chips in the order the schematic draws it.
  - Then hang each chip's passives directly off its pins.
  - Leave room for labels from the start: spread out rather than bunch into a corner (Lorenz P3,
    ECP5 P11).
- **Orientation.** Placement follows the schematic: a horizontal series resistor is horizontal on
  the board, along the trace; a vertical shunt is vertical (Lorenz P4: "I even specifically asked
  that the 100R resistors be horizontal").
- **Rotation.** Verify what 0/90/180/270 actually do to each footprint's pads before relying on
  them. "0 = horizontal" was wrong more than once (ECP5 P2, P9). KiCad's rot 90 puts a footprint's
  local -x at +y (below).
- **Decoupling** at the pins: straight to a ground via, on the back if that is closer (ECP5 P9,
  Icepi P28). In front of a fine-pitch chip, put it between two signal pins, never straight in
  front of one (fine-pitch-fanout.md).
- **Blocks.** Each functional block sits in a silkscreen box. Everything that belongs to it, part
  and label, lies inside its box; nothing else does.
  - Check it in code (`check_silk_boxes.py`). Rev A of GPSDO printed 71 designators in the wrong
    box (GPSDO P41, ECP5 P14).
  - Identical channels are laid out identically (ECP5 P11).
  - And in the order their names suggest: ADC A above ADC B **and** DAC 1 above DAC 2, even when
    the chip's pins come out the other way round; swap the strips, not the names (ECP5 P26: "no
    end of student confusion").
- **Get the geometry from KiCad, not from memory, and place against courtyards** before the first
  DRC: dump each footprint's pads and courtyard box and budget against those (AMOD §17, §26;
  tile-and-drawn-boards.md). A connector's courtyard is what the placer says, not the body; keep
  0.5 mm between courtyards (seven U.FL at 5.5 mm pitch need 38 mm). Pin-header footprints anchor
  on pin 1, not their centre: a lying 1x2 reaches 6.1 mm past its anchor, a 1x3 8.6 mm (ECP5 P26).
- **Plan the crossings before the coordinates:** write the nets that must meet, find the planar
  order, then rotate each part so its pins face where their nets arrive (AMOD-2 §20).
- **Check that a pair's pins face each other before laying it;** swap the pair at one end rather
  than cross beside a chip, and say so in the schematic (CostasLink build 17;
  generated-placement.md).
- **Place an amplifier's feedback, gain and shunt resistors at its pins, by hand** (CostasLink's
  THS4541: 4.02 k feedback 10 and 13 mm away on an 850 MHz-GBW part invites peaking).
- **Anchor every RF part to the pad it serves, by hand, and measure the distance in the build**
  (CostasLink rev A: a placer rule put 68 pF 36 mm from their chokes).
- **Keep a parts-free band round every fine-pitch chip** (16 pads or more: 1.8 mm beyond its
  courtyard) before any fan-out is planned (CostasLink).
- **Unshielded inductors** couple when they lie in line along their axes: space them or turn one
  90° (Rosenberg).
- **Aggressors and victims** (Rosenberg). Switching converters, motor and coil drivers and fast
  logic are aggressors; receivers, ADCs, sensors and high-gain analog are victims. Distance first,
  then a shield can. When schematic order and distance conflict, weigh both.
- **Room to assemble:** parts packed tighter than the assembler's spacing rules cannot be placed,
  inspected or reworked (JLCPCB publishes its own).
- **Check footprints at 1:1:** print the placed board at 1:1 (measure the outline with a ruler) and
  lay the real parts on it: the idiot-proof check for anything the user buys in hand, especially
  connectors and mechanical parts. Ribbon cables mirror (Rosenberg).
- **Probe-ability beats the PCB price on a low-volume board:** shrink a board every student gets;
  let a lab-station board be big (PID motor board, 170 x 120 mm).
- **The page.** The board sits in the middle of its page with a margin (25 mm) and the title block
  clear below it; a board at the page's 0,0 overlaps the border and the title block (ECP5 P26).
  Keep the design's own frame (origin at the board's corner) for every computation and shift only
  the written file, so gerbers, drill and CPL come out in one frame.

## Stack-up, ground and power

- **Stack-up and layer assignment** (Rosenberg). Choose the stack-up before routing, from the fab's
  own table, because impedances and via inductances follow from its thicknesses (JLCPCB's
  JLC04161H-7628: 0.21 mm from L1 to L2; inner copper 0.5 oz unless 1 oz or 2 oz is ordered).
  - **2 layers:** top = parts, signals and supplies; bottom = ground plane, with as few traces as
    possible, each short.
  - **4 layers, parts on top:** L1 parts and signals; **L2 solid ground with nothing but via holes
    in it: no traces**; L3 supplies and leftover routing, the rest filled with ground stitched to
    L2; L4 the same as L3.
  - **4 layers, parts on both sides:** L1 and L4 parts, signals and supplies; L2 ground; L3
    supplies.
  - **Why the ground goes on L2:** a via's inductance grows faster than its length. Rosenberg's
    curve: about 45 pH for the 0.38 mm from L1 to L2 of a typical 4-layer board, about 500 pH
    through 1.6 mm, eleven times as much. On 2 layers there is no choice, which is the main reason
    4 layers ground better.
- **Ground.** Keep an unbroken ground reference under every fast signal. A layer change gets a
  ground via within about 1.5 mm. Keep analog and digital apart physically, and keep switch nodes
  small (ECP5 P2).
- **Each ground pad gets its own via,** at the pad (Rosenberg: "I cannot stress enough how
  important this is"), and each power-plane connection likewise, beside its decoupling capacitor.
  A shared via is shared inductance, which couples the parts that share it. On 2 layers, make that
  via the pad's only path to ground: a second path through top-layer copper closes a loop that
  picks up and couples.
- **Never route ground, or a rail with a plane or pour, "whole" as a net:** its pads get stubs and
  vias; any helper that routes the rest of a net skips them (CostasLink: 875 mm of top-layer GND,
  "0 ground vias" in the log; power-and-pours.md).
- **Power.** Distribute it in pours or wide traces (GPSDO's unpoured +3V3_A lost 109 mV). Check the
  regulator's dropout from the **worst** input (USB: 4.75 V, less a fuse and a diode). Measure the
  drop, not the width, with a resistance-network walk of each rail (ECP5 `tools/power_path.py`).
  The analog rails get planes, not traces. Route rails at the pad's width, then widen where there
  is room (`pcb/fatten.py`); never widen in the router. All in power-and-pours.md.
- **DC resistance of high-current paths:** count the squares and compute the drop, return path
  included (Rosenberg; see the component-selection skill).
- **Count what an inner layer's supply pours leave for the signals;** draw a pour only where its
  rail's pins need it (CostasLink: In2 73% poured). One polygon per rail; keep rail strips 1.5 mm
  wide and other nets' vias out of them (AMOD).
- **No floating copper** (Rosenberg): an island connected to nothing is a resonator at RF and an
  antenna everywhere. Remove it or stitch it to ground.
- **Copper balance** (Rosenberg): about the same copper on every layer, over the whole board. A
  region bare on every layer laminates badly and warps the board. Fill unused area with ground on
  every layer and stitch the layers together; it also spreads heat.
- **Fill zones in the file you ship** (GPSDO r29 #18: the committed board had no pours). Count
  `filled_polygon` in the shipped `.kicad_pcb` and fail on zero.
- **After placing any slot or cutout, check every via on an inner pour still reaches it;** after the
  fill, check every ground via lies inside the filled plane (AMOD-B, PID motor board).

## Routing

- **Layout order** (Rosenberg):
  1. pour the ground plane (and any power plane);
  2. the critical lines: high-dynamic-range analog inputs, RF, crystals, reset, short and with
     ground on both sides;
  3. the high-current supply paths, wide and short;
  4. each block's own routing;
  5. the connections between blocks;
  6. whatever is left.
- **Plan the copper.** On GPiBridge the maze router was left only the ground vias: every other
  connection, down to each decoupling capacitor's 1 mm stub, is written as coordinates computed
  from the pads. The router's versions wandered (VBUS through three layers, a UART line along the
  board edge); the planned ones look like a person drew them.
- **Router.** The Java autorouter (Freerouting) made things worse. A simple maze router plus
  hand-planned routes worked (GPSDO); river-routing buses first worked (ECP5 P5). When routing
  fails, look at postage stamps of the router's own obstacle grid round one failed connection, the
  moment it fails (ECP5 P3). Judge by DRC's unconnected count, not the first-pass failure list.
  Rip-up and reroute, terminal protection and short-connections-first are in router.md.
- **Plan every fine-pitch chip's fan-out; never leave it to the router.** Fan every chip before
  any chip's local nets; run straight out of a 0.5 mm-pitch pin 1.4 mm before turning
  (fine-pitch-fanout.md).
- **Let the board choose the swappable pins** (GPIOs, LED channels, mux inputs, gate sections):
  route back to a ring round the chip, bind in arrival order, generate the schematic and firmware
  headers from the result (OWLternating Current: 59 nets unjoined with a table fixed first;
  router.md).
- **Put every signal on the FPGA face that looks at its chip** when the plan is first made; lay a
  long slow line the router finds only by luck by hand, before routing (ECP5).
- **Never fence a block on both routing layers** (GPSDO rev B: six clock branches went 171-319 mm
  round the block). Run a long run on the layer that leaves the other free where branches cross.
- **Keep a corridor for the board's long lines** in the plan, in board coordinates, before the
  blocks are laid (AMOD: 2.5 mm strip moved twice).
- **Clean traces.** No zig-zags, loops or detours around a part's own pins. If a resistor is in the
  way of its own trace, rotate the resistor (ECP5 P11).
- **Order reversals need a layer change,** once per line, where the lines run in the connector's
  order (GPiBridge Lite). Two side-entry headers on one side of a board always meet in reverse
  order (GPS adapters). Both in connector-routing.md.
- **Look at a gate package's pinout against the routing before choosing it** (74LVC2G14: VCC
  between the outputs had no way out; connector-routing.md).
- **Hop a low-impedance or slow net, never a high-impedance node** (an output, a bias, a supply, a
  Pmod line may hop to the back; a resonator node or summing junction may not; AMOD-2).
- **Vias as large as the room allows:** small drills are less reliable and more inductive. Keep
  the smallest for fine-pitch fan-out (Rosenberg).
- **No vias in holes.** Keep vias out of through-hole drills, including the routing net's own.
  GPSDO shipped a via drilled inside a header pin (GPSDO r28 #2).
- **No via holes in SMD pads:** a wire end dropped at a pad's edge is a via in the pad, which DRC
  passes (same net) and which drinks the pad's solder; gate it (AMOD `scripts/check_layout.py`).
- **Every via has copper on two layers** and every back-layer polyline ends on a via or a pad, not
  in mid-trace; draw an open stub as copper graphics on its net (AMOD; router.md).
- **Pass every width** explicitly; a borrowed default width shorted pads beside a ground stub
  (AMOD-C).
- **Put RF taps and synthesizer outputs in the RF net class** and route them by hand, short
  (CostasLink LO MON taps; post-route-checks.md and the rf-design skill).

## Paste, fiducials, layer markers

- **Paste:** check the paste layer. Every pad that needs solder has an opening; test pads,
  fiducials and edge contacts usually do not; a large exposed pad gets a window-pane pattern (about
  50-70 % coverage) so the part does not float (Rosenberg).
- **Fiducials:** three on the board, at three corners and as far apart as possible, and three more
  at the corners of a box round each fine-pitch part (Rosenberg). JLCPCB adds its own on the rails
  of the panels it makes, but marks on the board itself are what align a fine-pitch part. A
  board's fixed furniture (fiducials, stick-on feet's 8 mm circles) is per board and must yield to
  its parts: one hard-coded fiducial landed on a screw terminal (AMOD-2).
- **Layer markers:** each copper layer's number in copper on that layer, all at one spot, so the
  fab (and anyone holding the board against a light) can tell the layer order (Rosenberg).
- **In a generated board, fiducials and layer markers are netless graphics, not footprints** (ECP5
  build 31): a filled `gr_circle` on the copper layer and a larger one on the mask layer make a
  fiducial, a `gr_text` on each copper layer a marker. No footprint means no symbol, no parity
  warning, no BOM or CPL row. They must be known to everything that places or routes: the placer's
  keep-out list, the router's obstacle grid (the fine-grid rebuild included) and the silkscreen's
  occupancy map, or a track or a label lands on them. Pick the spots by scanning the previous build
  for discs free of copper, silkscreen and courtyards on both sides; the slot band that the
  enclosure hides is a good home for the layer numbers (and for JLCPCB's order number), not for
  fiducials, which the assembler's camera must see.

## After every routed build

- **List each clock net's length and vias against the last revision.** DRC passes a 300 mm clock;
  the comparison does not.
- **And every RF net's length against the shortest path through its pads:** print every net over
  2x its pads' minimum spanning tree; an RF net (touching a U.FL, SMA or MMCX, or named RF or LO)
  fails at 1.5x and 10 mm extra (CostasLink `tools/detour_check.py`: a 12.3 mm tap routed 115.6 mm
  read 25.7 dB low at 5.8 GHz).
- **Measure every rail's width in the shipped file, by net,** against its rule (ECP5: 27 builds
  said "0.4 mm rails" over 0.23 mm copper).
- **Print each plane net's track length per layer, and the ground vias placed.** A long run or zero
  vias means something joined the pads first.
- **Ask KiCad which pads nothing reaches, and join them,** by KiCad's connectivity, not your own
  geometry (CostasLink Response 15).
- The full list is in post-route-checks.md.

## Mechanical: connectors, cables, enclosure

- **Connectors point out.** Check the **3D render**, not the footprint's rotation (ECP5 P2: an RJ45
  faced into the board; Icepi P16: SMAs sideways). A connector's pad row faces the way its rotation
  says, not the way its name suggests: the HRO USB-C at rot 270 faces -x; on a right edge it is
  rot 90.
- **Flush at the edge, or a little past it.**
  - USB-C must sit where its drawing says, so a fat moulded plug can seat.
  - For the **HRO TYPE-C-31-M-12 (C165948)** the board edge is 5.79 mm past the upper shell tab,
    with the mating face 0.99 mm past the laminate. Do not let a silkscreen-to-edge DRC rule move a
    connector; trim the silkscreen instead (Lorenz R10).
  - Behind an end plate, faces must stand past the board edge by the plate's thickness (ECP5 R9).
- **Mating connectors on a generated board:** never model pcbnew's `Flip()` (it mirrors y whatever
  its enum says); put the host's measured pins into the generator and refuse to lay copper until
  pins 1, 2, 3, 39 and 40 sit on them (CostasLink; generated-placement.md).
- **For any keyed two-row connector, derive the pin from the pad's position relative to the body,
  never from its number,** and check both mating halves: KiCad's and JLCPCB's Pmod footprints
  number pads in opposite directions (AMOD-A, RF-MOD; connector-routing.md).
- **Cables.** Leave room for fat plugs beside each other: USB next to HDMI next to RJ45 (ECP5 P14).
  Space SMAs for fingers and wrenches, and spread them evenly along one edge (ECP5 P2, GPSDO P2).
  On a grid of two-port cells, put the jacks in a checkerboard (AMOD/RF-MOD; tile-and-drawn-boards.md).
- **Holes.** M3 mounting holes in the corners, clear of headers (GPSDO P4: a hole through the 2x20
  header). Leave a keep-out where cards and plugs slide in, checked in code (ECP5 P14, microSD).
- **Enclosures.** Design for a real one and check it against its **drawing** (ECP5 was 8 mm short of
  its Hammond extrusion); check part heights against the floor and slots; slice the vendor's 3D
  model; follow the force through the screws; check each screw's length against its stack and fail
  the build on a bad one; measure engraved text's strokes. Details in enclosure.md.
- **3D models.** Every part has one; missing ones were noticed every time (Lorenz P2, ECP5 P2,
  Icepi P39). KiCad's share ships no STEP file for some library footprints (the WSON-8 DSG0008A, the
  HRO USB-C, the 1812 fuse): the release check that every model resolves is right to fail; point
  those footprints at a stand-in body of the same name in the project's own 3dshapes (AMOD §17; the
  VRML scale trap is in the kicad-scripting skill).
- **Gender and orientation** of anything that plugs in. Label header pins 1, 2, 39, 40 as the
  mating module prints them, so a module that flips upside down goes in right (Icepi P30, P34,
  P35).
