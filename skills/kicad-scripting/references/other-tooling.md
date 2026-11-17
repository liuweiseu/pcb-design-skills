# Other tooling: scripted edits, renames, datasheets, data sources, build environments, FPGA builds

## Scripted edits of source files

- **Never replace a string you have not proved non-empty** (AMOD-2/RF-MOD-2, 2026-10-25).
  A scripted edit computed `old` as a slice that came out empty, and `s.replace("", new)`
  inserted `new` between every character of a 50 kB board module. It was recovered by
  striding the corrupt text (`s[L::L+1]` with `L = len(new)`), but every scripted edit now
  asserts `old` is non-empty and occurs exactly once, and a scratchpad copy is taken before
  each one.
- **Write the final expression, not a placeholder** (AMOD, 2026-10-28). `X if False else Y`
  left in while iterating reads as logic and is dead code; write Y, or a TODO the build
  fails on.
- **Pass every width.** A ground stub that defaults to "the tile's first wire" took a 1 mm
  motor rail's width on two tiles and shorted the pads beside it. A default borrowed from
  elsewhere is a bug waiting for the first wide wire.
- **The library's sexp round trip keeps one of two identical pad keys**: replace a line
  rather than adding a second one (see `pcbnew-api.md`).

## Renames (AMOD and RF-MOD tiles, 2026-10-28)

- **Rename with a tokenizer, not a regular expression.** The same two characters were tile
  names, USB-C pin names ("A4": "VBUS"), local net names ("N1", "P1"), a 4046's R1 and C1,
  a paper size (an A1 sheet), a PBM header ("P1\n") and the reel suffix of part numbers
  (ADL5350ACPZ-R7). Change a whole-string token only where the code makes it a tile (the
  tile constructor's first argument, the silk number, the keys of the per-tile dicts),
  change prose by word with a list of protected phrases, then grep the diff for a changed
  token glued to a hyphen or a part number. Net names built on the tile name ("/X3_V33")
  hide from a word-boundary search: search for the name followed by an underscore too.
- **A rename must never move a name onto something else**: retire, never reuse, the names
  that go, so a missed reference points at nothing instead of at the wrong item (the naming
  scheme itself is in `pcb-silkscreen`).
- **A document can hold two numberings.** The tutorial's appendix kept the plan's tile
  numbers beside the as-built ones; renaming the whole file would have pointed the plan's
  "Y9, an H-bridge" at the built board's noise source. Rename only the as-built sections
  and mark the plan's names as its own.
- **Rename the file with its references** (2026-10-28). An appendix's text was changed to
  new board names and its images kept the old file names: three broken pictures, found a
  day later. After any rename, loop over every referenced file and check it exists.

## One source for generated documents

- **Generate the README's tables and the handbooks from one source.** A per-tile record
  (what it does, the chip and its maker's page, specs, limits, experiments, how to cable
  it, what to buy) feeds both, so they cannot disagree (AMOD/RF-MOD, 2026-10-28). Back-panel
  silk lines live in the board's source (a dict per board) for the same reason.
- **One hand-laid geometry per circuit kind, reused with an offset** (AMOD-P/A,
  2026-10-25). The non-inverting op-amp stage was laid once (`opa_tile`) and used by five
  tiles; a double tile uses it with x + 21.5. The hours go into the first instance; the
  rest are free and DRC-clean.

## Datasheets and data sources

- **Datasheet fetching** (2026-10-09): ADI's direct PDF links want a browser `User-Agent`
  (a bare `curl` times out); Skyworks' `/-/media/` links need the exact revision in the
  file name (the product page returns HTML for a guessed name); JLCPCB's file endpoint
  (`tools/jlc_datasheet.py <code>`) serves the LCSC copy of oscillator and connector
  sheets. Digi-Key returns 403 to scripts and the aggregators (findchips, octopart) omit it
  or 403 too: ask the user to read Digi-Key/Mouser stock in a browser; quote the aggregator
  snapshot as such.
- **Read a chart's curves from the PDF's vector paths**, not by eye (PID motor board):
  `pdftocairo -svg -f N -l N` and parse the `<path d=...>` points with their `transform`;
  the grid lines give the axes. Eyeballing a rendered chart put the same curve's ends 5 %
  apart on two tries.
- **EasyEDA's `c_spicepin` is the SPICE order, not always the printed pin number**
  (AMOD/RF-MOD, 2026-10-29). Pairing names by it made the PAM8302's pin 2 read IN- and its
  pin 8 NC. The printed number is the pin group's numeric text; use that when the two
  differ. (Pin and rotation checks against EasyEDA data are in `jlcpcb-order`.)

## Build environments: the bench PC's `PATH` hides the system's tools behind a vendor's (GPiBridge, 2026-11-15)

- **What happened:** on the bench PC, Vitis 2022.1 puts its own CMake 3.3.2 (which no longer
  starts: it wants `libidn.so.11`) and its own `arm-none-eabi-gcc` 11 ahead of `/usr/bin`, so
  the firmware build picked up the vendor's tools, not the system's.
- **A build script must name what it uses:**
  - put `/usr/bin` first in the environment it gives CMake;
  - pass the toolchain's place explicitly (`-DPICO_TOOLCHAIN_PATH=/usr` for the Pico SDK);
  - build into `build-<hostname>/`, since a CMake cache remembers the folder it was made in
    and a cache made on another machine breaks the build.
- **Tools installed for a bring-up go in the user's own prefix (`.local` in the home
  directory) with names that shadow nothing:** `openocd-xpack` (an OpenOCD that knows the
  RP2350) sits beside the system's `openocd`, which another project's scripts call.
- See also "Let an explicit tool path win" in SKILL.md (KiCad 9's `kicad-cli` in /usr/bin
  beating the AppImage on reviewers' machines).

## FPGA builds: Vivado drops the tristates inside an IP Integrator module reference (CostasLink rev A, 2026-10-29)

- **What happened:** the block design's cells were synthesized out of context, and every
  PYNQ build said "[Synth 8-5799] Converted tricell instance to logic" for the I2C SCL and
  SDA pins. That is a critical warning, and nobody read the log.
- **The result:** the FPGA drove the open-drain lines instead of releasing them. I2C never
  worked on the board, and the build still reported success.
- **The fix:** `set_property synth_checkpoint_mode None` on the `.bd` (global synthesis),
  or real IOBUF instances.
- **Check it in the build:** fail the build unless each tristate port's leaf cells are an
  IOBUF or OBUFT (`get_pins -leaf` of the port's net; the plain net only reaches the
  hierarchical cell). Read every critical warning of every build, not only the timing.
- **Give every bus master a timeout**, and a register showing its raw pin levels. A master
  that waits forever on SCL turns a wiring fault into a hang. With the levels readable, the
  fault took minutes to place.
