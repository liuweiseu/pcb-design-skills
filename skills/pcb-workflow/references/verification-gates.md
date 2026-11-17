# Verification gates (run them every build)

Before calling a schematic, PCB or release done, pass every gate below. Gates 22 and 24-32 are
the RF ones (see the rf-design skill for the rules behind them), and gate 33 the accurate analog
one (analog-signals skill); write each RF gate's result per
band, not only at the board's top frequency: RF-MOD's stitching passed at 2.4 GHz (λ/20 is
3 mm) and fell short at its 5.8 GHz stretch (RF-MOD, 2026-10-29).

1. ERC clean (the warnings understood), with the netlist exported.
2. Every symbol pin checked against the datasheet figure, and **these checks run as scripts that
   fail the build** (SKILL.md, "Two checks no board ships without, and a third"; ECP5-2ADC-2DAC
   rev A failed 2a and 2b and lost its USB port: the FT2232H's VPHY and VPLL on 1.8 V where its
   data sheet says 3.0-3.6 V, and its D+ and D- swapped, after the author's pin audit and five
   LLM reviews in two rounds had passed it). How each check works, with the tools and the cases
   behind it: see the pcb-schematic skill, references/netlist-checks.md, "The pin audit".
   - **2a. Power pins, by voltage:** every power pin of every IC against a range table
     transcribed from its data sheet; a missing pin or a rail outside its range fails, and the
     table goes in the release log.
   - **2b. Pair polarity, by pin function, connector to chip,** through every in-line part by its
     data sheet's internal pairing; every + reaches a +, and each pair's path is printed.
   - **2c. Pin numbers by function, not by memory or variable name,** for every pin the generator
     names by number.
   - **2d. Standard connectors against the standard's drawing,** from the placed pads
     (`tools/pin_audit/connectors/`, which also mates every pair of boards meant to mate);
     dual-row and right-angle headers: the pcb-layout skill's ten steps.
   - **Not-fitted parts, both ways** (the user, 2026-11-16): every DNP part off, then each fitted
     alone and in any combination meant to go on together; `tools/pin_audit/pin_audit.py` also
     fails diode paths between rails, diode A/K mismatches and low-ohm ties between rails.
   - **"Checked" names the script and its output file.** A schematic note, a generator comment
     or "verified" in a review brief is not evidence.
3. A path trace of every signal, power rail, clock and strap.
4. No overlaps on schematic sheets, checked in code, by `pdftotext -bbox` on the exported PDF,
   and by eye on the PDF.
5. DRC at least as strict as the fab's: 0 errors and 0 unconnected, on the shipped file, with
   its zones filled.
6. Pads where KiCad puts them; connectors pointing out in the 3D render; every part with a 3D
   model.
7. Silkscreen:
   - no overlaps;
   - every label inside its box;
   - text at least 0.8 mm high and lines at least 0.15 mm wide;
   - nothing printed off the board;
   - every jumper's label beside it, every part and its label in the same box.
8. Parts:
   - every SMD part with an LCSC code;
   - every code's description matching its value and package;
   - every ordered land pattern fitting the board (no HOLE);
   - stock and price fetched with a timestamp.
9. CPL native plus JLC-corrected, with `PLACEMENT_CHECKS.txt`.
10. The revision and date on the silkscreen match the source of truth. A release is stamped
    DRAFT until the date is a real date.
11. Every rail's width measured by net from the shipped file against the rule.
12. `hand_solder_bom.csv` empty.
13. From the netlist (Rosenberg; pcb-schematic skill): no one-pin nets but test pads; the list
    of power nets read for aliases; every inductive load with its freewheel path; every
    high-current input fused; every polarized part's orientation listed for the preview.
14. The design equations asserted against the netlist's values (pcb-schematic skill, "Values").
15. Fiducials and layer markers present; paste openings on exactly the pads that need them
    (Rosenberg; pcb-layout skill).
16. Copper balance (each layer's copper fraction, by quadrant) and current capacity: each
    high-current net's narrowest track against its current (IPC-2221; component-selection
    skill) and its drop at full current, ground return included.
17. **The upload-readiness pass** (ECP5 P31: "is there anything that might block a successful
    run if I uploaded the board now?"), read from the release, not from memory:
    - DRC and ERC counts with every warning named and placed (a zone's `connection_width`
      warning reports the zone's anchor, not the neck: shrink each filled polygon until it
      splits to find it);
    - BOM lines against CPL rows (no designator in one and not the other, no duplicate code);
    - stock against the need for the order, with the fetch time (the free count, not the
      stock count: see jlcpcb-order);
    - the hand-solder list empty;
    - the gerber job's stack-up and the drill header;
    - `git grep` for absolute paths;
    - every capacitor's dielectric read off its part number (C0G where it sets a frequency or
      sits in the signal path);
    - the dissipation of every regulator at the worst load (the ECP5's ADC LDO: 1.7 V x 0.2 A in
      a SOT-23-5 at 187 °C/W is +64 °C);
    - a fuse on every input;
    - fiducials, layer markers and the order-number marker present.
18. **Every silkscreen text against the unit and region boxes**, from the written board with
    KiCad's own text boxes, and every designator nearer its own part than any other
    (pcb-silkscreen skill; GPSDO `pcb/check_unit_labels.py`).
19. **Every clock net's routed length and via count against the previous revision**
    (pcb-layout skill).
20. **Every net class binds the nets it was written for**, counted from the netlist (KiCad
    writes each net's class into it). CostasLink's `/^RF_/` and `/^LO_/` matched none of
    `Net-(U101-RF_IN)` or `/Receiver and Costas loop/LO_RX_P`, and its CPWG gap fell to the
    pour's 0.2 mm without a warning. Bind generated designs' classes by exact name from the
    generator's own list of the nets.
21. **Every exposed pad's and tab's via count against its datasheet's land pattern**, the small
    ones too (CostasLink build 17: 2 × 2 where the ADL5380 draws 3 × 3, none in the LNA's paddle
    or the SOT-89 tabs).
22. **Every RF launch measured in the plotted gerbers** (rf-design skill, "The stock SMA
    footprint"): at each through-hole RF pin, no pad flash on the inner layers, the planes the
    solved antipad off the barrel on every inner and back layer, the top pour the solved
    clearance off the pad, no track of another net inside the connector's legs on any layer,
    and the distances printed by name in the release log (CostasLink `tools/launch_check.py`).
    Not the board's settings, not DRC: the copper.
23. **Every PDF and image fills its page** (pages-and-plots.md). Check schematic sheets,
    assembly drawings and plots: the drawing is centred, about half an inch from the paper's
    tighter edges, and nothing is off the page. Use `fit_pdf.py check` and a render of every
    page.
24. **Every RF net's routed length against the shortest tree through its pads** (pcb-layout
    skill, "And every RF net's length"): no RF net, monitor taps included, over 1.5x its tree and
    10 mm extra. CostasLink `tools/detour_check.py`; rev A's LO TX MON tap was 9.4x, 25.7 dB low
    on the bench.
25. **Every RF path simulated as laid out** (rf-design skill, "Simulate the circuit the copper
    makes").
    - **Which paths:** jack to pin, pin to pin and pin to jack, extracted from the written board.
      Each is compared with the vendor's circuit placed at the pins.
    - **Pass:** within 1 dB of it across the band ±20 %, and no 3 dB dip or peak that it lacks.
      Print the range over the parasitics' sweep.
    - **The power side in the same run:**
      - each RF supply pin's impedance against the reference circuit's;
      - each choke's cold end;
      - each bead-capacitor resonance and its damping;
      - each plane island's modes in the band;
      - the coupling between chains through the rails, in dB.
    - **Rev A:** none of this was done, and its receive chain lost 30 dB at 5.8 GHz (REVB 8, 10).
26. **Every RF matching, shunt, bypass and bias part's track to the pad it serves**, measured on
    the written board.
    - **Limits:** matching parts under λ/50 at the top frequency (0.5 mm at 5.8 GHz); bypass and
      bias parts under 1 mm.
    - **No RF part on a branch of the line.**
    - **Print every T-junction on every RF net,** with its branch length and what hangs on it.
      Rev A's 0.5 pF match was 4.0 mm away, on a 1.8 mm branch.
27. **Every RF shunt part's and RF bypass capacitor's ground:** a via in, or touching, its ground
    pad (centre within 0.3 mm of the pad's edge), to the plane directly under it.
    - **Every RF IC's ground pins** joined solidly to its exposed pad and the pour.
    - **The exposed pad's vias:** at least the count gate 21 asks for.
28. **Every bias choke and every ferrite into an RF rail:**
    - an RF bypass on its cold pad, within 1 mm, via in pad;
    - no plane via ahead of that capacitor;
    - its SRF against the band, written in the design notes.

    Rev A: all three ADL5611 chokes went to a plane via with no capacitor within 5.4-13.6 mm
    (`bringup/layout/layout_survey.py`).
29. **Every supply plane island: which RF chains it serves.**
    - **Fail:** two chains on one island, or a transmitter's output stage and a receiver's input,
      without a filter between them.
    - **Under every relief window:** ground.
    - **Its cavity modes in the band:** listed.
30. **Stitching measured on the filled pours.**
    - **Within 10 mm of any RF net:** no pour point more than λ/20 from a ground via (1.25 mm at
      5.8 GHz in FR4).
    - **Elsewhere:** no point more than λ/6 (4 mm).
    - Rev A: 8.6 mm near the receive chain, 20.7 mm elsewhere.
31. **The isolation budget:** each transmitter-to-receiver path estimated in dB, written beside
    the receiver's dynamic range and its attenuator's range, and measured at bring-up
    (pcb-bringup skill).
32. **Every RF line segment measured on the filled board**, segment by segment:
    - its width against the class's;
    - its gap to the pour against the CPWG's, within 0.02 mm;
    - ground on the next layer under at least 95 % of it, outside the designed voids;
    - fence vias at least 1.5 per mm on any run over 2 mm;
    - which plane lies under the voids.

    Rev A (`bringup/layout/layout_survey.py`):
    - **Width, gap and ground:** right everywhere (0.29 mm, the gap 0.25 mm, ground under 100 %).
    - **Fence:** short. 0.9-1.0 vias per mm on its longer runs, where the generator skipped
      spots, and none within 1.6 mm along RX MON's 5.8 mm tap.
    - **What cost the dB:** gates 25-31.
33. **Every accurate analog net** (named in the design notes; analog-signals skill), measured on
    the filled board as gate 32 measures the RF lines:
    - ground on the next layer under at least 95 % of each segment, and under each of its parts'
      pads;
    - print every stretch over a supply, with the supply's name and the length.

    Not yet run on any board (added 2026-11-04).

Gates 25-32 came from CostasLink rev A's receive chain on the bench (2026-10-29): every check
rev A had (DRC, ERC, the net and detour checks, the field-solved launches, the gerber parser
and five reviews) asked whether things were connected and correctly sized; none asked what
they did together. Only a check that simulates the circuit as laid out sees a stub, a ground
return or a shared rail.

Also before an order, though not a build gate: the bring-up's test table (each block's inputs,
outputs, parts and limits, worked out from the netlist) is an order gate, as the first firmware
is (pcb-bringup skill; AMOD/RF-MOD bring-up planning, 2026-11-15).
