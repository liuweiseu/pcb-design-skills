# Tile boards: silkscreen on boards of building blocks

Read when a board is a grid of circuit tiles (AMOD, RF-MOD, PhMOD, AMOD-P2: a 100 x 100 mm
grid of 20 mm cells, every cell a circuit between two SMA jacks, the silkscreen the
schematic). Layout of the tiles themselves is in the pcb-layout skill; text sizes and
pitches in `text-metrics.md`.

## Relabelling the AMOD and RF-MOD silkscreens (2026-10-28, §21)

The user read the five boards' renders and could not tell what most tiles did or which
jack was which. What fixed it:

- **A label in the gutter between two boxes belongs to neither.** The jack names sat
  centred in the 1.5 mm gutter above or below each jack, so "OUT A  REF IN  IF" under one
  tile read as that tile's when two of the three belonged to the tile below.
  - Put a jack's name ON its own tile's frame line, beside the jack, and break the frame
    round it (a legend in a fieldset): a name inside a frame's line reads as that
    frame's, and the neighbour's frame across the gutter stays unbroken.
  - Any tile text that sits on the frame breaks it the same way.
  - Clear the jack's legs: their pads reach 3.64 mm from its centre, so the name's box
    stops 0.22 mm short of that.
- **Say what a tile is in words, not by its chip.** "QPL9547", "GALI-84+", "AD8318" mean
  nothing to a reader without the datasheet; "LNA QPL9547", "GAIN", "POWER METER" do.
  - The top frame line, right of the top-left jack's name, is the one strip every tile
    has free: put a short title there, slid left from the right end until it clears
    pads, bodies, drawn wires and the neighbours' names (0.8 mm along, 0.5 mm across the
    gutter).
  - Put the ranges and levels (RF 0.4-2.5 GHz, LO 0 to +6 dBm, IF DC-200 MHz) inside the
    tile where they fit.
- **Place free text by search, not by coordinates.**
  - A raster of each tile at 0.1 mm (bytearray rows; `find(1, i0, i1)` tests a box in C)
    marked with every pad, courtyard, footprint silk item, drawn wire (with its
    half-width) and placed text, plus 0.22 mm.
  - KiCad's own box for each text (`PCB_TEXT.GetBoundingBox()`).
  - Candidates sorted by distance from where the tile asks.
  - A block that does not fit drops its last lines with a warning, so the build says
    what the silk lost.
  - Tented vias are not obstacles. KiCad's DRC (`silk_overlap`, `silk_over_copper`) is
    the check.
  - Of 56 tiles, about 15 had no room for their ranges; their titles and jack names fit.
- **Never print a document's section numbers on copper.** The tiles carried the tutorial
  sections they serve ("4.06 5.02"); the tutorial is renumbered as it grows and the board
  cannot be. Name pages by title in the handbook, nothing on the board.
- **Give each tile its own picture in its handbook entry.** Render the board's top at
  about 25 px/mm, find the board in the image by its solder-mask green (columns and rows
  where G > R + 12 and G < 110), and crop each tile's frame with 0.9 mm round it. A table
  with the picture in the first column and the description beside it means the reader
  never scrolls back to the board. Save as JPEG: a render compresses badly as PNG.
- **Generate the README's tables and the handbooks from one source.** A per-tile record
  (what it does, the chip and its maker's page, specs, limits, experiments, how to cable
  it, what to buy) feeds both, so they cannot disagree.
- **The pcb stage reads the tiles' JSON written by the sch stage.** An edit to a board
  module followed by `--stage pcb` alone silently builds the old silk: run `--stage sch
  --stage pcb`. (Again in §24: rebuilding only the board stage drew the old panel text,
  and a debugging round went to a placement bug that was not there. Run the stage that
  consumes your edit.)

## Naming jacks and drawing modules (§22)

- **A jack's name says whose port it is.** "AUDIO IN" beside "MIC OUT" left the user
  asking "whose in?"; "SPEAKER IN" names the thing the signal goes to. On a tile with two
  channels, name each jack by its channel's device or function, never by a generic
  signal ("AUDIO", "SIGNAL", "RF" alone when the tile has two RF ports).
- **Draw what is inside a module.** A diode-ring mixer in a ceramic case is a white box;
  its two baluns and ring of four diodes drawn beside it on the silk (`Tile.draw_line`,
  `draw_arc`) are the lesson. Check the drawing's topology on a high-resolution render:
  the ring runs A to C to B to D, the LO across one opposite pair, the RF across the
  other.

## Text fit (§17, §23)

- About ten characters of 0.9 mm text fit a one-cell tile's top frame beside its jack:
  name tiles to fit (Attenuator, Balun, Preamp).
- Frame and clearance numbers, and mixed-case line pitch: `text-metrics.md`.
- **Moving a jack moves what was behind it** (§19): the back's QR code, the board's long
  back wires, the gutter labels of the tiles above and below, and a neighbour's ground
  symbol all met the moved jacks. Each was caught by a check (the QR-over-hole check,
  DRC's silk rules), so run the full build after every tile, not at the end.

## Back panels (2026-10-28, §24)

- **The back of a board of building blocks is its manual.** The user (AMOD-and-RFMOD
  Prompt 18): "When someone is screwing things into the board, it's far easier to read
  the silkscreen in front of them than it is to look up stuff on github and try to make
  sure they are looking at the correct list for the correct board."
  - Under each tile, on the back: its number and title, then its input limit, its load,
    its supply and switch, and the one thing that breaks it; where there is room, a small
    plot of the response to expect.
  - Keep the panel's lines in the board's source (a dict per board) so the handbook and
    the silk cannot disagree about which tile they describe.
- **The warnings that prevent damage go on the front as well.** The back is read while
  cabling, but the front is what faces you when the board is on the bench. "PULSES ONLY",
  an LNA's input limit and "start at mV" for a laser driver went onto the front, an LNA's
  noise figure making room.
- **Mirrored text: let KiCad measure it** (`text-metrics.md`).
- **Budget a line's length by the free space, not by the tile.** On a 20 mm cell with
  jacks at two opposite corners the free space is about 10 mm wide: 13 characters at
  0.8 mm. Longer lines forced a panel into scattered pieces or into no room at all;
  shortening them ("IN < -20 dBm", "+22 dBm BURNS") placed every panel. A QR code and its
  caption take most of a cell's back: the panel there gets 7 mm.
- **Place a panel in reading order and prefer compact to clear.** A greedy
  nearest-free-spot placement of a panel's parts put lines above their own title. Place
  each part below the one before; try one block, then two, three, four parts; for each
  split try clear of tracks and vias, then of tracks only, then over them. A block over a
  tented track reads; a panel in four scattered pieces does not.
- **A plot on the back runs mirrored.** Draw the x axis reversed in board coordinates so
  it reads left to right from the back; the y range in the line above the box ("0 to
  -60 dB"), the x ends below it, nothing inside but the curve; drop to a smaller size
  when the two x labels would meet. Plot what the tile does: a clipper's OUT against IN,
  not its (flat) frequency response.

## Naming and renaming tiles and boards (2026-10-28, §23, §25)

- **Give a family of boards one letter each, and name a tile by its letter and a number,
  in lower case.** The user (AMOD-and-RFMOD Prompt 19): "If we can have a nice, well
  justified single-letter designator for each board, it would make everything much more
  clear", and "D11, Q11, C11, etc look like a reference designators for diodes,
  transistors, and capacitors. d11, q11, and c11 don't look like obvious electronics or
  PCB things." The letter is the initial of what the board is about; board names keep
  their capitals, ports are capitals, titles mixed case.
- **A rename must never move a name onto something else.** Keep every letter on its
  board and retire, never reuse, the names that go: then a reference missed in the update
  points at nothing instead of at the wrong tile. Reassigning A from the active board to
  the passive one, or renumbering a board with gaps, would have turned every stale "A4"
  or "R5" into a silent error. Avoid letters that already mean something on the boards
  (s11 is a reflection coefficient) and letters that read as digits (i, l, o).
- **Give a new board a new name.** AMOD-2 became PhMOD; the new passive board took
  AMOD-P2, not the freed AMOD-2, because the commits, the tutorial and the chat log mean
  the physics board by the old name (§23).
- **Rename with a tokenizer, not a regular expression.** The same two characters were
  tile names, USB-C pin names ("A4": "VBUS"), local net names ("N1", "P1"), a 4046's R1
  and C1, a paper size (an A1 sheet), a PBM header ("P1\n") and the reel suffix of part
  numbers (ADL5350ACPZ-R7).
  - Change a whole-string token only where the code makes it a tile (the tile
    constructor's first argument, the silk number, the keys of the per-tile dicts).
  - Change prose by word with a list of protected phrases.
  - Then grep the diff for a changed token glued to a hyphen or a part number.
  - Net names built on the tile name ("/X3_V33") hide from a word-boundary search: search
    for the name followed by an underscore too.
- **A document can hold two numberings.** The tutorial's appendix kept the plan's tile
  numbers beside the as-built ones; renaming the whole file would have pointed the plan's
  "Y9, an H-bridge" at the built board's noise source. Rename only the as-built sections
  and mark the plan's names as its own.
- **Rename the file with its references** (§26). An appendix's text was changed to new
  board names and its images kept the old file names: three broken pictures, found a day
  later. After any rename, loop over every referenced file and check it exists.
- **A letter with a descender changes the silk's clearances.** Lower-case p and q hang
  0.15 of the text size below the line and met the line under them on three tiles; DRC
  found each.
