---
name: jlcpcb-order
description: Parts sourcing and the JLCPCB manufacturing package - LCSC codes checked against their descriptions, stock and price queries ("in stock" is not "free to order"), consignment, BOM and CPL files, CPL rotation and datum corrections predicted from JLCPCB's own drawings, the order form field by field, surface finish, through-hole assembly, fab review, cost estimates and the "Confirm Production file" zip. Use when choosing or substituting parts, writing gen/parts or a release, generating BOM/CPL, reading JLCPCB's placement preview, filling in the JLCPCB order form, costing a board, or answering a JLCPCB engineering question or stock email.
---

# Parts, sourcing and the JLCPCB order

The rules for getting a board from a design to a correct JLCPCB order: every part real,
stocked, matching its copper, and placed the right way round. Related skills:
`component-selection` (choosing parts on electrical grounds), `pcb-layout` (footprints and
placement), `pcb-bringup` (what to check on the first board), `kicad-scripting` (pcbnew and
tooling quirks), `pcb-workflow` (the gates every release passes).

## References (read when the task needs them)

- `references/order-form.md`: JLCPCB's order form field by field, the dialogs it raises,
  impedance control, via options and their cost, stack-ups, JLCPCB options that constrain a
  design (colour, panel size, lead time, duty). Read before writing `FABRICATION_NOTES.txt`
  or when the user is about to fill in the form.
- `references/cpl-rotations.md`: the known rotation/datum table, how to predict corrections
  from JLCPCB's drawings, reading their viewer, bottom-side conventions, the overlay and body
  checks. Read before generating or changing a CPL, or when a preview shows a part wrong.
- `references/cost-estimate.md`: the itemised cost model, calibrated cart numbers, the
  consignment cost and three-bucket estimate. Read when costing a board.
- `references/production-file-zip.md`: checking JLCPCB's "Confirm Production file" zip and a
  returned "gerbers_Y11" set. Read when JLCPCB sends files to confirm.
- `references/parts-notes.md`: part-specific findings (codes, stock, mechanical quirks,
  stories behind the rules). Read when choosing a connector, header, trimmer, switch, test
  point or basic passive, or when JLCPCB emails about stock or polarity.

## Sourcing

- **One-step order.**
  - Every machine-placed part must be in JLCPCB's stock, deep enough to survive a week, and
    active at Digi-Key and Mouser too (GPSDO P2).
  - Consign only when the user agrees and it saves real cost or complexity.
  - **Count a consignment's whole cost, spares included, before choosing it over JLCPCB's
    shelf** (CostasLink, Prompt 31, 2026-10-14): pieces plus two spares a line, tax,
    shipping, the parcel to Shenzhen ($35-60) and a week. For a two-board order a shelf part
    up to about $100 dearer is still cheaper; the margin shrinks as the board count grows.
    The user is more willing to consign for more than two prototype boards. Details in
    `references/cost-estimate.md`.
  - JLCPCB's shelf first when it covers the order; keep the distributor numbers as a
    **fallback** the release applies only when live stock is short on the day (`gen/parts.py`
    `consign=` on a part that also has an LCSC code; `mfg/make_release.py` parts_report).
  - **A single part that forces a consignment is worth replacing** by a slightly dearer or
    slightly different shelf part when the datasheets say it is the same thing (the ADL5380's
    Johanson 5400 balun, 0 at JLCPCB, replaced by TDK HHM1907B1, 7,884 in stock: same ratio
    and band, better numbers; it took the only consigned line off the order).
  - **Search JLCPCB's library by category** ("balun", "RF Mixers"), then every maker's
    prefix, not only by the datasheet's part number. Three part-number searches missed the
    HHM1907B1; part numbers found Mini-Circuits mixers with 2-15 in stock, the category found
    the ADEX-10L+ with 861 (§22).
  - **Look for the small package under every name** (§19): TI's TSSOP 4046 had 21 in stock,
    Nexperia's automotive 74HC4046APW-Q100J had 234. Search "-Q100" and other vendors' parts
    before giving up on a package; read the small package's pinout from its datasheet (the
    SOT-23-6 OPA847 moves the pins).
  - **A consigned part's distributor number and price come from the distributor's own page,
    read on the day the release is written** (CostasLink, Prompt 30). Keep them once, dated,
    in the parts table; the estimate and release read them there. (Seen: a Digi-Key number
    copied from an old listing that was no Digi-Key part; Digi-Key renumbering ADI parts with
    a `505-` prefix; the ADL5375 at $17.26, not an aggregator's $14.12.)
  - **Read the datasheet of the number you buy, not of its legacy number.** Johanson's
    5400BL15B0050001E is rated 4900-5875 MHz; the legacy 5400BL15B050E's sheet said 5900.
    The board's band changed with it.
  - Prefer Basic parts: each distinct Extended part costs a setup fee (about $3).
- **Query stock and price through JLCPCB's parts API** (`jlc_api.py`, caching each answer
  with its timestamp). Never trust memory: "in stock" is a statement about a moment, and the
  search web page does not render for an agent (GPSDO r40).
- **"In stock" is not "free to order"** (AMOD/RF-MOD pre-order, §29).
  - The API returns `stockCount` and `canPresaleNumber`; the second is stock less what other
    orders hold. On the order day four codes read 644 to 51 401 in stock and were oversold
    (free count negative): a 27 ohm and a 6.8 k 0402, a 220 nF 0402, the OPA847IDBVR. Another
    went from 40 328 to 74 in four days.
  - Gate on `min(stockCount, canPresaleNumber)` for the codes a BOM actually orders, on the
    day you pay; ignore codes no BOM orders.
  - Swap for the same value and package; for an IC, the same die on another reel
    (OPA847IDBVT for IDBVR).
  - **Then fit the swapped code's rotation afresh.** JLCPCB draws each code separately: the
    IDBVT's drawing is a quarter turn from the IDBVR's (+180 against +270).
- **Re-query stock on the day of the order** (`build_release.py N --refresh`): yesterday's
  cache is not "in stock".
- **Thin stock the user has accepted is a per-part exception, not a loosened rule**
  (`stock_exception` on the part records who accepted it and when; the fab check prints it
  beside the stock instead of failing) (§20).
- **A line can run out AFTER the order is placed.** JLCPCB then emails and enables "Replace
  Parts" in Order History (pick one, or leave it unpopulated; nothing is re-uploaded). Search
  the shelf by free text with the API, take the requirement from the datasheet or design
  guide, keep the design's part, and record the substitution wherever the part is named
  (parts table, design notes' risk list, bring-up check, README status) so the next order
  expects it. The GPiBridge L1 case is in `references/parts-notes.md`.

## Codes, ratings and fit

- **Every code is checked against its description.** Eight ECP5 codes typed from memory named
  the wrong part (a 2.2 pF capacitor was a 180 kΩ 1206 resistor, a 24.9 Ω load 470 kΩ) and
  every existing check passed (ECP5 4c). The release must fail if:
  - any LCSC code's JLCPCB description lacks the schematic's value and package;
  - any SMD part has no code (eleven codeless parts silently became "hand-solder" on ECP5).
- **Ratings: read voltage, current and power off the code's own description.** A 50 mA chip
  inductor was drawn where a 600 mA power inductor was required (ECP5 4b); check resistor
  power at the worst-case input (ECP5 R2).
- **The part is its attributes, not its value field** (GPSDO, 2026-10-10). Rev A and B carried
  F2002 as "1.1A PPTC"; its code C70076 is the nSMD050-24V: 0.5 A hold, 1 A trip, under the
  643 mA heater it fuses. Read every protection and power part's hold/trip current, voltage
  and power off the code's attributes (`jlc_api.by_code(code)`) and compare with the sheet.
- **The part must fit the copper.** Compare every ordered code's EasyEDA land pattern with the
  board (`footprint_check.py`: HOLE, PADS, LAND, datum). A substituted switch with two
  locating posts and no holes stopped JLCPCB's line (Icepi P38).
  - An MPN search can return a zero-stock code first; read the stock column.
  - Family variants differ mechanically.
  - **Read the maker's land pattern, not only JLCPCB's** (§28): for parts with locating
    posts, make each hole/slot take both drawings. Check every NPTH post against their
    drawing.
  - **Compare the package, not only the pins** (§29): the PAM8302AASCR (C113367) is an MSOP-8,
    the only PAM8302 JLCPCB stocks; on a SOIC-8 footprint its leads fell between our pads,
    yet a pin-number fit printed "ok" at 0.77 mm rms. Compare the code's package field with
    the footprint (the MPN said only PAM8302A), and each R, C, L, LED and diode footprint's
    size code (0402 ...) with JLCPCB's stated package (310 lines checked on AMOD, all agreed).
- **Compare every symbol's pins with the distributor's drawing** (§26). AMOD-and-RFMOD's
  `scripts/check_pinouts.py` reads each LCSC code's pin names from EasyEDA beside the
  symbol's: it found a dual transistor in another part's order and a SAW filter whose output
  was on a ground pad. The other differences are naming ("+" against IN+); read each against
  the maker's table and note it in the board's DOA list.
  - **Keep polarised two-pin parts in that check** (§28): skipping Device:D, LED and C skips
    exactly where numbering hurts. JLCPCB's KT-0805G numbers its anode 1.
  - **EasyEDA's `c_spicepin` is the SPICE order, not always the printed pin number** (§29):
    pairing by it made the PAM8302's pin 2 read IN- and pin 8 NC. Use the pin group's
    numeric text when the two differ.
  - **When JLCPCB's symbol leaves a polarised part's pins unnamed, read its drawing's silk**
    (§29): the 220 uF electrolytic C2992606 and SMBJ12A C19077565 have blank pin names; their
    land patterns carry a "+" with chamfered corners at pad 1 and a cathode band on pad 1's
    side, both agreeing with KiCad's pad 1 at 0.
- **For a keyed two-row connector, derive the pin from the pad's position relative to the
  body, never from its number, and check both mating halves.** KiCad's horizontal 2x6 Pmod
  header/socket put pad 1 on the row far from the body; JLCPCB's drawings (PZ254R-12-12P
  C492434, HC-PM254 C22373932) put it near the body, so their pad p is KiCad's 13 - p (§17;
  caught by mating the footprints on paper; `check_pmod` maps every plug pad to its pin).
- **A fetched footprint can carry the board edge.** An edge-mount jack's EasyEDA footprint
  (easyeda2kicad) draws Edge.Cuts lines and KiCad cuts the board along them. Read a fetched
  footprint's layers before vendoring it. Choose vertical or edge-mount on purpose
  (CostasLink's first MMCX, BWMMCX-KEF C5250057, was edge-mount; the taps wanted the vertical
  BWMMCX-KE C5137198).
- **A vendor's interface table can be wrong; its schematic and the firmware decide.**
  CubePilot's GPS1 table says the safety button is "shorted to GND on press"; the Cube Orange
  schematic has a 1.5 k pull-down on SAFETY and ArduPilot's IOMCU hwdef says
  `PB5 SAFETY_INPUT INPUT PULLDOWN`: the button pulls up to 3.3 V. Two CubePilot pages also
  swap GPS1's TX and RX against their own carrier schematic.
- **Packages.** 0805 or 0603 for hand rework and probing, unless the datasheet or density says
  otherwise (GPSDO P6, Icepi P16). Prefer solderable packages that are common everywhere.
- **A fix found on one board goes to every board that copies the part, the same day** (§28).
  The op-amp board's KF301 footprint had read the "3.60" of the front view as a depth (CPL
  turned 180 to fix it); motor-pid, generated from the same code, kept it two more days and
  would have fitted all three terminal blocks facing inward; AMOD-and-RFMOD's KF301 still had
  it (body -4.0 / +3.6, table 0). A copied PLACEMENT_CHECKS lookup lost lines the same way
  (motor-pid's dropped J3, J6 and D3/D4, and had none at all for D5/D6). After a lesson names a part or
  a function, grep every board for it.

## BOM and upload files

- **BOM: one line per LCSC code.** "51R1%" and "51R" mapped to one part produced JLCPCB's
  "multiple lines matched to the same part" (GPSDO P32).
- **Annotated BOM:** price per item and for N boards, stock with the query time,
  Basic/Extended/consigned, and a note for anything to look at (GPSDO P23).
- **Upload files:** gerbers zip, BOM, CPL (KiCad native), CPL JLC-corrected, assembly notes to
  paste, and a cost estimate. Write `release/` so the user uploads exactly that folder.
  - **CPL names** (2026-10-08): `<board>_cpl_jlcpcb_upload.csv` is the one uploaded, with
    JLCPCB's rotations and positions; `<board>_cpl_kicad_native.csv` is KiCad's numbers for
    reference. Older names (`_cpl.csv` beside `_cpl_jlc_corrected.csv` in GPSDO and Icepi,
    `_cpl_native.csv` in ECP5) did not say which goes to JLCPCB: rename them (every board in
    OpticsPCBs was). A plugin's `CPL-<board>.csv` (SyzygyRadioDrivers) is renamed after each
    run.
- **The order form, spelled out in the form's own order**, in `FABRICATION_NOTES.txt`; values
  that come from the board computed, never typed; every value that differs from JLCPCB's
  default marked (`>>` in plain text naming the default to avoid; **bold** in Markdown);
  every dialog the form raises on its own line with the answer and why. See
  `references/order-form.md`.
- **Assembly notes:** say which through-hole parts are keyed (SMA, RJ45, DIP) and which the
  preview must show pointing the right way (SMA barrels off the edge, Pmod openings off the
  edge); a part placed at an odd angle (an HC-49S crystal at 45 degrees between diagonal
  jacks; JLCPCB places any angle) is stated so nobody "corrects" it (§19); parts that show as
  "unknown part" checkerboards in the preview are named.
- **An assembly drawing** (§29) is plotted from F.Fab, F.Silkscreen and Edge.Cuts (B.Fab,
  B.Silkscreen mirrored) without the drawing sheet (`--include-border-title` puts the board
  1:1 in an A4 frame's corner; F.Cu plotted black buries the silk), then fitted to Letter
  with the scale in a caption (CostasLink's `fit_pdf.py`). On a page with slack, put the
  caption half a margin under the drawing; at the paper's foot it widens the box
  `fit_pdf.py check` measures and a centred drawing fails as off centre.

## Assembly scope

- **Nothing hand-soldered, except a host socket that costs more than a few dollars to have
  fitted.** JLCPCB assembles every part, through-hole included (SMAs, RJ45, DIP switch,
  2.54 mm headers at their own lengths, Pmod sockets) (ECP5 P26: "I don't want to hand solder
  anything"). The exception (GPSDO rev B's J4001; CostasLink Prompt 15: "if it costs more than
  a few dollars to have JLCPCB solder the raspberry pi connectors, I'll do that myself. I'd
  like them to do SMAs and small-pin headers"): a 2x20 socket alone on the BACK makes the order
  two-sided (second setup, stencil, feeder: about $38 before duty, $51 with it), so it goes in
  `hand_solder_bom.csv` with its LCSC code to order loose and the order stays one-sided. Price
  it every time; when nothing else is on the back and the saving is more than a few dollars,
  the user solders it. The same list carries what ships loose (jumper shunts, with each
  jumper's position).
- **Through-hole parts: have JLCPCB fit them** (ECP5, 2026-10-06: "even if it costs extra").
  THT labour is a per-order fee (about $3.58, Icepi jlcbuild J1) plus a per-joint rate; every
  USB-C's soldered shell legs already put the per-order fee on the order, so after that each
  THT part costs only its joints and its code. They go in the BOM and CPL like everything
  else; the cost estimate counts their joints (ECP5 `mfg/make_fab.py`).
  - **Order each header at its own length, not as a strip to snap** (ECP5 build 33's
    preview): a 1x40 / 2x40 strip (C2337, C29952) showed as a 100 mm bar centred on pin 1,
    across and off the board, uncheckable. The exact parts are stocked, cheaper (about $0.02
    against $0.13) and fit by pin number: XFCN PZ254V-11-02P C492401, -03P C2937625, -04P
    C2691448, -06P C492405 (one row), PZ254V-12-16P C492425, -18P C492426 (two rows). Their
    drawings' origin is the middle of the pins; the release's datum shift moves the CPL point
    there from KiCad's pin 1.
  - A header's "value" is the jumper's name (TERM, RAILS): check its code for the pitch, not
    the name.
  - Through-hole parts with keyed hole patterns go in one way only; note them (Lorenz
    MANUFACTURING).
- **A hand-soldered part must fit before it is offered** (§22): a polyvaricon with its dial is
  about 20 mm square; the answer was a 2-way screw terminal for an external capacitor.

## CPL rotations and positions (core rules; detail in `references/cpl-rotations.md`)

- **KiCad's zero and JLCPCB's zero differ by a property of THEIR drawing of each LCSC part.**
  Apply, in order: (1) **bottom-side mirror** `rot -> 180 - rot` (fixed points 90 and 270;
  confirmed on 10 placements, Icepi jlcbuild); (2) the **per-part correction**.
- **Only a real "Confirm parts placement" preview is a reading.** Absent from the table means
  nobody has looked; zero means somebody looked. A prediction is a placeholder: mark it
  "predicted" in the CPL and list it in `PLACEMENT_CHECKS.txt` for the order day. Third-party
  rotation tables disagree with each other (GPSDO took one and got two wrong, one on 59
  placements).
- **Predict per part (LCSC code), not per footprint**, by fitting JLCPCB's EasyEDA land pattern
  onto ours *by pin number*: the correction is minus that turn. JLCPCB draws the SN75160B lying
  down and the SN75161B upright on the same SOIC-20W. Fit predictions were right 32 of 32 on
  CostasLink rev A; the one prediction made from a *description* was wrong (its SMAs). "The
  standard drawing" is a description: the AMOD boards' SOT-23s set to 0 would have put every
  powered tile's P-FET on backwards (they are +180, "-BR").
- **A pin-number fit cannot see which way a symmetric part faces** (screw terminals, a square
  of SMA holes, a 2x6 grid, a BNC whose posts JLCPCB numbers differently). Compare JLCPCB's body
  outline with our courtyard/F.Fab; fail when they lean opposite ways. The release must fail on
  any part of three or more pads with neither a prediction nor a table entry, and must not ship
  such a part at KiCad's angle.
- **Polarised two-pad parts: use the polarity mark or JLCPCB's pin names (K, A), never pad
  numbers** (their 0603 and KT-0805 LEDs call the cathode 2; their AOTA inductor's dot is at
  pad 2). A footprint copied from JLCPCB's drawing is not a reading of their viewer.
- **JLCPCB places THEIR origin.** The CPL's Mid X/Y is where the origin of *their* drawing
  goes; fit it ("datum") and add it, turned with the part, to the JLCPCB CPL only (the native
  CPL stays as KiCad wrote it). Every USB-C so far needed it (HRO TYPE-C-31-M-12 C165948:
  1.572 mm toward the pad row).
- **Every correction lives in the file, made by the script, from a source of truth.** Never
  nudge or turn a part in JLCPCB's viewer: every hand fix is lost on the next upload. A preview
  reading goes into the rotation or position table with its evidence; the release recomputes
  the CPL. When a preview has been read, record it.
- **Check the upload itself, not only the table:** lay JLCPCB's drawing where the upload CPL
  puts it and require each of their pad centres inside our matching pad, and their body centre
  within 0.5 mm of our courtyard's centre. Prove the check fails on a known-wrong release.
  Make the build stop on it.
- **Check the BACK in the preview too** ("I almost forgot to check the back parts",
  2026-10-08). Every `PLACEMENT_CHECKS.txt` and every hand-over of an upload ends by naming
  the back-side parts to look at.
- **When JLCPCB's engineers ask about polarity,** answer from the board file: compute where
  pad 1 lands from the footprint's rotation, name its net and neighbour, check the datasheet's
  marking end, say which end their mark (their model's pin 1) should be on. Keep their picture
  in the board's `mfg/jlcpcb_order/` and record the answer where the rotation is recorded.

## Gates before the order

- **DRC** at least as strict as JLCPCB's rules for the chosen stack-up, at every severity,
  0 errors, with schematic parity; zones filled and saved first. Count unconnected items
  yourself (GPSDO printed a false "UNROUTED" caption while DRC said 0).
- The release refuses when: a part has no LCSC code; a code's description does not match its
  value and package; stock (free count) is short on the day; DRC is dirty; zones are unfilled;
  a 3+-pad part has no rotation entry or prediction; the overlay or body check fails.
- **Surface finish: ENIG, 1 U" gold**, for any board with a BGA or fine-pitch parts, parts on
  both sides or through-hole parts. OSP is flat too, but each reflow and wave or hand soldering
  consumes it, it keeps months rather than years, and test pads under it probe badly. 2 U" is
  for gold fingers and other wearing contacts.
- **Order number:** since May 2026 JLCPCB prints none by default and asks for no
  `JLCJLCJLCJLC`: choose "Remove Mark". (Before then the board carried `JLCJLCJLCJLC` on the
  back in a band the enclosure hides, e.g. ECP5 build 31's top slot band on B.SilkS, with
  "Remove order number: Specify a location" on the form, said in the notes.)
- **Landed cost:** the US has no de minimis exemption any more; JLCPCB pre-collects duty under
  DDP. Price boards with shipping and duty (`references/cost-estimate.md`,
  `references/order-form.md`).
- **Fab review:** when JLCPCB returns files to confirm, compare them with what was sent
  (`references/production-file-zip.md`).
