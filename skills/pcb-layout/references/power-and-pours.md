# Power distribution, ground nets and pours: the detail

Read this when laying out supply rails, pours or planes, when a rail's drop or width is in
question, or when DRC reports an island, a starved thermal or an "unconnected" ground via.

## Measuring a rail

- **Pours or wide traces.** GPSDO's +3V3_A lost 109 mV in 1.4 m of 0.5 mm track because the
  "plane" was never poured (GPSDO REVB #5, ECP5 P2).
- **Dropout from the worst input.** A USB port can give 4.75 V, less a fuse and a diode.
- **Measure the drop, not the width.** A script that walks each rail's copper as a resistance
  network from its source to every supply pin (ECP5 `tools/power_path.py`) answers "is enough
  power getting there?" in millivolts, and finds the 0.127 mm feed nobody remembered (ECP5 P28:
  102 mΩ to VCCAUX, 4 mV, fine).
- **Analog rails get planes, not traces.** An LDO 16 mm from its converter on 0.4 mm track is
  45 mΩ; op amps fed 60 mm from one bead share 0.2 Ω. The fix is a patch on the power layer from
  the regulator to the chip, a via per pin (ECP5 P30: 45 → 5 mΩ, 206 → 5 mΩ, and the router
  finished in half the time).
- **Join copper by overlap, as KiCad's connectivity does:** a via on a track's interior, a track
  ending inside a through-hole pad on the back layer. An endpoint model reports opens that are not
  there; find the construct, do not explain the report away (ECP5 P29).
- **DC resistance of high-current paths:** count the squares and compute the drop, return path
  included (Rosenberg; see the component-selection skill). GPSDO's +3V3_A above is the example.

## Rail width: route narrow, then widen

- **Measure every rail's width in the shipped file, by net, against the rule.** ECP5's router
  narrowed a whole net to the narrowest pad it touched: one 0.25 mm LQFP pin laid 200 mm of
  +3V3_ADC at 0.23 mm, and +5V and +3V3 the same, through 27 builds that all said "0.4 mm rails"
  (ECP5 P26).
- **Do not fix it in the router.** Every rule that routed the rails wide and narrowed them near
  the fine pads took the room the converters' own signals needed (three build-28 runs each lost
  two to five nets). Route at the pad's width as before, then widen each track toward its class
  width wherever the copper round it leaves clearance (`pcb/fatten.py`): no route moves, DRC sees
  the same board or more room, and the long runs come out wide.
- **A rail routed wider than its fan-out stub leaves a sliver the tidy re-makes** (CostasLink
  Prompt 35: rails routed at 0.3 mm into 0.15 mm stubs; a 0.2 mm overhang at the DSA's VDD pin was
  called dangling by DRC, removed by the refill, and laid again by the next tidy, in every pass of
  six builds). Route a rail at the stub's width and let the widening pass (which keeps narrow near
  fine pins) do the rest, or end the stub where the wide track starts. Measure the result by net:
  the widening finds room on a third of the length.
- **Never widen a planned line or anything within a millimetre of a fine-pitch pin** (see
  fine-pitch-fanout.md, the radius-0 cell query).

## Never route a plane net "whole"

CostasLink, 2026-10-10, Response 15. It cost 875 mm of top-layer copper nobody needed.

- What happened: the planned-copper stage gave a fan-out line to every pin of a chip, the ground
  pin of a chip without a paddle included. A pin the fan-out could not serve was then routed
  "whole, while the board round it is still empty". For a ground pin, the whole net was GND.
- It ran before the stage that drops a via beside each ground pad. Every bare ground pad was still
  a piece of its own, and the router joined them all with top-layer tracks: 875 mm in 580
  segments, between U112's two pin rows and along pin rows.
- The via stage then found every ground pad already joined and placed no vias. Its log said
  "0 ground vias" in every build of Response 14, and nobody read it.
- The top layer round the loop block was fenced before the first signal was routed. VC's 2 mm hop
  from U112 pin 7 to its capacitor was walled into 48 cells. Four nets failed in every variant
  tried (eight router orders, a wider rip-up, smaller pours) until the planned copper was looked at.
- **The rule:** a plane net's pads each get their own short stub and via. Any helper that routes
  the rest of a net skips GND and the rails that have a pour.
- **The check, every build:** print each plane net's track length per layer after the planned
  stage, and the vias the via stage placed. GND on a signal layer is a few hundred stubs of half a
  millimetre (CostasLink after the fix: 288 mm in 550, and 173 ground vias). A long run, or zero
  vias, means something else joined the pads first.

## Pours on inner layers

- **Count what an inner layer's supply pours leave for the signals.** A pour drawn as a routing
  obstacle closes its layer to every other net. CostasLink's In2 pours covered 73% of In2; with In1
  solid ground, most of the board had two signal layers, one under the parts. Draw a pour only
  where its rail's pins need it. The +3V3_DIG pour served three slow chips across the whole loop
  block; shrunk to the comparator strip that needs it, and with In2 priced at 3 instead of 6 for
  signals, the last two nets routed. Trials side by side on copies: 2 nets in pieces with short
  connections first alone, 1 (only GND, which the fills join) with both.
- **Rails as pours on an inner layer, one polygon per rail** (AMOD, §17). Two zones of one net that
  overlap fail `zones_intersect`; two that only touch do not connect once each is inset by its
  minimum width. Draw the rail as one polygon. A strip of pour narrower than two via clearances is
  cut by the first via of another net that crosses it (the -5 V strip under the Pmod plug was):
  keep rail strips 1.5 mm wide and vias of other nets out of them.
- **A pour's membership test uses its outline, not its bounding box** (CostasLink, 2026-10-09,
  Response 9). The router joined a supply via to its In2 pour when the via lay inside the pour's
  bounding box; an L-shaped pour (+3V3_ANA wrapped round the PLL's) has a notch inside that box,
  two vias landed in the notch, the router called them joined, DRC called them dangling. Test the
  polygon, with a margin from its edges (`routing.inside_margin`), and the two vias went away.
- **Holes cut inner-layer pours** (AMOD-C/M/B, §26). The +3.3 V strip on L3 ran under the gimbal;
  its side slots cut it, the middle piece (the encoder's supply via) became an island, and DRC
  reported it only as two missing connections on the front. After placing any slot or cutout,
  check every via on an inner pour reaches the rest of it; bridge the pour round the holes.

## Ground pours on outer layers

- **Back runs box the ground plane** (PID motor board). Two −15 V branches plus a +15 V spine plus
  their taps made a closed rectangle on the back with a bypass via inside it; the fill removed the
  island and DRC said "unconnected". After the fill, test every ground via against the plane
  polygon (`ZONE.HitTestFilledArea`) and fail the build if one is outside; route the taps to one
  side so no loop closes.
- **Leave the back's pour a way to a plug's ground pad** (§26). Lanes on three sides of a Pmod
  plug's ground pad left it one thermal spoke (DRC: starved thermal). Keep the nearest lane 1 mm
  off the pad row so the pour passes between them; on the fine nets' 0.35 mm pitch the rest of the
  lanes still fit above.
- **A floating jack needs its legs on their own net and a void on every layer** (§23). A 1:1
  transformer's OUT whose shell is the secondary: the four legs on their own net joined by a U of
  track, no plane within 5.6 mm, the schematic labelling the shield instead of grounding it.
- **Fill zones in the file you ship.** GPSDO's committed board had no pours: zones were filled
  into a copy for DRC, and the original went to the gerbers (GPSDO r29 #18). Count
  `filled_polygon` in the shipped `.kicad_pcb` and fail on zero.
