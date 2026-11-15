# Checking what JLCPCB sends back

## Fab review ("gerbers_Y11")

JLCPCB may return a "gerbers_Y11" set to confirm. Compare it with what was sent: hole counts,
NPTH, outline (Lorenz P11).

## The "Confirm Production file" zip

CostasLink, 2026-10-17; the full worked case is in `CostasLink-PYNQ-Z2/mfg/PRODUCTION_FILE_CHECK.md`.

**What is in it.** The zip (`<name>_Y21.zip`, about 17 MB) holds:

- `ok/`: their CAM layers, all RS-274X in inches 2.6:
  - `tl bl l2 l3`: copper;
  - `ts bs`: mask;
  - `to bo`: silk;
  - `drl`;
  - `ko`: outline with rails;
  - `vcut`;
  - `sk`: the tented vias;
  - `qrt qrb`: QR places.
- `YG/`: the upload echoed back. Check it is byte-identical to the release zip.
- `YG/4te.json`: the order record in GBK (`iconv -f GBK`): layers, thickness, copper, finish
  (沉金 = ENIG), 过孔塞油 = tented vias, 不加客编 = no order number, the rails remark. The record
  carries no stack-up field; read that off the order page.

**Check it by rendering, not by reading.**

1. `pip install --target <scratch> gerbonara`.
2. `GerberFile.open(...).to_svg(force_bounds=panel frame)` for theirs and ours (ours offset so
   the outline sits at the panel's board position).
3. Inkscape to PNG at 20 px/mm, threshold, numpy diff.
4. Erode 2 px to drop the polygon-conversion slivers.
5. Label what survives and match it to pads with pcbnew.

**Expect exactly:**

- non-functional pad removal on the inner layers (through-hole pins with no connection on that
  layer lose the annulus; connected ones keep it);
- the rails with their V-cuts, tooling holes, fiducials and QR places outside the outline;
- plated drills 0.13-0.15 mm over finished size;
- vias unchanged.

Anything else on the board itself is a question for them before confirming.

**In git:** do not commit the zip (`*_gerbers_Y*.zip` is ignored); commit the check.
