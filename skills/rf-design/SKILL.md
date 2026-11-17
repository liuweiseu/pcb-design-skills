---
name: rf-design
description: RF and microwave board design rules - vendor reference layouts, 50 ohm CPWG lines and via fences, matching/tuning networks, SMA and U.FL launches, antennas, crystals, bias chokes and RF supplies, isolation budgets, simulating the as-laid circuit, latency-link theory and FCC rules. Use when a board carries a radio, an SMA/U.FL jack, an LNA, PA, mixer, synthesizer, coupler or antenna, any signal above about 500 MHz, or when the user mentions RF, S11, VNA, impedance, CPWG, launch, Costas, latency link or field solver.
---

# RF design

From CLAUDE_PCB.md §14 and the RF lessons of §18-29: the radio vendors' reference designs,
Rosenberg, the SyzygyRadioDrivers field-solver study, CostasLink (rev A on the bench, 2026-10-29)
and the RF-MOD / IQ-MOD tile boards. Fast digital edges, clocks, PDN and EMC are in
`highspeed-digital`; accurate analog signals (ADC/DAC paths, references, tuning voltages) in
`analog-signals`; release gates 22-32 in `pcb-workflow`; bench work in `pcb-bringup`; component
derating in `component-selection`.

References (read when the task reaches them):
- `references/launches.md`: the 7-step standard for every through-hole RF launch, the gerber gate,
  re-running the launch field solve, calibration-standard and floating-jack voids. Read before
  placing any SMA or changing a stack or connector.
- `references/as-laid-simulation.md`: the full procedure for simulating the circuit the copper
  makes, CostasLink rev A's faults in detail, why they generalise (§27), and the gates on internally
  matched boards (§29). Read before ordering or reviewing any board with a path above ~500 MHz.
- `references/latency-links.md`: decision SNR, false-alarm thresholds, decision boundaries, the
  t ≥ z²·N0/P bound, filter delay, RSSI, SERDES, link rise time, free-space optics. Read when a link's
  figure of merit is latency or false-alarm rate.
- `references/rf-tile-lessons.md`: generator RF rules, lines leaving a tile, couplers, splitters,
  synthesizer loop filters, step attenuators, termination power, JLCPCB's stack-up page. Read when
  generating many RF cells or ordering a controlled-impedance board from JLCPCB.

## Layout: copy, then make it measurable

- **Ground, not a supply plane, under every RF chain** (the user, 2026-11-04: first in the RF rules
  and first in the `analog-signals` skill, which has the same rule for accurate analog). Every copper
  layer that an RF line, pad or part can see is ground:
  - the layer under the line, on whichever side of the board it runs. A line on B.Cu of a 4-layer
    board sees In2, which the standard stack-up (`pcb-layout`) makes the supply layer: fill it with
    ground there;
  - whatever lies under a void in that ground: the relief window under a wide pad, a launch's
    antipad, a slot;
  - the layer under each match, bypass, choke and load.

  The supply islands go beside the chains, never under them. Each RF part's supply comes in as a
  short filtered feed: the choke with its bypass on its cold pad, then a ferrite (the bias-choke and
  supply-island bullets under "Supplies, bias and isolation").
  - **Why:** a line's return current runs in the plane nearest it (`highspeed-digital`, return
    paths). Over a supply, the return reaches ground only through that supply's decoupling
    capacitors. The island is also a cavity that every pad, window and choke opening onto it shares:
    what one chain puts in, every other reads out. Over ground, the return runs straight back under
    the line, and the fields end on the reference that every part of the chain measures against.
  - **Rev A broke it** (CostasLink; `sim/aslaid/REPORT.md` findings 5, 6 and 8):
    - one +5V_RF island, 86 x 44 mm on In2, under both chains, opened onto by the In1 relief windows
      under the ADL5611s' pads;
    - RFOUTB's pull-ups on B.Cu over the PLL supply islands;
    - the coupler taps and J204's route referenced to a supply.

    Its transmitter leaks into its own receiver at -53 dBm at RX MON (REVB 10), and the path is still
    not found. The as-laid model puts the plane's own share 20-40 dB under the leak, only because
    that island happens to sit 0.21 mm over the bottom ground (the "one supply island" bullet below).
    Do not count on the stack to rescue the next board: rev B puts ground on In2 under the RF chains
    (REVB 10, 54).
  - **Check it:** gates 29 and 32 (`pcb-workflow`, verification gates) check the plane under every
    RF segment and every void in it.
- **Copy the radio vendor's reference layout exactly**, as GPiBridge copied the RP2350's regulator:
  the same kind of stack-up, the same 50 Ω line, the matching network beside the chip, the ground
  vias under and round it.
- **Lines:** grounded coplanar waveguide (CPWG) on L1 over a solid L2; a fence of ground vias on
  both sides at no more than λ/10 in the dielectric (1-1.5 mm in practice below 6 GHz); the gap
  constant; no right-angle corners at multi-GHz (mitre or curve them). Match pad widths to the line,
  or void the plane under wide pads (U.FL, SMA, 0603).
- **Take a CPWG's width from a field solver, not a closed form.** CostasLink rev A's lines are
  53.7 Ω by a 2D finite-difference solve where the closed form gave 49.8; its couplers' quarter wave
  came out at 5.97 GHz, not 5.8, because the even and odd modes' εeff (3.20 / 2.73) were never
  computed. Impedance comes from the fab's stack (see `highspeed-digital`).
- **At microwave frequencies "next to the pin" is a distance with a phase:** 1 mm is
  360°·√εeff·f/c (12° at 5.8 GHz on FR4 CPWG / JLC04161H-7628, 2° at 1 GHz). Write down how far each
  part is, in degrees. The vendor's lumped values are only true where its layout puts them.
- **A part in a matching network sits on the pin's own pad, or on the line at the pin, never on a
  branch:** the track from part to pin under λ/50 at the top frequency (0.5 mm at 5.8 GHz). Rev A's
  0.5 pF LNA input shunt 4.0 mm away on a 1.8 mm branch series-resonated near 5.9 GHz and cost
  20-30 dB.
- **A shunt part's ground return is part of its value:** every RF shunt part (match, ESD choke,
  load, bypass) gets a via in, or touching, its ground pad, to the plane right under it. Count the
  return's inductance in the simulation.
- **An RF IC's supply pin sees an inductance the vendor chose** (SKY65404: 0.6 nH from VCC to its
  100 nF; rev A had ~2 nH). Put the inductor on the pin, the capacitor on the inductor's far pad, a
  via in its ground pad; count the tracks' inductance.
- **Anchor RF matching, decoupling and bias parts by hand to the pad they serve, and measure the
  distance in the build.** A rule placer hangs a rail's capacitor on "the chip the schematic drew it
  beside", at the pin's fan band (3-8 mm), or tens of mm away (rev A: 68 pF 36 mm from its chokes).
  A review finding about where an RF part sits is a layout change before the order, not a bench item.
- **Count the pads' capacitance on a thin dielectric:** an 0402 pad 0.21 mm over its plane is about
  0.08 pF. Void the plane under RF passives' pads, or use 0201 parts and fewer series parts.
- **RF grounds join the pour solidly: no thermal reliefs on the top or the inner layers**
  (CostasLink, Prompt 32, from a SyzygyRadioBoard design checklist). A relief's four 0.25 mm spokes
  are inductors at 5.8 GHz; a balun's ground pad, an ESD shunt, a 49.9 Ω load or an SMA's leg
  through them is not grounded at RF. Set the zone's pad connection to solid
  (gen/routing.zone connect="solid"); give the one hand-soldered part its own thermal setting on its
  pads (zone_connect 1) and leave the back fill thermal. Reflow does not need reliefs.
- **Ground:** many vias in an RF chip's exposed pad and along every RF line; no floating copper
  (Rosenberg: islands resonate); no slots; shield-can footprints round RF sections where the budget
  allows (the assembler places a frame; the lid goes on later).
- **Stitch the pours:** near RF every point within λ/20 of a ground via (a via grid at λ/10: 2.5 mm
  at 5.8 GHz in FR4); everywhere else within λ/6, so no via-free patch reaches the resonant half
  wave. Fences along the lines alone are not enough (rev A: 43 % of the top pour round the receive
  chain was more than 2.5 mm from a via, up to 8.6 mm; elsewhere 20.7 mm). Write each gate's result
  per band, not only at the board's top frequency.
- **An ESD / DC shunt on a microwave line must stay inductive across the band.** Use a wirewound
  part whose self-resonance is above the band (CostasLink: LQW15AN6N8, 6.8 nH, ≥ 6.0 GHz,
  400 Ω-1.5 kΩ across 4.9-6 GHz, ~0.05 dB). A multilayer 0402 of the same value (LQG15HS:
  3.4-4.5 GHz) is capacitive there.
  - Put it on the jack's side of the DC block, so it drains the cable's static.
  - Anchor it by hand on the line: a rule placer stood it 4 mm off, a stub that would detune the
    line once fitted. Keep any stub under ~0.05 of a wavelength.
- **A late block can break the board somewhere else.** Adding CostasLink's detectors moved the
  router's power tracks beside a regulator 60 mm away and cut its ground pin's pour off. Re-run the
  whole DRC after any addition, and try a few route seeds side by side rather than nudging parts.

## Launches (SMA, U.FL)

- **The stock SMA footprint is wrong for a launch above a GHz.** Its full pad ring on every layer,
  planes up to the barrel and top pour at the CPWG gap make 2 pF across a 50 Ω line at 5.8 GHz, and
  DRC says nothing (SyzygyRadioDrivers: 70 % reflected; CostasLink build 36: 85 %, 8 dB per jack).
  Every through-hole RF launch follows the 7-step standard in `references/launches.md`: signal pad on
  end layers only, antipads as rule areas in the generator (never a DRC `hole_clearance` rule or the
  pad's clearance property), the top pour at the solved distance, a plain round pad, nothing inside
  the legs, the field solve re-run, the gerber parser as a release gate.
- **Check the launches in the plotted gerbers, not in the board's settings.**
- **A new stack or a new connector means the launch study is run again, not copied**, anchored first
  on a cached point.

## Tuning, parts, antennas

- **Always leave a tuning network and a test port:** a pi (shunt-series-shunt) footprint set between
  radio and antenna, fitted 0 Ω and DNP at first, and a U.FL or a switch connector (Murata MM8030) to
  measure S11 and conducted power. Tune it on the bench with a NanoVNA.
- **Leave rework room on rev A:** a DNP 0402 shunt pad on each RF IC pin's own pad, and a capacitor
  pad on each choke's cold end, so the bench can try what the simulation suggests.
- **Parts:** C0G capacitors, high-Q wire-wound or thin-film inductors (Murata LQW/LQP),
  self-resonances well above the band, and the makers' S-parameter models in the simulation
  (Rosenberg).
- **Read the gain block's P1dB at the operating frequency, for the largest constellation point.** The
  ADL5611's P1dB is 21 dBm at 900 MHz and 12.8 dBm at 5.8 GHz: where CostasLink's corner points land
  when the axis point is 9.8 dBm.
- **Find where a vendor's S-parameters are referenced:** a gain block's table is often measured at
  its evaluation board's SMAs, launches and lines included, not at the pins.
- **Antennas:**
  - A chip or PCB antenna sits at a board edge or corner, every layer cleared to the vendor's
    keep-out, on the ground plane size the vendor assumed: the ground is half the antenna.
  - No metal near it: batteries, screws, shields, cables.
  - A plastic case or a hand pulls the resonance down a few percent (εr 2-3). Design a little high and
    tune down.
  - A custom antenna is simulated with the real stack-up, the board's ground plane and the enclosure
    (openEMS; NEC2 for wire antennas), then measured. FR4's Dk (4.2-4.7) and loss tangent (about
    0.02) vary from lot to lot.
- **Crystals:** the radio's ppm budget sets the crystal (Espressif asks for 40 MHz ±10 ppm). Load
  capacitors from C_L = C1·C2/(C1+C2) + C_stray, with 2-5 pF of stray. Close to the chip, guarded,
  nothing routed under it.
- **Harmonics:** keep the vendor's low-pass at the PA output, and look at the harmonics with a
  spectrum analyser.

## Supplies, bias and isolation

- **Isolation:** the PA away from the LNA and the crystal; RF supplies through LC or
  ferrite-plus-capacitor filters (read the bead's impedance at its DC current, and damp the
  bead-capacitor resonance); regulators with PSRR at the frequencies that matter.
- **Supply networks are RF circuits too.** Above a few hundred MHz a choke is a capacitor above its
  SRF, a capacitor is an inductor above its own, a via through a core is a nanohenry, a plane island
  is a resonant cavity. Simulate bias and decoupling paths with the signal paths.
- **A bias choke's cold end gets its RF bypass on its own pad, before any via to a plane:** via in
  pad, a capacitor series-resonant near the band (a few pF in 0402) and a 68-100 pF, then a ferrite
  or a resistor to the rail. (Rev A's LQW18AN43NG00D chokes, SRF ≥ 2.7 GHz, are ~340 Ω capacitors at
  5.8 GHz and went straight to the plane.)
- **One supply island per RF chain, beside it, never under it:** separate transmit and receive
  islands, each through its own ferrite and capacitors. The layer under the lines and under a relief
  window is ground, not a supply (the first rule under "Layout"). Model the plane before blaming it: the cavity that matters is the one each island
  forms with its nearest ground, which may not be the plane named in the stack-up.
- **The isolation budget is a design number.** Before the order, estimate each transmitter-to-
  receiver path (rails, plane cavities, layout coupling) and write the leak beside the weakest signal
  the receiver must resolve and its attenuator's range. On the bench, measure it first (§9).

## Verify: the circuit the copper makes

- **Controlled impedance is necessary, not sufficient.** A 50 Ω line delivers what its ends present.
  DRC, ERC, net and detour checks, field-solved launches, a gerber parser and five reviews all passed
  CostasLink rev A, which lost ~30 dB at 5.8 GHz. Only a simulation of the as-laid circuit sees a
  stub, a ground return or a shared rail.
- **Simulate every path above about 500 MHz** (or wherever λ/50 in the dielectric is under 2 mm)
  before the order, and again in the design review from the written board
  (`references/as-laid-simulation.md`):
  1. cut the paths at their ports (jacks and IC pins);
  2. extract from the written `.kicad_pcb`, not the schematic;
  3. model lines, parts (Touchstone), ESL, SRF and ground returns;
  4. simulate the vendor's reference beside it, anchored first;
  5. sweep ESL 0.2-0.5 nH, ground returns ×0.5-×2, εr 4.2-4.7; if the result flips, change the
     layout, not the model;
  6. pass: within 1 dB of the reference, no 3 dB dip or peak it lacks, port return losses as the
     vendor assumed, across the band and 20 % either side; table and plot per path in the notes;
  7. the same for supply pins, bias tees, beads, plane islands and coupling between chains.
- **A rough model early beats an exact one late:** 80 lines of ABCD matrices gave rev A's trend and
  most of its size. **Fit at most one parameter, and say which.**
- **Trace every path by hand before an order** (CostasLink, Prompt 32; `docs/PATHS.md` is the
  pattern): hop by hop from each jack or pin through every series and shunt part to the next IC pin,
  with the DC on the node, the level, the coupling, and a second table of every port's impedance,
  operating range and absolute maximum against what the circuit presents. A netlist walker
  (`tools/path_walk.py`) supplies the hops so nothing is from memory. This found the ADC filters
  drawn capacitor-first and the balun with no blocks (Prompt 31), which five reviewers reading the
  sheets had missed.
- **Inverting one arm of a quadrature receiver is a mirror, not a rotation: re-derive every loop
  sign after it.** Write the loop's sign end to end in the design notes; a wrong sign with a sign()
  detector holds at ±90° with the comparator chattering, which looks like a lock (details in
  `references/as-laid-simulation.md`).
- **At bring-up, separate the paths before interpreting a shape:** a knob in the path (an
  attenuator, a switch) sorts them; measure the leak floor with the ports terminated first.

## Latency and detection links (summary; see `references/latency-links.md`)

- A zero-IF arm's decision SNR is P / (kTF B); a sign comparator errs with Q(√snr), not the
  textbook Q(√(2 Eb/N0)) (3 dB optimistic otherwise).
- An idling link counts false events per hour: Rice's rate ν0·exp(−u²/2); u = 7.3 for one per hour
  at 100 MHz. Set the idle-side threshold from the idle (CFAR).
- Put the decision boundary through the idle point, not the origin.
- No receiver decides sooner than t ≥ z²·N0 / P (z ≈ 7.5 σ): at range, transmitter power is a
  latency knob before bandwidth.
- Selectivity costs about order/(2π·f_c) of delay at each end.
- A coherent receiver's averaged "RSSI" works only when locked; give it a real detector.
- A link's rise time is the transmitter's and the receiver's together; budget the whole chain
  (detectors, cables at 3.9 ns/m, optics) before buying radio nanoseconds; a SERDES buys throughput,
  not latency.

## Regulatory (US)

- A certified module keeps its FCC ID only with its own or its listed antennas.
- A bare-chip radio with a custom antenna is uncertified: FCC §15.23 lets a hobbyist build up to
  five, not from a kit and not for sale, for personal use.
- A board that radiates says this in its README.
