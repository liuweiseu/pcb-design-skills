# Dual-row and right-angle headers: working out the geometry

Read before placing, copying or checking any 2-row connector (Pmod, SYZYGY, a 2 x 20 host
header, IDC, any vendor header), and above all a right-angle one. The rule in SKILL.md:
**dual-row headers, and right-angle ones above all, are worked out from geometry, never from pad
numbers** (the user, 2026-11-16: "There have been several problems with these, especially where
they are supposed to be 90 degree headers").

## The record

- **ECP5-2ADC-2DAC rev A's J303/J304** were copied from the IcepiZero Pmod adapter's J3. All
  three are mirrored end to end against the Pmod spec's figure 5, so a bought Pmod meets +3V3 on
  IO1 (ECP5-2ADC-2DAC REVB 14; found by the first whole-tree audit, 2026-11-16,
  `tools/pin_audit/`).
- **AMOD-A and RF-MOD's plugs** were first laid with KiCad's pad numbering on JLCPCB's footprint,
  which numbers the same part from the other end. Every plug pin k met host pin 13 - k
  (connector-routing.md, "Pmod and other keyed two-row connectors").
- **OWLternatingCurrent's tree-perch joint** is turned round: pin n meets pin 17 - n (REVB 1.9).
  Its first suggested fix, turning the tree's own header, could not work: a right-angle part
  turned 180 degrees in place points its pins into its own board. Only the mating part can turn,
  or the numbering.
- **The GPS adapters** taught that two side-entry headers on one face of a board meet in reverse
  order (connector-routing.md).
- **PMOD_direct_to_SMA and VerifierPCB** do not say which row holds Pmod pins 1-6.
- **The IcepiZero AD9226 and AN108 adapters' J2** look like the mirror image of their modules'
  connectors (*uncertain*, from photographs).
  - **Cause:** J2 was drawn as if a module's pin positions did not depend on which face of it
    meets the adapter.
  - **AN108:** "right way up" feeds the module -5 V.
  - **AD9226:** every signal lands on its row partner (`IcepiZeroADCDAC/PIN_AUDIT.md` C1, C2).
- **The ECP5's Pmod sockets** stood a quarter turn round in JLCPCB's placement preview (the
  jlcpcb-order skill, CPL rotations and the preview).

The netlist is right in every one of these, so no netlist check can see them.

## The ten steps

Work through these for every 2-row connector, as code where it can be:

1. **Name the four ways it can sit.** A 2 x N part fits its outline four ways: as intended,
   mirrored end to end, with its rows swapped, or both (a half turn). For each of the other three,
   say what it does, starting with where power and ground land.
   - **Pmod:** a row swap puts IO1-4 and IO5-8 on each other's lines, which is a labels fault. An
     end-to-end mirror puts 3.3 V on IO1, which damages parts.
   - A right-angle part's opening must face off the edge, but the pad numbering can still be any
     of the four.
2. **Know which numbering each side uses.**
   - **Zigzag:** 1 and 2 across from each other, odd pads in one row, even in the other. KiCad's
     footprints and IDC use it.
   - **Row by row:** the Pmod spec puts 1-6 in the upper row and 7-12 in the lower.
   - **Other footprints of the same part:** a vendor's or JLCPCB's footprint may number from the
     other end (connector-routing.md: JLCPCB's pad p is KiCad's pad 13 - p).
   - Write the mapping as a function in the generator, with its source and a test. Derive each
     pin from the pad's **position relative to the body**, never from its number.
3. **Read the footprint's geometry from the board file, not from memory:** each pad's position
   and the F.Fab body outline.
   - **KiCad's `PinSocket_2xNN_P2.54mm_Horizontal`,** as placed on ECP5 J303 and read 2026-11-16,
     at rotation 0:
     - pad 1 at the origin, with the odd pads running +y (south) at x = 0;
     - the even pads at x = -2.54;
     - the housing and its opening toward -x.
   - **The odd column is the upper row,** because it is the row farther from the opening, and the
     upper row's leads bend down farther back.
   - **Turned 180 degrees at an east edge,** pad 1 is therefore at the **south** end. That is the
     opposite of the Pmod spec's figure 5, and it is how J303/J304 went wrong.
   - **Any other footprint:** check it the same way. Assume nothing about a header (male) from the
     socket.
4. **Write down the standard's viewpoint, then compare in the same frame.** Every figure has one:
   a top view of the host, a view into the socket, or the module's component side.
   - **Pmod:** figure 5 is a top view of a host socket on an east edge (pin 1 north, VCC and GND
     south). Figure 2 is a top view of a module plug on a west edge (pin 1 north).
   - Compute your pads in that same frame and compare them position by position.
   - Convert between views with coordinates, never in your head. A view into the socket from
     outside the edge is a different frame from a top view, and getting its handedness wrong is
     exactly the end-to-end mirror.
5. **Mate the halves in one frame, and say how they meet.**
   - **Edge to edge,** both component sides up (a right-angle socket and a right-angle plug):
     contacts meet at the same position along the edge, upper row to upper row.
   - **Stacked,** a board plugged on face down (a HAT, a shield, the Icepi adapters): its socket
     is on its bottom side, so mirror that footprint properly. Seen from above, its pad n must sit
     over pin n, at 0.000 mm.
   - **A ribbon:** trace pin 1 through the cable as it will be crimped (the stripe and the key).
     Two side-entry headers on one face meet in reverse order.
   - Assert VCC on VCC and GND on GND first, then IO1 on IO1.
6. **Two halves that agree prove nothing about the standard.** The ECP5 sockets and the AMOD plugs
   mate with each other and both disagree with Digilent's.
   - Check at least one half against the standard's own figure, independently of the other.
   - Then mate every partner the board will meet, including a bought module drawn from the
     standard's figure.
7. **Re-derive a copied connector on every board.** "The same footprint, the same mapping as the
   ECP5's sockets" carried the adapter's mirror onto a built board.
8. **Put the orientation on the silkscreen.** Print pin 1, and print the names at the end where
   they are ("3V3 GND" at the power end, "IO1" at its end). Then a person plugging in, and a
   reviewer holding the standard's figure, can see it. A label such as "PMOD 1-4: IO1-4" in the
   middle says nothing about which way round it is (the pcb-silkscreen skill, "Header pins").
9. **Check it physically.**
   - Before ordering: print the board 1:1 and lay the real connector and the mating module on it
     (SKILL.md, "Check footprints at 1:1").
   - On a built board, before power: plug in a bought module and buzz its GND to the board's GND,
     and its VCC to 3V3 (under 1 ohm).
10. **Gate it.** The connector check (the pcb-workflow skill's verification gates, gate 2d;
    `tools/pin_audit/connectors/`) reads the placed pads. For each contact it computes the
    position along the edge, the row and the side; it compares those with the standard's table
    and mates every pair of boards meant to mate. The build fails on a mismatch.

## A mirrored 2-row connector cannot be undone by re-soldering or by stacking straight parts

The user (2026-11-16) asked whether the ECP5's and the AMOD plugs' right-angle Pmods could be
moved to the bottom side, or extended with long double-row pins and sockets, to make them
standard. Worked out from J303's placed pads in
`tools/pin_audit/connectors/pmod_rework_options.py` (`.out` beside it), it can't be done:

- **Moving a through-hole right-angle part to the bottom** keeps every contact's place along the
  edge and its net, and moves the far row to the far side below the board: a mirror through the
  board.
  - J303 moved to the bottom mates a standard module pin for pin only with the module turned
    over, components down.
  - Upright, it still puts 3.3 V on IO1.
  - The as-built socket already takes a turned-over module, with IO1-4 and IO5-8 swapped in the
    `.lpf`. So the move gains only the swap, at the cost of desoldering two 12-pin sockets from a
    built multilayer board.
- **Moving both the socket and the plug to the bottom** keeps them mating each other, and each
  still meets standard parts only turned over: today's situation in mirror image.
- **A chain of straight-through parts** (long double-row pins, sockets on pins, a pin-for-pin
  extender) is invisible upright and acts as one turn when turned over, and two turns cancel. So a
  chain gives either today's mismatch or "power right, IO1-4 on IO5-8", never the standard.
- **The reason:** an end-to-end mirror that keeps the rows reverses the order along the row, and
  turning or sliding rigid straight parts can only produce that together with a row swap. Undoing
  it needs wires that cross.
- **What does work:**
  - plug the other part in turned over and swap pmod[0..3] with pmod[4..7] in the `.lpf` (power
    lands right);
  - or use a **crossed adapter:** a small board with a right-angle 2 x 6 plug on one edge and a
    socket on the other, rows kept and positions reversed (s to 5 - s). The same design makes a
    rev A host standard for a bought module, and a standard host fit an AMOD rev A plug.
  - A crossed 12-wire jumper harness does the same, less tidily.
