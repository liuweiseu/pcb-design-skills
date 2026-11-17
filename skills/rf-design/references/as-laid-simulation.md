# Simulate the circuit the copper makes (a design step and a review step)

From CLAUDE_PCB.md §14 (subsection of the same name) and §27 (CostasLink rev A's receive chain on
the bench, 2026-10-29). The matching release gates are §10 items 25-32 (see the `pcb-workflow`
skill); bench practice is §9 (see `pcb-bringup`). Read this before ordering any board with a path
above about 500 MHz, and when reviewing one.

## The case

CostasLink rev A's receive chain had controlled-impedance lines everywhere:
- 0.29 mm CPWG;
- the 0.25 mm gap held along every millimetre;
- solid ground under all of it;
- a via fence.

It still lost about 30 dB at 5.8 GHz (bench, 2026-10-29). Two layout faults caused it:
- **the parts on the lines were not where the vendor's circuit puts them;**
- **the bias chokes fed a supply plane that both chains share.**

The checks the board passed could not see either fault, because none of them asks what circuit
the copper makes:
- DRC and ERC;
- the net check and the detour check;
- the field-solved launches and the gerber parser;
- five design reviews.

A rough simulation of the as-laid circuit shows both faults in an afternoon. The user: "Even if the
simulation doesn't match exactly, it helps to know if it's going to roughly (and certainly
qualitatively) work."

## When

**Do it for every path that carries a frequency where a millimetre matters:** above about 500 MHz,
or wherever λ/50 in the dielectric is under 2 mm. Do it before the order, then rerun it in the
design review from the written board.

## Procedure

1. **Cut the paths at their ports.**
   - **What a port is:** every jack and every IC pin on the path.
   - **Representing an IC:** its vendor's S-parameters, or the datasheet's S11 and S22. For a part
     matched by external parts, use the admittance that the vendor's matching network assumes
     (CostasLink: Y = 1/50 − jωC_match).
   - **Scope:** the simulation does not need to go through the ICs, only between them: jack to pin,
     pin to pin, pin to jack.
2. **Extract from the written board, not the schematic.** Read the `.kicad_pcb` (CostasLink
   `bringup/layout/rfgeo.py`: tracks, arcs, vias, pads, zone fills).
   - **Each track segment of each RF net:** its width, length and layer.
   - **Each junction:** a branch is a stub. Record its length and what hangs on its end.
   - **Each pad:** a shunt capacitance to the plane under it, or the relief and what lies below that.
   - **Each via:** its inductance and the layers it spans. About 0.1 nH to a plane 0.2 mm down;
     about 1 nH through a 1.3 mm core.
   - **Each part:** between its own pads.
   - **Each part's ground return:** its pad, the track or pour to its via, and the via.
3. **Model every element.**
   - **Lines:** transmission lines, with Z0 and εeff from the stack's formula for each width and gap
     (`sim/rf_lines.py`).
   - **Parts:** the makers' Touchstone files where they exist (Murata, Coilcraft and the IC vendors
     publish them).
   - **Capacitors without a file:** C with its mounted ESL (0402: about 0.3 nH) and ESR.
   - **Inductors without a file:** L with its Q and its self-resonance,
     C_p = 1/((2π·f_SRF)²·L), taken from the datasheet's SRF. Above f_SRF the part is a capacitor.
   - **Ground returns:** series inductance. A 0.2 mm track over a 0.2 mm dielectric is about
     0.3 nH/mm; a 0.4 mm track about 0.25 nH/mm.
4. **Simulate the reference beside it.** This is the vendor's circuit with the same parts placed at
   the pins: no lines and a via-in-pad ground. The difference between the two is what the layout
   costs.
   - **Anchor the model first where you can.** The vendor's evaluation circuit should give the
     datasheet's gain within a few dB, as the launch study anchors on its cached point.
5. **Sweep what is uncertain:** ESL 0.2-0.5 nH; each ground return ×0.5 to ×2; εr 4.2-4.7.
   If the result flips inside that range (for example, a resonance wanders into the band), change
   the layout. Do not tune the model.
6. **Pass criteria,** across the band and 20 % either side:
   - the as-laid path within 1 dB of the reference;
   - no dip or peak of 3 dB that the reference does not have;
   - each IC port's return loss what the vendor assumed.

   Write a table and a plot per path into the design notes, so a reviewer can rerun them.
7. **Run the same simulation on the power and ground paths.**
   - **Supply pins:** each RF IC's supply pin, through its tracks, inductor and capacitors to their
     ground vias. Compare the impedance the pin sees across the band with the reference circuit's.
   - **Bias tees:** model each choke from its maker's file, and look at what sits on its cold end.
     Above its SRF the choke is a capacitor of a few hundred ohms, so RF reaches the cold end.
   - **Ferrite beads:** each bead at its DC current, with the capacitors after it. Find the
     bead-capacitor resonance and its damping.
   - **Plane islands:** treat each island as a cavity. List its modes,
     f_mn = c/(2√εr)·√((m/a)² + (n/b)²) from its size. List which chokes, relief windows and vias
     tap it.
   - **Coupling between chains:** from all of the above, the coupling from each transmitter or
     amplifier output to each receiver input through the rails, in dB. Compare it with what the
     receiver must reject.
8. **Tools.**
   - **The circuit:** plain ABCD cascades in numpy (`bringup/layout/lna_input_model.py`, 80 lines),
     or scikit-rf with the Touchstone files. Qucs-S, or ngspice's transmission-line elements, for an
     AC sweep.
   - **3D discontinuities only** (launches, wide pads, a via transition): openEMS. Its results go
     into the circuit as S-parameter blocks.
   - **The geometry:** `bringup/layout/layout_survey.py` reads the board file for everything gates
     26-32 measure.

## The faults it should have caught on CostasLink rev A (full detail)

- **A part in a matching network sits on the pin's own pad, or on the line at the pin, never on a
  branch.**
  - **Phase length:** at 5.8 GHz on JLC04161H-7628, 1 mm of 50 Ω CPWG is 12°.
  - **What rev A did:** the LNA's 0.5 pF input shunt (Skyworks: "a shunt capacitor match at the RF
    input port") sat 4.0 mm of track from RF_IN, about 50°. It was at the end of a 1.8 mm branch of
    0.2 mm track.
  - **Why it failed:** the branch's ~0.6 nH, the capacitor's 0.3 nH and its ground's ~0.5 nH
    series-resonate with 0.5 pF near 5.9 GHz. That is a short across the input.
  - **Result:** the model loses 25 dB at 5.8 GHz; the bench lost 20-30
    (`CostasLink-PYNQ-Z2/bringup/REVB.md` row 8).
  - **The rule:** the track from the part to the pin under λ/50 at the top frequency (0.5 mm here),
    on no branch.
  - **Background:** this is "Copy the radio vendor's reference layout exactly" made measurable.
    Skyworks says of its LNAs that "the most sensitive regions are the input match and the RF
    decoupling regions", and adds multiple vias on its evaluation boards to cut their parasitic
    inductance (Microwave Journal, "Two-Stage Ultra Low Noise Amplifiers", SKY65048/49/66).
- **A shunt part's ground return is part of its value.**
  - **The rule:** every RF shunt part (match, ESD choke, load, bypass) gets a via in, or touching,
    its ground pad, to the plane right under it.
  - **Model it:** count the return's inductance in the simulation.
  - **Rev A:** its parts reached ground through the pour to vias 0.7-0.8 mm away. The LNA's exposed
    pad had one via.
- **An RF IC's supply pin sees an inductance the vendor chose.**
  - **The reference:** the SKY65404 has 0.6 nH from VCC to its 100 nF.
  - **Rev A:** 1.6 mm of 0.2 mm track before the inductor and 2.3 mm of 0.4 mm track after it, about
    2 nH in all.
  - **The rule:** put the inductor on the pin and the capacitor on the inductor's far pad, with a via
    in its ground pad. Count the tracks' inductance.
- **A bias choke's cold end gets its RF bypass on its own pad, before any via to a plane.**
  - **The parts:** rev A's three ADL5611 chokes are LQW18AN43NG00D, self-resonant at 2.7 GHz or
    above (Murata). At 5.8 GHz each is a capacitor of about 340 Ω.
  - **What happened:** each went to a +5V_RF via 0.8 mm from its cold pad, with no capacitor within
    5.4-13.6 mm. The 68 pF the schematic drew "beside" the receive chokes was placed 36 mm away.
  - **The risk:** RF on the plane can reach the other chain. On rev A it did not, measurably (next
    bullet), but only because of the stack.
  - **The rule:** on the cold pad, via in pad, put a capacitor that is series-resonant near the band
    (a few pF in 0402) and a 68-100 pF. Then a ferrite or a resistor to the rail.
- **One supply island per RF chain, and ground under the RF lines.**
  - **Rev A's plane:** +5V_RF was one 86 x 44 mm island under both chains. Every choke and every
    relief window under an ADL5611 pad opened onto it.
  - **What the bench found:** a transmitter leak entering the receiver after its step attenuator, at
    -53 dBm at RX MON. It capped the attenuator's range at 23 dB and swamped the chain above
    5.86 GHz (REVB row 10).
  - **Model the plane before blaming it.** The shared island was the first suspect, but the as-laid
    simulation cleared it.
    - **Why:** the island sits 0.21 mm over the bottom layer's ground pour. That thin cavity is a
      low-impedance plane pair, about 1 Ω between the chokes' vias.
    - **The numbers:** the choke-to-plane-to-choke path models 20-40 dB under the measured leak, with
      the wrong shape against frequency (`CostasLink-PYNQ-Z2/sim/aslaid/REPORT.md`).
    - **The lesson:** the cavity that matters is the one each island forms with its nearest ground,
      which may not be the plane named in the stack-up. Simulate it (step 7) before calling it the
      path.
  - **The rule still stands:** separate islands for transmit and receive, each through its own
    ferrite and capacitors. A stack with the supply far from any ground would have made rev A's
    plane a real path. The layer under a relief window is ground, not a supply. Do not count on the
    stack to rescue the next board: rev B puts ground on In2 under the RF chains (REVB 10, 54; the
    first rule in SKILL.md, "Ground, not a supply plane, under every RF chain", the user, 2026-11-04).
- **The as-laid simulation's own lessons** (CostasLink rev A, `sim/aslaid/REPORT.md`):
  - **Count the pads' capacitance on a thin dielectric.** An 0402 pad 0.21 mm over its plane is about
    0.08 pF. Eight DC blocks, the shunts and the tees on rev A's receive chain cost about 2 dB at
    5.8 GHz and 8 dB at 5.0, through gain blocks with a poor match. Void the plane under RF
    passives' pads, or use 0201 parts and fewer series parts.
  - **Take a CPWG's width from a field solver, not a closed form.** Rev A's lines are 53.7 Ω by a 2D
    finite-difference solve, where the closed form gave 49.8. Its couplers' quarter wave came out at
    5.97 GHz, not 5.8, because the even and odd modes' εeff (3.20 / 2.73) were never computed.
  - **Find where a vendor's S-parameters are referenced.** A gain block's table is often measured at
    its evaluation board's SMAs, launches and lines included. It is not the pins.
  - **Fit at most one parameter, and say which.** Rev A's model matched the bench after one fit
    (C102's ground return, 0.14 nH extracted, 0.59 nH fitted). A model with several free parasitics
    fits anything and predicts nothing.
- **Stitch the pours.**
  - **Near RF:** every point within λ/20 of a ground via, which is a via grid at λ/10 (2.5 mm at
    5.8 GHz in FR4).
  - **Everywhere else:** within λ/6, so that no via-free patch reaches the half wave that resonates.
  - **Rev A:** its fences ran along the lines only. 43 % of the top pour round the receive chain was
    more than 2.5 mm from a ground via, up to 8.6 mm. Elsewhere on the board it reached 20.7 mm.
- **The isolation budget is a design number.**
  - **Before the order:** estimate each path from a transmitter to a receiver: rails, plane cavities,
    layout coupling. Write the leak beside the weakest signal the receiver must resolve and beside
    its attenuator's range.
  - **On the bench:** measure it first (§9).
- **RF matching, decoupling and bias parts are anchored by hand to the pad they serve, and the build
  measures the distance.**
  - **What the rule placer does (§5):** it hangs a rail's capacitor on "the chip the schematic drew it
    beside", at the pin's fan band (3-8 mm). If the sheet's nearest chip on that rail is another one,
    the capacitor goes tens of mm away.
  - **Rev A:** its design reviews flagged this ("no decoupling within 2.5 mm of any RF chip's supply
    pin", REVA_CHANGES 35), and it was sent to the bench as "to confirm".
  - **The rule:** a review finding about where an RF part sits is a layout change before the order,
    not a bench item.
- **Leave rework room on rev A.**
  - **Why:** rev A's faults can be tested on the bench only because the parts are reachable: lift
    C102; bodge a capacitor onto a choke's cold pad.
  - **The rule:** give each RF IC pin a DNP 0402 shunt pad on its own pad, and each choke's cold end a
    capacitor pad. Then the bench can try what the simulation suggests.

## Why these rules are general (§27, CostasLink rev A on the bench, 2026-10-29)

For any board where a millimetre is a phase.

- **Controlled impedance is necessary, not sufficient.**
  - **What it means:** a 50 Ω line delivers what its ends present to it.
  - **Rev A:** every line measured right in the board file, and the chain still lost 30 dB at
    5.8 GHz. The circuit made of the parts, their branches and their grounds was wrong; the lines
    were not.
  - **The question to ask:** "is the circuit the copper makes the circuit we meant?", not only "is the
    line 50 Ω?".
- **Every check rev A had asked whether things were connected and correctly sized; none asked what
  they did together.**
  - **What passed it:** DRC, ERC, the net and detour checks, the field-solved launches, the gerber
    parser and five reviews.
  - **The rule:** a check that simulates the circuit as laid out is the only one that sees a stub, a
    ground return or a shared rail.
- **At microwave frequencies, "next to the pin" is a distance with a phase.**
  - **The arithmetic:** at f, 1 mm is 360°·√εeff·f/c. That is 12° at 5.8 GHz on FR4 CPWG, and 2° at
    1 GHz.
  - **The trap:** the vendor's schematic shows lumped values at the pins. Its layout puts them there,
    and its numbers are only true there.
  - **The rule:** write down how far each part is, in degrees.
- **A rough model early beats an exact one late.**
  - **Rev A's model:** 80 lines of ABCD matrices, with lossless lines and an idealised LNA.
  - **What it did:** gave the bench's trend and most of its size, and named the part to lift.
  - **How far to trust it:** the anchor (the vendor's circuit at the pins) and the parasitic sweep
    tell you.
  - **What it settles:** whether the design will work roughly, and certainly qualitatively, before
    money is spent.
- **Supply networks are RF circuits too.** Above a few hundred MHz:
  - a choke is a capacitor above its SRF;
  - a capacitor is an inductor above its own;
  - a via through a core is a nanohenry;
  - a plane island is a resonant cavity.

  **The rule:** simulate the bias and decoupling paths with the signal paths, and keep each chain's
  supply its own.
- **An automatic placer optimises what it is told.**
  - **Rev A:** "the capacitor beside the chip the schematic drew it beside" put the receive tees'
    68 pF 36 mm from their chokes.
  - **The rule:** anchor every RF part to the pad it serves, by hand, and measure the distance in the
    build.
- **A review finding about an RF part's placement is a change, not a bench item.**
  - **Rev A:** reviewers flagged the decoupling distances before the order (REVA_CHANGES 35). They
    were carried as "to confirm", and the bench confirmed them.
- **Inverting one arm of a quadrature receiver is a mirror, not a rotation: re-derive every loop sign
  after it.**
  - **What happened:** CostasLink Response 10 swapped the I arm's inputs so its pair would route
    uncrossed. Its note said the Costas loop "locks 180 degrees round". That is true when the LO is
    inverted, which flips I and Q together.
  - **Why it was wrong:** with I alone inverted, sign(-I) x Q = -sign(I) x Q, so the loop's feedback
    sign flipped. The jumpers' default was never changed.
  - **How it showed:** a wrong sign in a loop with a sign() detector does not run away, as the
    bring-up text expected. It holds at the detector's jumps (±90 degrees) with the comparator
    chattering, which looks like a lock.
  - **The rule:** write the loop's sign out end to end in the design notes: the demodulator's I/Q
    convention, each arm's polarity, the comparator's sense, the switch's select, every inverting
    stage and the oscillator's tuning slope.
  - **Check it on the bench before closing the loop:** with the loop held and the carrier on a known
    side of the LO, the arms' phase order (Q ahead of or behind I) gives the sign.
- **At bring-up, separate the paths before interpreting a shape.**
  - **Rev A:** a notch and a recovery were the chain cancelling against a leak.
  - **The rule:** a knob in the path (an attenuator, a switch) sorts them. Measure the leak floor with
    the ports terminated first.

## The same gates on boards of internally matched blocks (§29, RF-MOD and IQ-MOD)

CostasLink's RF gates run on RF-MOD and IQ-MOD (`gates.py` in that session's scratchpad):
- The lines were exact: 0.29 mm, a 0.25 mm gap, ground under 100 % outside the jacks' designed
  launch voids.
- No matching part sat on a branch. The RF chips are internally matched, so the only shunt parts on
  RF lines are bias chokes, 0.5-2 mm off the line: under 10 degrees at 2.4 GHz.
- The stitching fell short of gates 30 and 32 at the 5.8 GHz stretch, though: fences of 0.2-1.7
  vias per mm; the top pour 2.0 mm (median) and up to 9.8 mm from a ground via near the lines. That
  is fine at 2.4 GHz (λ/20 is 3 mm), and short of the gates at 5.8 GHz.
- **Write each gate's result per band, not only at the board's top frequency.**
- The synthesizers' output-pin nets were in no class, as on CostasLink, but here they are 3 mm long.
