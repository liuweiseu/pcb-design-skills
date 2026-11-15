# CPL rotations and positions in detail

KiCad's zero and JLCPCB's zero differ by a property of **their** drawing of each LCSC part.
Apply two things, in this order:

1. **Bottom-side mirror:** `rot -> 180 - rot` (fixed points 90 and 270; confirmed on 10
   placements, Icepi jlcbuild).
2. **Per-footprint correction**, taken only from a real "Confirm parts placement" preview. Absent
   from the table means nobody has looked; zero means somebody looked. A prediction from the
   drawings is a placeholder, not a reading.

Then add the **datum** (where JLCPCB's drawing has its origin in our footprint), turned with
the part, to the JLCPCB CPL only.

## Known corrections

| footprint / part | correction | evidence |
|---|---|---|
| `SOT-23-5` | +180 | GPSDO, 59 placements |
| `VSSOP-8_2.3x2mm_P0.5mm` | +180 | Icepi jlcbuild |
| `Texas_DRT-3` | +270 | Icepi jlcbuild (top side) |
| `TSOP-II-54_22.2x10.16mm_P0.8mm` | +270 | Icepi jlcbuild |
| `SOIC-8_5.3x5.3mm_P1.27mm` | +270 | Icepi jlcbuild, read twice |
| `QFN-20-1EP_4x4mm_P0.5mm` | +270 | Icepi jlcbuild, read twice |
| `Oscillator_SMD_SiT_PQFN-4Pin_2.5x2.0mm` | 0 | Icepi jlcbuild, read twice |
| `D_SOD-523` | 0 | Icepi jlcbuild |
| LF412 SOIC-8 (C15322), MPY634 SOIC-16W (C1523457) | +270 | Lorenz P8 |
| 6-way DIP switch C54952 | +270 | Lorenz P8 |
| 78L12 / 79L12 SOT-89 (C8615, C8626) | +180 | Lorenz P8 |
| BNC C41416668 | +90 | Lorenz P8 |
| Edge SMA BWSMA-KWE-Z001 C496551 | **0** | READ in JLCPCB's viewer (CostasLink rev A, 2026-10-17): at +90 all nine SMAs needed a quarter turn clockwise. The footprint says the same: its body runs along +x at 0, as JLCPCB's drawing does. The +90 had been predicted from a misreading of the footprint (barrel along -y), and the ECP5 build 33 note that '+0 lay along the edge' is contradicted by this reading: ECP5 re-reads its SMAs in its own preview before ordering |
| 2.54 mm headers PZ254V-11-02P C492401, -03P C2937625, -06P C492405, PZ254V-12-18P C492426 | +270 | JLCPCB draws them lying along x, KiCad standing along y (ECP5 build 34; the 1x3, 1x6 and 2x9 by pin number, the 1x2 from the drawing). READ for the 1x2 and 1x3, with their 1.27 / 2.54 mm datum moves, in CostasLink rev A's preview (2026-10-17) |
| 2835 red LED XL-2835SURC-05 C2843878 | +180, and the CPL point 2 x 0.30 mm along its axis | READ in JLCPCB's viewer (ECP5 build 34, 2026-10-08): our footprint is JLCPCB's own drawing, yet +0 showed the cathode on the anode's side |
| 2x6 right-angle Pmod socket C22373932 | +270 | ECP5 build 33 preview showed +0 wrong (a quarter turn round); +270 from the drawings' body directions. Confirm in the next preview |
| USB-C HRO TYPE-C-31-M-12 C165948 | 0 | Lorenz (built), GPiBridge preview. Its *position* needs moving 1.572 mm: see "Part positions" |
| GPiBridge's eleven: RP2354A 0, SN75160B +270, SN75161B 0, AO3401A, 2N7002, XC6206 +180, BM03B +180, AOTA inductor +180, KT-0805Y/G and NCD0805R1 LEDs 0 | as predicted | GPiBridge rev A preview, 2026-10-06: "all of the rotations were correct" |
| CostasLink rev A's 32, on KiCad's own footprints: QFN-24-1EP (ADL5380, ADL5375, PE43711), VQFN-16 (THS4541), MSOP-8/-10 (HMC536, AD8310, MCP4728), VSSOP-8 (OPA2187), TSSOP-10/-16 (ADS1115, AD5696R) all +270; SC-70-5/-6 (74LVC1G04/1G17/2G34/1G3157, TLV3601/3603) +180 and the TS5A3159's SC-70-6 +270, by pin number; SOT-89 ADL5611 C208262 +180 with a 0.7 mm datum move; U.FL C88374 on `U.FL_Hirose_U.FL-R-SMT-1_Vertical` +270 with a 0.763 mm datum move; MMCX BWMMCX-KE C5137198 0; QFN-32 MAX2871, QFN-6 SKY65404, the 3225 TCXO/VCXO, the HHM1907B1 balun, the SMAJ5.0A, the 1N4148W, the 0603 LEDs and the 5x5.9 polymer 0 | as predicted | CostasLink rev A preview, 2026-10-17: "Everything look correct except the SMAs" (the SMAs' row above); each by LCSC code in CostasLink's `mfg/jlc_rotation.py` |
| AMOD-and-RFMOD's SOT-23 family on KiCad's `SOT-23` / `SOT-23-5` / `SOT-23-6` where JLCPCB's package name ends "-BR" (pin 1 bottom-right): AO3401A C15127 (every powered tile's switch FET), 2N7002 C20917, MMBT3904 C20526, TMP235 C2868809, LM2664 C108573, TLV3501 C193413, TPS22917 C2681320, TPS7A2033 C2862740, SN74LVC1G17 C7836, LMH6629 C2059678, SMS7630 C6489012 | **+180** | Fit by pin number (AMOD-and-RFMOD `scripts/check_rotations.py`, 2026-10-28), agreeing with the GPSDO's SOT-23-5 and GPiBridge's AO3401A / 2N7002 readings above. Rev A's table had them all at 0 as "the standard drawing", a prediction from a description: every powered tile's P-FET would have gone on backwards. Not yet read on these boards; **read** for MMBT3904 C20526 and MMBT3906 C53444 on the op-amp's rev A preview (2026-10-29) |
| SOT-23-6 drawn in rows, "-BL" (pin 1 bottom-left): OPA847 C160422, LT6230 C580235, MT3608 C84817 | +270 | the same fit |
| SOT-23-5 drawn "-TL" (KiCad's own): OPA810 C2833513 | 0 | the same fit: the suffix, not the package, decides |
| `SOIC-8_3.9x4.9mm` PAM8302A C113367, `SOIC-14_3.9x8.7mm` MC1496 C7295, `TSSOP-16_4.4x5mm` 74HC4046 C546981 | +270 | the same fit, as the SOIC and TSSOP readings above (note: C113367 is really MSOP-8 and does not fit a SOIC-8 footprint; see "Overlay and body checks") |
| 1x3 header C2937625, 1x5 / 1x2 sockets C2894928 / C2894925 | +270, the datum at the middle pin (2.54 / 5.08 / 1.27 mm) | the same fit, as the header rows above |
| `Crystal_SMD_3225-4Pin` (TC32H4 TCXO C5119013, TXC 7U crystal C2889142) | 0 | the same fit, and CostasLink's 3225 reading; AMOD-and-RFMOD's table had said +180 from reading JLCPCB's drawing with y upward (easyeda's SVG y runs down) |
| GALI-84+ C3193261 on KiCad's `SOT-89-3` | +180, datum 0.593 mm | the same fit, on pins 1 and 3 only (pad 2 is the tab in their drawing, the lead in KiCad's) |
| MSK12C02 slide switch C431540 | 0, datum 0.251 mm (slotted posts) or 0.55 mm (round posts at Shouhan's 1.95 mm) | the same fit; see "MSK12C02" below |
| OPA847IDBVT (the IDBVR's reel swap) | +180 (IDBVR +270) | §29: JLCPCB draws each code separately; caught by `check_rotations.py` on the rebuilt BOM |
| The op-amp's rev A preview (2026-10-29), all **read**: DSIC02LSGET C54949 on its own 2-way footprint; KF301-5.0-2P / 3P C474881 / C474882 with the wire openings to the edge; B5819W C8598 and 1N4148W C81598 on KiCad's `D_SOD-123`; RH-5019 loop C5199800; R2512 C2934068 | +270; +180; 0; 0; 0 | the user: "Everything else looked fine" |
| Bourns 3362P C52754333 on a footprint with pins 1/3 at y +1.27 and 2 at -1.27 | 0, read, **but its body is not centred on its pins** | pads fit within 0.04 mm, yet the preview showed JLCPCB's body 1.3 mm off the op-amp's printed box and the user nudged it: see "A pad fit cannot see the body" |
| 220 uF electrolytic C2992606, SMBJ12A C19077565 | 0 (by drawing's "+"/chamfer and cathode band at pad 1) | §29, predicted from the land pattern's silk |
| ECP5's five KiCad-library LED and SOD-123 codes | 0 by mark (cathode on the left at 0, where KiCad's pad 1 is) | predicted from the EasyEDA `png` |
| JLCPCB's KT-0805G | 0 (their cathode pad lies on ours) | GPiBridge preview; a pin-number fit says +180 because they number the anode 1 |
| The 2-way DIP DSIC02LSGET C54949 (op-amp board, before its preview) / RH-5019 loop C5199800 | +270 predicted (same family as the Lorenz 6-way, +270 read) / 0 predicted (the loop lies along x) | later read, row above |

Third-party rotation tables disagree with each other: GPSDO took one and got two wrong, one of
them on 59 placements. List every unverified footprint in a `PLACEMENT_CHECKS.txt` for the day
of ordering.

## Predicting corrections from JLCPCB's own drawings (GPiBridge, 2026-10-06)

- The EasyEDA land pattern of each LCSC part (`footprint_check.py` fetches it), turned until its
  pads lie on ours *by pin number*, predicts the correction: minus that turn. It reproduces every
  top-side correction in the table (7 footprints) for all 14 part numbers that use them on the
  Icepi, GPSDO and ECP5 boards. Predictions by pin number were right 32 for 32 on CostasLink
  rev A; the one from a description was the wrong one.
- **Per part, not per footprint**: JLCPCB draws the SN75160B lying down and the SN75161B
  upright, on the same SOIC-20W.
- **Fit JLCPCB's drawing to every footprint before trusting a rotation table** (§23). JLCPCB's
  SOT-23 drawings are KiCad's turned 180 ("-BR" in the package name: pin 1 bottom-right), its
  row-style SOT-23-6s KiCad's turned +90 ("-BL"), and one SOT-23-5 is KiCad's own ("-TL").
  AMOD-and-RFMOD's `scripts/check_rotations.py` fits JLCPCB's land pattern onto the board's
  footprint by pad number at each quarter turn and also reports the datum: it found the USB-C's
  1.572 mm and the ADL5611's 0.7 mm that earlier previews had shown and that had been moved by
  hand. Run it whenever a part is added: it found the SOT-23 family wrong on all five boards of
  a design that had passed every other check.
- **When a part is predicted, read the footprint's own body outline (F.Fab) for its direction
  at 0, not a description of it.** CostasLink's SMAs were predicted +90 from a wrong reading of
  the footprint's barrel direction and every one needed turning in the preview.
- **A part that numbers its pins unlike KiCad gets no prediction, and it must not ship at
  KiCad's angle** (ECP5 build 33's preview: every edge SMA lay along the board edge and both
  Pmod sockets stood a quarter turn round). Pads that fit by position only (a square of five
  SMA holes, a 2x6 grid) say nothing about which way the body faces. Read the body's direction
  off JLCPCB's land drawing (the EasyEDA record's `png`: the silkscreen outline shows where the
  barrel or the socket goes) against KiCad's courtyard, put the correction in the per-part
  table, and make the release fail on any part of three or more pads that has neither a
  prediction nor a table entry (ECP5 `mfg/make_fab.py` does since build 34).
- **Two-pad polarised parts: use the polarity mark in their drawing, not the pad numbers.**
  JLCPCB's KT-0805 LEDs call the cathode pad 2, and their AOTA inductor has its dot at pad 2
  where Raspberry Pi's has it at pad 1.
- **Polarity from JLCPCB's own pin names.** Their symbol for each diode or LED names its pins
  (K, A, COM+), and their land pattern numbers its pads to match; put their cathode pad where
  the CPL puts the part, and it must land on our cathode. A pad number proves nothing: their
  0603 LEDs call the cathode 2 (ECP5 `mfg/preview_check.py`, which found a 180-turned copy of
  D501, D309 and D602 REVERSED and the real CPL right).
- **Polarity marks without rasterising:** the EasyEDA API's footprint record carries a `png`
  URL (`image.easyeda.com/component_pngs/...`, protocol-relative) of the drawing with its +/−
  marks; fetch it and look.
- **Reading their drawing:** easyeda's SVG y runs down. AMOD-and-RFMOD's table had the 3225
  crystal at +180 from reading it with y upward.
- **A footprint copied from JLCPCB's drawing is not a reading of their viewer.** ECP5's 2835 LED
  used JLCPCB's own land pattern, so +0 was taken as "derived" and right; their viewer drew the
  part a half turn from that drawing and showed the cathode where our anode is (the user's
  screenshot, 2026-10-08). Only a preview reading settles a polarised part; until then list it,
  however its footprint was made.
- Put predictions in the CPL, marked "predicted", and still list them in
  `PLACEMENT_CHECKS.txt`.
- ECP5's `make_fab.py` does the prediction in the build: `FOOTPRINT_CHECK.txt`'s fit becomes the
  CPL's rotation where nobody has read the part, `PLACEMENT_CHECKS.txt` lists every predicted
  part, and a cross-check prints the prediction beside each correction somebody has read (7 of 7
  agree on ECP5: SOT-23-5, TSOP-II-54, SOIC-8 5.3 mm, VSSOP-8).
- **Confirmed:** all eleven of GPiBridge's predictions (12 placements, including the SN75160B's
  270 beside the SN75161B's 0 on one footprint, and the LEDs and inductor read by polarity mark)
  were right in its preview (2026-10-06).
- **A swapped code gets its rotation fitted afresh** (§29): OPA847IDBVT's drawing is a quarter
  turn from the IDBVR's.

## Every correction lives in the file

- Made by the script, from a source of truth (2026-10-08): never nudge or turn a part in
  JLCPCB's viewer. "I don't want to do that every time I upload the BOM and CPL", and every hand
  fix is lost on the next upload. A preview reading goes into the rotation or position table,
  with the screenshot's evidence, and the release recomputes the CPL from it.

## Reading JLCPCB's viewer

- **The purple dot is JLCPCB's pin 1** of each part, and a neighbour's dot can sit beside a
  small part (U502's beside Y501). A four-pad crystal is right when the dot is on a pad wired to
  the oscillator, pin 1 or 3 of the diagonal pair; an oscillator or any other part, when it is
  on pin 1. Compute it: their pad 1 at the CPL's position and angle must land on our pad 1 (ECP5
  `preview_check.py`, 42 parts).
- **Their viewer can turn a part about its body, not its origin** (ECP5 D201, the 2835 LED):
  +180 put the cathode right, and the part then sat 0.56 mm short, twice the 0.30 mm from the
  drawing's origin (the pads' midpoint) to the body outline's centre. Move the CPL point by
  twice that, turned with the part (`jlc_rotation.VIEWER_HALF_TURN`,
  `footprint_check.body_centre`), and draw it the same way in the computed preview.
- **Preview checkerboards.** The preview shows an "unknown part" checkerboard where their
  library has no drawing, so those rotations cannot be read there. The Lorenz RGB LED went in
  right from the plain CPL; say so in the notes (Lorenz P8, P9, MANUFACTURING).
- **Check the BACK too** (2026-10-08: "I almost forgot to check the back parts"). The preview
  opens on the top side and the back is easy to skip. The back is also where the rotation rules
  are least proven (the bottom mirror, a board that stores its back pads the other way round),
  and the computed preview covers only the top. Every `PLACEMENT_CHECKS.txt` and every response
  that hands the user an upload ends by naming the back-side parts to look at.
- **Their engineers may ask about polarity before production.** CostasLink rev A (2026-10-18,
  the day after the order): "we are not so sure about the polarities of the T101, L102
  components", with a placement snapshot (their red mark is their model's pin 1). The parts were
  the four-terminal balun and an 0402 chip inductor whose library entry is flagged polarised.
  Answer from the board file, not from how the picture looks: compute where pad 1 lands from
  the footprint's rotation, name the net on it and the neighbour it runs to, check the
  datasheet's marking end, and say which end of the part their mark should be on. Keep their
  picture in the board's `mfg/jlcpcb_order/` and record the answer where the rotation is
  recorded.

## Compute the preview before the user sees it (ECP5 `mfg/preview_check.py`, build 34)

- Put JLCPCB's own land drawing of every part where the upload CPL says, turned as it says, and
  compare it with the board: each of their pads must land on one of ours, and their silkscreen
  outline (the body) must lie on the same side of the part as our courtyard. Pad fits alone
  cannot see a half turn of a symmetric pattern; the outline can.
- Run it on a release known to be wrong first, to see it fail (build 33's CPL: it flags the six
  SMAs and both Pmod sockets the preview showed). Make the build stop on it. Footprint checks
  compare footprints; only this compares placements.

## Overlay and body checks

- **Check a CPL rotation by overlaying their drawing on your pads, posts included** (PID motor
  board). Transform every pad of JLCPCB's land pattern (`easyeda.py <code>`) by the upload CPL's
  (x, y, rotation, counter-clockwise) and measure each against the board's pads. A pin row alone
  is symmetric under 180 degrees: one reviewer "confirmed" the RK09K knob's rotation from its
  pin row while the posts and the body sat on the wrong side, 6-8 mm off; the overlay showed it
  at once. Calibrate the overlay on parts whose rotation a real preview showed, and expect pad
  numbering to differ for LEDs and connectors.
  - The op-amp board's `scripts/check_overlay.py` (2026-10-29) does it from the upload files
    themselves (Mid X, Mid Y, Rotation, the BOM's codes), in the build: each of their pads
    within 0.25 mm of one of ours, pad for pad by number where both sides number alike, and for
    a connector whose pins are symmetric (BNC, screw terminals) the face a cable enters, turned
    by the CPL, against the nearest board edge's outward normal. A terminal block turned for its
    wire openings puts their pin 1 in our hole 2: say so, it is right.
- **Rotations and datums live in one table** (PID motor board). JLCPCB's origin for a DPAK is
  1.9 mm toward the tab from KiCad's, the RK09K's is the body centre, and their D2PAK is drawn
  turned 180 degrees from KiCad's TO-263-2 (pins at +x) with its leads 2.45 mm further out.
  `JLC_ROTATION` entries are `(deg, (dx, dy), how, note)`; the upload CPL moves each part by its
  shift rotated into board coordinates, and `check_outputs.py` proves the two CPLs differ by
  exactly the table.
- **Check the upload itself, not only the table** (motor-pid, §28). Lay JLCPCB's drawing where
  the upload CPL puts it: their origin at Mid X/Y, y up from the drill origin, turned by
  Rotation. Measure each of our pads from theirs. This tests the generator's sign conventions
  along with the table: motor-pid's table stores the datum y-up (as `gen_outputs.py` applies it
  to the CPL), while a fit in the footprint's frame reports it y-down; a comparison without the
  conversion called two right entries wrong.
  - Report mechanical pads (tabs, shells, posts) apart from signal pads, each with the reason it
    differs. The D2PAK's tab is pad 2 in KiCad's footprint and 4 in JLCPCB's, 1.3 mm further
    out.
  - Paste-only apertures have no number: leave them out.
- **A pin-number fit cannot see which way a symmetric part faces** (§28). A screw terminal's pin
  row fits the same at 0 and 180; a BNC's four posts are numbered differently by JLCPCB. Compare
  JLCPCB's outline (the box of their top silk) with our courtyard, each measured from the pads'
  centre, and fail when they lean opposite ways (motor-pid `scripts/check_rotations.py`,
  FACING).
- **A wrong package with the right pin order passes a pin-number fit** (§29; the user,
  2026-10-29: "AMOD-A's U1201 seems to have the wrong package in the preview"). The PAM8302AASCR
  (C113367) is an MSOP-8 on a SOIC-8 footprint; its leads fell half-way between our pads.
  `check_rotations.py` had fitted it at +270 with 0.77 mm rms and printed "ok": it reported the
  residual and never failed on it.
  - The gate (AMOD `scripts/check_overlay.py`, in the build): lay JLCPCB's drawing where the
    table's turn and datum put it. Every one of their pads' centres must lie inside our pad of
    the same number, or inside one of ours for a part numbered differently. Read custom pads'
    primitives: a SOT-89's tab is a primitive of pad 2.
  - Prove it fails: turned a quarter off, two SOT-23s stood 2.0 and 2.25 mm outside.
  - Two-pad parts escape it, so compare each R, C, L, LED and diode footprint's size code with
    JLCPCB's stated package (310 lines, all agreed), and compare the package name too.
- **Skip lists by footprint name, not library** (§28, §29). "Capacitor_SMD:" does not mean "not
  polarised": a skip by library skipped the CP_Elec electrolytics. Skip by footprint name (`C_`,
  `R_`).
- **A pad fit cannot see the body: draw a through-hole part's body from the maker's drawing,
  and compare the centre of JLCPCB's whole drawing with your courtyard's** (op-amp, rev A
  preview, 2026-10-29). Every pad check passed RV1, a Bourns 3362P, at 0.04 mm, but its
  footprint centred the body, silk box, courtyard and 3D model on the triangle of pins, where
  Bourns puts the body's centre on the line of pins 1 and 3, 1.3 mm away. The preview drew
  JLCPCB's body poking out of the printed box and the user nudged it to the box, which moves the
  pins off the holes: harmless for legs that only fit their holes, wrong for anything placed by
  machine. The centre of EasyEDA's drawing is in the `docType 4` entry's `bbox` (canvas units of
  10 mil, from the land pattern's `c_origin`); turned and placed by the upload CPL it lands
  within 0.11 mm of the courtyard's centre for every other part on that board (0.4 mm for a
  KF301's side tab), so 0.5 mm is the line (`check_overlay.py`, `BODY_TOL`).
- **The preview's bodies, read back** (motor-pid rev A's preview, 2026-10-29: the user nudged
  RV2-RV4 and SW1-SW5).
  - BOCHEN's 3362P also centres the body on the line of pins 1 and 3, 1.30 mm from the middle of
    its pins.
  - **An SMD part with locating posts is placed by its body.** JLCPCB's MSK12C02 drawing puts its
    terminals 0.3 mm further from the posts than Shouhan's land pattern. A datum fitted to the
    terminals (0.25 mm) left the body 0.3 mm short of the posts. Set the datum so their body's
    posts land on ours (0.55 mm).
  - **Draw the actuator where it is.** The MSK12C02's knob sticks out 1.45 mm sideways from the
    long edge opposite the terminals; motor-pid's footprint and model had it standing up,
    outside the courtyard.
  - motor-pid's `check_rotations.py` takes the body from the component record
    (`/api/products/<code>/components`, the 3D model's outline in an SVGNODE) and lays it on our
    courtyard. Cache the record and fetch slowly: easyeda answers a burst of requests with 403s.

## MSK12C02: the datum depends on the footprint

- Shouhan's datasheet (page 1) puts the terminals 1.95 mm from the posts' line, as KiCad's
  footprint does; JLCPCB's drawing puts them at 2.25 mm. Lay the part by its terminals and slot
  the posts (0.9 x 1.45 mm) to take either (§28).
- 0.55 mm (motor-pid) is the datum for round post holes at Shouhan's 1.95 mm.
- AMOD's footprint slots the posts (0.9 x 1.45 mm) where JLCPCB's drawing puts them. With the
  datum fitted to the terminals (0.251 mm), JLCPCB's posts land at the slots' centre, and
  Shouhan's position lies inside the slots too. Keep 0.251 there (§29).

## Part positions: JLCPCB places THEIR origin

- The CPL's Mid X/Y is where JLCPCB puts the origin of *their* library drawing. Where that is
  not KiCad's origin, the part lands off its pads by the difference, whatever the rotation.
- Every USB-C so far has done it. JLCPCB's drawing of the HRO TYPE-C-31-M-12 (C165948) has its
  origin 1.572 mm from KiCad's, towards the pad row. The preview showed it hanging off the board
  edge with its pads beside ours, and the user moved it by hand on every board (Lorenz P9-P10;
  GPiBridge, 2026-10-06).
- The Lorenz board's answer, that nothing in a CPL can address their model's origin, was wrong.
  The JLCPCB CPL is read by JLCPCB alone (the native CPL stays as KiCad wrote it), so put each
  part where their origin goes.
- `footprint_check.py` fits their land pattern onto ours and reports where their origin sits in
  our footprint (its "datum"); GPiBridge's `make_release.py` adds it, turned with the part, to
  the JLCPCB CPL, and `PLACEMENT_CHECKS.txt` lists what moved. Check in the preview that each
  moved part sits on its pads.
- AMOD-and-RFMOD's `scripts/check_rotations.py` (2026-10-28) does the same fit over every code on
  every board, turn and datum together, against `parts.JLC_ROTATION` and `parts.JLC_DATUM`;
  `gen_outputs.py` applies both and `check_outputs.py` accepts exactly those moves.
- **Fit a datum on single pads, and drop a pad that is drawn differently** (§23). A SOT-89's
  pad 2 is the lead in KiCad's footprint and the tab in JLCPCB's drawing; a fit over every pad
  put the origin 1.5 mm off. Fit on the pad numbers that are single on both sides and drop any
  whose residual exceeds 0.5 mm.
- Header drawings have their origin at the middle of the pins; the datum shift moves the CPL
  point there from KiCad's pin 1.
- Through-hole parts with keyed hole patterns go in one way only; note them (Lorenz
  MANUFACTURING).

## The bottom side

- On the bottom side the prediction was untested until ECP5 build 34. ECP5-2ADC-2DAC stores its
  bottom SOT-23-5s mirrored left-right, while the Icepi parts behind `BOTTOM_FLIP` are mirrored
  top-bottom. Look hardest at those in the preview.
- **A generated board may store its bottom side the other way round** (ECP5, 2026-10-06).
  KiCad's own flip mirrors a footprint's pads top-to-bottom; ECP5's writer mirrors them
  left-to-right, which is a top-bottom mirror turned half way round, so the same physical
  placement carries a stored angle 180 from KiCad's, and `BOTTOM_FLIP` must see angle + 180
  first (`jlc_rotation.BOTTOM_STORED_X_MIRRORED`, with `verify_bottom_convention` reading the
  file so the flag cannot go stale). Every bottom rotation in ECP5's earlier CPLs was 180 out.
  Two checks agree with the fix: a part placed on both sides (the BAV99) predicts the same
  correction from its bottom-side fit (turn + 180) as from its top-side fit, and EasyEDA-sourced
  footprints on the bottom (the magnetics, the microSD) predict 0, as they must.
- **Confirmed in a preview:** the user checked the back of ECP5 build 34 in JLCPCB's viewer on
  2026-10-08 and every part was right (the three SOT-23-5 regulators, the two BAV99s, the
  magnetics, the microSD and the 0402/0603 passives under the BGA).
