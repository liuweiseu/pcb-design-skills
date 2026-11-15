---
name: pcb-workflow
description: Entry point for designing, changing or ordering any PCB with generated KiCad files - how to work with the user (logging, questions, rev A, git, licence), the build system and single sources of truth, generated documents and pages, and the verification gates every build must pass. Use at the start of any board task, before a release or order, when setting up a board's build/generators, or to find which other pcb-design skill to load.
---

# PCB workflow: how to design a board the user will be proud of

Read this before starting or changing any PCB. It distils what went right and wrong on a
dozen Claude-generated boards. Every rule is something the user had to ask for, or a fault
that a fab, a reviewer or a working board found. The boards, their outcomes and where their
histories live: [references/boards.md](references/boards.md) (read it to decode a citation).

**Citations.** "(Lorenz P3)" or "(GPSDO r29)" point at the prompt (P) or round (r) that
taught the lesson. "(Rosenberg)" is Hans Rosenberg's *Electronic Product Development
Checklist*, version 5 (2025), folded in on 2026-10-07 wherever the rules did not already say
the same thing; the PDF is copyrighted and is never committed. The fast-digital, RF, power
and children's-board rules (highspeed-digital, rf-design, component-selection,
boards-for-children) were written before a board needed them (the user, 2026-10-07: "be sure
to incorporate tips for those fancier boards") and cite sources instead of boards; when a
board teaches one the hard way, rewrite it with the board's citation.

## Which skill to load for which stage

| stage / question | skill |
|---|---|
| starting a board, the build, the gates, "is it ready?" | `pcb-workflow` (this one) |
| the board is ready for outside LLM reviews; writing a review brief; reconciling reports | `pcb-design-review` |
| the user asked for something, or a fault was found: write it down as a rule | `record-lesson` |
| drawing the schematic (Art of Electronics standard), values, design equations | `pcb-schematic` |
| silkscreen: labels, boxes, the board that explains itself | `pcb-silkscreen` |
| placement, routing, mechanical: connectors, cables, enclosure | `pcb-layout` |
| parts, LCSC codes, stock, manufacturing package, CPL rotations, the JLCPCB order | `jlcpcb-order` |
| bring-up plan, test points, debuggability | `pcb-bringup` |
| choosing real components; power, current, magnetics | `component-selection` |
| a board for a child: toy safety | `boards-for-children` |
| KiCad 10, pcbnew Python, kicad-cli, ngspice, tooling quirks | `kicad-scripting` |
| fast digital: clocks, DDR, differential pairs, escape | `highspeed-digital` |
| RF: CPWG, launches, matching, stitching | `rf-design` |

## 1. How the user works with you

- **Log everything.** Each prompt goes verbatim, with minor typos fixed, into the project's
  `CLAUDE_CODE_CHAT.md`, followed by your response. Head each response with the real time
  range of the work. Put decision tables **in the response**, not only in a README.
  Responses show the renders as they were then, so the next prompt makes sense; include
  images only when they changed (Lorenz P7, P8).
  - The log lives in the board's own directory (`<board>/CLAUDE_CODE_CHAT.md`), never at a
    shared repository's top level: a conversation belongs to its board. CostasLink's first
    response was written to the top level and had to be moved (the user, 2026-10-10: "They
    are specific to the project or the board, not [the repository] as a whole").
- **Questions.** Ask in the chat and in a temporary `QUESTIONS.md`; the user answers in
  `ANSWERS.md`. Both are gitignored. Check them when you can (ECP5 P1).
- **"Go all night".** Keep going, log progress in the chat as you go, and write findings
  down before a session or the power could die (GPSDO r28). Do not stop to ask what you can
  decide; record the decision and why.
- **Be opinionated.** Recommend, with the trade-off stated; do not survey options you will
  not pursue (GPSDO P14).
- **Self-critical review.** End with the most likely causes of a dead-on-arrival board and
  what mitigates each (Lorenz P3: "If I got these back and told you they didn't work, what
  would be the most likely cause?").
- **Think five steps ahead** (Rosenberg). Before drawing each block, ask:
  1. What could go wrong, and what on the board would rescue it? A DNP footprint for the
     alternative part, a 0 Ω choice, a pi network, a spare pin brought to a pad. Prototype
     the subcircuit you are least sure of, in simulation or on the bench.
  2. Can it be assembled (by JLCPCB, with no hand work), and serviced?
  3. Will it last? Heat, ageing, and voltage, current and power at the worst case.
  4. Can one part do two jobs? "The best part is no part."
  5. Is there a simpler way?
  6. Can the number of unique parts drop, especially resistor and capacitor values? Fewer
     BOM lines mean fewer Extended fees, fewer feeders and fewer chances to fit "10" where
     "10k" was meant.
- **Rev A until ordered.** It stays "rev A" until the user pays a fab. Then:
  - lock it: a git tag, a `<board>-revA.zip` of the project and `mfg/release/`, and SHA-256
    sums;
  - start `REVB_CHANGES.md`, applied all at once (Lorenz P2, GPSDO P37, P42).
- **Outside reviews.** When the board is ready, brief other LLMs and reconcile their reports
  by evidence: see the `pcb-design-review` skill for the `design_reviews/` layout, the brief
  and the rounds.
- **Git.** On a branch shared with other agents and projects, do not commit or push unless
  the user asks, and never commit another project's files. In a project's own repository,
  where the user says it is the agent's alone, **commit as you go** (Halloween board,
  2026-10-07: "Commit as you go. You are the only one on this repo, so use git").
- **Minimise what the user must do beyond uploading the JLCPCB order,** even at some extra
  cost (Halloween board, 2026-10-07). Every extra step lowers the odds that a deadline
  project is finished, most of all steps that depend on each other: printing, ordering,
  gluing magnets.
  - Prefer what JLCPCB makes and fits: PCB parts instead of printed ones, connectors instead
    of wiring, break-away tabs instead of separate orders, SMT standoffs instead of
    stick-on feet.
  - What remains goes on one list, and one print plate with no supports.
  - Count the steps in the plan, and say which depend on which.
- **Open source by default, permissive** (GPS adapters P2, 2026-10-08: "This is going to be an
  open source project with permissive license"). A new repository gets `LICENSE`
  (CERN-OHL-P-2.0 for the hardware, MIT for the scripts, the third-party notes) and
  `LICENSE-HARDWARE.txt` in its first commit, as GPiBridge has; the schematic's title block
  and the board's back say which.
- **Every request is a lesson.** When the user asks for something on one board it becomes a
  rule with its reason at once, so the user never asks for it again on the next board (ECP5
  P26: "Put this requirement and lessons on how to do it in CLAUDE_PCB.md. Do that for all
  such requests and lessons"). Use the `record-lesson` skill.
- **A fix found on one board goes to every board that copies the part, the same day**
  (motor-pid pre-order, 2026-10-29). The op-amp's review round 1 (2026-10-27) found its KF301
  footprint had read the "3.60" of the front view as a depth; motor-pid, generated from the
  same code, kept the misreading two more days (all three terminal blocks would have faced
  into the board), AMOD-and-RFMOD's KF301 still had it (body -4.0 / +3.6, table 0), and the
  op-amp's own 3D model kept the old depths. The first-designator PLACEMENT_CHECKS lookup bug
  spread the same way: motor-pid's copy dropped the lines for J3, J6 and D3/D4 and had none at
  all for D5/D6. After a
  lesson names a part or a function, grep every board for it.
- **Give a new board a new name** (AMOD-P2, 2026-10-28). AMOD-2 became PhMOD; the new passive
  board took AMOD-P2, not the freed AMOD-2, because the commits, the tutorial and the chat log
  mean the physics board by the old name. Renaming families of boards and tiles:
  [references/generators-and-edits.md](references/generators-and-edits.md).

## 2. Build system and sources of truth

Detail, audits and worked examples for this section:
[references/build-system.md](references/build-system.md).

- **One command makes everything:** schematic, PCB, checks, manufacturing files, renders,
  documents and cost estimate. `--clean` removes exactly what it generates, so it is obvious
  what lives in git (Lorenz P1, P2).
- **Reproducible from a fresh clone** on another machine (Lorenz P2, P7):
  - vendor every symbol, footprint and 3D model the board uses into the project's own
    library (a fresh KiCad AppImage has an empty `~/.local/share/kicad/10.0/symbols`);
  - relative paths only (Icepi P15): the next rule;
  - the KiCad AppImage path comes from an environment variable with a default.
- **All paths are relative** (the user, 2026-10-06: "In general, *all* paths should be
  relative"). Nothing committed may name a place on one machine: no `/home/<user>/`,
  `/Users/`, `/tmp/` or mount point.
  - Inside a repository a path is relative to the file that holds it or to the project:
    `os.path.dirname(__file__)` in scripts, `${KIPRJMOD}` in KiCad's library tables and 3D
    model paths, `${workspaceFolder}` in editor settings, plain relative links in documents.
  - A tool outside the repository (KiCad, oss-cad-suite, a bench library) comes from `PATH`
    or one environment variable, whose default may be under `~`. One module finds it for
    every script (GPiBridge's `tools/kienv.py`).
  - Scratch files go in a gitignored build directory inside the project, or come from
    `tempfile`; never a fixed name in `/tmp`.
  - Generated files count: a KiCad netlist's `(source …)`, `.kicad_pcb`'s
    `outputdirectory` and `.kicad_pro`'s `last_paths` hold absolute paths; rewrite them as
    relative in the step that writes them. CMake build directories, compiled host tests and
    KiCad's `fp-info-cache` stay out of git.
  - Before every commit: `git grep -I -n -E '/home/|/Users/|/tmp/|/mnt/'`, and with `-a`
    instead of `-I` for binary files (STEP, PDF, PNG, executables). The 2026-10-06 audit
    found about 100 offending files: see the reference.
- **One source of truth per fact**, everything else derived from it:
  - pin assignments drive the schematic, the firmware constraints and the pinout document
    (Icepi P7, GPSDO P29);
  - part numbers live in one parts table;
  - the revision and date live in one place, and the silkscreen reads them;
  - placement drives the silkscreen labels that belong to parts (GPSDO r29: hand-placed
    "H"/"T" markers drifted away from their heaters).
- **One place for every parameter and every computed passive** (the user, 2026-10-12: "Is the
  source of truth for the schematic, PCB, and simulations duplicated or all in one place (one
  place for each parameter or passive value)? If that source of truth is changed, does
  everything downstream get updated and remade? If there are hard coded things that cannot be
  traced to a single initial source of truth (often in markdown documentation), check that they
  are at least up to date."). Ask it of every board before an order, and:
  - **A value the arithmetic chooses is written once**, in the design script; the schematic
    generator reaches it through a lookup to the nearest stocked value that asserts the
    match; every note quoting it is formatted from the same results. A passive may be typed
    into a generator only when nothing else uses its value (a decoupling capacitor, a
    pull-up); a resistor that also enters a latency sum or a trim's reach is a parameter.
  - **Run-time code gets the board's numbers from a generated module**, and a test fails
    when the module differs from the build. A constant copied by hand goes stale silently.
  - **Changing the source remakes everything downstream in one command**: netlist, board,
    gateware includes, every analysis and plot, block diagrams. Any study a document quotes
    is a build step. Only the network steps (release, cost) stay manual, and the build says
    so.
  - **Hand-written documents are checked, not trusted**: every number a document quotes from
    the build has a claim in a docs step (pattern, files, current value); a claim that no
    longer matches anywhere fails too. Chat logs, review rounds and changelog rows are
    history and are not checked; mark a past number as past ("build 17 had …").
  - **A document-claims check collapses whitespace before matching** (op-amp
    `scripts/gen_docs.py`): `re.sub(r"\s+", " ", text)` first, patterns written against the
    normalised text, or every claim wrapped at 80 columns reads stale.
  - **Evaluate the design as fitted, not as computed**: rerun the arithmetic with the stocked
    values the schematic draws, in the same script, and assert the result.
  - **Then grep for the old number.** "If I change this, what still says the old value?" A
    figure no script produces is a figure nobody can update: write the script.
  The CostasLink examples (`sim/budget.py`, `gen/levels.py`, `board_constants.py`,
  `tools/doc_check.py`, the Prompt 30 audit) are in the reference.
- **Generated documents.** From the source of truth, generate the pinout (ASCII art), a
  bring-up handbook and the end-user guide (GPSDO P29); PDFs and PNGs of every sheet, layer
  plots cropped to the board outline (Lorenz P2), and 3D renders from several sides.
  Generate the README's tables and the handbooks from one per-item record so they cannot
  disagree (AMOD/RF-MOD, 2026-10-28; detail in the reference).
- **Look at the output.** Export the schematic to PDF/PNG, render the board, and look, as the
  user will. Most corrections were visible in one glance at a render. Plot one corner as the
  fab prints it layer by layer, not all top layers at once (GPSDO r45); render one tile or
  block at a time while laying it out (2026-10-25). Recipes in the reference.
- **Every page fits what is on it: sized to it, centred, filling it** (the user, 2026-10-29:
  "I've seen many examples of things hanging off of the page or the page being far too big
  for the thing on it"). The drawing spans the paper less about half an inch (12.7 mm), in
  the orientation that suits it, centred; nothing off an edge, nothing in the corner of a page
  several times its size. kicad-cli does not do this: fit after export
  (`tools/fit_pdf.py`), plot paper drawings in black, size schematic sheets to their content,
  check in code and by eye, plot an off-sheet board at another scale first, make the fitted
  PDF byte-stable, and check that no text crosses the frame. Full recipe:
  [references/pages-and-plots.md](references/pages-and-plots.md).
- **Datasheets** go in `datasheets/`, gitignored for copyright. Fetch all of them: every IC,
  connector and mechanical part. Read pinouts from the datasheet's **pin figure**, not only
  its table. Fetching recipes (Analog Devices, LCSC) are in the reference. **When you have to
  ask the user for a datasheet, ask for the link** they would click, not just the file: the
  link shows the vendor's URL pattern for next time.
- **Pad checks.** Check pad positions against KiCad's own pcbnew (`check_pads_kicad.py`),
  because rotation conventions have bitten every board.
- **The build re-reads every LCSC code against JLCPCB's own description** (op-amp
  `check_outputs.check_codes`): MPN prefix, value ("1kΩ", "100pF") and package ("0805",
  "SOT-23") must all appear in the API's description, from the gitignored cache; offline, it
  notes the date the codes were last checked rather than failing. (More in `jlcpcb-order`.)
- **Number the probe points by name, never by the order they were drawn** (op-amp,
  2026-10-24). A `testpoint()` helper that hands out TP1, TP2, ... as called renumbers every
  later loop when one is inserted earlier, and the board generator, whose wires name "TP6",
  then connects six loops to the wrong nets and shorts half the board. Keep one
  `TP_NUMBER = {"IN-": 1, "IN+": 2, ...}` table and have the helper refuse an unknown name.
- **A second board from the same pipeline** (GPiBridge Lite, 2026-10-06): one environment
  variable selects it, and one module holds every path that differs (project, checks,
  release folder, image names), so the two never overwrite each other. Refactor the shared
  code into functions first, and after each step check that the first board's schematic and
  board files come out **byte for byte** the same: with deterministic builds that is a free
  regression test, and it caught a refactor that had silently run a whole drawing section
  five times.
- **Board IDs.** To tell variants apart in one firmware image, look first for a resistor that
  both boards already have in the same place, and fit it with a different value or to the
  other rail (GPiBridge's DC pull-up, 10 k up, became the Lite's 1 k down). The spare pin
  first chosen for a strap turned out to be walled in by decoupling copper.
- **Run the stage that consumes your edit** (AMOD/RF-MOD, 2026-10-28). The pcb stage read the
  tiles' JSON written by the sch stage: an edit to a board module followed by `--stage pcb`
  alone silently built the old silk, and a debugging round went to a placement bug that was
  not there. Run `--stage sch --stage pcb`.
- **Run the full build after every block, not at the end** (AMOD jacks, 2026-10-25). Moving a
  jack moved what was behind it: the back's QR code, the long back wires, neighbouring labels,
  a ground symbol; each was caught by a check only because the build ran.
- **Scripted edits and generator hygiene** (bound every edit by what it replaces, never
  replace an unproved string, rename with a tokenizer, check renamed files' references, write
  the final expression): [references/generators-and-edits.md](references/generators-and-edits.md).

## 3. Verification gates (run them every build)

Before calling a schematic, PCB or release done, pass every gate. The full list (32 gates,
with the numbers, tools and rev A failures behind each) is in
[references/verification-gates.md](references/verification-gates.md); read it before any
release, order or "is it ready?" question. In short:

1-4. ERC clean with the netlist exported; every symbol pin against the datasheet figure; a
path trace of every signal, rail, clock and strap; no overlaps on schematic sheets (code,
`pdftotext -bbox`, eye).
5-6. DRC at least as strict as the fab's, 0 errors and 0 unconnected on the shipped, filled
file; pads where KiCad puts them, connectors pointing out in 3D, every part with a model.
7. Silkscreen: no overlaps, labels in their boxes, text ≥ 0.8 mm high, lines ≥ 0.15 mm,
nothing off the board, jumper labels beside their jumpers.
8-12. Parts with LCSC codes matching value and package, land patterns fitting (no HOLE),
stock and price timestamped; native and JLC-corrected CPL with `PLACEMENT_CHECKS.txt`;
revision and date from the source of truth (DRAFT until real); rail widths by net;
`hand_solder_bom.csv` empty.
13-16. Netlist checks (Rosenberg); design equations asserted against netlist values;
fiducials, layer markers, paste; copper balance and current capacity.
17. **The upload-readiness pass**, read from the release, not from memory.
18-24. Silk text against unit/region boxes; clock lengths and vias against the last revision;
net classes bind their nets; exposed-pad via counts; RF launches measured in the gerbers;
every page fills its page; RF net lengths against the shortest tree.
25-32. RF as laid out: simulated paths, part-to-pad distances, shunt grounds, chokes and
ferrites, supply islands, stitching, the isolation budget, every RF segment measured.
Write each gate's result per band, not only at the board's top frequency (RF-MOD, 2026-10-29).
