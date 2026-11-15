---
name: boards-for-children
description: Safety rules for a board or toy meant for young children - magnets (ASTM F963, 16 CFR 1250/1262, flux index, small-parts cylinder, use-and-abuse tests), small parts, ESD on touchable metal, speaker loudness, violet/UV LEDs (IEC 62471), touch temperature, edges and finish, and safe power. Use when designing a toy, a kids' kit, or any board a child will handle, or when a design includes magnets, UV LEDs, speakers or exposed metal a child touches.
---

# Boards for children (CLAUDE_PCB.md §16)

First applied to the Halloween board (2026-10-07), a board for a young child, and to the
OWL board (2026-10-09). Related skills: `component-selection` (power input protection,
coil heating, mains off the board), `pcb-silkscreen`, `pcb-layout`.

- **Magnets:** two swallowed neodymium magnets can pinch through the intestine.
  - The US toy rules (ASTM F963, through 16 CFR 1250; 16 CFR 1262 for other magnet
    products) target magnets that fit the small-parts cylinder (31.7 mm) and have a flux
    index of 50 kG^2*mm^2 or more. That is every useful NdFeB magnet (even a 2 x 1 mm N52
    disc scores about 81).
  - Encapsulate each one completely in a part too big for the cylinder: print it in (pause
    the print and drop it in) rather than glue it into a pocket.
  - For ages 3-8 the part must keep it after soaking, drops, 4 in*lbf of torque, a 15 lbf
    pull and a 30 lbf squeeze (F963's use-and-abuse tests).
- **Small parts:** nothing that fits the small-parts cylinder may come loose. That includes
  the printed piece that holds a magnet: a snap-on cap of 25 x 13 x 6 mm with 0.8 mm hooks
  is a small part with a hazardous magnet in it (OWL, Grok's review, 2026-10-09). Glue it to
  the board it sits on, or make it too big for the cylinder.
- **Bare metal a child is told to touch** (a theremin's gold antenna) is an ESD path
  straight into whatever gate it reaches: an ESD diode at the pad (a sub-picofarad one, so a
  capacitive sensor hardly notices) and a series resistor to the gate (OWL, 2026-10-09).
- **Loudness:** a hardware ceiling on the speaker (the amplifier's gain) keeps a toy under
  85 dB whatever the firmware does.
- **Violet and UV LEDs** (420 nm and below) are a blue-light hazard.
  - Keep their radiant power low, diffuse them, point them away from eyes, prefer 400-410 nm
    to 365-395 nm, and read the datasheet's IEC 62471 risk group (the cheap ones give none).
  - 395 nm looks dim, so the blink reflex does not protect; and 62471 rates exposure at
    200 mm, where a child's eye at 2 cm gets about a hundred times more.
- **Heat:** anything a hand can reach stays below about 45 C, coils and regulators
  included. Where the hardware could exceed it, a temperature sensor and the firmware
  enforce it.
- **Edges and finish:** rounded corners and no sharp tabs; snapped mouse-bite edges get
  sanded before the board is handed over; a lead-free finish (ENIG or lead-free HASL) on a
  board that will be handled.
- **Power:** a certified wall adapter at a safe extra-low voltage (12 V), a fuse on the
  board, and nothing exposed where a dropped hairpin could short the supply (a 12 V, 5 A
  brick can make a dropped paper clip across two pads hot enough to burn a finger; see
  `component-selection`).
