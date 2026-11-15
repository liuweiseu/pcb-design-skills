# Build system: detail, audits and worked examples

Companion to SKILL.md §2. Read it when setting up a board's build, auditing paths, wiring a
parameter through generators and documents, or fetching datasheets.

## Relative paths: the 2026-10-06 audit

About 100 committed files in the older projects broke "all paths are relative":

- Library tables and 3D model paths into other people's home directories (`/home/<user>`, `/Users/<user>`):
  SyzygyRadioDrivers, PMOD_direct_to_SMA, VerifierPCB, Photodiode amplifiers, STM32. Those
  boards open without their libraries and models anywhere else.
- Netlists with an absolute `(source …)`: ECP5, GPSDO, IcepiZeroADCDAC, SyzygyRadioDrivers'
  review, and the old Windows ones (`C:\Users\<user>\…`).
- Icepi's inherited plot directory, in a previous author's `/home/<user>/…`.
- Scripts reading data or scratch files from outside the repository: SyzygyRadioDrivers'
  `SMABridgeTestAnalysis/`.
- About 30 scripts naming tools under `~`, many with no environment override (ECP5's
  `gen/gen.py`, `gen/kisch.py`, `tools/kisym.py`; GPSDO's `gen/kigen.py`).
- The root `.gitconfig`'s diff driver in a user's `~/.venv`.
- Caches committed by mistake: `fp-info-cache`, `temp-freerouting.dsn`, STM32Cube's
  `.mxproject`.

Generated files that hide absolute paths: a KiCad netlist records its schematic's absolute
path in `(source …)`; plotting from the GUI stores the output directory in `.kicad_pcb`
(`outputdirectory`) and `.kicad_pro` (`last_paths`). Rewrite them as relative in the step that
writes them.

## One place for every parameter: the CostasLink example (2026-10-12, Prompt 30)

- **The value is written once** in the design script (`sim/budget.py`). The schematic generator
  gets it through a lookup to the parts table's nearest stocked value, which asserts the match
  (`gen/levels.py`: `res_key`, `cap_key`, `VAL`). Every note that quotes it is formatted from
  the same results.
- **Run-time constants**: `gateware/board_constants.py`, written by the build from the budget.
  The driver and the register scripts import it, because they travel to the target without
  `build/`. A test fails when the module differs from the build. The driver's hand-copied
  `A_REG_V` had been the 10 m case's level, not the regulated one: 0.1 dB.
- **Studies are build steps**: `sim/wifi_channels.py`, left out of the build, had crashed
  since its last edit, unnoticed.
- **Document claims**: `tools/doc_check.py`, one claim per quoted number (a pattern, the files,
  the value it must read now); a claim that matches nowhere fails, so rewording a sentence
  cannot drop its check silently.
- **As fitted, not as computed**:
  - the Costas loop was designed for 3000 Hz, ζ 0.707; the fitted 10 k makes it 2916 Hz,
    ζ 0.687;
  - the budget had printed an "E24" 9.1 k that the board never had;
  - its block diagram quoted the computed values, with a 2 % overshoot; a phase step's real
    overshoot with the PI's zero is 21 %.
- **Grep for the old number**: two auditors (subagents, one per document group) checked every
  number in CostasLink's documents against the JSON. They found:
  - 23 computed or shared passive values typed into five sheet generators: consistent, but
    nothing tied them to the budget;
  - a sheet note giving the log amp's input noise as 0.8 mV; that is the demodulator's input
    noise, the right figure is 2.3 mV, 9 dB more;
  - the driver's hand copies of the gains, levels and noise bandwidths; its bring-up check also
    left out the I2C part added two prompts before;
  - the latency and its halves quoted in nine places as they were before build 18's 33 Ω made
    them 23.5 ns (8.5 + 15.0);
  - the supply current, in five documents, a revision behind; the budget also counted six
    comparators where the board has eight;
  - about 80 more stale figures in the plan: noise floors, the isolation table, ranges, header
    pins;
  - figures no script computes at all (section 19's passive knobs). Write the script.

## Generated documents

- From the source of truth: the pinout (ASCII art), a bring-up handbook and the end-user guide
  (GPSDO P29); PDFs and PNGs of every sheet; layer plots cropped to the board outline (Lorenz
  P2); 3D renders from several sides.
- **Generate the README's tables and the handbooks from one source** (AMOD/RF-MOD,
  2026-10-28). A per-tile (per-block) record (what it does, the chip and its maker's page,
  specs, limits, experiments, how to cable it, what to buy) feeds both, so they cannot
  disagree.
- **Give each block its own picture in its handbook entry** (AMOD/RF-MOD, 2026-10-28). Render
  the board's top at about 25 px/mm, find the board in the image by its solder-mask green
  (columns and rows where G > R + 12 and G < 110), and crop each tile's frame with 0.9 mm round
  it. A table with the picture in the first column and the description beside it means the
  reader never scrolls back to the board. Save as JPEG: a render compresses badly as PNG.
- **A document can hold two numberings** (AMOD renaming, 2026-10-28). The tutorial's appendix
  kept the plan's tile numbers beside the as-built ones; renaming the whole file would have
  pointed the plan's "Y9, an H-bridge" at the built board's noise source. Rename only the
  as-built sections and mark the plan's names as its own.

## Looking at the output

- Export the schematic to PDF/PNG, render the board, and look, as the user will. Most of the
  user's corrections were visible in one glance at a render.
- **One corner as the fab prints it**: GPSDO's `pcb/silk_region.sh BOARD X0 Y0 W H out.png`
  plots F.SilkS, F.Mask and Edge.Cuts one at a time
  (`kicad-cli pcb export svg --mode-single --page-size-mode 0`), crops each by rewriting the
  SVG's `viewBox` in board millimetres, recolours it and stacks the three. One plot of all the
  top layers buries the silkscreen under copper fill and Fab text (GPSDO r45).
- **Render one tile at a time while laying it out** (AMOD jacks, 2026-10-25).
  `kicad-cli pcb export svg` of F.Cu, F.Silkscreen and F.Courtyard, cropped to the cell with
  Inkscape's `--export-area`, shows a tile at 35 px/mm in seconds; most mistakes are visible
  before DRC runs.

## Datasheets

- `datasheets/`, gitignored for copyright. Every IC, connector and mechanical part. Pinouts
  from the **pin figure**, not only the table.
- **Analog Devices PDFs download directly** (2026-10-08):
  `https://www.analog.com/media/en/technical-documentation/data-sheets/<name>.pdf` with plain
  `wget` (ECP5 `tools/adi_datasheet.py ad9238`). The product pages that link to them return 403
  to scripts. The name is the datasheet's, not always the part's: the AD9767 is in
  `ad9763_9765_9767.pdf` and `ad9767.pdf` is a 404. Case does not matter.
- LCSC's copies come through JLCPCB's file endpoint (`tools/jlc_datasheet.py <code>`).
- When you must ask the user for a datasheet, ask for the link they would click: it shows the
  vendor's URL pattern, so next time you fetch that vendor's PDFs yourself.
