# Cost estimate

- **Cover:** board, parts, setup, stencil, Extended fees, SMT and THT joints, shipping and duty,
  for 1, 2, 5 and 20 boards. Note the quantity break where panelising pays (Icepi P31).
- **Landed cost:** the US has no de minimis exemption any more. JLCPCB pre-collects duty under
  DDP, which they band at 35-90 % of the goods' value (35 % on PCBs and SMT; the table is in
  `order-form.md`). Price boards with shipping and duty.
- **Ask the user how many will be assembled:** they typically order 5 PCBs and assemble 2.

## Itemise it as JLCPCB's cart does, and calibrate every line on a real order

ECP5, 2026-10-08: 5 PCBs, 2 assembled, $616.06 in the cart; 2026-10-09 with every option set:
$727.90 (PCB $159.17, PCBA $566.41, depanel $2.32). The model gives $615.97 and $727.89.

- **Components markup:** JLCPCB's components line runs 0.66 % above the API's price breaks for
  the same quantities, on both carts. No per-line rule explains it (attrition stacked on the
  feeder minimum overshoots; rounding each line to the cent recovers a fifth), so it is a
  calibrated markup (`PARTS_MARKUP`) until JLCPCB's per-line BOM page shows the cause.
- **Fixed per order:** 6-layer engineering $33, confirm production file $1.05, Standard PCBA
  setup $51.50 and stencil $16.54 (both sides), hand-soldering labour $3.61, PCB assembly
  fixture $16.54, packaging $0.51, special components $0.12, depanel $2.32.
- **Scaled:** the 158 x 119 6-layer ENIG board $2.64 a PCB; feeder loading $2.70 per Extended
  code (49: $132.33); SMT $0.0017 per pad plus $1.50 a board; through-hole $0.0157 per joint;
  X-ray $1.65 a board.
- **Components:** JLCPCB buys the parts needed plus each line's attrition (the API's
  `lossNumber`, e.g. 10 extra 0402s) and at least a feeder's minimum (`leastPatchNumber`), at
  that quantity's price break.
- **Other per-part fees:** each distinct Extended part costs a setup fee (about $3) on Economic
  PCBA; Standard PCBA loads a feeder for every distinct part ($1.53, Basic or Extended alike).
  THT labour is a per-order fee (about $3.58, Icepi jlcbuild J1) plus a per-joint rate.
- **The PCB page of the ECP5 order** (5 boards, 158 x 119 mm, 6 layers): engineering $33, board
  $13.20, ENIG 1 U" $19.00, stack-up JLC06161H-7628 $33.08, confirm production file $1.05, the
  0.15 mm via option $38.14 plus the 4-Wire Kelvin Test $17.89 and FR4 TG155 $3.81 it forces:
  $159.17 for 5.
- **A second assembled side** (a lone 2x20 socket on the back): a second setup, stencil and
  feeder, about $38 before duty, $51 with it.

## Small-board calibration

GPiBridge (5 boards, 2 assembled, 4 layers, ENIG, 60 x 25.5 mm): $24.80 PCBs + $60.56
assembly; GPiBridge Lite $25.85 + $40.18 (2026-10-06). The estimate was about $5 low on each:
it left out the through-hole labour that the USB-C's soldered shell legs bring. ENIG is most of
the PCB price at this size.

## Three buckets, from the generator (CostasLink, 2026-10-09, `mfg/cost_estimate.py`)

- **JLCPCB:** the boards, the assembly fees as the ECP5 cart calibrated them, their parts with
  attrition, 35 % duty, shipping.
- **Digi-Key:** the consigned lines plus tax, shipping and the shipment on to Shenzhen.
- **Other:** the bench and the field (attenuators, pigtails, antennas, power banks).
- Say which lines are the cart's, which the API's and which a model with a range, and where the
  money could move (an Extended code merged, a consignment avoided) before the user asks.

## Consignment's whole cost (CostasLink, Prompt 31, 2026-10-14)

The user: "factor in the spare 'attrition on consigned parts', which I will probably not use.
If I order more than 2 prototype boards, I'd be more willing to consign than just for the
initial 2 quick prototypes."

- A consigned line costs the pieces for the boards PLUS two spares a line (JLCPCB's attrition
  and one for the bench) that are never used, tax, the distributor's shipping, the parcel to
  Shenzhen ($35-60) and a week.
- For a two-board order a shelf part up to about $100 dearer than the distributor's price is
  still the cheaper buy (`mfg/cost_estimate.py consignment_cost`), and the number shrinks as
  the board count grows.
- The consigned part's distributor number and price are read off the distributor's own page on
  the day the release is written, and kept once, dated, in the parts table.

## Board-size trade-offs

- **Probe-ability beats the PCB price on a low-volume board.** The user, on 170 x 120 mm
  against the 100 x 100 discount (PID motor board): "I'd rather keep the ability to probe than
  save a few dollars. Not every student needs one of these boards, whereas every student needs
  an op-amp board." Shrink a board every student gets; let a lab-station board be big.
