# Every page fits what is on it

Companion to SKILL.md §2 and gate 23. Read it when exporting schematics, assembly drawings,
board plots, block diagrams, renders or figures to PDF or images.

The user (2026-10-29): "The board in ./mfg/release/CostasLink-PYNQ-Z2_assembly_top.pdf should
take up the entire page (with a reasonable margin). Right now, if I were to print it, I
couldn't read it. In general, the schematics, PCBs, and PDFs should be sized and centered
properly. I've seen many examples of things hanging off of the page or the page being far too
big for the thing on it."

- **What it covers:** schematic sheets, board plots, assembly drawings, block diagrams, renders
  and figures. The drawing spans the paper less a margin of about half an inch (12.7 mm, past any
  printer's unprintable edge), in whichever orientation suits its shape, with its centre at the
  page's. Nothing hangs off an edge; nothing sits in a corner of a page several times its size.
- **The exporters do not do this.** kicad-cli plots a board 1:1 where it lies on its sheet. The
  CostasLink assembly drawing put the 120 x 100 mm board in the top-left corner of an A4 page,
  using 41 % of its width. Its `--scale 0` (autoscale) stayed on A4, at 77 % of the height and
  66 % of the width, 10 pt off centre (KiCad 10.0.7).
- **Fit it after export:** CostasLink's `tools/fit_pdf.py fit IN OUT --caption "... scale
  {scale}:1"`.
  - It measures each page's drawn box with Ghostscript's bbox device, scales it onto Letter and
    centres it, all in vectors.
  - It prints the scale in the bottom margin, because a fitted drawing is no longer 1:1.
  - `make_release.py` runs it on both assembly drawings and refuses one that fails `check`.
  - Look for an existing copy of `fit_pdf.py` in sibling projects before writing another
    (grep the tools a lesson names before writing one).
- **Plot drawings meant for paper in black** (`--black-and-white`). KiCad's pale yellow
  F.Silkscreen and pink B.Silkscreen hardly show on a printed page.
- **An assembly drawing is plotted from Fab, silkscreen and outline, without the drawing sheet**
  (AMOD/RF-MOD pre-order, 2026-10-29).
  - `--include-border-title` puts the board 1:1 in the corner of an A4 frame. F.Cu plotted black
    buries the silk under the pours.
  - Plot F.Fab, F.Silkscreen and Edge.Cuts (B.Fab, B.Silkscreen mirrored), then fit to Letter
    with the scale in a caption.
  - On a page with slack, put the caption half a margin under the drawing. At the paper's foot it
    widens the drawn box that `fit_pdf.py check` measures, and a centred drawing fails as off
    centre.
- **A schematic's sheet size is chosen for its content.** The content fills the frame the same
  way the frame fills the page; a block that overflows gets a bigger sheet, or goes on a sheet of
  its own.
- **Check it in code and by eye.** `fit_pdf.py check` prints each page's fill and its offset from
  centre. It cannot see a drawing clipped at the edge, or a circuit lost in one corner of a frame
  that fills the page. Render each page with `pdftoppm` and look at it whole.
- **A board that hangs off its sheet at 1:1 must be plotted at another scale first** (op-amp,
  2026-10-29). Its board sits at the sheet's origin, so at scale 1 its left jacks were off the A4
  page, where the bbox device cannot see them. At any scale but 1 kicad-cli centres the board
  (measured: `--scale 1.5` put the outline 150.1 mm wide, 1 pt off centre), so plot at 1.5 and
  fit from there; the op-amp's copy of `fit_pdf.py` takes `--from-scale 1.5`, so the caption's
  scale is against the board, not the plot.
- **Make the fitted PDF the same every build:** Ghostscript's pdfwrite writes a date, a document
  ID and an XMP packet; `-dOmitInfoDate -dOmitID -dOmitXMP` drop them (Ghostscript 9.55 and
  later; checked on gs 10.06), and two rebuilds then match byte for byte. Without them
  `fit_pdf.py`'s output churns in git; motor-pid's copy did (motor-pid pre-order, 2026-10-29).
- **Check that no text crosses the frame.** The op-amp's title block (110 mm) holds about 60
  characters of title and 79 of each line under it; a 113-character company line and a
  98-character comment ran off the A2 page, and the schematic's overlap check, which reads the
  generator's boxes, passed them. `pdftotext -bbox-layout` gives every printed line's box: fail
  any outside the frame, the frame's own ruler (one or two characters) excepted (op-amp
  `scripts/check_outputs.py`, `check_prints`).
