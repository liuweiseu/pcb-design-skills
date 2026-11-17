---
name: highspeed-digital
description: Fast digital and signal-integrity rules - edge rates and bandwidth, transmission lines and termination, controlled impedance targets, return paths, differential pairs, length/delay matching, DDR3/DDR4, crosstalk, via stubs, fibre weave, power integrity (PDN target impedance), clocks and jitter, simultaneous switching, EMC and stitching. Use when a board has FPGAs, fast MCU I/O, USB, Ethernet, LVDS, HDMI, MIPI, SATA, PCIe, DDR memory, high-speed ADC buses, clocks or oscillators, or when the user mentions signal integrity, impedance, skew, crosstalk, jitter, decoupling/PDN, EMC or latency of a digital path.
---

# Fast digital

From CLAUDE_PCB.md §13. For the fast boards to come: most of it is from the sources below, not yet
tested on one of the user's boards; a rule a board has taught carries that board's citation. Sources: Howard Johnson, *High-Speed Digital Design*; Eric Bogatin, *Signal and
Power Integrity — Simplified*; Henry Ott, *Electromagnetic Compatibility Engineering*; the FPGA
vendors' PCB guides (AMD/Xilinx UG583, Lattice's ECP5 notes).

Related skills: `rf-design` for anything above about 500 MHz where a millimetre is a phase (CPWG
lines, launches, simulating the as-laid circuit, latency-link theory, SERDES latency, a link's rise
time); `pcb-layout` for general placement and routing; `jlcpcb-order` for ordering impedance control;
`kicad-scripting` for the field-solver and simulation tooling.

## Latency and edges

- **Before choosing a faster host, add up every term of the latency chain for each host, the FPGA's
  sampling included** (CostasLink, Prompt 20, `sim/hosts.py`).
  - The Icepi Zero's missing 200 Ω header resistors save 2 ns over the PYNQ-Z2 only if its inputs
    sample at 656 Ms/s (GDDRX2); at the 200 Ms/s its first gateware used, the 5 ns grid gave all of
    it back and tripled the jitter.
  - A carry-chain TDC (CARRY4, CCU2) beats any sampling grid, on any host, without new hardware.
  - Where a threshold is set by the noise (CFAR), widening the detection filter speeds the rise but
    moves the threshold out: the two nearly cancel, so check before widening.
  - The rest of the link budget (transmitter RC plus receiver rise, SERDES word latency, the whole
    chain) is in `rf-design` (`references/latency-links.md`).
- **Edges, not clocks, set the bandwidth:** BW ≈ 0.35 / t_rise. A 10 MHz clock with 1 ns edges has
  content past 350 MHz. **Give every FPGA and MCU output the slowest slew rate and lowest drive
  strength that meet timing.**

## Lines and impedance

- **A trace is a transmission line** once its one-way delay exceeds about a sixth of the rise time.
  FR4 delays are about 6 ps/mm for outer-layer microstrip and 7 ps/mm for stripline, so with 1 ns
  edges anything over about 25 mm is a line.
- **A line gets a defined impedance and a termination:**
  - a series resistor at a point-to-point source (22-33 Ω, so that it plus the driver's own
    impedance equals Z0);
  - parallel or Thevenin at the end of a multidrop bus;
  - or on-die termination where the chip has it.
- **Impedance comes from the fab, not from a formula.** Use the stack-up's thicknesses and Dk and the
  fab's own calculator (JLCPCB's), and order impedance control. Targets:
  - 50 Ω single-ended;
  - differential 90 Ω for USB;
  - 100 Ω for Ethernet, LVDS, HDMI, MIPI and SATA;
  - 85 Ω for PCIe (100 Ω tolerated).

## Return paths

- **The return current runs in the plane directly under the trace.** So:
  - never route a fast line across a split, slot or void in its reference plane, and keep it a few
    widths in from the plane's edge;
  - every layer change of a fast signal gets a ground via within about 1 mm (two for a differential
    pair, one each side);
  - where the reference changes between a ground and a power plane, put a stitching capacitor beside
    the via.

## Pairs, groups and buses

- **Differential pairs:** routed together at constant spacing, on one layer where possible.
  - Match the two lines within a few picoseconds (about 0.1-0.15 mm) at multi-Gb/s, compensating
    near where the mismatch arises (at the bend), not at the far end.
  - Serpentine gaps at least 3-4 trace widths, so the meander does not couple to itself.
- **Groups:** match delays (per layer, not just lengths) to the interface's timing budget: DDR data
  and mask to their strobe within the byte lane, address and command to the clock, a parallel ADC
  bus to its clock.
- **DDR3/DDR4:**
  - fly-by topology for address, command, control and clock, with VTT termination at the far end;
  - data point to point;
  - byte lanes over a solid reference;
  - swap bits within a lane, and lanes within the bus, only where the controller allows it;
  - the controller's guide is the rulebook.
- **Crosstalk:** long parallel runs at least 3 widths apart, centre to centre; keep aggressor-victim
  parallel lengths short; stripline for long buses (its far-end crosstalk is nearly zero).
- **Simultaneous switching:** spread a wide bus over banks with enough ground pins, and terminate it.
- **Check which pins take a DDR (or other I/O) register before assigning a fast bus.** On
  ECP5-2ADC-2DAC nobody had, and the one bank whose pins do not was found by the first gateware,
  after the order (bring-up planning, 2026-11-15). Read the FPGA family's pin and bank tables for
  every interface that needs IDDR/ODDR, and build a test bitstream with them before the order.

## Multi-Gb/s details

- **Vias at multi-Gb/s:** an unused via stub is a quarter-wave resonator at c / (4·L·√εr): about
  26 GHz for a 1.4 mm stub in FR4, harmless below 10 Gb/s on a 1.6 mm board, harmful on thick ones
  (12 GHz for 3 mm).
  - Use layer pairs that use the whole barrel, back-drill, or use blind vias.
  - Size anti-pads for impedance and remove unused inner pads.
- **Wide pads** (AC-coupling capacitors, connector pads) drop the impedance: void the reference plane
  under them.
- **Fibre weave:** at 5-10 Gb/s and up, one line of a pair over glass and the other over resin skews
  the pair. Route at about 10° to the weave, or ask for spread glass (1067/1078/2116 rather than 7628
  or 106).

## Power integrity

- **Keep the supply's impedance below Z_target = ΔV allowed / ΔI step from DC up to the edge rate:**
  - the regulator at low frequency;
  - bulk and MLCCs in the middle;
  - the capacitance of an adjacent power/ground plane pair (thin dielectric) and the package above
    that.
- **An MLCC is limited by its mounted inductance:** vias at the pad ends or in the pad, short and
  wide, two per end for large parts, the smallest packages nearest the pins.
- **Mixed values anti-resonate:** check the combined impedance (the FPGA vendor's PDN tool) rather
  than adding values by habit.

## Clocks

- **Clocks:** inner layers between planes, away from board edges and connectors, series-terminated at
  the source, one load per output (or a fan-out buffer), nothing routed under a crystal or
  oscillator, a ground guard round the crystal.
- **Clock jitter caps an ADC's SNR** at −20·log10(2π·f_in·t_jitter).
- **Count an ECP5 design's global clocks; a design can build clean, meet timing, load, and still
  be dead** (ECP5-2ADC-2DAC board A, 2026-11-16, REVB 16). Read the count in every build's
  report and keep it low: a clock that only feeds a counter gets `(* noglobal *)`. What happened,
  the fix and how it was found: see the pcb-bringup skill, references/firmware-gateware-fpga.md,
  "An ECP5 design can build clean, meet timing, load, and still be dead".
- **Put every converter's sample clock on an FPGA output that a PLL can drive** (ECP5-2ADC-2DAC
  board A, 2026-11-16): stepping the PLL's phase then lets the board measure its own analog chain
  with no scope. How, and what it found: see the pcb-bringup skill, references/bench-planning.md,
  "The board measures its own analog chain".
- Crystal load capacitors and radio ppm budgets: see `rf-design` ("Crystals").

## EMC

- **Every cable is an antenna.**
  - Keep fast lines away from connectors and board edges, and filter whatever leaves the board at its
    connector.
  - Stitch the edges of ground pours with vias at λ/20 of the highest frequency of concern (in FR4,
    about 3 mm at 2.4 GHz).
  - Plane-pair cavities resonate from c / (2·√εr·length) up: about 720 MHz on a 100 mm board.
    Stitching and decoupling along the edges damp them.
  - The "20H rule" (pulling a power plane back from the edge) shows little measured benefit on
    ordinary stack-ups; do not count on it.

## Simulate the risky nets

- IBIS models of the drivers, a 2D solver for the cross-section, and openEMS (installed on the
  user's machine as `~/.local/bin/em-env`) for vias, launches and transitions, as in SyzygyRadioDrivers'
  `SMABridgeTestAnalysis/FIELD_SOLVER.md`.
