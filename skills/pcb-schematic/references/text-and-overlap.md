# Schematic text extents and the overlap check

Read before writing or trusting a schematic generator's overlap check.

## The rule

No text, reference or value overlaps a symbol, wire, box or other text, and everything
stays inside the page border. Check it in code and by looking at the exported PDF
(Lorenz P1, GPSDO P5, P6). The usual offenders: references on vertical R/C, GND flags on
decoupling caps, notes next to GND symbols.

## A text's real extent is not its anchor

- KiCad snaps a field's anchor to the 1.27 mm grid.
- It draws a **reference's** glyphs from 0.76 x size before the anchor to 0.23 x size
  after it.
- It draws a **value's** glyphs from 0.38 x size after the anchor to 1.37 x size after.
- This holds whatever the symbol's rotation (measured on a calibration sheet, ECP5 P26).
- Model that in the generator's overlap check, and test wires against text boxes and
  text against symbol bodies, not only text against text.

## Check the exported PDF itself

`pdftotext -bbox` gives every word's box; two words whose boxes overlap, or one past the
page's frame, fail the build (`gen/check_sch_text.py`). The PDF is what the user reads.

In the PDF scan, a word box includes the font's whole ascent and descent: demand overlap
of half a line before calling two lines of a note overlapping.

## A checker that passes is only as good as its model of KiCad (GPSDO, 2026-10-10)

GPSDO's check had passed for weeks with four faults:

1. every text anchored on its baseline (KiCad centres one unless told top or bottom);
2. power symbols skipped as bodies;
3. a label's direction read from its angle, while kigen writes left-pointing labels as
   angle 0 with `justify right`;
4. one width, 0.82 x height per character, when capitals and digits run 0.87-0.99.

Fixed, it found fourteen kinds of real overlap, among them a pull-up resistor drawn
across another pin's wire. Calibrate the model against a render whenever the eye sees
what the check does not.

For KiCad's stroke font widths on the board (capitals about 1.0 x size per character),
see the pcb-silkscreen skill's `references/text-metrics.md`.

## Fields

Hide every field but reference and value: a footprint suffix ("K1A2") printed in the
middle of a BAV99 is a question the user will ask (ECP5 P26).
