---
name: analog-signals
description: Accurate analog signal rules - ground (never a supply plane) under ADC inputs, DAC outputs, references, thresholds, VCXO/VCO tuning voltages, loop filters and high-impedance or high-gain nodes; capacitive coupling and return paths over a plane; every amplifier slewing its full swing across the band; stability at more than one DC level; naming the accurate nets for gate 33. Use when a board has an ADC or DAC front end, a precision reference, a PLL/VCXO loop filter, an op-amp or discrete amplifier, a high-impedance or summing node, or when the user mentions noise, offset, distortion, slew rate, full-power bandwidth, microvolts, picoamps or analog accuracy.
---

# Accurate analog signals

From CLAUDE_PCB.md §14a (added 2026-11-04). Like `highspeed-digital` and `rf-design`, this is
general practice: the rule on ground under analog signals is the same as the first RF rule, written
down at the user's request before a board needed it. The slew-rate rule was then taught the hard way
by ECP5-2ADC-2DAC board A (2026-11-16), and the stability rule by the op-amp board's bring-up
rehearsal (2026-11-15). When another board teaches one of these, add its citation beside the rule.

Related skills: `rf-design` (the same ground rule for RF chains, and supply islands and filtered
feeds); `highspeed-digital` (return paths, the stack-up's impedances); `component-selection`
(metal-film resistors, Kelvin connections to current shunts, amplifier and reference parts);
`pcb-layout` (stack-up and layer assignment, analog rails as planes or patches, the layout order,
hopping nets); `pcb-bringup` (what may and may not go on a monitor mux); `pcb-workflow` (gate 33).

## What counts as accurate analog

- ADC inputs and DAC outputs;
- references and the thresholds set from them;
- a VCXO's or VCO's tuning voltage, and loop filters;
- high-impedance nodes, summing junctions and high-gain stages;
- anything whose microvolts or picoamps matter.

**Name these nets in the design notes**, so the rules below and gate 33 know which they are.

## Ground under them

- **Ground, not a supply plane, under every accurate analog signal** (the user, 2026-11-04; the
  same rule as the first in `rf-design`, "Ground, not a supply plane, under every RF chain").
  - **Under what:** each such trace and part, its feedback network, its filter capacitors and its
    reference.
  - **Which ground:** the plane the ADC, DAC or amplifier measures against.
  - **On a 4-layer board:** route them on L1 over L2. One that must run on L4 gets ground fill on L3
    under it, not a supply island (the standard 4-layer stack-up in `pcb-layout` puts supplies on
    L3).
  - **Supplies:** feed these parts as short patches from their regulator (`pcb-layout`, power),
    beside the signal, not under it.
  - **Why, in numbers** (estimates for JLC04161H-7628): a trace couples, through its capacitance,
    whatever the plane under it carries.
    - 20 mm of 0.2 mm track 0.21 mm over its plane is about 1.6 pF: 100 kΩ at 1 MHz, 1 kΩ at
      100 MHz.
    - Over a supply, a 10 kΩ node carries about a tenth of the plane's 1 MHz ripple, and a 100 kΩ
      node about 70 %.
    - At 100 MHz, a switching converter's edges reach either node almost whole.
    - Over ground, the same capacitance only loads the node; it couples nothing in.
  - **And the return:** the signal's return current runs in the plane under it (`highspeed-digital`,
    return paths). Over a supply, it reaches the measuring chip's ground only through the supply's
    decoupling capacitors, and the supply's noise lies between the signal and its reference.
  - **Check it: gate 33** (`pcb-workflow`, verification gates), measured on the filled board as
    gate 32 measures the RF lines: ground on the next layer under at least 95 % of each named net's
    segments and under each of its parts' pads; every stretch over a supply printed with the
    supply's name and its length. Not yet run on any board (added 2026-11-04).

## Amplifiers

- **Every amplifier in a converter's path must slew its full swing across the band it is sold
  for** (ECP5-2ADC-2DAC board A, 2026-11-16, REVB 21).
  - **The formula:** full-power bandwidth is SR / (2π·V_peak).
  - **What happened:** the ADC front end's OPA1612 (27 V/µs; its data sheet's full-power bandwidth
    4 MHz at 1 V pk-pk) feeds a 65 MS/s ADC's 32 MHz band. On the board its step response compressed
    above 150 mV (33 V/µs at a 1 V step, measured at 0.25 ns by equivalent-time sampling) and the
    harmonics climbed from -45 dBc at 6 MHz to -26 dBc at 11 MHz.
  - **How it was seen:** the board measured its own analog chain, DAC -> cable -> ADC at an
    effective 4 GS/s by stepping the sample clock's PLL phase (`pcb-bringup` has the method).
  - **The rule:** check SR against the largest signal at the Nyquist frequency for every stage, the
    low-noise one included. Where low noise matters more, say in the design notes what band is clean
    at full scale.
- **Look for instability at more than one DC level** (op-amp board, bring-up rehearsal on a
  simulated bench, 2026-11-15). A class-B output's loop gain is lowest inside its dead band. In the
  model the uncompensated amplifier is quiet with the output at 0 V and oscillates at 10 V p-p with
  it at 3 V. A stability test at rest, or a handbook exercise that says "watch it ring" without
  saying where the output sits, sees half of it. Run stability and capacitive-load checks with the
  output well away from zero as well as at rest (the same lesson as design review round 1's "a
  margin taken at 0 V in a class-B stage proves nothing about the load", `pcb-design-review`).

## The rest, from the other skills

- **Analog rails as planes or patches, measured in milliohms, not traces** (ECP5 P30; `pcb-layout`).
- **Analog apart from digital and switch nodes;** for aggressors and victims, distance first, then a
  shield can (`pcb-layout`).
- **The critical analog lines are routed second**, right after the ground pour, short, with ground
  on both sides (Rosenberg's layout order, `pcb-layout`).
- **Metal-film resistors** for low excess noise and distortion (`component-selection`).
- **A Kelvin connection to every current shunt** (`component-selection`, power and current).
- **Hop a low-impedance or slow net to the other layer, never a high-impedance node** (`pcb-layout`).
- **Never put a high-impedance node, a loop filter or a fast node on a monitor mux** (`pcb-bringup`).
