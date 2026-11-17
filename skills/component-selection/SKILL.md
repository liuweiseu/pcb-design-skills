---
name: component-selection
description: Choosing real components and sizing for power, current, heat and magnetics - capacitor dielectrics (C0G vs X7R/X5R DC bias, electrolytic, polymer, tantalum, film), resistor and termination power ratings, inductors, LDO and MOSFET dissipation, trace width for current (IPC-2221), copper weight, vias, connectors, fuses/PTCs/TVS/reverse-polarity protection, inductive loads, motors, PCB coils, and rail current budgets. Use when picking a part or package, sizing a power path, heatsink or fuse, protecting an input, or designing coils or motor drivers.
---

# Choosing real components; power, current and magnetics (CLAUDE_PCB.md §12, §15)

A schematic assumes ideal parts, and every real part does the circuit some damage. Choose
the part that does the least, at a sensible price (Rosenberg). Related skills:
`jlcpcb-order` (sourcing, stock, LCSC codes, rotations), `pcb-layout` (switch node, §5),
`highspeed-digital` (mounted inductance, §13), `pcb-workflow` (the current-width gates,
§10 gates 11 and 16), `pcb-bringup` (current monitors, probe access),
`boards-for-children` (toy safety).

Reference files:
- `references/power-current-thermal.md`: IPC-2221 widths, copper resistance, vias, 2 oz
  copper, heatsink checks, hot-plug ringing, input protection, the bench input's drop,
  switching regulators' constant power, switching converters,
  current sensing, gate drive, rail budgets. Read when sizing any power path or heatsink.
- `references/pcb-coils-magnetics.md`: planar spiral inductance (Mohan), skin depth, Q and
  link efficiency, coil heating, coils as sensors, plane voids, L/R and PWM ripple, loop
  simulation with sensor noise. Read when designing a PCB coil, a wireless link or a
  magnetic actuator.
- `references/protection-case-studies.md`: the PID motor board and op-amp board lessons
  (linear driver into a stall, PTC hold/trip, fuse position, split-rail clamps, series
  diode coupling, class-B current limiter). Read before deciding a fuse, PTC, clamp or
  current limit.
- `references/parts-notes.md`: part-specific facts (LM358 swing, OPA1612 slew rate,
  FT2232H supply pins, motor resistance, fader tapers, slide-switch travel, ECW-F film cap, JLCPCB basic 0402 codes, package hunting,
  DIP switch ratings, bus sharing). Read when choosing a specific part or package.

## Capacitors

- **Class 1 (C0G/NP0):** low loss, stable with voltage and temperature, 5 % (1 % for more
  money), up to about 220 nF/25 V in 1210. Use for filters, RF matching, oscillators and
  crystal loads, PLL loop filters, timing, low-distortion coupling.
- **Class 2/3 (X7R, X5R, Y5V...)** are cheap and large, but their value moves:
  - **with DC bias:** an X5R can lose about 84 % of its capacitance at its rated voltage.
    Read the maker's bias curve for the actual part (Murata SimSurfing, TDK, Samsung) and
    design with the capacitance at the working voltage. Use a larger value or a higher
    rating: Rosenberg uses 100 nF/100 V X7R up to 35 V. The same value in a smaller case
    loses more.
  - **with temperature:** -70 % from 25 to 75 C in the worst part Rosenberg has seen.
  - So **never in an RC timer, a filter that sets a frequency, or an audio coupling
    capacitor**: the time constant comes out short and the signal distorted.
  - **An integrator's capacitor is a filter part: film or C0G, never X5R** (PID board: a
    10 uF X5R moves I's time constant with its own output; see `references/parts-notes.md`).
  - **They are piezoelectric:** they pick up vibration beside a sensitive sensor, and audio
    frequency current makes them sing (LED PWM, coil drives, burst-mode regulators between
    1 and 20 kHz). Use C0G or film there, or switch above 20 kHz.
- **Self-resonance:** every capacitor is a series RLC and an inductor above its SRF. Pick
  values and packages whose SRF lies above the band they serve. Mounted, the pads and vias
  usually add more inductance than the part (`highspeed-digital`).
- **Aluminium electrolytics:** most capacitance per dollar; polarized (reversed, they vent
  "dirty brown muck and smoke"); leaky; +-20 %; they wear out. Life is rated in hours at
  105 C at rated ripple current and roughly doubles per 10 C cooler. Check ripple current at
  the frequency it flows at.
- **Polymer** (aluminium or tantalum polymer): "dry" electrolytics, low ESR, little loss
  under bias, long life (check the datasheet). An economical replacement for a bank of
  large MLCCs.
- **Tantalum (MnO2)** is mostly replaced by polymer. If used, derate voltage by half: they
  fail short, and can burn.
- **Film:** stable, accurate, low loss, high voltage; polypropylene has the lowest loss.
  Mostly through-hole; SMD parts are PPS. **Silver mica** is best and dearest, for crazy
  specifications only.

## Resistors, inductors, regulators, semiconductors

- **Resistors:** check dissipation at the worst case and the voltage rating (typically
  50-75 V for 0603, 150 V for 0805). Thick film is fine for most things; thin or metal film
  for low 1/f excess noise and low distortion in precision analog, with low tempco and power
  to spare where self-heating would distort. Pulse-rated (anti-surge) parts take inrush and
  surges. A hot resistor needs copper to spread its heat, and big copper adds capacitance.
- **A termination is a load a signal generator can burn** (§29): a 49.9 ohm 0402 is
  62.5 mW; a generator at 10 V p-p into 50 ohm (20 V p-p open) puts 0.25 W in it; a
  back-termination behind an OPA810 into a shorted jack takes I_sc^2 R, about 0.28 W. Rate
  every termination and back-termination at 0.2 W or more, with no layout change:
  Vishay CRCW0402...HP is 200 mW in 0402, Yageo SR0603 250 mW in 0603. Size the resistors a
  misplaced scope clip loads, at every jack.
- **Inductors:** for a DC-DC converter, the type its datasheet asks for, saturation current
  above the peak current (not the average), shielded where neighbours are sensitive. For RF
  matching and filters, simulate with the maker's model including Q, and keep the SRF well
  above the frequency of use, or the inductor is a capacitor.
- **Switching regulators draw about constant power, so their input current falls as the
  input rises** (ECP5-2ADC-2DAC board A, 2026-11-16: 0.388 A at 4.0 V, 0.369 A at 5.0 V).
  Budget the input current at the lowest input voltage, and judge a power-up staircase by
  V x I, not by the current.
- **Linear regulators:** dissipation is (Vin max - Vout) x I max, at the highest ambient
  inside the enclosure. ECP5's ADC LDO was 0.36-0.45 W in a SOT-23-5 (187 C/W): 110-129 C
  in a 45 C box. A resistor ahead of it shares the drop and filters the input (2.2 ohm 1206:
  0.1 W), as long as headroom at the lowest input stays above dropout.
- **Semiconductors:** compute dissipation and junction temperature at the highest ambient.
  A MOSFET's R_DS(on) at 100 C is about 1.5x its 25 C value; add switching loss. Theta-JA
  comes from the copper the part sits on, not the datasheet's test board.
- **Model an LM358-class output 2 V from each rail** (TI: V+ - 2 V typical, V+ - 3 V
  guaranteed; sinks mA only ~2 V above V-).
- **Choose every amplifier in a converter's path by slew rate as well as noise:**
  full-power bandwidth is SR / (2 pi V_peak), and it must cover the band the converter is
  sold for. ECP5-2ADC-2DAC's OPA1612 (27 V/us, 4 MHz full-power bandwidth at 1 V pk-pk) in
  front of a 65 MS/s ADC compressed above 150 mV and its harmonics climbed to -26 dBc at
  11 MHz (board A, 2026-11-16; `references/parts-notes.md`; the rule in full is in the
  analog-signals skill).
- **Read every supply pin's range, and what an internal regulator may feed, before
  trusting a reference design or a note:** the FT2232H's VPHY and VPLL need 3.0-3.6 V; its
  1.8 V VREGOUT feeds only the core (ECP5-2ADC-2DAC rev A's USB port was dead on arrival,
  2026-11-16; `references/parts-notes.md`; the netlist check is in pcb-schematic).
- **A push-pull output cannot share a bus:** read "high impedance when deselected" in the
  datasheet before sharing any SPI output (MT6701's DO needed a 74LVC1G125, §26).
- **A DIP switch is for milliamps** (contacts rated tens of mA): switch a reference resistor
  or coupling capacitor, never a current shunt.

## Choosing and finding the part

- **Choose the small package first, and look for it under every name** (automotive
  "-Q100", other vendors; search JLCPCB by category, not just part number). Read the small
  package's pinout from its datasheet. Details in `references/parts-notes.md`.
- **Ask for the exact part number of anything the board plugs into**, and decode its order
  code (the fader's "B2" taper).
- **Read a chart's curves from the PDF's vector paths**, not by eye.
- **Before spending board area on a function, look for the output the chip already has**
  (a complementary output terminated in 51 ohm is a second LO); a part the user can buy as
  a cable accessory does not earn board area.
- **A hand-soldered part must fit before it is offered** (a polyvaricon with dial is ~20 mm
  square; offer a screw terminal for an external part instead).

## Power and current (summary; numbers in `references/power-current-thermal.md`)

- **Width for current (IPC-2221):** I = k * dT^0.44 * A^0.725 (A in mil^2, k = 0.048
  outer, 0.024 inner). 10 C rise, 1 oz outer: 1 A 0.30 mm, 2 A 0.78, 3 A 1.37, 5 A 2.77;
  2 oz halves those; inner ~2.6x the area; JLCPCB inner is 0.5 oz unless ordered. Compute
  per net in the build and fail on a narrower track.
- **Count squares** of every high-current path, ground return included: 0.98 / 0.49 /
  0.25 mohm per square at 0.5 / 1 / 2 oz, +0.39 %/C.
- **Vias carry about 1 A each** (0.3 mm drill, 10 C rise): arrays at every power layer
  change (at least four for 3 A), thermal vias under hot parts.
- **Connectors:** the exact part's rating (barrel jacks 1-5 A and more; 2.54 mm headers
  ~3 A a pin; screw terminals by datasheet).
- **2 oz copper** when a coil or power path needs the conductance; it raises the fab's
  minimum track/gap for the whole board (JLCPCB 8 mil). Say so on the order and in release
  notes.
- **Check the heatsink on the board as built, in the build** (two-sheet copper model,
  fail above the junction limit).
- **Hot-plugging a supply on a cable rings** to ~2x (AN88): damp with bulk
  electrolytic/polymer, clamp with a TVS.
- **Protect the input:** reverse polarity (P-MOSFET or ideal diode, not a series
  Schottky), overcurrent (fuse/PTC/eFuse below what copper and connector survive), a TVS.
- **Budget the bench input from the supply's terminals to the rail, at full load**
  (ECP5-2ADC-2DAC board A, 2026-11-16: 5.00 V at the supply was 4.22 V on +5V at 0.385 A,
  through a BNC cable, a 0.1" header, an SS34 and a PTC, with the FPGA unconfigured). A
  bench input gets a connector that takes real leads, an ideal-diode FET where the drop
  matters, and a rail window the board's own drop fits inside.
- **Inductive loads** need a freewheel path; expect regeneration ("supply pumping").
- **Switching converters:** the datasheet's layout is the layout; small hot loop.
- **Current sensing:** Kelvin connection, sense pair, RC filter; mind low- vs high-side.
- **Gate drive:** small gate loop, gate resistor, bootstrap cap at the driver, dead time.
- **Budget a rail in the board's worst state, not its working one** (GPSDO rev B), and
  check that the bring-up instruction actually produces the state you budgeted.
- **A passive board can take a little power from a host connector** (Pmod 3.3 V; give it a
  PWR_FLAG).
- **Mains stays off the board:** a certified (UL/ETL-listed) external adapter; mains needs
  IEC 62368-1 creepage and clearance, which no board here has had.

## Protection (summary; stories in `references/protection-case-studies.md`)

- **A linear driver into a stalled motor dissipates most at half the rail, below any
  fuse:** size the heatsink for Vcc^2/4R before trusting a fuse; sweep the stall over DRIVE
  in simulation.
- **A PTC opens only above its trip current, and its own resistance is in the circuit.**
  Between hold and trip nothing is promised. Simulate the fault with the fuse's resistance
  range; read the time-current curve; take the higher voltage grade if a rail can sit across
  the open fuse.
- **Put the fuse ahead of everything a user can reach**, feedback taken from behind it. Ask
  of every probe point: what does a ground clip here do?
- **Split rails with series reverse-supply diodes want a clamp from each rail to ground**,
  but simulate the missing rail first.
- **A series diode's resistance at a few mA couples load current** into anything referenced
  to that rail.
- **A class-B output stage needs diodes in its current limiter.** Simulate a limiter shorted
  and swinging, not only at rest; give an added protection circuit its own labelled box.
- **Decide the protection before the floorplan:** adding six parts to a finished layout
  cost a re-plan of a third of the board.
