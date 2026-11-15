# pcbnew from Python: the full list of traps

KiCad 10 (10.0.6, 10.0.7). Run every script as `AppDir/AppRun python3.11 script.py` (see
SKILL.md). Generator scripts in the style of `gen/board.py` relaunch themselves inside it.

## Saving, loading and filling (GPiBridge, 2026-10-06; CostasLink)

- **`board.Save()` also rewrites the `.kicad_pro`** with default net classes and rules.
  Write the project file again after saving.
- **A `LoadBoard()` in a process that has already saved a board built in memory reuses
  KiCad's in-memory default project**: its zone fill ignores the project's net classes and
  custom rules, and its save writes the defaults over the `.kicad_pro` (CostasLink build
  18: Default clearance 0.2 mm, 479 DRC errors). Fill by the project's rules in a fresh
  process (`AppRun python3.11 board.py --refill`), then write the project file again.
- **`pcbnew.WriteDRCReport()` segfaults in a bare Python** (it needs KiCad's program
  object). Run `kicad-cli pcb drc` on the saved file instead.
- **A board built in memory has no connectivity until `board.BuildConnectivity()`.**
  Without it, `ZONE_FILLER` judges islands unconnected and silently drops pours (the
  ground under a USB-C vanished).

## SWIG object lifetime and identity

- **pcbnew hands back a fresh Python wrapper on every call, so `is` never matches.**
  `t is item` over `board.GetTracks()` is always false; compare
  `item.m_Uuid.AsString()`. CostasLink's first cleanup pass found every track touching
  itself and fixed nothing until it compared IDs.
- **`BOX2I.Merge()` returns a non-owning view of the box it was called on.**
  `bb = bb.Merge(b) or bb` keeps the view and drops the owner, the box is freed under it,
  and KiCad aborts later with "malloc(): unaligned tcache chunk detected", sometimes
  (CostasLink, 2026-10-09: two 25-minute builds lost at their last stage). Merge in place
  and keep the owner: `bb.Merge(b)` on its own line.
- **`SHAPE_POLY_SET.Outline(i)` is a view into the set.** On a temporary
  (`make_set(...).Outline(0)`) it reads freed memory: Edge.Cuts segments to -1000 mm. Keep
  the set in a name while its outline is read.
- **Copy a SWIG vector's numbers before the list that owns it goes away** (RF-MOD,
  2026-10-25): `m.m_Scale` kept as a proxy wrote a scale of 1486236861 into the board file.
- **After a zone fill, KiCad's SWIG hands back `GetConnectivity()` as a bare object
  without its methods.** One connectivity-based pass a process.
- **KiCad 10's SWIG loses VECTOR2I after a Remove/Add and a connectivity rebuild**
  (CostasLink, Prompt 31): `track.GetStart()` comes back as an opaque SwigPyObject with no
  `.x` on the next item. One removal a process, then a fresh process (gen/board.py
  `drop_dangling_by_drc`), as the fills already do.
- **The library's sexp round trip keeps one of two identical pad keys**: to change a
  vendored pad's `remove_unused_layers`, replace its line, do not add one.

## Layers, fields, strokes

- **Layer names.** KiCad 10's `board.GetLayerID()` knows only the long names
  (`F.Silkscreen`); `"F.SilkS"` gives an undefined layer, the item is saved there, and
  `kicad-cli` then refuses to load the board ("items on undefined layers"). Map layer names
  to the `pcbnew.F_SilkS` constants yourself.
- **`FOOTPRINT.SetField()` with a new name (LCSC, MPN) creates a visible field on
  F.SilkS.** Hide it and move it to F.Fab, or 400 silkscreen DRC errors appear.
- **`pcbnew.STROKE_PARAMS` is not exposed to SWIG** (10.0.7, op-amp board 2026-10-24), so
  a dashed line cannot be set by stroke style: draw the dashes as individual segments (and
  clip each around pads and wire crossings yourself).
- **A fiducial without a footprint** (so schematic parity stays clean) is a filled
  `PCB_SHAPE` circle on F.Cu (r 0.5) plus a filled circle on F.Mask (r 1.0); DRC accepts
  the unconnected copper graphic (op-amp board, 10.0.7).

## Text metrics

- `SetBold(False)` resets a text's stroke to size/8. Call it before `SetTextThickness()`.
- KiCad's stroke font is wide: capitals advance about 0.9 x the size. Measure a text's
  real extent with `GetEffectiveTextShape().BBox()`; `GetBoundingBox()` adds margins.
- **KiCad's text bounding box includes the font cell**, about 0.3-0.4 mm above the
  capitals (GPSDO rev B). A containment check on KiCad's boxes needs that much tolerance,
  or a heading standing on its own box's edge reads as "in" the box.
- **Text strokes are clamped to a quarter of the character width.** 0.58 mm wide letters
  came out with 0.145 mm strokes and failed DRC's 0.15 mm `text_thickness`. Keep letters
  at least 0.6 mm wide for 0.15 mm strokes, and assert it where texts are made (GPS
  adapters).
- **0.8 mm text is up to 1.1 mm tall** once it has parentheses, commas or descenders.
  Lines of notes need a pitch of about 1.36 mm, or leave the parentheses out. In mixed
  case allow 1.5 mm between 0.8 mm line centres (two lines 1.3 mm apart cleared in
  capitals and collided once "Clipper" and "pass" had descenders; 1.4 mm collided once a
  line had parentheses). Lower-case p and q hang 0.15 of the text size below the line.
  KiCad's box for 0.9 mm text is 1.68 mm tall.
- **Mirrored text: let KiCad measure it** (AMOD back panels, 2026-10-28).
  `SetMirrored(True)` on B.SilkS; a left-justified mirrored text extends to the left of
  its anchor on the board, so it reads left-aligned from the back. Take each line's box
  from a `PCB_TEXT` with the same settings, not from a character count: 0.8 mm text runs
  0.65 (lower case) to 0.79 (digits) mm a character.
- **Place free text by search, not by coordinates** (AMOD/RF-MOD relabel, 2026-10-28): a
  raster of each region at 0.1 mm (bytearray rows; `find(1, i0, i1)` tests a box in C)
  marked with every pad, courtyard, footprint silk item, drawn wire (with its half-width)
  and placed text, plus 0.22 mm; KiCad's own box for each text
  (`PCB_TEXT.GetBoundingBox()`); candidates sorted by distance from the requested spot. A
  block that does not fit drops its last lines with a warning, so the build says what the
  silk lost. Tented vias are not obstacles. KiCad's DRC (`silk_overlap`,
  `silk_over_copper`) is the check. (Of 56 tiles, about 15 had no room for their ranges.)
  See `pcb-silkscreen` for what the text should say.
- **A 0.25 mm occupancy grid cannot judge a 0.15 mm line.** Two boxes that only touch
  round onto the same cell; test thin silk lines against the exact boxes of the texts
  already placed (ECP5 P26: no centre-pin ticks were drawn at all, and the plot could not
  show it).

## Footprint geometry

- **Get the geometry from KiCad, not from memory** (AMOD-P/AMOD-A, 2026-10-25). Dump every
  footprint's courtyard and pad bounding boxes with pcbnew (`FootprintLoad`,
  `GetCourtyard`, `GetBoundingBox`) before placing by hand; the SOT-23-5 pin-one triangle
  pokes 0.09 mm past its courtyard, the SOIC pads are 0.6 wide at 1.27 mm so nothing passes
  between them, the 0402 is the only passive whose body fits a 1.27 mm pin pitch. Every hand
  placement budgeted against those numbers passed DRC first time; every one from recalled
  numbers did not.
- **Place against courtyards before the first DRC** (AMOD-C/M/B, 2026-10-28). A part placed
  by its pads alone collides with a neighbour's courtyard, a jack's legs or a slot one DRC
  round at a time. Print each footprint's pads and courtyard box (a small script over the
  `.kicad_mod`), place against those, and check the boxes in the generator before running
  KiCad.
- **A pad table keyed by pad number loses pads.** A vertical SMA jack's four legs are all
  pad "2"; a USB-C's four shell pads are all "SH". Keyed by (ref, number) they collapse to
  one, and a router or a silk clipper that reads that table puts vias and silk on the three
  it cannot see. Keep every pad in a list for obstacles and the (ref, number) map only for
  wire ends.
- **A drawn symbol replaces the footprint's own outline** (op-amp board, 2026-10-24).
  KiCad's SOT-23 prints a rectangle round the package; inside a hand-drawn transistor
  symbol it reads as a fourth lead. Remove the footprint's F.SilkS graphics in pcbnew
  (`fp.GraphicalItems()`, `fp.Remove`) when the symbol is drawn, and set
  `lib_footprint_mismatch` to ignore in the project's rule severities with the reason in a
  comment, because DRC otherwise reports every edited footprint as differing from its
  library copy. (The user on the first version: the transistor symbols "don't look like the
  transistor symbols in the Art of Electronics. Isn't the arrow always the emitter?" The
  arrow is always the emitter; the legs leave the bar near its ends at about 30 degrees,
  and the package sits between them. See `pcb-silkscreen`.)
- **easyeda2kicad footprints** are in the old format (run `kicad-cli fp upgrade`), and
  their courtyards exclude the pads.

## 3D models

- **A stock 3D model's axes are the stock footprint's.** A footprint drawn in another frame
  (CostasLink's underside socket: rows along -x, the even row at -y) shows KiCad's socket
  model turned 90 degrees. Give the model a `rotate` in the footprint
  (gen/footprints.MODEL_ROT) and LOOK at `kicad-cli pcb render --side bottom`: the user saw
  it in the 3D view (Prompt 35).
- **The AppImage does not ship every 3D model its footprints name** (MSK12C02, RK09K, the
  1812 fuse; also the WSON-8 DSG0008A and the HRO USB-C). Generate a stand-in body of the
  same name in the project's own 3dshapes and let the board generator (`gen_pcb.py`) swap
  it in when the named file is not on disk, or the model check fails and the render shows
  bare pads. The release check that every model resolves is right to fail.
- **A stand-in VRML body is drawn in mm and VRML's unit is 2.54 mm**: substitute it with a
  scale of 1/2.54 (RF-MOD).

## QR codes (KiCad 10: `pcbnew.PCB_BARCODE`, `BARCODE_T_QR_CODE`)

- Make it a knockout (`SetIsKnockout(True)`): a white square with the modules left dark.
  Silkscreen modules on a dark mask read inverted, which many phone cameras will not
  decode.
- KiCad pads the knockout by at least a tenth of the code's size (9 mm -> 10.8 mm), and
  DRC wants 1 mm of "barcode visual separation" from the board edge and from vias.
- Make it on the front and `Flip()` it to the back, so it reads right from the back.
- Measure its extent with `GetBoundingBox()`, not from the size you asked for.

## PCB coils and couplers as net-tie footprints

PCB coils (OWLternating Current's `gen/coils.py`): the footprint's own copper is the
spiral, joining pad 1 to pad 2.
- The footprint's copper may overlap its own pads without a DRC error, but pads with no
  net (the layer-change vias) are still held to hole clearance against it.
- DRC never checks a net tie's copper against its own pads, so the generator must check
  that geometry itself.
- DRC does not compare copper of no net in one footprint with copper of no net in another,
  so the courtyard must enclose all of a coil's copper: it is the only check that keeps two
  spirals apart.

**A PCB coupler or other copper-only element is a net-tie part**, not a label: a symbol
with the line's two pins and the coupled line's two, a footprint whose own copper joins
each pair (`net_tie_pad_groups`), `in_bom` off. Then ERC, the netlist walk and the board
all know it.

## Connectivity clean-up after routing

- **Finish every routed board with KiCad's own connectivity, not the router's grid.** A
  grid router calls two pieces joined when their cells meet, but their copper can stop
  0.05-0.2 mm apart, or a stub can end just outside a pad's corner: DRC then reports
  dangling tracks and unconnected items the router never saw. After the zones are filled,
  ask `GetConnectivity().TestTrackEndpointDangling` for each track. Join each dangling end
  to same-net copper within 0.45 mm with a short segment; remove what is left if it is a
  short dead stub, and remove dangling vias. Refill the zones. Join before removing
  anything, and recompute after every round that joined: removing a dangling via first
  stranded the tracks that nearly reached it, and later rounds removed those too, which
  broke two nets in CostasLink's first run. `gen/tidy.py` is the pass.
- **KiCad's DRC and its connectivity API disagree about a track end that lands on the
  middle of another track of its net**: `TestTrackEndpointDangling()` calls it joined, and
  the DRC calls it `track_dangling` (CostasLink build 18: a fan-out stub whose via never
  fit, ending on the router's own line). After the last fill, take the DRC's list from
  kicad-cli and remove each such track whose removal leaves the unconnected count where it
  was (`gen/board.drop_dangling_by_drc`). One such pass a process (see SWIG above).
- **A clean-up pass that adds copper must be idempotent.** CostasLink's `snap_to_vias`
  added its joining segment again every time the tidy ran: build 17 carried 90 duplicate
  segments, and a second tidy after the refill made 786. Key what a pass adds by (net,
  layer, both ends) and skip what is there; drop exact duplicates at the end
  (`gen/tidy.dedupe`). Count the tracks before and after a pass: a count that doubles is
  the symptom.

## Determinism (detail)

- Every item gets a random UUID, so each rebuild of an unchanged board diffs by about
  20 000 lines. Call `pcbnew.KIID.SeedGenerator(n)` before creating anything, and run the
  script with `PYTHONHASHSEED=0` so set iteration (creation order) repeats: the file then
  comes out byte for byte the same. Seed once and a change to one footprint (more graphics,
  say) shifts every later UUID and reorders the file; reseed before each footprint (from a
  hash of its reference) and before each later stage, so a change shows up only where it is.
- **Footprint items keep the library's uuids in every copy** (GPSDO rev B, 2026-10-09). A
  generator that copies a `.kicad_mod`'s text into the board gives every instance's pads,
  graphics and keep-outs the same uuids: 97 of them on 1491 items. KiCad 10's solder-mask
  check keys apertures by uuid, and it reported a U.FL's mask rectangle as bridging a track
  of another U.FL's net 125 mm away, in one build and not the next. Give each instance's
  items their own uuid, derived from the reference and the library uuid so rebuilds stay
  identical (GPSDO `pcb/build_pcb.py`, `footprint()`).
