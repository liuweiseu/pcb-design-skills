# Writing and running a router: the lessons

Read this when a script routes the board (a maze router, planned copper, rip-up and reroute), when
nets stay in pieces after routing, or when choosing which of a chip's pins drive which signal.

## Which router

- The Java autorouter (Freerouting) made things worse.
- A simple maze router plus hand-planned routes worked (GPSDO). River-routing buses first worked
  (ECP5 P5).
- **Plan the copper.** On GPiBridge the maze router was left only the ground vias: every other
  connection, down to each decoupling capacitor's 1 mm stub, is written as coordinates computed
  from the pads. The router's versions wandered (VBUS through three layers, a UART line along the
  board edge); the planned ones look like a person drew them and are no more work to write than
  the fixes they replaced.

## Debugging a failed net

- **Look at postage stamps of the router's own obstacle grid** round one failed connection. Three
  looks found what a day of blind rebuilds did not (ECP5 P3). Take them the moment the net fails:
  by the end of the run later nets have covered over what walled it in.
- **A first-pass failure list is not the result;** the retry and fine passes fix most of it. Judge
  by DRC's unconnected count.
- **A net router must not stop at the first piece it cannot join.** OWLternating Current's first
  runs joined each net's pieces smallest first and returned on the first failure: one walled-in pad
  left +3V3 in 35 pieces. Set the failed piece aside (others may still reach it) and go on; report
  why each failure failed (walled in, or out of search budget), because the cures differ.
- **When the same nets fail whatever the router does, the wall was laid before the router ran**
  (CostasLink Response 15). Build the planned stage alone and look at it as the router receives it.
  A cleanup pass that removes dangling copper must not run on that view: every fan-out via dangles
  before routing, and the tidied view showed nothing round the chip that was walled in.
- **Seeds are for luck; a net that fails in every seed is a placement fault** (see
  generated-placement.md).

## Rip-up and reroute

- A short function and worth it: keep the cells a walled-in search explored, take out the
  router-laid copper of the nets that bound them, route the walled-in net first and then those, and
  keep the result only if fewer nets end in pieces (else put the old copper back exactly). On
  OWLternating Current it finished 4 to 6 nets per run that ordering alone could not.
- Tag what the router laid (planned copper is never ripped), and make vias removable (count each
  drill's keep-out instead of setting a flag).

## Order and protection

- **Put every signal on the FPGA face that looks at its chip when the plan is first made**, spare
  balls permitting. A slow control line on the far face is the board's longest route and the first
  to fail when anything tightens (ECP5's AD9238 DCS and PDWN_A: 60 mm detours from bank 8 that only
  the fine grid finds). Moving them late is not free: the pin swap that follows a plan change
  reshuffles other balls and a board routed at the margin loses other nets (build 28 tried and
  reverted). A long slow line the router finds only by luck is laid by hand on the route it once
  found, before routing: the router cannot lose what it never has to find.
- **A board at the router's limit fails one net at a time, and a different one each run** (GPSDO
  rev B, 2026-10-10, after 26 parts were added). More attempts (16, 32) and a wider board did
  nothing. What did:
  - **Terminal protection:** while a net routes, block the free cells round every other pending
    net's terminal, and give exactly those back before its own copper goes in. Otherwise an early
    net runs half a millimetre past a later net's hand-over point and seals it in.
  - **Exempt the nets that route first** and must stay short (the helper clocks): under protection
    they detoured round every pending terminal, 149 mm instead of 98.
  - **A keep-away for asynchronous aggressors:** clocks 1.2 mm from I2C. A router with one
    clearance put a 55 mm clock beside SCL.
  - **Late hand routes:** copper drawn by hand only if the net is still split after routing, and
    only where the real geometry is clear (several candidate paths, vias checked). Laid early, any
    hand copper in the congested band moves the outcome.
- **Join a net's short connections before routing any net whole** (CostasLink Response 15). A
  router that takes nets in order of span routes a board-wide net's 2 mm hop late: VC's U112 pin 7
  to its capacitor, the PI node's two resistors. By then the long nets have fenced the pad in.
  Before the long routing, join every pair of a signal net's pieces whose pads lie within 5 mm,
  shortest pair first. Search only round the pair: the top layer without a via first, then any
  layer. CostasLink joined 72 of 95 that way. With the GND fix, nets in pieces after the repair
  went from 3 to 2, and from 3 to 1 together with shrinking the inner pours (power-and-pours.md).
  GPSDO rev B's terminal protection is the other cure for the same disease.
- **Never route ground, or a rail with a plane or pour, "whole" as a net** (power-and-pours.md).
- **Never fence a block on both routing layers** (GPSDO rev B, 2026-10-09). The helper block's right
  edge carried the +3V3_D spine on F.Cu and an I2C pair on In2 for its whole length, so nothing
  could leave that side. The six clock branches to the right-hand column went round the block:
  171-319 mm and 6-14 vias each, against rev A's 39-115 mm and 2, and one did not route at all. The
  detours then stranded three other nets. Run a long run on the layer that leaves the other free
  where the branches cross, and draw the crossing by hand.

## Joining copper so KiCad agrees

- **Join a track that ends inside its own via, off the via's centre, to the centre** (CostasLink
  Response 15). Planned fan-out vias sit at exact, off-grid places; a grid router ends its tracks
  on its grid inside them, up to 0.2 mm off. KiCad does not count such an end on an inner layer as
  connected. The cleanup pass then saw a dangling via, removed it and cut ERR in two. Add a segment
  no wider than 0.15 mm from the end to the centre: it lies inside the via's pad. Moving the end
  instead dragged 346 tracks at an angle into their neighbours (18 clearance errors, 7 crossings)
  and collapsed short tracks to nothing. A 0.5 mm rail-width segment stood out of the via's pad:
  2 more.
- **Ask KiCad which pads nothing reaches, and join them** (CostasLink Response 15). A grid router
  can count a line that runs past a pad as joined to it; KiCad wants the copper on the pad. TX_EN's
  line passed R227's pad 0.05 mm clear of its rounded corner, both of the line's ends were anchored
  elsewhere, so the dangling-end pass never saw it, and DRC said "unconnected". After the fill: for
  every SMD pad whose `GetConnectivity().GetConnectedItems(pad)` holds nothing but pads, add a
  segment from its centre to the nearest same-net track on its layer within reach. Decide by
  KiCad's connectivity, not by geometry of your own: a test of track ends inside the pad flagged
  eight pads that a track crossing them already joined.
- **A via with copper on one layer only is "dangling"** (AMOD, §17). A back wire that T-joins
  another back wire must not end in a via; make it one polyline, or let it end on a pad.
- **Every back-layer polyline end is a via** (AMOD-2, §20). A branch that ends on the middle of
  another back trace drops a via there, often under a front-side part. Draw a branch as one
  polyline from via to via (overlapping a same-net segment is fine), never ending in mid-trace.
- **An open-ended line is not a dangling track** (§23). Draw a stub as copper graphics on its net
  (KiCad joins them to the line they start on), or DRC calls its open end dangling.
- **A pad table keyed by pad number loses pads** (§17). A vertical SMA jack's four legs are all pad
  "2"; a USB-C's four shell pads are all "SH". Keyed by (ref, number) they collapse to one, and a
  router or a silk clipper that reads that table puts vias and silk on the three it cannot see. Keep
  every pad in a list for obstacles and the (ref, number) map only for wire ends.
- **Pass every width** (§26). A ground stub that defaults to "the tile's first wire" took a 1 mm
  motor rail's width on two tiles and shorted the pads beside it. A default borrowed from elsewhere
  is a bug waiting for the first wide wire.

## Let the board choose the swappable pins: river routing with late assignment

Agents (and people) fix a chip's interchangeable pins in a table before anything is placed: GPIO 0
drives coil 1, LED channel 0 lights star 0. The table's order then fights the board's, the router
has to cross lines that never needed to cross, and the failures look like congestion. Before
routing, list every set of interchangeable pins (an MCU's GPIOs, an LED driver's channels, a mux's
inputs, the sections of a dual op-amp or a gate package, the contacts of a connector you define),
and leave them unbound until the rivers meet:

1. Route each destination's line back toward the chip, without choosing a pin, until it reaches a
   ring round the chip. A coarse multi-source search outward from the ring, with only the big
   obstacles in it, does this for every destination at once.
2. Read off the order in which the lines arrive on the ring.
3. Bind the pins in that cyclic order. A minimum-cost matching on distance along the ring is
   non-crossing. Keep within each pin's real constraints:
   - an LED driver's channels are all alike (keep a feature's LEDs in one brightness bank only if
     the firmware needs it);
   - an MCU's GPIOs move within their function classes: ADC pins, a bridge's two PWM inputs on one
     slice, I2C and UART on the pins their instance allows, consecutive pins where the firmware
     does one masked write.
4. Route each bundle in that order as a river, outermost line first.
5. Generate the schematic and the firmware's pin and channel headers from the result, so nothing
   downstream is edited by hand.

OWLternating Current's first routing pass, with a table written before placement, left 59 nets
unjoined. Most were LED-driver channels and GPIO lines.

A signal's destination is the chip pin it reaches, not every pad on its net. Follow it through
series parts (a two-pad R, C or L whose far side is not a rail) and drop shunts. CostasLink's first
header swap averaged the positions of its 1 k series resistors, which the placer puts wherever the
header pin pulls them: the assignment chased itself (14 moves, then 4 more) until the destinations
were the comparators. Re-run the swap after the rebuild; it is right when it proposes nothing.
