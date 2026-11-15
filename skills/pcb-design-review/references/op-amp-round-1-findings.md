# What the op-amp board's review round 1 found

Worked examples of what a review round turns up, each now a check. Read them when writing the
brief's numbered "things to attack" and when reconciling a round: a new board likely has the
same classes of fault. Board: LAoE Discrete Op-Amp (github.com/gallicchio/op-amp-pcb).

## The author's own review (2026-10-24, `design_reviews/2026-10-24_Claude-Fable-5.1/REPORT.md`)

- **Derive what each switch position does on its own from the netlist.** A 2-pole DIP wired as a
  chain (pole 1 in series with the 1 k, pole 2 across the 1 k) made "2 alone" an open circuit
  while the board, the sheet and the handbook all called it "the bare 100 pF"; the checker's
  "pole 2 shorts R14" was true and useless. Write the switch table (each pole alone, both,
  neither) from the netlist, and assert each row.
- **Mark ON on the silkscreen** at the side the footprint says, and make the preview check "the
  part's own ON marking is on the side of the silk ON". "On is toward the number" cannot be
  checked in a preview and was not true as drawn.
- **A teaching board's bench-supply current limit is part of the design.** Compute what a scope's
  ground clip on every probe loop does (here 0.55 to 0.68 W into an 0805 when Q2 C or Q3 E is
  grounded) and what a shorted output does; print the limit on the board and make it the
  handbook's rule, not a bring-up step.
- **Rate the part JLCPCB stocks, not the famous maker's.** The C20526 "MMBT3904" is 200 mW and
  625 K/W where onsemi's is 350 mW and 357 K/W; "a short to a rail is survived" was written
  against the wrong datasheet.
- **Do not change the project while a round runs** (see SKILL.md).

## The outside reviewers (2026-10-27, Gemini 4 Argon and Kimi K3)

- **A margin taken at 0 V in a class-B stage proves nothing about the load.** The author's "100 pF
  of coax raises the margin to 90 degrees" was measured with the push-pull in its dead band; a
  few volts off zero the follower oscillated at 13 MHz. Simulate capacitive loads in transient
  with the output well away from zero, and isolate the jacks with a resistor *after* the
  feedback tap (emitter sense resistors are inside the loop and isolate nothing).
- **Size the resistors a misplaced scope clip loads, not just the supply limit.** A clip on Q3 E
  drew 45 mA, under the 50 mA limit, and put 0.65 W in an 0805. Compute every loop to ground at
  the real current and give each resistor a package that survives it (here a 1 W 2512 and a
  1206).
- **Read the side view for a terminal block's wire face.** "3.60" in the front view was the pin
  length; the pins sit 4.0 mm from the back. EasyEDA draws the wire openings; fit them, not just
  the pin row, and set the CPL so they face the edge. (This fix then had to be carried to every
  board using the KF301: see pcb-workflow, "A fix found on one board goes to every board".)
- **A lookup on the first designator of a row is a bug.** PLACEMENT_CHECKS matched only "Q1" of
  "Q1, Q3, ..." and gave whole groups the wrong line or none.
- **Model the rail diodes and bypass in the simulation** and take the rail voltage from it; a
  hard-coded 14.6 V beside ideal 15 V rails broke the handbook's KVL.
- **Count pads, not pad numbers.** Four BNC posts numbered "2" collapsed to one in a dict keyed
  by number: 9 joints a board went missing from the cost.
- **Reviewers misname themselves.** Kimi K3 signed its review "Claude"; ask the user which model
  ran before trusting a directory's name.
- **Protection is a part count against the board's message.** On a board whose point is "op-amps
  are just transistors", a 741-style limiter (two transistors, two sense resistors, two diodes)
  made a third of the transistors not the op-amp. One resistor inside the loop (330 ohm from the
  push-pull to OUT, the feedback taken after it) did the same job: a short draws 46 mA, the
  SOT-23s stay at 127 mW of 200, and it also isolates a cable. Sweep the value for the smallest
  one with margin (270 ohm left 84 % of the rating at 25 C), keep no probe loop on the node it
  protects, and prefer the protection the student reads as one part.
