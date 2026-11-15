# Silkscreen text metrics, pitches and clearances

Read before giving any silk text a slot, writing a placer, or laying mirrored text.

## Minimums (JLCPCB)

- At least 0.8 mm text height and 0.15 mm line width. KiCad checks text height but **not
  the width of graphic lines**: stock footprints draw 0.12 mm (GPSDO r29 #23).
- Keep the fab's silk minimum in mind from the first text: the PID board's rules say
  0.8 mm; thirty labels written at 0.75 all came back as `text_height` errors.
- The board's DRC rules (silk text 0.8 mm minimum, silk-to-silk clearance 0.15 mm,
  warnings counted) catch every overlap, so design to them rather than to the eye.

## KiCad's stroke font is about as wide as it is tall (op-amp board)

- Measured with `PCB_TEXT.GetBoundingBox()` at 0.15 mm stroke: capitals advance
  0.95-1.05 x the size per character ("PUSH-PULL" at 0.8 mm = 7.45 mm, "OUTPUT CURRENT" =
  10.8 mm, "FOLLOWER x1" = 8.4 mm), lowercase and digits 0.8-0.9 x ("1: X to IN- (x11)"
  at 0.8 mm = 11.3 mm), and a lone letter 1.2 x.
- An earlier "0.76 x size" figure was a lowercase average and put four titles through box
  edges.
- Measure a string before giving it a slot: load the board in pcbnew and ask for the
  bounding box.
- On the tile boards' back panels, 0.8 mm text ran 0.65 (lower case) to 0.79 (digits) mm a
  character: take each line's box from a `PCB_TEXT` with the same settings, not from a
  character count.
- (For the schematic's text extents, see the pcb-schematic skill's
  `references/text-and-overlap.md`.)

## Line pitch

- Lines of lowercase text 0.8 mm high need a pitch of 1.3-1.5 mm (descenders and commas),
  capitals 1.2 mm (op-amp board).
- **A change of case changes the silk's clearances.** Two 0.8 mm lines 1.3 mm apart
  cleared each other in capitals and collided once "Clipper" and "pass" had descenders.
  Allow 1.5 mm between line centres in mixed case (AMOD-P2, §23).
- At 0.8 mm, lines 1.5 mm apart: 1.4 mm collided once a line had parentheses (back
  panels, §24).
- **A letter with a descender changes the silk's clearances.** Lower-case p and q hang
  0.15 of the text size below the line and met the line under them on three tiles; DRC
  found each (tile renaming, §25).

## Clearances round frames and copper (tile boards, §17)

- The silk needs 0.15 mm from everything, and a tile's frame line is 0.6 mm wide.
- Right-justify names at the frame's inner edge minus 0.25; keep 0.5 mm above and 0.7 mm
  below an 0.8 mm text line.
- A tented via under a label is fine, an exposed pad is not.
- KiCad's box for 0.9 mm text is 1.68 mm tall (§22).

## Mirrored text on the back (§24)

- `SetMirrored(True)` on B.SilkS; a left-justified mirrored text extends to the left of
  its anchor on the board, so it reads left-aligned from the back. Let KiCad measure it.

## Line length budgets (§23, §24)

- About ten characters of 0.9 mm text fit a one-cell (20 mm) tile's top frame beside its
  jack: name tiles to fit (Attenuator, Balun, Preamp).
- On a 20 mm cell with jacks at two opposite corners the free space is about 10 mm wide:
  13 characters at 0.8 mm.
