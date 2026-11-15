# RF lessons from the tile boards (RF-MOD, AMOD, IQ-MOD; CLAUDE_PCB.md §18-29)

The AMOD / RF-MOD boards are 100 x 100 mm grids of 20 mm cells, every cell a circuit between two SMA
jacks, on JLC04161H-7628. Read this when generating many small RF circuits from one generator, when
adding couplers, splitters, synthesizers, calibration standards or 50 Ω terminations, or when
ordering a controlled-impedance 4-layer board from JLCPCB. Tile layout, silk and placement lessons
from the same sections are in `pcb-layout` and `pcb-silkscreen`; sourcing and CPL rotations in
`jlcpcb-order`.

## Lines and the generator

- **A tile's RF rules belong in the generator, not in each tile** (§18, RF-MOD, 2026-10-25).
  - A wire of one width (0.29 mm on JLC04161H-7628) is a 50 Ω CPWG line.
  - The generator gives it an "RF" net class (0.25 mm clearance), pours L1 ground round it at
    0.25 mm, fences it with ground vias (0.845 mm off its centre, every 1.0 mm, wherever a via fits
    clear of pads, tracks and other vias), and voids L2-L4 within 2.2 mm of every RF jack's centre
    pin (rule areas with fills forbidden).
  - The tile only says `t.rf(net, pts)`.
- **A 50 Ω line may leave its tile, but its ground must go with it** (§22).
  - R10's second output runs 1.25 mm below the tile, in the margin, because the slide switch fills
    the tile's bottom edge. Outside the tile's top pour it was a microstrip (about 58 Ω on
    JLC04161H-7628); a tongue of pour that follows it (`Tile.pour_below`) makes it coplanar again.
  - Keep it 1.25 mm below the frame: KiCad's box for 0.9 mm text is 1.68 mm tall, and the jack's name
    sits there.
- **Narrow a fine-pitch RF part's pads rather than the RF class** (§22).
  - JLCPCB's land pattern for the 1608 coupler leaves 0.2 mm between 0.35 mm pads, under the RF
    class's 0.25 mm.
  - The part's terminals are 0.25 wide; 0.29 mm pads clear the class and still cover them.
  - Say so in the footprint's description and the DOA list.
- **An open-ended line is not a dangling track** (§23). Draw a stub as copper graphics on its net
  (KiCad joins them to the line they start on), or DRC calls its open end dangling.
- **JLCPCB's order page: "Specify Stackup: No" is the JLC04161H-7628 construction** (§29).
  - The impedance page lists "No requirement" for 4-layer 1.6 mm as the same layers: 0.2104 mm of
    7628 prepreg and a 1.065 mm core.
  - So a board drawn for JLC04161H-7628 needs no choice there (the user could not pick one on the
    RF-MOD quote).
  - Set "Min via hole size" to the board's smallest via (0.25 mm holes: 0.25mm/(0.35/0.4mm)).
  - "Via covering" now offers Plugged by default, and Tented is greyed out. Plugged suits a design
    drawn for tented vias.

## Circuits and parts

- **A synthesizer loop filter for two bands at once** (§18).
  - The VCO's range is fixed (3-6 GHz on the MAX2871) and the output divider sits outside the loop,
    so each band sees the loop through Kvco / N at the VCO.
  - Search the stocked values with the open-loop model over the Kvco spread and every N in use.
  - Keep the phase unwrapped: a margin of 350 degrees is a wrapping bug, not a stable loop.
- **Before spending cells on a splitter, look for the output the chip already has** (§22).
  - Two RF-MOD tiles were resistive splitters (two cells each, 6 dB lost) while each MAX2871's
    complementary output, RFOUTA-, sat terminated in 51 Ω. Brought to its own jack it is a second LO
    at full power, 180 degrees from the first.
  - A part the student can buy as a cable accessory (the user: "I have passive splitters") does not
    earn board area.
- **Two single-direction couplers back to back make a dual directional coupler** (§22). Each is used
  in the direction its datasheet specifies ("bi-directional: no"), its isolated port in 51 Ω: FWD
  from the first, REFL from the second.
- **Weak capacitive ports beat buffers in a crowded tile** (§20). Two coupled LC tanks read through
  2.2 pF into the host's 50 Ω inputs (about -43 dB at 10 MHz) need no op amp, no bias and no power,
  and load the tanks less than a buffer's input would: the cavity's coupling antennas, on a board.
- **A step attenuator can have switches and SPI at once** (§24).
  - The PE43711's direct parallel mode (P/S low, LE high) is pSemi's "ideal for manual control": an
    8-way DIP (way 1 drives P/S for SPI, ways 2-8 the bits), 100 k pull-downs on every bit and P/S,
    LE pulled up by 100 k so a floating FPGA pin leaves the switches in charge.
  - In serial mode the parallel pins must be low (every bit off).
  - The chip still needs its 3.3 V: switches do not make an active switch array passive.
- **A termination is a load a signal generator can burn** (§29).
  - A 49.9 Ω 0402 is rated 62.5 mW. A generator set to 10 V p-p into 50 Ω (20 V p-p open) puts
    0.25 W in it.
  - A back-termination behind an OPA810 into a shorted jack takes I_sc² R, about 0.28 W.
  - The rule: rate every termination and back-termination at 0.2 W or more. That needs no layout
    change: Vishay's CRCW0402...HP is 200 mW in 0402, and Yageo's SR0603 is 250 mW in 0603.
  - This is the op-amp reviewers' "size the resistors a misplaced scope clip loads", applied to
    every jack.

## Calibration standards and floating jacks

See `launches.md` ("Related launch-void cases"): the SHORT gets no launch void, the OPEN keeps it,
the LOAD may sit at the end of a matched line; a floating jack gets its own net and a void on every
layer.

## Gates on internally matched boards

See `as-laid-simulation.md` (last section): CostasLink's RF gates on RF-MOD and IQ-MOD, and writing
each gate's result per band.
