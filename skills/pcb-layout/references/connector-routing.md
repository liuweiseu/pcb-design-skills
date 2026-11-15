# Routing to connectors and headers: pin order, crossings, two-row plugs

Read this when lines run between a chip and a connector, or between two headers, and they must
cross; and before laying out any keyed two-row connector (Pmod, 2x20 header).

## Order reversals

- **Order reversals need a layer change.** When a chip's pins leave it in the reverse of a
  connector's contact order (GPiBridge Lite: the RP2354A against the GPIB plug), no single-layer
  routing exists, however the lines bend. Find the one place where the lines run in the
  connector's order and change layer there, once per line: on the Lite, where the ribbon rises
  into a row of series resistors, a via above each takes it to the bottom layer and straight down
  to its contact.
- **Two side-entry headers on one side of a board always meet in reverse pin order** (GPS
  adapters, 2026-10-08). Turn them how you like: ribbons leaving two connectors on the same face
  keep the same handedness, so head-on they reverse, and every shared net crosses every other. With
  SMD headers, a net needs two vias. The plan that drew both adapters:
  - each net leaves its pin on the top layer to a via in its own column, runs down or up the bottom
    layer to the row of its pin on the other header, and comes back up;
  - put the second header's rows half a pitch (0.625 mm for GH) off the first's. Then a track along
    any row clears every other row's vias by 0.625 - 0.1 - 0.3 = 0.225 mm. Assert it in the
    generator;
  - the net that is the middle pin of both headers (SDA there) can cross on the top layer with a
    jog and no via;
  - two vias of one net closer than about 1 mm break hole-to-hole (0.5 mm). Join the second track
    to the first via instead of drilling again;
  - any column order works; choose it for where the other parts need their taps.
  A third header in the same bus (the any-to-any hub) is the same thing with one column per signal
  for all of them.
- **Look at a gate package's pinout against the routing before choosing it.** The 74LVC2G14's VCC
  pin sits between its two outputs, so on a 2-layer board whose bottom was all bus columns its
  supply had no way out. Two R + LED lamps from 3.3 V into the lines (lit while low, about 1 mA,
  only then) did the job with no IC (GPS hub).
- **Inner-layer lines between through-hole pads need no vias** (Icepi Pmod adapter, §18): on a
  four-layer interposer whose outer layers are full, eight lines ran on In2 from header pin to
  socket pin, 0.2 mm wide through the 0.84 mm half-pitch gaps. Lay them so the leftmost line turns
  lowest and the highest lane descends rightmost: no crossings, by construction.

## Pmod and other keyed two-row connectors

- **"Pmod pin k is pad 2k-1" is true of KiCad's numbering only** (AMOD-A, RF-MOD, §17). KiCad's
  horizontal 2 x 6 header and socket put pad 1 on the row FAR from the body; JLCPCB's drawings of
  the same parts (PZ254R-12-12P C492434, HC-PM254 C22373932) put pad 1 at the other end of the row
  NEAR the body, so their pad p is KiCad's pad 13 - p. AMOD-A and RF-MOD were laid with the KiCad
  rule on the JLCPCB footprint: every plug pin k met the host's pin 13 - k, IO lines on the host's
  ground and 3.3 V. Caught before the order by mating the two footprints on paper; fixed by moving
  the plug two columns and renaming the nets, and a fab check (`check_pmod`) now maps every plug pad
  to its standard pin. For any keyed two-row connector, derive the pin from the pad's POSITION
  relative to the body, never from its number, and check both mating halves.
- **A 2 x 6 Pmod plug's lower row is reachable only through the upper row's 0.74 mm gaps** (0.2 mm
  tracks with 0.27 mm to spare) or along the bottom edge (two tracks fit between the pads and the
  0.3 mm edge clearance). Feed the upper row from the back, straight down; feed the lower row from
  the front. Feeds come from one side, each above the feed of the pad to its right, so none cross.
  A via that an F.Cu feed passes needs 0.625 mm from the feed's centre line.
- **Choose the Pmod pins so the lines nest; do not route around a fixed pin order** (AMOD-B, §26).
  On a 2 x 6 plug the lower row's lines leave through the gaps between the upper row's pads. For
  lanes that never cross, the order of the exits along the plug must be the order of the lanes in
  the gutter, and the lane that turns off first must be the outermost. Two lines shared by two
  tiles (SCK and MISO for an IMU and an encoder) cannot both branch from one bundle in a gutter
  without a crossing: run all the lines into one tile and let the other tile's lines leave it as a
  bundle above them. Swapping two pins' assignments (AMOD-B's MISO and CS ENC) made the whole
  bundle planar.
- **Leave the back's pour a way to a plug's ground pad** (power-and-pours.md).
