# Teaching boards: the silkscreen is the schematic

Read when the board's front silk draws the circuit (wires, symbols, stage boxes) for
students: the op-amp board (2026-10-24) and the PID motor board (Lab 10L,
2026-10-24/26). For toy-safety rules see the boards-for-children skill; for probe loops
and fusing see pcb-bringup and component-selection.

## Words, names and boxes (op-amp board)

- **For people who have never seen the material, every label is a word** (the user,
  2026-10-24: "'tail' should indicate that the transistor is there to make a constant
  current source. Other labels like 'comp' should be full words, even if they need to be
  rotated. This is for people who have never seen this material."). No "COMP.", no
  "1 cap / 2 no 1k": "COMPENSATION", "1: 100pF + 1k", "2: no 1k", "CURRENT SOURCE"
  standing up the side of the TAIL box when it has no room across. Rotate a title rather
  than abbreviate it.
- **Never name a node after a part that exists.** The diff pair's output was labelled
  "C2" on the sheet and on its probe loop, while the board also has a 10 µF bypass called
  C2. Name nodes by part and pin, "Q2 C", "Q3 E", "Q1 B", on the schematic labels, the
  loop values and the handbook alike, and keep the one spelling everywhere, because the
  netlist names are what the board's wire table and the circuit checker match on.
- **Dashed boxes around the stages, named as the book names them** (the user: "draw boxes
  with labels around things like 'difference amplifier' and 'push pull emitter follower'
  or however the book explains it"), with the stage's gain in the title ("x11", "x30",
  "x1"). The box generator clips its dashes around pads, courtyards and the wires that
  cross its edges.
- **A dashed stage box's title must dodge the wires that enter the box from above**: a
  vertical feed to a transistor's collector cuts the title strip in two, and a
  transistor's symbol circle (r 4 mm) blocks the rows beside it.
- **A wire crossing a box's title band gets a jog, not the title an abbreviation**: Q4's
  collector could not run straight up to +15 V without splitting "PUSH-PULL FOLLOWER", so
  it steps 4 mm sideways just above the circle, rises along the box's edge and hops under
  the bus. The jog is a cost in schematic fidelity paid once; an abbreviated or missing
  stage name is paid by every student.
- **Nothing sits on a box edge.** The box generator clips its dashes round every
  courtyard, so a part whose courtyard straddles an edge erases a whole run of it: the
  FEEDBACK switch sat 0.2 mm below the limiter box and the bottom of one box and the top
  of the next both vanished (the user: "There is a component right on the border ...
  that prevents the bottom of the 'OUTPUT CURRENT LIMIT' box and the top of the
  'FEEDBACK' box from being drawn"). Leave a clear band of 1 mm or more between boxes,
  and run any bus that joins two boxes along that band (the limiter's two diode returns
  go round the outside of the push-pull box, above and below), never through a third
  box.
- **A loop that sits on a labelled rail needs no label of its own**; "+15V" printed
  beside a loop on the line already marked "+15 V" is one more thing to dodge in the band
  above the rail.
- **Label a thing where it is**, never in a legend band by designator (see SKILL.md).
- **The schematic's own characters**: KiCad's stroke font has ± (U+00B1); write "±13 V",
  not "+/-13 V", on the board and on the sheet.
- Font widths and line pitches: `text-metrics.md`.

## Grounds

- **Grounds point down, except where ground really is above** (the user: "Move things
  around so that the ground symbols always point down. The exception ... might be for
  the decoupling capacitors for the -15V, where ground really is above -15V"). A part
  that returns to ground hangs down from its rail: the divider under the output line,
  the +15 V lamp down from the top rail, the -15 V lamp up from the bottom rail with its
  symbol pointing up. A ground stub may be a path (pad, corner, via) so the symbol can
  hang down beside a connector body instead of pointing sideways out of it.
- **Grounds pointing up are allowed when the geometry forces it** (PID board): the
  difference amplifier's 100k from the + input to ground has no room below the + row
  (the − row is 6 mm under it), so it stands above with its symbol up, like the −15 V
  decoupling exception.

## A transistor symbol a novice can read (SOT-23)

The user, twice: "the arrows on your transistor symbols aren't that great. They need to
be inside of the circles. It should be very obvious ... whether it's NPN or PNP, and
which pin is the emitter, base, and collector"; then "The vertical line where the base
comes in, the emitter arrow, and the collector's line should all be more well within the
circle. Maybe the circle just needs to be bigger. The 'E', 'B', and 'C' labels can be
inside of the circle. The 3 SMT pads themselves also awkwardly connect to the symbol
lines ... make them much thinner than the lines for the symbol itself".

What works, round a SOT-23 (`gen_pcb.q_geometry` on the op-amp board):

- a circle of r 4.0 mm (0.25 mm line) centred on the package;
- the base bar 2.2 mm from the centre on the side the base wire arrives from, 2.8 mm
  long, 0.55 mm wide; the base lead from the circle to the bar;
- the collector and emitter legs (0.45 mm) leaving the bar's two ends at 45 degrees,
  turning vertical at 3.6 mm and leaving the circle at the top and bottom directly above
  and below the package, so the wires outside are straight;
- a filled arrowhead on the emitter leg, at its outer end pointing out for an NPN,
  against the bar pointing in for a PNP;
- B, C and E in 0.8 mm letters inside the circle, in the three empty corners;
- a 0.16 mm hairline from each pad to its lead, square on to the leg, with the copper
  under the hairline and under the lead out to the circle, so the wire, the symbol and
  the pad are one conductor.
- Everything in a frame with the bar on the left and the collector up, mirrored per part
  (base side, NPN/PNP), with the wires ending where the leads leave the circle (resolve a
  transistor pad in a wire to that point, not to the pad).
- The symbol replaces the footprint's own outline (drop its F.SilkS items; set
  `lib_footprint_mismatch` to ignore) and the wire clipper treats the circle as a
  keep-out so the wire stops at the ring.
- **Turn the package so the base pad is on the bar's side, always**: rotation 90 (lone
  pad up) for an NPN with the base from the left, 270 for one with the base from the
  right, and 90 for a PNP, whose lone collector pad then sits under the emitter leg and
  gets a hairline running down between the other two pads. The other arrangements put a
  pad where its copper cannot reach without crossing another lead (the 0.4 mm gap
  between the lone pad and the pair is impassable; the 1.3 mm gap between the pair is
  not).
- A wire must reach the circle square on, along the lead's line: a riser that touches the
  ring tangentially looks wrong, so a base that comes from below turns horizontal 1.4 mm
  before the ring.
- One type legend ("Q1 Q2 Q4 Q6 Q7 = 2N3904 NPN") in the title band beats eight captions
  fighting for room.

## Power transistors (PID board)

- **A DPAK symbol.** KiCad's TO-252-2 has the base and emitter pads 2 mm below the tab,
  in line; a 45-degree emitter leg from a bar beside the tab cannot pass between the tab
  and the base pad with silkscreen clearance. What fits: the circle r 8.2 centred 1.5 mm
  toward the tab, the bar 4.5 mm out, legs at 33 degrees (BH 3.25, bend 6.17), the base
  hairline running horizontally from the pad to the bar's line and the bar extended down
  to it, the emitter hairline just below its pad across to the leg's vertical, the E
  letter between the tab and the emitter pad, the collector lead 2 mm wide into a pour
  that stops outside the circle. Two DPAKs in a push-pull with 2512 sense resistors
  between them need the circles 32 mm apart centre to centre.
- **A D2PAK is too big to draw round.** Its tab (10.8 x 9.4 mm) fills any circle that
  holds it. Draw the transistor's circle round the two leads and let the tab cap it (the
  arc stops at the tab's silk clearance); run the base lead straight through the base pad
  into a bar between the leads; end the collector leg at the tab. The pour round the tab,
  on the collector's net, then reads as the collector.
- **An NPN/PNP push-pull in one unmirrorable package needs one crossing.** Turning the
  PNP 180° keeps its B, C, E in the same cyclic order as the NPN's, while the schematic's
  PNP is mirrored, so the wire from BASES to the PNP's base must cross the PNP's emitter
  wire or go round its collector pour. With big pours, plan one hop under the emitter
  wire beside the emitter resistor and leave room for its two vias.
- **A 'silk clipped by solder mask' warning names the nearest pad, not the cause.** It
  pointed at the tab while the leg's corner touched it 1.6 mm away from the bar it seemed
  to blame. Delete the symbol's pieces one at a time in a scratch build until the warning
  moves: five minutes, where reasoning about the geometry took an hour.

## Op amps in SOT-23-5 (PID board)

- **An op-amp in SOT-23-5 is drawn + on top.** Pin 1 (+IN) is the upper-left pad, pin 3
  (−IN) the lower-left, so a triangle round the package has + above − whatever the book
  does; feed the − network from below and put the feedback row under the triangle.
- **V− of a SOT-23-5 is trapped.** Pin 2 sits between the two inputs; no front copper can
  leave the triangle from it. Take it to the back through a via *inside* the triangle,
  surface it just under the triangle's bottom edge as a "−15 V" flag with the bypass
  capacitor hanging from it, and join the flags with a back trunk. The sheet draws a
  power symbol at each op-amp; the board can too. Draw the hairline from pad 2 to the via
  dashed.

## Back runs drawn as dashed silk (PID board)

- **A signal that must cross every stage goes on the back as a dashed line** (POSITION
  from the plant terminal back to the LOOP switch): a net label with a route. Everything
  else stays a drawn front wire. (Back runs can box in the ground plane: see the
  pcb-layout skill.)
- **Dashed back-run silk is silk**: it collides with text, footprint outlines and pads
  like any line. Route it under part bodies only where their silk is clear (between the
  terminals' pins and the parts above them), and keep probe loops off it.

## Switches (PID board)

- **A three-pin slide switch with the pins on one edge (MSK12C02) traps its common pin.**
  Pin 2 sits between 1 and 3 on the same edge: with the body horizontal (rot 0/180) the
  two outer wires go up and turn away left and right and the common goes straight up
  between them; with the body vertical the outer wires must leave up and down. So choose
  the schematic's pole assignment for the board: pole 3 (the upper pin at rot 90) =
  "into the sum", pole 1 (lower) = "off"; and put the D-capacitor selector *before* its
  two capacitors so its common faces the ERROR column. The datasheet draws pin 2 common
  and nothing about which travel closes which pole: unverified, on the DOA list.
- **KiCad symbol coordinates have y up.** The SW_SPDT's pin 1 at (5.08, 2.54) is the
  *upper* right pin on the sheet; `mirror x` puts pole 3 on top. Check a pin's sheet
  position before deciding which pole is "upper".

## Knobs and trimmers (PID board)

- **Clockwise is more resistance; say what that does.** The user (2026-10-25): "I
  generally do want clockwise 'screwing in' to increase the resistance. Sometimes that
  corresponds to decreasing the relevant gain, which might be counter-intuitive."
  - Bourns' 3362 data sheet marks terminal 3 CW (the wiper reaches it turning
    clockwise); wire every trimmer as a rheostat between 1 and 2 with 3 tied to the
    wiper.
  - Put a short arc over the top of each knob and trimmer ending in an arrowhead at 12
    o'clock with the effect beside it ("↑R ↑P", "↑R ↓I", "↑TARGET").
  - Newstroke has ↑ ↓ → ↻ ↷ (not ⟳), so the arrows are plain silk text.
  - `check_circuit` asserts the 1-2 wiring; `gen_pcb` refuses an arc that comes within
    0.5 mm of a drawn wire, since DRC does not mind ink over ink.
- **The arc needs 5 mm of clear board above the part.** A 3362P's wiper is on top, so its
  tie to terminal 3 wanted to leave upward through the arc; run it under the body instead
  (pin 2 across to pin 3's column and down: the one wire the part hides), feed the ends
  from the sides, and give the stage the height (the D stage's feedback row went up 1 mm
  and its return row down 0.5 mm). Radius 5 from 238 degrees: a 10 o'clock start lands
  on the wire that feeds terminal 1, and anything lower than 4.1 mm above the centre
  overlaps the trimmer's own silk box (DRC silk clearance 0.15 mm).

## Probe-loop names (PID board)

- Where a probe loop's name has no room beside it, print it rotated 90 degrees between
  the parallel wires. (Which nodes get loops: the pcb-bringup skill.)

## The back silkscreen is the students' manual (PID board)

The user (2026-10-25): "Students will *not* read the documentation in the README.md, but
they might read this silkscreen."

- Use the back's room: one item per line (each switch position its own line, a second
  column for the options), inputs, outputs, trimmer directions, a start sequence,
  warnings; a wide column is fine if it buys one idea per line.
- URLs with https://.
- Name class-foreign words in class terms ("fader (motorized potentiometer)").
- Skip what the front shows.
