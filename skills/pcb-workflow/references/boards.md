# The boards behind the lessons

Read this to decode a citation such as "(Lorenz P3)", "(GPSDO r29)" or "(op-amp, 2026-10-24)".
P = prompt, r = round of the board's chat log. Board names are the provenance of each rule;
keep them when you quote or move a rule.

| board | outcome | where the history is (in the board's own project) |
|---|---|---|
| **AI UNLEASHES CHAOS** ("Lorenz": Lorenz attractor) | Built by JLCPCB; worked first time, including the RGB lamp and the sync input | `CLAUDE_CODE_CHAT.md`, `docs/MANUFACTURING.md`, `docs/DESIGN_REVIEW.md` |
| **GPSDO-PYNQ-Z2** | Built by JLCPCB; brought up; rev B list from real measurements | `README.md` (rounds and prompts), `REVB_CHANGES.md`, `DESIGN_REVIEW_RESPONSE.md`, `HANDBOOK.md` |
| **Icepi Zero JLC rebuild** (`IcepiZeroADCDAC/jlcbuild`) | Built by JLCPCB after a wrong switch stopped the line | `jlcbuild/README.md` |
| **ECP5-2ADC-2DAC** | Designed, five LLM reviews reconciled; rev A built by JLCPCB (two assembled boards), with its USB programming port dead on arrival (FT2232H VPHY/VPLL on 1.8 V, D+/D- swapped; pcb-workflow "Two checks"); bring-up planned 2026-11-15, board A powered 2026-11-16 | `CLAUDE_CODE_CHAT.md`, `DESIGN_REVIEW_RESPONSE.md`, `BRINGUP.md`, `bringup/REVB.md` |
| **IcepiZeroADCDAC** (maximal/minimal) | Abandoned: the BGA would not escape with an autorouter | `README.md` |
| **GPiBridge** and **GPiBridge Lite** (USB-C to GPIB; public, github.com/gallicchio/GPiBridge) | Both ordered from JLCPCB on 2026-10-06, 2 assembled of each; received in November; bring-up prepared 2026-11-15 (every step run against the firmware on a simulated board, seven firmware faults fixed before any board had power), no board powered yet | `CLAUDE_CODE_CHAT.md`, `PLAN.md`, `DESIGN_NOTES.md`, `BRINGUP.md`, `bringup/STATUS.md`, `bringup/REVB.md`; its `CLAUDE_PCB.md` is a public snapshot of the source of these skills |
| **Halloween board** (`halloween1`: a cute, physics-y board for a young child, the first with real power: 12 V, amperes into PCB coils) | In design from 2026-10-07 | `CLAUDE_CODE_CHAT.md`, `PLAN.md` |
| **GPS GH adapters** (JST-GH GPS port adapters, Holybro 10-pin to Cube 8-pin and an any-to-any debugging hub; public, github.com/gallicchio/gps-gh-adapters) | Designed 2026-10-08/09, rev A, not yet ordered | `CLAUDE_CODE_CHAT.md`, `research/PINOUT_EVIDENCE.md` |
| **LAoE Discrete Op-Amp** ("op-amp": the Lab 5L op-amp of *Learning the Art of Electronics* from the book's six SOT-23 2N3904/2N3906 on a 100 x 100 mm board whose silkscreen is the schematic, for a first electronics lab; public, github.com/gallicchio/op-amp-pcb) | Designed 2026-10-24, rev A; design review round 1 (author, Gemini 4 Argon, Kimi K3) closed and applied 2026-10-27 (`design_reviews/`); the 741-style current limit replaced by one 330 ohm resistor inside the loop 2026-10-28; pre-order checks of 2026-10-29 (JLCPCB's drawings overlaid by the upload CPL, pin names, pages fitted, one rail missing simulated) passed; ordered, and a rev A board amplified a sine by hand on 2026-11-10; bring-up planned and rehearsed on a simulated bench 2026-11-15, not yet run on a board (pcb-bringup skill) | `CLAUDE_CODE_CHAT.md`, `docs/DESIGN_NOTES.md`, `docs/HANDBOOK.md`, `BRINGUP.md`, `bringup/REVB.md` |
| **LAoE PID Motor Control Loop** ("motor-pid": Lab 10L of *Learning the Art of Electronics*, a motorized fader held to a target by P, D and I on a 170 x 120 mm board whose silkscreen is the schematic; seven LM321 singles, a D2PAK push-pull on 2 oz copper, a PTC fuse ahead of DRIVE; public, github.com/gallicchio/motor-pid) | Designed 2026-10-24/27, rev A, design review round 1 closed (three reviews applied); pre-order checks 2026-10-29, BOARD_DATE 2026-10-29, being ordered | `CLAUDE_CODE_CHAT.md`, `docs/DESIGN_NOTES.md`, `docs/HANDBOOK.md` |

Boards cited in the dated lessons but not in the table above: **CostasLink** (CostasLink-PYNQ-Z2,
an RF link whose rev A receive chain was measured on the bench), **OWL** (four outside reviews in
round 1, 2026-10-09), and the **AMOD / RF-MOD family** (AMOD-P, AMOD-A, AMOD-P2,
AMOD-C, AMOD-M, AMOD-B, PhMOD, RF-MOD, RF-MOD-2, IQ-MOD: 100 x 100 mm tile boards of 20 mm
cells, each cell a circuit between two SMA jacks, in the AMOD-and-RFMOD project; bring-up of nine boards planned 2026-11-15 in its `BRINGUP.md` and `bringup/`, with AMOD-A and RF-MOD rev A's Pmod plugs marked non-standard), **SyzygyRadioBoard** (cited for a DNI inductor in the DNP check).
