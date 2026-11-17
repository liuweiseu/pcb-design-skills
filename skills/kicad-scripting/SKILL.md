---
name: kicad-scripting
description: KiCad 10 tooling quirks for generated boards - running KiCad/kicad-cli/the AppImage, pcbnew Python (SWIG) traps, generated schematics and symbols, DRC/ERC messages, deterministic UUIDs and outputs, easyeda2kicad, Inkscape, and netlist-to-SPICE simulation with ngspice. Use when writing or debugging a board/schematic generator, calling pcbnew or kicad-cli from a script, chasing a puzzling DRC/ERC report, making rebuilds byte-identical, doing scripted edits of source files, or simulating the exported netlist.
---

# KiCad 10 scripting and tooling quirks

Rules learned the hard way while generating boards with KiCad 10 from Python (CLAUDE_PCB.md
§11 plus the tooling lessons of the dated sections). Each bullet names the board it came
from; keep those citations when you add to this skill (see `record-lesson`).

Related skills: `pcb-workflow` (build system, gates), `pcb-schematic` (what a schematic
must show), `pcb-silkscreen`, `pcb-layout`, `jlcpcb-order` (CPL rotations, parts,
release), `component-selection`.

References (read when the task touches them):
- `references/pcbnew-api.md`: every pcbnew/SWIG trap in full, the connectivity tidy pass,
  text metrics, QR codes, net-tie coils, 3D models. Read before writing or debugging any
  `import pcbnew` code.
- `references/schematic-generation.md`: schematic quirks, generated symbols, placing notes
  and labels, root sheets, block diagrams, "every wire states what is on it". Read when
  generating or checking a schematic.
- `references/drc-erc-plotting.md`: DRC/ERC findings a script misses, zone necks, rule
  traps, plotting and rendering recipes, deterministic outputs. Read when a DRC/ERC report
  puzzles you or when making images/release files.
- `references/ngspice.md`: simulating the exported netlist (PID motor board), ngspice
  traps, friction and op-amp models. Read before any SPICE work.
- `references/other-tooling.md`: datasheet fetching, chart reading from PDFs, Vivado
  tristates, a bench PC's `PATH` and build environment, Ghostscript, renames and scripted
  edits in detail. Read when those come up.

## Running the tools

- **Run KiCad's Python through the AppImage's `AppRun`.** `kicad-cli` is a subcommand of
  the AppImage (e.g. `kicad-10.0.6-x86_64.AppImage`). With an extracted copy (`AppDir`),
  run `AppDir/AppRun python3.11 script.py`: calling `usr/bin/python3.11` directly with
  `LD_LIBRARY_PATH` set segfaults on `import pcbnew` (10.0.6).
- **On a bench PC, a vendor's `PATH` can hide the system's tools** (GPiBridge,
  2026-11-15: Vitis 2022.1's broken CMake 3.3.2 and its own `arm-none-eabi-gcc` ahead of
  `/usr/bin`). A build script names the tools it uses, builds into `build-<hostname>/`, and
  bench tools are installed under names that shadow nothing (`references/other-tooling.md`).
- **Let an explicit tool path win, and check the version of one found on PATH** (PID motor
  board). Two reviewers' machines had KiCad 9's `kicad-cli` in /usr/bin; it beat
  `KICAD_APPIMAGE`, and /usr/share/kicad's KiCad 9 libraries beat the AppImage's.
- **The GUI under Wayland** (no middle-drag, layers not repainting until a zoom) is the
  native Wayland canvas, not the file. Open boards with a `kicad-gui.sh` that sets
  `GDK_BACKEND=x11`.
- **Inkscape 1.x hangs** with `DISPLAY`/`WAYLAND_DISPLAY` and a session bus. Run it with
  those unset and `DBUS_SESSION_BUS_ADDRESS=/dev/null`.
- **Never `source` a Python file in bash** (AMOD/RF-MOD, 2026-10-28). Its first line,
  `import atexit, glob, os`, runs ImageMagick's `import`, which waits for a mouse click to
  grab the screen: the shell hangs until killed.
- **Absolute paths in every shell command** (CostasLink, 2026-10-09). The tool shell's
  working directory can be reset between commands; one batch wrote four datasheet PDFs at
  the repository root. Check `git status` at the repository root before calling a response
  done.
- **Keep build scratch inside the project's gitignored `build/`**: an agent's scratchpad
  directory can vanish between sessions.
- **`find` does not follow a symlink given as its starting point.** If the repo path is a
  symlink, `find <link> -name fit_pdf.py` finds nothing (and a board nearly got a second,
  divergent fitter). Use `find -L` or a trailing slash (`find <link>/ ...`), and grep the
  tools a lesson names before writing a new one.

## Build stages

- **A stage that reads another stage's output must make it if it is missing** (PID motor
  board): the sim ran before the schematic and read the uncommitted `out/*.net`, so a fresh
  clone fell back to committed results with a misleading message.
- **Run the stage that consumes your edit** (AMOD/RF-MOD, 2026-10-28). The pcb stage reads
  the tiles' JSON written by the sch stage: an edit to a board module followed by
  `--stage pcb` alone silently builds the old silk (and a debugging round went to a
  placement bug that was not there). Run `--stage sch --stage pcb`.
- **A crash in a generator must exit with a code the build does not accept as a soft
  result** (e.g. "overlaps") (CostasLink).

## pcbnew from Python: the traps (detail in references/pcbnew-api.md)

- **`board.Save()` rewrites the `.kicad_pro`** with default net classes and rules. Write
  the project file again after saving (GPiBridge, 2026-10-06).
- **Fill zones in a fresh process.** A `LoadBoard()` in a process that already saved an
  in-memory board reuses KiCad's default project: the fill ignores the project's net
  classes and custom rules, and its save writes defaults over the `.kicad_pro` (CostasLink
  build 18: Default clearance 0.2 mm, 479 DRC errors). Refill in a fresh process
  (`AppRun python3.11 board.py --refill`), then rewrite the project file.
- **Call `board.BuildConnectivity()` on an in-memory board** before `ZONE_FILLER`, or it
  judges islands unconnected and silently drops pours (the ground under a USB-C vanished).
- **`pcbnew.WriteDRCReport()` segfaults in a bare Python** (needs KiCad's program object):
  run `kicad-cli pcb drc` on the saved file.
- **One structural change per process.** After a zone fill, SWIG hands back
  `GetConnectivity()` as a bare object without methods; after a Remove/Add and a
  connectivity rebuild, `track.GetStart()` comes back as an opaque SwigPyObject with no
  `.x` (CostasLink, Prompt 31). One removal pass a process, then a fresh process.
- **Never use `is` on pcbnew objects**: every call returns a fresh wrapper. Compare
  `item.m_Uuid.AsString()` (CostasLink's first cleanup found every track touching itself).
- **Views die with their owners.** `BOX2I.Merge()` returns a non-owning view: write
  `bb.Merge(b)` on its own line, never `bb = bb.Merge(b) or bb` ("malloc(): unaligned tcache
  chunk detected", two 25-minute builds lost; CostasLink 2026-10-09).
  `SHAPE_POLY_SET.Outline(i)` on a temporary reads freed memory (Edge.Cuts to -1000 mm):
  keep the set in a name. Copy a SWIG vector's numbers before its owner goes: `m.m_Scale`
  kept as a proxy wrote a scale of 1486236861 (RF-MOD, 2026-10-25).
- **Layer names: map to constants yourself.** `board.GetLayerID()` knows only long names
  (`F.Silkscreen`); `"F.SilkS"` gives an undefined layer, the item is saved there, and
  `kicad-cli` refuses the board ("items on undefined layers"). Use `pcbnew.F_SilkS` etc.
- **New footprint fields are visible on F.SilkS.** `FOOTPRINT.SetField()` with a new name
  (LCSC, MPN) makes a visible silk field: hide it and move it to F.Fab, or 400 silk DRC
  errors appear.
- **Text:** call `SetBold(False)` before `SetTextThickness()` (it resets the stroke to
  size/8). Measure real extent with `GetEffectiveTextShape().BBox()` (`GetBoundingBox()`
  adds margins, and includes a font cell 0.3-0.4 mm above capitals). Strokes are clamped to
  a quarter of the character width: keep letters at least 0.6 mm wide for 0.15 mm strokes
  and assert it. Let KiCad measure mirrored text too (`SetMirrored(True)` on B.SilkS).
- **`pcbnew.STROKE_PARAMS` is not exposed** (10.0.7): draw dashed lines as individual
  segments.
- **Get footprint geometry from KiCad, not memory** (AMOD, 2026-10-25): dump courtyards and
  pad boxes (`FootprintLoad`, `GetCourtyard`, `GetBoundingBox`, or a small script over the
  `.kicad_mod`) and place against those boxes before the first DRC.
- **Keep every pad in a list for obstacles**; a (ref, number) map only for wire ends. A
  vertical SMA's four legs are all pad "2", a USB-C's shell pads all "SH": a table keyed by
  number loses three of them.
- **A clean-up pass that adds copper must be idempotent**: key additions by (net, layer,
  both ends), skip what exists, dedupe at the end, count tracks before and after (a count
  that doubles is the symptom; CostasLink build 17: 90 duplicates, then 786).
- **Finish every routed board with KiCad's own connectivity, not the router's grid**:
  after filling, join dangling ends to same-net copper within 0.45 mm, then remove dead
  stubs and dangling vias, recompute after every joining round, refill; then remove the
  DRC's remaining `track_dangling` items one per process. Full procedure in the reference.

## Determinism

- **Rebuilds must be byte-identical.** Call `pcbnew.KIID.SeedGenerator(n)` before creating
  anything, run with `PYTHONHASHSEED=0`, and reseed before each footprint (from a hash of
  its reference) and before each later stage, so a change shows only where it is (an
  unseeded rebuild diffs by about 20 000 lines).
- **Give each footprint instance its own item uuids**, derived from the reference and the
  library uuid (GPSDO rev B, 2026-10-09): copying `.kicad_mod` text gave 97 shared uuids on
  1491 items, and KiCad 10's solder-mask check, which keys apertures by uuid, reported a
  U.FL's mask bridging a track 125 mm away, in one build and not the next.
- **Hash every UUID the generator writes** (`uid(key)` = uuid5): key strings written as
  UUIDs ("box/fuse") were replaced at random by `kicad-cli sch upgrade` on every build.
- **Stamp dates over plot times**: Gerbers, drill files, job files and zips carry the
  plot time; Ghostscript PDFs carry an ID, dates and XMP. See
  `references/drc-erc-plotting.md`.

## Schematic and symbol generation (detail in references/schematic-generation.md)

- **KiCad symbol coordinates have y up**; check a pin's sheet position before deciding
  which is "upper" (SW_SPDT pin 1 at (5.08, 2.54) is the upper right pin; `mirror x` puts
  pole 3 on top; PID motor board).
- **Every generated pin on the 1.27 mm grid**: wires and pins connect only where they
  coincide on the 50-mil grid (CostasLink: 35 stub warnings, every ground "not
  connected").
- **Pins that touch a wire's interior do not connect.**
- **Bus aliases live in the `.kicad_pro`** (`schematic.bus_aliases: {"NAME": [...]}`);
  `kicad-cli sch upgrade` drops any `(bus_alias ...)` in a sheet (ECP5 build 28).
- **Number power symbols** `#PWR0001`... across the sheets of one run, or the netlist
  export warns of annotation errors.
- **Pin names: hyphens, not spaces** (spaces print as underscores).
- **Local labels carry the sheet path** ("/TX_FC_TO_GPS"), power symbols do not; a board
  generator that looks nets up by name must try both. Name cross-tile/cross-block nets
  globally from the start (`/ENC_DO`), and give helper nets distinctive names (`GQ`, `SQ`,
  not `G`): local names in one namespace merge silently and ERC is happy.
- **Resolve `extends` chains recursively** and rename every `NAME_u_s` sub-symbol whatever
  its prefix; one level of flattening yields a symbol with no pins.
- **Gate: every pad of every footprint carries a net or a no-connect flag**
  (tools/net_check.py): an incomplete generated symbol passes ERC, the netlist walk and
  the renders.
- **Place, then check, then look**: the generator places notes against the checker's own
  geometry, then render every sheet and crop each flagged spot at 300 dpi.

## DRC/ERC and plotting (detail in references/drc-erc-plotting.md)

- **DRC and the connectivity API disagree** about a track end on the middle of a same-net
  track: `TestTrackEndpointDangling()` says joined, DRC says `track_dangling`.
- **`track_dangling` points at a track's start**, even when the other end is loose.
- **End tracks at a via's centre** and at least half their width inside a pad.
- **A via with copper on one layer only is dangling**; a branch ends on a via or pad,
  drawn as one polyline, never mid-trace. An open-ended stub is drawn as copper graphics
  on its net.
- **ERC's JSON positions are in 100 mm units** (`"x": 2.9972` is 299.72 mm).
- **A custom `silk_clearance` rule on text** makes KiCad 10 report every designator
  against Fab text and courtyards as `silk_overlap`.
- **`kicad-cli pcb drc --severity-all`** lists warnings as `[rule]:` lines like errors.
- **Warnings name the nearest item, not the cause** (`connection_width`, "silk clipped by
  solder mask"): bisect by deleting pieces in a scratch build.
- **easyeda2kicad footprints** are in the old format (`kicad-cli fp upgrade`) and their
  courtyards exclude the pads.
- **The AppImage does not ship every 3D model** its footprints name: generate stand-in
  bodies and swap them in when the file is missing.

## Simulation (detail in references/ngspice.md)

- **Simulate the exported netlist, not a hand-typed deck**, and make the
  netlist-to-SPICE step refuse a value it has no model for ("rebuild the schematic first").
- **`limit(x, lo, hi)` in ngspice is a Monte-Carlo function**, not a clamp: use
  `min(max(x, lo), hi)`.
- **Spell signs in node names** ("P15V", "M15V"): "+15V" and "-15V" sanitise alike.
- **`.ic V(out)=0` on every integrator**, or it starts railed.
- **Take a transistor's dissipation from its own pins** (`V(c) - V(e)` via `Deck.pin`).
- **Stop a stuck ngspice-through-ctypes run with `timeout -s KILL`**: a Python signal
  handler cannot interrupt the library (op-amp bring-up rehearsal, 2026-11-15).

## Generator code and scripted edits

- **Never replace a string you have not proved non-empty** (AMOD-2/RF-MOD-2, 2026-10-25):
  `s.replace("", new)` inserted `new` between every character of a 50 kB module (recovered
  by striding `s[L::L+1]`, `L = len(new)`). Assert `old` is non-empty and occurs exactly
  once, and copy the file to scratch before each edit.
- **Rename with a tokenizer, not a regular expression**, and after any rename check every
  referenced file exists (see `references/other-tooling.md`).
- **Pass every width**: a default borrowed from "the tile's first wire" took a 1 mm motor
  rail's width and shorted the pads beside it (AMOD, 2026-10-28).
- **Write the final expression, not a placeholder**: `X if False else Y` is dead code that
  reads as logic; write Y, or a TODO the build fails on.
- **One hand-laid geometry per circuit kind, reused with an offset** (`opa_tile` used by
  five tiles; a double tile at x + 21.5): the hours go into the first instance.
- **Generate tables, handbooks and silk text from one source** (a per-tile record, a
  budget JSON), so they cannot disagree.
- **Make checkers say which line drew the item** (`file:line` via `inspect.stack()`) and
  provide a `sch_where.py SHEET X Y` (CostasLink: 108 problems to 0 in an hour).
