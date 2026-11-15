---
name: pcb-silkscreen
description: Silkscreen that lets the board explain itself - identity block, connector names and limits in consistent rows, header-pin and jumper labels, test points, region boxes, overlap and printable sizes, back-side manuals, teaching boards whose silkscreen is the schematic, and tile boards. Use when placing or checking silkscreen labels, legends, designators, label placers or label checks, back-silk text, QR codes, or drawing schematic symbols in silk.
---

# Silkscreen: the board explains itself

The board should be usable without the schematic. It must be obvious how *not* to make a
mistake with an input level or a plug direction (GPSDO P7).

Reference files (read when the task touches them):
- `references/connector-label-rows.md`: the "one relation per row" rule in full - row
  definition, sizes, reserving strips in the placement plan, cascades, the labeller's
  priorities and the release check. Read when placing or checking connector names.
- `references/text-metrics.md`: KiCad stroke-font widths, line pitches, descenders,
  mirrored text, minimum sizes and clearances. Read before giving any text a slot.
- `references/teaching-boards.md`: boards whose silkscreen is the schematic (the op-amp
  board, the PID motor board): words not abbreviations, stage boxes, transistor/DPAK/
  D2PAK silk symbols, SOT-23-5 op amps, grounds, trimmer arcs, back-silk manuals.
- `references/tile-boards.md`: boards of building-block tiles (AMOD, RF-MOD, PhMOD):
  jack names on the frame line, tile titles, free-text placement by search, back
  panels, tile naming and renaming.

## Identity

- **Identity:** the board name; "by <the user> and Claude"; the URL; the date; and "rev A", the least prominent of these
  (Lorenz P1, P5, GPSDO P10). Add a QR code with its URL printed under it when there is a
  web page (Lorenz P2, P4).
  - The date is the day the file was built, written by the build, never typed in.
- **Never print a document's section numbers on copper**: the tutorial is renumbered as
  it grows and the board cannot be (tile boards).

## Connectors

- Names are **big**, right next to the connector they name, never between two
  connectors (ECP5 P2, memory).
- Every connector that leaves the board is labelled with what it is for and its limits:
  "±1 V MAX", "15 V DC, 1 A MIN" (ECP5 P2, GPSDO P13).
- The label sits by **that** connector, not the neighbour's (GPSDO P17).
- A U.FL tap's name stands beside the tap and its designator is not printed: "J107"
  reads as a jumper, and nobody finds the jumper (ECP5 P26).
- **A tap's name says what it carries, and sits tight against the jack** (GPSDO rev B:
  `IN` and `SQ` on each channel), on the side away from any jumper. A first try that let
  the name range 8 mm put it on a 3-pin header's edge, where it read as one of the
  jumper's settings.
- A connector that is one of a pair says which way it goes ("TRIG A" with "OUT" on a
  small line over its level; "ANT" with "TX+RX" under it). A limit may hold a newline:
  KiCad prints it on two lines, the placer reserves the longest line wide and both tall
  (CostasLink Prompt 35: "TRIG OUT A" did not fit before the next chip).
- **One relation per row, enforced** (CostasLink Response 15): every name in a row of
  like connectors stands on the same side of its own connector, at the same gap,
  angle and size; reserve the strips in the placement plan before small parts are
  placed; check it on the written board and fail the release. Details:
  `references/connector-label-rows.md`.
- **Ports named for the student, by whose port it is.** "USB USER", not "USB FPGA": a
  name that says whose port it is keeps the one cable out of the wrong jack (ECP5 P26).
  "SPEAKER IN", not "AUDIO IN" beside "MIC OUT" ("whose in?"); on a two-channel tile name
  each jack by its channel's device or function, never by a generic signal (tile boards).
- **Name UART lines by whose they are.** Pixhawk, CubePilot and ArduPilot label a GPS port
  from the flight controller's side (pin 2 TX); Holybro's GPS tables label the same wires
  from the GPS's side (pin 2 "RX (in)"). Print "FC TX" and "FC RX", say so on the board,
  and map connectors by pin number, never by the words.
- **Every pin of every connector, even at 1.25 mm pitch** (GPS adapters P2: "It would be
  nice if all pins of each connector could be labeled, again even if the labels are
  small"; "the github page ... even if it's very small"):
  - 0.9 mm text in a column beside the pads, one label per pin, centred on its row;
  - the back of the board repeats them with the pin numbers and longer names. It is free
    room when every part is on top: "2 TX: FC TO GPS";
  - the URL goes on the front even at 0.8 mm, and on the back with the QR code.
- **Card slots.** A microSD on the back, inboard, says which way the contacts face
  ("contacts toward the board") and where the card goes in ("card slides in here")
  (ECP5 P26).

## Header pins, jumpers, test points

- **Header pins.** Every pin is labelled next to itself: the top row's labels above it,
  the bottom row's below. Never all on one side, which makes people probe the wrong pin
  (GPSDO P29, Icepi P30).
  - Rotate the labels with the header (GPSDO P17).
  - Name the colours and signals of screw-terminal wires at the screw (GPSDO P13).
    - Centre each label under its pin, in the strip just outside the terminal's outline.
    - Reserve that strip before placing the terminal's own resistors, and keep the
      designator out of it.
    - A placer that slides a label sideways to clear a part makes it read as the
      neighbouring pin's. Rev A's `red` sat nearer GND than VCC (GPSDO r45).
- **Jumpers.** Say what each does, **right beside it**, on every copy: a legend's "1-2 =
  50R" asks the reader to find pin 1, which a fitted shunt hides, and a column of tiles
  turned 180° puts the same choice at the other end (GPSDO rev B: `50R` and `PARK` beside
  each header's own pins, a tick at the common one).
  - A 2-pin jumper's "50Ω IN / hiZ OUT" or "x1 IN / x10 OUT" next to its pins; a 3-pin
    selector's two choices beside its two outer pins with a tick through the centre pin
    between them. Two selectors stacked with "PD" and "NOISE" between them label neither
    (ECP5 P11, P26).
  - Fail the build when a jumper's label lands more than a few millimetres from it. A
    jumper that cannot select what its label says is a bug the user will find.
  - Take each choice's text from the net on that pin, never from the drawing's left and
    right. CostasLink's two sign jumpers printed "Q-" at pin 1, and the netlist puts Q_P
    there (found in Response 15). Two selectors with the same choices also need different
    names ("SIGN B1", "SIGN B2"), or the board cannot say which is which.
- **Test points.** Labelled at the pad with the rail or the expected reading ("3V3",
  "In 10 MHz 0.7-8 Vpp"). If a legend is used, it must be legible and aligned, and the
  letters unambiguous (an "I" read as a "1": GPSDO P29, P13).
- **Label a thing where it is, never somewhere else by its designator** (the user, op-amp
  board, 2026-10-24, in as many words: "if you can label something where it is relevant,
  it's *much* easier for humans to read than labeling it somewhere else with its
  reference designator. I don't want to have to read something on the top and say to
  myself, 'Okay, now which switch is SW3?', nor do I want to see a switch (or group of
  switches) and say to myself, 'Okay, now where is the function of this described?'").
  A switch's function goes in a box round the switch; a connector's limits beside the
  connector; a stage's name in the stage's box. A legend band that says "SW3: ..." is a
  failure of layout, not a solution to it. Plan the room for the words when the part is
  placed, as for connector names.

## Parts, regions and designators

- **ICs.** Name them by function and part number ("MPY634 multiplier", "op-amp LF412"),
  along with the component values (Lorenz P1, P3). On tile boards, say what a tile is in
  words ("LNA QPL9547", "POWER METER"), not by its chip.
- **Region labels** sit **inside** the box, under its top edge, never in the line: a name
  cut into a line that two boxes share reads as either box's, and "ADC B IN" ended up
  halfway between ADC A and ADC B (ECP5 P14, P26). A label for a box must not look like
  a label for one part inside it. (Exception by design: a tile's jack name sits *on* its
  own frame line with the frame broken round it; `references/tile-boards.md`.)
- **No label in another unit's box, checked on the written board** (GPSDO rev B,
  2026-10-10; the user: "one of the most confusing things from last time was when labels
  for one unit showed up in another unit's box").
  - A placer check that only covers parts with a home box misses parts that live in a
    tile but belong to another sheet. Rev B's in-tile heaters had no home, and eight of
    their designators sat in the NEXT unit's box.
  - Give such a part its tile as home, and keep a homeless label out of every unit box.
  - Then read every F.SilkS text off the written board with KiCad's own text boxes and
    find each one's owner: a designator's footprint, a free text by the placer's record
    of who placed it. GPSDO's `pcb/check_unit_labels.py` does this in every build; with
    `--stamps DIR` it draws one picture per unit, labels coloured by owner, for the look
    by eye.
- **A designator prints only where its own part is the nearest one**, or it goes to
  F.Fab. A last-resort search for "any clear spot inside the box" had walked 236 of GPSDO
  rev B's names up to 9 mm, beside other parts (R251's name under the heater R2002, so
  the heater read as R251). A name by the wrong part is worse than none, inside a unit as
  much as across units.
- **Pin-1 marks.** Add one only where the pad pattern is symmetric under a half turn
  **and** the library prints nothing. A second dot next to the library's triangle is one
  more dot to confuse with JLCPCB's purple one (Lorenz P5, Icepi jlcbuild). Oscillators
  and crystals with only an "L" for a cue need a big dot (GPSDO P35).
- **Never drop a library's silkscreen by a crude test.** ECP5's writer dropped every
  footprint silk line that came within a square the size of a pad's longer side, which
  removed nearly all outlines and the SOD-123's cathode line (0.2 mm from its pad), so
  JLCPCB's viewer and anyone holding the board had no cathode end to check D501 by
  (2026-10-08). Clip against the pad's real outline plus the fab's silk-to-pad
  clearance, and count each footprint's silk lines in and out of the writer.

## Overlap and sizes

- **Overlap.** Nothing overlaps anything: silk on silk, silk on pads, silk over the edge.
  A label that will not fit goes to F.Fab, not on top of something.
  - The checks must cover labels as well as components (ECP5 P14).
  - Report both lists every build: labels outside their part's box, and parts outside
    their box. A part on one side of the line with its label on the other is "never
    good" (ECP5 P26); grow the box or move the part.
  - Leave out "MountingHole" and its reference (Lorenz P2).
  - Silk over tented vias and tracks is fine; never over pads (or exposed copper).
- **Printable sizes.** At least 0.8 mm text height and 0.15 mm line width at JLCPCB.
  KiCad checks text height but **not the width of graphic lines**: stock footprints draw
  0.12 mm (GPSDO r29 #23). Keep the fab's minimum in mind from the first text: thirty
  labels written at 0.75 mm all came back as `text_height` errors (PID board).
- **Measure text before giving it a slot**: KiCad's stroke font is about as wide as it is
  tall; numbers, pitches and clearances in `references/text-metrics.md`.
- **Look at the real thing.** Judge silkscreen from KiCad's own rendering (`kicad-cli pcb
  export svg`, rasterised), not from a quick matplotlib plot that draws text at a third
  of its size: the plot said "fine" where the print overlapped (ECP5 P26).

## Prose and manuals

- **Prose on the silkscreen.** Left-justified, broken at sentence boundaries, and checked
  for grammar (Lorenz P3, P4).
- **A legend paragraph sits beside what it explains**, wrapped to the room there: the
  headers' paragraph above the box the headers live in, the USB paragraph under the
  FTDI. "The largest free area" put them in the middle of the board (ECP5 P28).
- **The user's instructions go on the back** where the back is bare: how to cable the
  alternatives (one antenna or two), which 5 V source is which, the jumpers' defaults
  (CostasLink Prompt 35).
- **The back silkscreen is the students' manual** (the user, 2026-10-25: "Students will
  *not* read the documentation in the README.md, but they might read this silkscreen").
  One item per line, inputs, outputs, trimmer directions, a start sequence, warnings;
  URLs with https://; skip what the front shows. Details: `references/teaching-boards.md`;
  per-tile back panels: `references/tile-boards.md`.
- **The warnings that prevent damage go on the front as well**: the back is read while
  cabling, the front faces you on the bench ("PULSES ONLY", an LNA's input limit, "start
  at mV").

## Teaching boards (silkscreen is the schematic)

Core rules; the geometry and stories are in `references/teaching-boards.md`.

- **For people who have never seen the material, every label is a word**: "COMPENSATION",
  not "COMP."; rotate a title rather than abbreviate it.
- **Never name a node after a part that exists**: "Q2 C", not "C2" beside a bypass C2;
  one spelling everywhere.
- **Dashed boxes around the stages, named as the book names them**, with the stage's gain
  in the title ("x11", "x30", "x1").
- **A wire crossing a box's title band gets a jog, not the title an abbreviation.**
- **Nothing sits on a box edge**: leave a clear band of 1 mm or more between boxes.
- **A loop that sits on a labelled rail needs no label of its own.**
- **A transistor symbol a novice can read**: arrows inside the circle, B/C/E letters
  inside, hairlines from the pads thinner than the symbol's lines.
- **Grounds point down, except where ground really is above** (the -15 V decoupling) or
  the geometry forces it.
- **Write "±13 V", not "+/-13 V"**: KiCad's stroke font has ± (U+00B1).
- **Clockwise is more resistance; say what that does** with an arc and arrowhead over
  each knob and trimmer.
- **Draw what is inside a module** (a mixer's baluns and diode ring) on the silk.
