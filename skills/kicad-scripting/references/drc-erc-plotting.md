# DRC, ERC, plotting and deterministic outputs

The gates themselves (DRC 0 at every severity, ERC 0, parity) are in `pcb-workflow`.
This file is what KiCad 10's reports mean and how to make images and release files.

## DRC findings that a script's own checks miss

- **`connection_width`**: a track that ends exactly on a pad's corner (end the track at
  least half its width inside the pad); and two same-net vias whose pads touch on a layer
  neither uses (remove unconnected inner pads, or bridge them on the outer layer).
- **`track_dangling` points at a track's *start***, even when its other end is the loose
  one.
- **A track that ends inside a via's pad but outside its drill does not connect it** on a
  layer whose unused pads are removed: end tracks at the via's centre.
- **DRC and the connectivity API disagree** about a track end on the middle of a same-net
  track (`TestTrackEndpointDangling()` joined, DRC `track_dangling`): see
  `pcbnew-api.md`, "Connectivity clean-up".
- **A via with copper on one layer only is "dangling"** (AMOD-P/A, 2026-10-25). A back wire
  that T-joins another back wire must not end in a via; make it one polyline, or let it end
  on a pad.
- **Every back-layer polyline end is a via** in a tile generator (AMOD-2, 2026-10-25). A
  branch that ends on the middle of another back trace drops a via there, often under a
  front-side part. Draw a branch as one polyline from via to via (overlapping a same-net
  segment is fine), never ending in mid-trace.
- **An open-ended line is not a dangling track** (PhMOD/AMOD-P2, 2026-10-28). Draw a stub
  as copper graphics on its net (KiCad joins them to the line they start on), or DRC calls
  its open end dangling.
- **A fine board's DRC still uses each net's class** (AMOD-C/M/B, 2026-10-28). A 0.4 mm
  pitch QFN's stubs pass at 0.2 mm wide only (the Default class's 0.2 mm clearance applies
  between nets of that class); an LGA's unconnected pins, 0.15 mm apart, are each a Default
  net. Put a fine tile's nets in the Fine class, and its unconnected pins too with a
  netclass pattern (`unconnected-(U601-*`).
- **Islands after a fill**: test every ground via against the plane polygon after the fill
  (`ZONE.HitTestFilledArea`) and fail the build if one is outside (PID motor board: back
  runs boxed the ground plane, the fill removed the island, DRC said only "unconnected").
  See `pcb-layout`.
- **Same-net vias in SMD pads pass DRC**; a separate gate must catch them (see
  `jlcpcb-order` / `pcb-layout`).

## Messages that point at the wrong place

- **A zone fill's narrow necks.** KiCad's `connection_width` warning on a zone names the
  zone and its anchor, nothing else. Find the neck by reading the zone's
  `filled_polygon`s and shrinking each (shapely `buffer(-w/2)`) until one splits: the
  piece that splits is the crumb, and its bounding box says where (ECP5 build 30: two
  ground vias 0.7 mm apart in the gap between two In4 planes, their annuli joined by 0.03
  and 0.06 mm webs of fill -- harmless, but it took a script to say so). The fill's own
  `min_thickness` does not remove such webs: the deflate-inflate pass re-merges two lobes
  whose cores were separate.
- **A 'silk clipped by solder mask' warning names the nearest pad, not the cause** (PID
  motor board). It pointed at the tab while the leg's corner touched it 1.6 mm away from
  the bar it seemed to blame. Delete the symbol's pieces one at a time in a scratch build
  until the warning moves: five minutes, where reasoning about the geometry took an hour.

## Rule and severity traps

- **A custom `silk_clearance` rule on text** makes KiCad 10 report every designator
  against Fab text and courtyards as `silk_overlap`.
- **`lib_footprint_mismatch`**: set it to ignore in the project's rule severities, with the
  reason in a comment, when the generator edits footprints (e.g. removes their silk);
  otherwise DRC reports every edited footprint (op-amp board).
- **`kicad-cli pcb drc --severity-all` lists warnings in the same `[rule]:` form as
  errors**; a build that counts lines starting with "[" stops on `silk_over_copper`
  warnings too, which is the right call on a board whose silkscreen is the point (op-amp
  board, 10.0.7).
- **ERC's JSON positions are in 100 mm units** (`"x": 2.9972` is 299.72 mm).
- DRC does not mind ink over ink: a generator that must keep silk arcs off drawn wires
  checks it itself (PID motor board's `gen_pcb` refuses an arc within 0.5 mm of a drawn
  wire).

## Looking at the board

- **The quickest "look at the board" image** (op-amp board): `kicad-cli pcb export pdf
  --mode-single` of F.Cu + F.SilkS + Edge.Cuts, rasterised with `pdftoppm` and cropped to
  the outline's ink; crop regions of it by board millimetres (px = (mm + pad) x dpi / 25.4)
  when chasing one label.
- **Render one tile at a time while laying it out** (AMOD, 2026-10-25). `kicad-cli pcb
  export svg` of F.Cu, F.Silkscreen and F.Courtyard, cropped to the cell with Inkscape's
  `--export-area`, shows a tile at 35 px/mm in seconds; most mistakes are visible before
  DRC runs.
- **Give each tile its own picture in its handbook entry** (AMOD/RF-MOD, 2026-10-28).
  Render the board's top at about 25 px/mm, find the board in the image by its solder-mask
  green (columns and rows where G > R + 12 and G < 110), and crop each tile's frame with
  0.9 mm round it. A table with the picture in the first column and the description beside
  it means the reader never scrolls back to the board. Save as JPEG: a render compresses
  badly as PNG.
- **3D views**: `kicad-cli pcb render --side bottom` shows a model turned wrong (see
  `pcbnew-api.md`, 3D models).
- **Schematic sheets**: render every sheet, and crop the PDF at 300 dpi round every
  two-row block (see `schematic-generation.md`).

## Assembly drawings (AMOD/RF-MOD pre-order, 2026-10-29)

- **An assembly drawing is plotted from Fab, silkscreen and outline, without the drawing
  sheet.** `--include-border-title` puts the board 1:1 in the corner of an A4 frame. F.Cu
  plotted black buries the silk under the pours.
- Plot F.Fab, F.Silkscreen and Edge.Cuts (B.Fab, B.Silkscreen mirrored), then fit to Letter
  with the scale in a caption (CostasLink's `fit_pdf.py`).
- On a page with slack, put the caption half a margin under the drawing. At the paper's
  foot it widens the drawn box that `fit_pdf.py check` measures, and a centred drawing
  fails as off centre.

## Deterministic release files

- **Gerber and drill files carry the time they were plotted**, so a rebuild never gives the
  same zip. Stamp the design date over `TF.CreationDate`, the job file's `CreationDate` and
  the header comments, and give the zip entries a fixed date (GPS adapters'
  `mfg/make_release.py`); then an unchanged board makes the same bytes.
- **Ghostscript's PDFs differ every run** (a document ID, dates, an XMP packet). Pass
  `-dOmitID -dOmitInfoDate -dOmitXMP` (Ghostscript 9.55 and later), or `fit_pdf.py`'s
  output churns in git (motor-pid's copy of it does; 2026-10-29).
- Board and schematic UUIDs: see SKILL.md "Determinism" and `pcbnew-api.md`.
