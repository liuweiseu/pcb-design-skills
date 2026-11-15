# Through-hole RF launches (SMA and similar)

From CLAUDE_PCB.md §14 (CostasLink Prompts 32-33; the SyzygyRadioDrivers field-solver study;
a SyzygyRadioBoard design checklist). Read this before placing any
through-hole RF connector, changing a stack-up or connector, or writing a launch gate.

## Why the stock footprint is wrong above a GHz

**The stock SMA footprint is wrong for a launch above a GHz, and it has bitten twice.**
- SyzygyRadioDrivers' first test board: 70 % of the power reflected, found on the bench with a
  VNA. Four changes that cost nothing to fabricate got it back to 20 %.
- CostasLink build 36: 85 % in the gerbers, 8 dB at each of five jacks, found by a gerber parser
  one commit before an order of about $1,000 of boards.

What the vendor's and KiCad's default pad does:
- the through-hole pad carries its full ring on every layer (`remove_unused_layers no`): a 2 mm
  disc 0.2 mm above the ground plane and a flange at every inner layer;
- the planes come up to the barrel at the zone's clearance (0.25-0.9 mm);
- the top pour hugs the pad at the line's CPWG gap;
- DRC never says a word, because each of those is "correct".

Together they are 2 pF across a 50 Ω line at 5.8 GHz.

## Standard practice for every through-hole RF launch, on every board from now on

1. **The signal pad on the end layers only** (`remove_unused_layers yes` + `keep_end_layers yes`),
   confirmed in the plotted inner layers, not in the footprint file (KiCad 9 and 10 rewrite an
   explicit layer list).
2. **An antipad on every inner and back layer, drawn as a rule area without copper fill, in the
   generator** (CostasLink: radius 2.2 mm on a 1.6 mm 4-layer board; the study: 4.0-4.6 mm across
   on its 6-layer).
   - Never a DRC `hole_clearance` rule: a wrong property name in its condition matches nothing,
     silently.
   - Never the pad's own clearance property: it binds every layer, every connector with that
     footprint and every track, and the generator's router does not know it.
3. **The top pour the solved distance off the pad** (0.9 mm on both boards), as a rule area on the
   top layer too.
4. **A plain round pad of the vendor's diameter, symmetric under rotation.**
   - No taper: the study's "1.0 mm taper" was hidden inside its pad disc; CostasLink's real 1 mm
     taper from the pad's edge moved S11 by 0.03 dB.
   - No smaller pad for an annulus under 0.3 mm.
5. **Nothing else inside the legs on any layer:** a router keep-out over the connector's body (the
   LNA's supply track once circled J101's pin inside the legs to get across the line).
6. **The field solve re-run on the actual stack and connector with the study's model**, anchor
   first, the result and the gerber distances written up (`docs/LAUNCH.md`).
7. **The gerber parser as a release gate** (§10, item 22; see the `pcb-workflow` skill).

## Check the launches in the plotted gerbers, not in the board's settings

(CostasLink, Prompt 33.)
- A DRC rule meant to hold the planes 1.35 mm off an SMA's pin never matched (a wrong property
  name), DRC said nothing, and the gerbers had a 1.8 mm antipad where the design said 4 mm; the
  top pad sat over the ground plane at 0.21 mm.
- Draw the antipads and the ground relief under RF pads as rule areas in the generator (explicit
  copper, whatever the DRC engine thinks).
- Gate the release on a parser of the copper gerbers (`tools/launch_check.py`):
  - no pad flash at the pin on the inner layers;
  - the planes the designed radius off it;
  - the plane under each relieved pad clear.
- The user, from the SyzygyRadioBoard study: the KiCad defaults for a connector's through-board
  transition are not right.

## A new stack or a new connector means the launch study is run again, not copied

(CostasLink, Prompt 33.)
- The SyzygyRadioDrivers field solve (`SMABridgeTestAnalysis/fieldsolver/launch_model.py`,
  validated on the V1 and V3 test boards) is parametric. `CostasLink-PYNQ-Z2/sim/launch/launch_cl.py`
  is the same model with the 4-layer stack and the BWSMA-KWE-Z001 substituted.
- Order of work:
  1. reproduce one of the study's cached points with its own code on the machine at hand (the
     anchor: S11 and IL to three figures);
  2. run the study's rasterised-metal check on every new geometry;
  3. sweep the knobs the study showed matter (inner antipad, pad diameter, taper, pad clearance to
     the top pour, B.Cu clearance) and read the optimum off the sweep.
- Cost: twelve to twenty solves of 1-2 M cells, six at a time, in one to two hours on 32 cores
  (openEMS through the user's `em-env`).
- The user: "I'd rather spend design time and simulation time here to get it right."

## Related launch-void cases (tile boards, §23)

- **Calibration standards on a board: the SHORT gets no launch void.** A launch void (no top pour
  within 1.9 mm of the pin) leaves a pin on the ground net connected to nothing; the short wants the
  pour all round it. The OPEN keeps its void. The LOAD can sit at the end of a few millimetres of
  50 Ω line, outside the jack's courtyard: a matched line is still a match.
- **A floating jack needs its legs on their own net and a void on every layer.** A 1:1
  transformer's OUT whose shell is the secondary: the four legs on their own net joined by a U of
  track, no plane within 5.6 mm, the schematic labelling the shield instead of grounding it.
