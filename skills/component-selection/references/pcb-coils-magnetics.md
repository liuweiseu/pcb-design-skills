# PCB coils and magnetics (CLAUDE_PCB.md §15)

From the Halloween board (2026-10-07): a 12 V brick, amperes into PCB coils, a magnetic
pendulum bat levitation loop.

## Inductance of a planar spiral

Current-sheet formula of Mohan et al. (IEEE JSSC, 1999):

L = mu0 * n^2 * d_avg * (c1/2) * (ln(c2/rho) + c3*rho + c4*rho^2)

with d_avg = (d_out + d_in)/2 and rho = (d_out - d_in)/(d_out + d_in);
c = (1.00, 2.46, 0, 0.20) for a circle, (1.27, 2.07, 0.18, 0.13) for a square.

Identical layers in series on a thin dielectric couple almost completely: four give nearly
16 times one layer's L. Check anything that matters with a field solver.

## Resistance and skin depth

Count squares (0.98 / 0.49 / 0.25 mohm per square at 0.5 / 1 / 2 oz). The skin depth in
copper is 66 um / sqrt(f in MHz): 210 um at 100 kHz (35 um copper is all used), 25 um at
6.78 MHz (it is not), and the proximity effect between neighbouring turns adds more.

## Q and link efficiency

Q = wL/R sets a resonant link's efficiency: at best
eta = k^2 Q1 Q2 / (1 + sqrt(1 + k^2 Q1 Q2))^2, with k the coupling.

## Heat and self-resonance

- A coil is a heater: compute its temperature at its current, and limit duty in firmware.
- Turn-to-turn and layer-to-layer capacitance set the self-resonance; stay well below it.

## A coil is also a sensor

A magnet moving over it induces a voltage (Faraday). Size it before relying on it. By
reciprocity the EMF is the coil's force per amp times the speed: about 3 mV for a 48-turn
PCB coil under a pendulum bat (Halloween board), where a classic kicker's 1500-turn coil
gives volts. A Hall sensor is usually the better position sensor; the back-EMF is a bonus.

## Void every plane under a coil, on every layer, with a margin

A plane is a shorted turn: it cancels the coil's AC field (no wireless power through it),
lowers the inductance, and brakes a magnet moving over it with eddy currents.

## A PCB coil's L/R is microseconds

31.5 uH and 3.35 ohm is 9.4 us on the Halloween board. Driven by an H-bridge at tens of kHz,
its current follows the PWM square wave: amperes of ripple, and the heat that goes with it.
Switch at hundreds of kHz, use 3-level PWM (ripple vanishes near zero mean current), or add
series inductance.

## Simulate a feedback loop with its sensor's noise and quantisation before trusting its gains

The Halloween board's levitation loop held the bat at the first tuning, but with 0.6 A rms of
chatter (1.4 W) from Hall-sensor noise through the derivative term. Averaging the ADC and a
lower bandwidth took it to 20 mA rms (1 mW) with the same catch range
(`halloween1/sim/physics/levitation_loop.py`).

## Magnets near children

See `boards-for-children` (ASTM F963 flux index, encapsulation).
