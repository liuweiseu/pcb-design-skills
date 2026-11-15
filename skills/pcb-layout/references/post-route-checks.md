# Checks after every routed build

Read this when a build has routed and you are deciding whether the copper is right. DRC and the
net checks ask whether a net is connected; these ask how it got there.

## Clock nets against the last revision

- **After every routed build, list each clock net's length and vias against the last revision.**
  DRC passes a 300 mm clock; the comparison does not. (GPSDO rev B's fenced block sent six clock
  branches 171-319 mm with 6-14 vias each, against rev A's 39-115 mm and 2; see router.md.)

## Every RF net against the shortest path through its pads

CostasLink rev A bring-up, 2026-10-29.

- What happened: LO TX MON's tap, C231 to the U.FL J204, 12.3 mm apart, was routed 115.6 mm round
  the north half of the board.
- DRC, the net check and the design reviews passed it: they ask whether a net is connected, not how
  far it goes. The bench found it: the monitor read 25.7 dB low at 5.8 GHz, and its loss grew from
  2 dB at 3 GHz with ripple, a long mismatched line.
- **The check:** each net's track length over its pads' minimum spanning tree, printed for every net
  over 2x; an RF net (touching a U.FL, SMA or MMCX, or named RF or LO) fails at 1.5x and 10 mm extra
  (CostasLink `tools/detour_check.py`). A monitor tap is as much an RF line as the path it taps:
  route it by hand, short, as the 50 ohm line it is.
- **Put it in the RF net class.** Neither CostasLink LO MON tap, nor the synthesizer outputs that
  feed them, was in any class list. They went in at the Default 0.15 mm and 0.2 mm (about 60-75 ohm
  against the 0.29 mm CPWG's 50), through 2-4 vias each, with their 27 nH pull-ups at the ends of
  2.5-17 mm branches instead of at the pins. LO RX MON's 9.5 mm tap still read 8 dB low at 5.8 GHz
  and 17-22 dB low at 3.0-3.4 GHz. The same chips' other outputs, in the LO class, were laid right:
  the pull-up 1.0 mm from the pin.
- Controlled impedance is necessary, not sufficient: simulate the circuit the copper makes (the
  rf-design skill).

## The rest of the per-build list

Each item's story is in the file named.

- Each rail's width by net in the shipped file, against its class (power-and-pours.md).
- Each rail's drop from source to every supply pin, in millivolts (power-and-pours.md).
- Each plane net's track length per layer after the planned stage, and the number of ground vias
  the via stage placed: a long run or zero vias is a fault (power-and-pours.md).
- `filled_polygon` count in the shipped `.kicad_pcb`: fail on zero (power-and-pours.md).
- Every ground via inside the filled plane polygon (`ZONE.HitTestFilledArea`) after the fill, and
  every via on an inner pour reaching the rest of it after any slot or cutout (power-and-pours.md).
- Every SMD pad that KiCad's connectivity says nothing reaches, joined (router.md).
- No via hole's edge inside an SMD pad's copper (tile-and-drawn-boards.md).
- No vias in through-hole drills, the routing net's own included (GPSDO r28 #2).
- Every shunt's signal pad nearer its chip; the span of every rule-placed series part
  (generated-placement.md).
- Judge routing by DRC's unconnected count, not the router's first-pass failure list.
