# Part-specific notes and the stories behind the sourcing rules

## Stock and substitution stories

- **A line can run out AFTER the order is placed** (GPiBridge L1, Abracon AOTA 3.3 µH,
  C42411119). 347 on JLCPCB's shelf when the release was costed (2026-10-08); the order placed
  2026-10-06 with "stock >= the order" passing; on 2026-10-18 an email: "Due to insufficient
  stock of C42411119, we have enabled the 'Replace Parts' function for your order"; 3 left for 4
  boards.
  - The fix is in Order History (Replace Parts: pick one, or leave it unpopulated); nothing is
    re-uploaded.
  - Before answering, `tools/jlc_api.py` with a free-text search ("3.3uH 2016") lists the shelf
    with stock, Isat, DCR and package in a minute, and the datasheet or the vendor's design guide
    says what the part has to be (here: 3.3 µH, 2016 land, Isat > 1 A; the AOTA's only special
    property was a polarity dot).
  - Keep the design's part and record the substitution where the part is named (gen/parts, the
    design notes' risk list, the bring-up's check of what the part affects, the README's status),
    so the next order expects it.
- **Oversold on the order day** (AMOD/RF-MOD, §29): a 27 ohm and a 6.8 k 0402, a 220 nF 0402
  and the OPA847IDBVR read 644 to 51 401 in stock with a negative free count; another code went
  from 40 328 to 74 in four days. A dropped tile's crystal had none free (ignored: no BOM ordered
  it). OPA847IDBVT replaced IDBVR; its rotation differs (+180 against +270).
- **Consignment avoided:** the ADL5380 datasheet's Johanson 5400 balun (0 at JLCPCB) replaced by
  TDK HHM1907B1 (7,884), same ratio and band with better numbers.
- **Search by category:** Mini-Circuits mixers by part number had 2-15 in stock; the category
  "RF Mixers" found the ADEX-10L+ with 861.
- **Under another name:** TI's TSSOP 4046 had 21 in stock; Nexperia's 74HC4046APW-Q100J had 234.

## Connectors

- **Connectors JLCPCB stocks only in part** (GPS adapters, 2026-10-08). The genuine JST GH
  side-entry headers: 10-pin plenty (C2683602), 8-pin none (C265111), 6-pin 118. JUSHUO's
  GH-compatible GH125-SxxDCA-00 had all three. Its signal pads match KiCad's JST land pattern
  exactly, but its mounting pads sit 0.30 mm further toward the mating face, so the footprint's
  pads were stretched to take either part. Beware "1.25 mm" headers that are Molex PicoBlade
  (MX 1.25) clones, not GH: the description says which.
- **Pmod 2x6 numbering:** KiCad's horizontal 2x6 header and socket put pad 1 on the row FAR from
  the body; JLCPCB's drawings of the same parts (PZ254R-12-12P C492434, HC-PM254 C22373932) put
  pad 1 at the other end of the row NEAR the body, so their pad p is KiCad's pad 13 - p. AMOD-A
  and RF-MOD were laid with the KiCad rule on the JLCPCB footprint: every plug pin k met the
  host's pin 13 - k, IO lines on the host's ground and 3.3 V. Caught before the order by mating
  the two footprints on paper; fixed by moving the plug two columns and renaming the nets; a fab
  check (`check_pmod`) now maps every plug pad to its standard pin (§17).
  - **Correction, 2026-11-16: "both mating halves" was not enough;** `check_pmod`'s "standard
    pin" was a mirrored host's, so the AMOD and RF-MOD rev A plugs mate with nothing standard.
    See the pcb-layout skill, references/connector-routing.md, "Pmod and other keyed two-row
    connectors".
- **Edge vs vertical:** CostasLink's first MMCX candidate, BWMMCX-KEF (C5250057), was edge-mount
  (its EasyEDA footprint carries Edge.Cuts); the taps wanted the vertical BWMMCX-KE (C5137198).
- **2.54 mm headers at their own length:** XFCN PZ254V-11-02P C492401, -03P C2937625, -04P
  C2691448, -06P C492405 (one row), PZ254V-12-16P C492425, -18P C492426 (two rows); about $0.02
  each against $0.13 for a cut strip (C2337 1x40, C29952 2x40). Sockets 1x5 / 1x2 C2894928 /
  C2894925.
- **KF301 screw terminals** (KF301-5.0-2P / 3P C474881 / C474882): the op-amp board's footprint
  had read the "3.60" of the front view as a depth; the CPL is +180 with the wire openings to
  the edge, body 3.7 / 4.0 (§28, §29; a wire-face check in `check_outputs.py`).

## Parts to know for a teaching board (op-amp board, 2026-10-24)

- **RH-5019 SMT test loop, C5199800** ($0.10, 101 k in stock): one 4.0 x 2.2 mm pad, a 3.8 mm wire
  loop a scope hook or mini-grabber takes. The right "test point" when students will clip on; a
  2.54 mm pin is through-hole and flops over with the hook. JLCPCB rotation 0 (predicted, later
  read; the loop lies along x).
- **KingTek DSIC02LSGET 2-way DIP, C54949** (SMD, 2.54 mm, raised sliders): one per selectable
  variant, so nothing ships loose. Same family as the Lorenz 6-way (C54952), whose +270 was read;
  the 2-way was +270 predicted, then read. Pins 1-4 are position 1, 2-3 position 2; "ON" is
  toward +x in the footprint frame.
- **MMBT3906 has no Basic-library code**: C53444 (onsemi), C2143 and C727128 are all Extended.
  The MMBT3904 C20526 is Basic. One Extended fee is the price of a real PNP.
- **Bourns 3362P-1-xxx, C52754333 (50 Ω)**: three holes in a triangle, so it fits one way; 520
  in stock, with the 100 Ω C52754331 as the drop-in alternate. Its body is not centred on the
  pins: pins 1 and 3 sit 3.53 mm from the body's edge and pin 2 2.54 mm further in, so the body's
  centre is on the line of pins 1 and 3 (Bourns' 3362P drawing; EasyEDA's agrees). BOCHEN's
  3362P does the same (1.30 mm from the middle of its pins).
- **Panasonic ECW-F film capacitor** (450 V, "active filter circuit" in its data sheet) is
  stocked at JLCPCB (C242107, 18.1 x 9.3 mm, leads on 15 mm); JLCPCB's land pattern
  (`easyeda.py`) confirmed the footprint's origin (PID motor board; the choice of film over X5R
  is in `component-selection`).
- **MSK12C02 slide switch C431540:** Shouhan's land pattern puts the terminals 1.95 mm from the
  posts' line, JLCPCB's drawing 2.25 mm; slot the posts 0.9 x 1.45 mm; the knob sticks out
  1.45 mm sideways from the long edge opposite the terminals (datum details in
  `cpl-rotations.md`).

## JLCPCB Basic passives that fit a SOIC's pin pitch (§17)

0402 basics: 10 k C25744, 1 k C11702, 470 C25117, 1.5 k C25867, 100 n C1525, 1 n C1523; 0603
10 ohm C22859 and 1 uF C15849. These let a SOIC's pins have their resistors at the pin pitch.
51 ohm (C25125) and 3.9 k (C51721) are Extended.

## Wrong codes and attributes

- ECP5 4c: eight codes typed from memory named the wrong part (a 2.2 pF capacitor was a 180 kΩ
  1206 resistor, a 24.9 Ω load 470 kΩ); eleven codeless SMD parts silently became "hand-solder".
- GPSDO F2002: "1.1A PPTC" on the sheet; C70076 is the nSMD050-24V, 0.5 A hold, 1 A trip, under
  the 643 mA heater it fuses.
- ECP5 4b: a 50 mA chip inductor where a 600 mA power inductor was required.
- PAM8302AASCR C113367: MSOP-8, the only PAM8302 JLCPCB stocks; it was placed on a SOIC-8
  footprint.
- Legacy datasheet: Johanson 5400BL15B0050001E is rated 4900-5875 MHz; the legacy
  5400BL15B050E's sheet said 5900.
