# JLCPCB's order form, spelled out

Why (the user, 2026-10-09): "To minimize error when I upload (over and over as we make
changes)." `FABRICATION_NOTES.txt` opens with JLCPCB's order form as a list, field by field
in the order the web form shows them, each with the value to pick and, where it is not the
default, why. Values that come from the board are computed (dimensions, layers, the smallest
via's option, the sides that carry parts, the assembled quantity), never typed.

The form changes: when the user sends a screenshot, update these lists and the date.

## The form as of 2026-10-09 (ECP5 `mfg/make_fab.JLC_PCB_FORM`, `JLC_PCBA_FORM`)

- **PCB:** Base Material, Layers (High Precision PCB 6, 8...), Dimensions, PCB Qty, Product
  Type (Industrial/Consumer electronics, Aerospace, Medical).
- **PCB Specifications:** Different Design, Delivery Format, PCB Thickness, PCB Color,
  Silkscreen, Material Type (FR4 TG135 default, TG155 and others), Surface Finish (OSP new and
  default, ENIG; ENIG adds Gold Thickness 1 U" / 2 U").
- **High-spec Options:** Outer Copper Weight, Inner Copper Weight, Specify Layer Sequence,
  Specify Stackup, Impedance Control (shown once a stack-up is chosen: No requirement /
  +-10%), Via Covering, Min via hole size/diameter (0.3/(0.4/0.45) default down to
  0.1/(0.2/0.25)), Board Outline Tolerance, Confirm Production file, Mark on PCB (Remove Mark /
  2D barcode), Electrical Test, Gold Fingers, Castellated Holes, Press-Fit Hole, Edge Plating,
  Blind Slots, UL Marking, Backdrill, Humidity Indicator Card.
- **PCB Assembly:** PCBA Type (Economic / Standard), Assembly Side, PCBA Qty, Edge
  Rails/Fiducials (Added by JLCPCB: two 5 mm rails, 158 x 119 becomes 158 x 129), Confirm Parts
  Placement, Stencil Storage, Fixture Storage, Parts Selection; Advanced Options in rows: Bake
  Components, Photo Confirmation, Board Cleaning, Conformal Coating, Special stencil, Packaging,
  Depanel boards & edge rail before delivery, Solder Paste, Flying Probe Test, Nitrogen reflow
  soldering, Function test, Assembly remark. Then Stencil.

## Marking what differs from the default

- **Mark every value that differs from JLCPCB's default** (the user, 2026-10-09: "so that I
  don't accidentally pick up on the Default setting in a late-night or
  office-hours-is-about-to-start rush"). In the plain-text notes such a line starts with `>>`
  and names the default to avoid; in any Markdown table that shows a default beside the value
  to set, the value to set is **bold** and the default plain. Keep the value exactly as the
  form spells it.
- The defaults are not the board's: OSP finish and a 0.3 mm minimum via on ECP5, whose vias
  are 0.3 mm across with 0.15 mm drills, would both have been wrong.

## Dialogs

- **Every dialog the form raises gets its own line in the table**, with the answer and why
  (2026-10-09). JLC06161H-7628 raises a Reminder: "The actual thickness of this stackup is
  1.5544mm (tolerance +-10%), not 1.6mm ... Do you still want to select this stackup?" The
  answer on ECP5 is Yes: no connector clamps the board edge, the extrusion's slots take it, and
  the impedances depend on the outer prepregs only. A board with an edge-clamp connector (an
  edge-launch SMA that straddles the board, a card-edge finger) must check that connector's
  thickness range before answering.

## Stack-up and impedance

- **Impedance Control is its own field** (2026-10-09), separate from Specify Stackup. +-10%
  binds JLCPCB to the impedance and obliges an impedance table or diagram in the zip (which
  net, layer, width, target); without the table the order waits on an engineering question.
  "No requirement" still holds width and spacing to +-20%, and a specified stack-up fixes the
  dielectric. Choose +-10% only for a line long against its edges, and then generate the table
  from the router's widths. ECP5: No requirement (SMA feeds 8 mm, MDI 20 mm; the 70 mm HDMI
  pairs are 0.1-0.127 mm, not drawn to an impedance).
- **JLC06161H-7628 as JLCPCB's Layer Stackup dialog lists it** (2026-10-09): 1 oz outer,
  0.5 oz inner; 0.035 / 7628 0.2104 / 0.0152 / core 0.4 / 0.0152 / 7628 0.2028 / 0.0152 /
  core 0.4 / 0.0152 / 7628 0.2104 / 0.035 = 1.5544 mm. It is a "special stackup" that Economic
  PCBA does not support. The other 6-layer 1.6 mm choices: -3313, -7628D, -1080, -2116A,
  -1080A, -3313C, -1080B, -3313E, -1080C, -2116B, -2116, -7628B, -3313D, -2116C, -7628A, or No
  requirement. Copy the dialog's layers into the board's stack-up (ECP5 `pcb/board.py` had the
  middle prepreg 0.0076 mm thick until build 35).
- **"Specify Stackup: No" is the JLC04161H-7628 construction** (AMOD/RF-MOD, §29). The
  impedance page lists "No requirement" for 4-layer 1.6 mm as the same layers: 0.2104 mm of
  7628 prepreg and a 1.065 mm core. A board drawn for JLC04161H-7628 needs no choice there (the
  user could not pick one on the RF-MOD quote).

## Vias

- **Min via hole size:** set it to the board's smallest via (0.25 mm holes:
  0.25mm/(0.35/0.4mm)) (§29).
- **A 0.15 mm via hole costs about $56 on 5 boards of 158 x 119 mm** (2026-10-09): the
  0.15mm/(0.25/0.3mm) option $38.14, plus the 4-Wire Kelvin Test ($17.89) and FR4 TG155
  ($3.81) that JLCPCB then selects by itself. Use it only where the BGA's fan-out needs it. The
  rest of that PCB page: engineering $33, board $13.20, ENIG 1 U" $19.00, stack-up
  JLC06161H-7628 $33.08, confirm production file $1.05: $159.17 for 5.
- **Via Covering:** Tented, which the form may upgrade to Via Plugged for free: say "Tented or
  Plugged" in the order notes when either is fine, as it is unless a via must stay open
  (CostasLink rev A, 2026-10-17). As of 2026-10-29 (§29) the form offers Plugged by default
  and Tented is greyed out; Plugged suits a design drawn for tented vias.

## JLCPCB options that constrain a design

Read on their capability and help pages, 2026-10-07, for the Halloween board; re-check, they
change.

- **Colour decides the assembly service.** Economic PCBA does 4-layer boards in green only;
  purple, black or any other colour on 4 layers means Standard PCBA, whose smallest single
  board is 70 x 70 mm. Smaller boards go on a panel, or ride as break-away tabs on a bigger one.
- **An assembled panel stays inside 250 x 250 mm.** JLCPCB accepts bigger "at the customer's
  risk": it warps through two reflows, and an engineering question follows. Plan a
  multi-design panel inside it from the start; turn a tall board 90 degrees if that is what
  fits (OWLternating Current: 323.6 x 154.2 mm became 245.2 x 223.2 mm).
- **Standard PCBA loads a feeder for every distinct part** ($1.53, Basic or Extended alike;
  the Extended-only fee is Economic PCBA's). Every BOM line merged saves it.
- **No order number.** Since May 2026 JLCPCB adds none by default and asks that
  "JLCJLCJLCJLC" not be put on the silkscreen: choose "Remove Mark". (Superseded practice:
  before then JLCPCB printed its order number wherever it liked unless the board carried
  `JLCJLCJLCJLC` and the form said "Remove order number: Specify a location"; the marker went
  on the back in a band the enclosure hides, ECP5 build 31's top slot band on B.SilkS, and the
  fabrication notes said so.)
- **Locating posts.** JLCPCB's own drawing of a part can put its posts somewhere other than the
  maker's land pattern does (the MSK12C02 slide switch: 0.30 mm further from the pins). Make
  each hole take both, and check every NPTH post against their drawing.
- **2 oz outer copper** on multilayer boards: the solder-mask dam needs 0.20 mm between pads
  (0.10 mm at 1 oz), and the minimum track and gap is 0.15-0.16 mm (design to 0.2 mm). Inner
  copper is 0.5 oz unless ordered; 2 oz inner has been tied to the JLC3313 stack-up, which
  changes every impedance.
- **Lead time:** a 4-layer board takes 2-5 days, Standard PCBA at least 4 more, and parts not
  in stock 9-15 days of global sourcing. To the US, DHL and FedEx Express are for corporate
  accounts; individuals get UPS Express Saver (DDP, 4-5 business days). Plan on about two weeks
  from order to door.
- **Duty:** DDP pre-collects a flat 35 % on PCBs and assembly, 40 % on 3D prints. JLCPCB's own
  table (news page, March 2026; tariff FAQ updated September 2026): PCB 35 %, SMT 35 %, a
  stencil ordered on its own 90 %, CNC and sheet metal 40-90 % by material (they band DDP duty
  at 35-90 % of the goods' value). They set the rate "based on the product type and material",
  not on the usage picked at checkout, and "reserve the right to replace the HS code to match
  the actual product". The field is the form's **Product Type**: Industrial/Consumer
  electronics, Aerospace or Medical; every board of the user's so far is Industrial/Consumer
  electronics. So the usage choice is a truthful description for the declaration, and no
  truthful choice is cheaper than another: pick the board's real primary use (research,
  teaching or hobby; the Halloween board is a child's decoration), never a category picked for
  an exemption (ECP5 P38, 2026-10-08).
- **JLC3DP** prints SLA, MJF, SLS and FDM (8001 resin is clear or translucent) but nothing
  glow-in-the-dark; JLCCNC mills acrylic (polished edges on request) but nobody in the group
  laser-cuts it.
