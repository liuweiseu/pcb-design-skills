---
name: pcb-design-review
description: How to run outside LLM design reviews of a PCB - the design_reviews/ directory layout, the brief (DESIGN_REVIEW_PROMPT.md) and what it must contain, the report's sections, the author's own review first, reconciling findings by evidence, second rounds and rebuilding after. Use when a board is ready for review, when writing a review brief or prompt for other models (Gemini, Kimi, Grok, GPT, Claude), or when reading and reconciling review reports.
---

# Outside design reviews

When the board is ready, write a brief for other LLMs and keep everything about the reviews
under one `design_reviews/` directory at the project's root (op-amp board, 2026-10-24, the
user: "make a new directory called design_reviews ... They should make a new directory within
this design_reviews directory that includes the date and their name. They should write a report
in their own directory and only ever modify files within their own directory, since many agents
will be doing the review at the same time. If they need to copy or clone any part of this
project, they should do it in their own directory"). The op-amp board's
`design_reviews/DESIGN_REVIEW_PROMPT.md` (github.com/gallicchio/op-amp-pcb) is the model; a
reusable skeleton is in
[references/DESIGN_REVIEW_PROMPT_TEMPLATE.md](references/DESIGN_REVIEW_PROMPT_TEMPLATE.md).

## Before the round

- **Fix what the lessons already ask for first.** The user (ECP5 P31): "If you think those
  things should be fixed before others do a design review, fix them now." A reviewer's time on
  a known gap is wasted; the ECP5's fiducials, layer markers, order-number marker and the bench
  input's fuse went in as build 31 the hour before the brief. Run the pcb-workflow skill's gates
  first.
- **Review the design yourself first, before reading theirs** (OWL round 1, 2026-10-09). With the
  four reports unread, the author's own pass found the one fault none of them had whole: a
  driver standing on its sense shunt, so its supply minus the shunt's drop sat under its UVLO in
  the worst corner (Kimi had the UVLO "minor", without the shunt). The author's review goes in
  the same place as the others, under its own model's name, written before reading anyone
  else's.
- **Do not change the project while a round runs.** The reviewers hold copies of a stated
  commit; the author's own fixes go into a tested patch in the author's review directory and
  are applied when the round is reconciled. The author's own KiCad may have the project open,
  so nothing in the tree is touched by reviewers either.

## The layout

- `design_reviews/DESIGN_REVIEW_PROMPT.md` is the brief; `design_reviews/README.md` explains
  the layout and indexes the rounds and their verdicts.
- Each reviewer works in `design_reviews/<YYYY-MM-DD>_<Model-Version>/` (letters, digits, dots,
  hyphens and underscores; `2026-10-24_Claude-Fable-5.1`), writes `REPORT.md` there, and copies
  the project into its `project/` subdirectory to build or change anything (an `rsync` recipe in
  the brief, excluding `.git`, `build/`, the datasheets and `design_reviews/` itself).
- The project's `.gitignore` has `/design_reviews/*/project/` so the copies are never
  committed; everything else a reviewer leaves is kept.
- The date orders the rounds: a second round is a later date, not a "2" suffix. (Boards before
  the op-amp used `design_review_<Name>/` directories at the root and `design_review_<Name>2/`
  for the second round; leave those as they are.)

## The brief must

1. **Say in bold, first, before the ground rules, that only files count** (ECP5 P32,
   2026-10-07: Grok's round-2 review was lost because it answered in its chat window and the
   user closed the windows): "Nothing you say in the chat will be read or kept. Your review
   exists only if it is a file in your directory." Make it equally plain that creating that
   directory and writing into it is **required**, not a change to the project: "do not modify
   the project" must never read as "do not write anything". Give the exact path of the report
   file, and ask the reviewer to write its verdict and findings table into it first, then fill
   it in.
2. List what the build rewrites, so "do not run the build in place" is concrete; give the copy
   recipe.
3. State the claim to break, with the board's own numbers.
4. Number the things to attack, with the file to read for each.
5. Restate the lessons' rules as checks: the reviewers cannot read this plugin, and reviewers
   who have only the git branch cannot read an uncommitted lessons file.
6. Give a tools table: each command, and what it writes and where.
7. List what is already known or decided.
8. Prescribe the report's sections:
   - verdict;
   - findings table first, then each finding in full with severity, place, evidence, fix,
     confidence;
   - the brief's questions answered by number;
   - what was checked and found right;
   - what could not be checked;
   - publishing concerns;
   - patches.

## Reconciling

- **Reconcile by evidence (datasheet numbers), not by majority** (ECP5 P15-P17). Read every
  report in full and weigh each finding by its evidence. OWL round 1's ranking (Kimi: ran
  everything, found three real bugs, wrote no report; Gemini: broad, patched, two findings wrong
  and severities inflated; Grok: best judgment, saw the magnet cap nobody else saw; GPT: thin)
  says a review's worth is in what it ran and re-derived, not in its length or its verdict.
- **Reviewers misname themselves.** Kimi K3, run through the Copilot SDK, signed its review
  "Claude (Fable 5)" and named its folder so (op-amp round 1; motor-pid round 1, the user
  confirmed the model the next day). Ask the user which model ran before trusting a directory's
  name; name review folders by what was run, not by what the report says.
- **Before committing a review folder**, move out any datasheet text or page crops it gathered
  and shorten absolute paths in its logs (motor-pid round 1).
- **A review finding is a change, not a bench item.** CostasLink's reviewers flagged the RF
  decoupling distances before the order (REVA_CHANGES 35); they were carried as "to confirm",
  and the bench confirmed them (CostasLink rev A, 2026-10-29).
- **Every finding becomes a check.** Turn each accepted finding into a build check or a rule
  (record-lesson skill), and grep every board that copies the part or code it names (pcb-workflow
  skill). What the op-amp's round 1 found, as worked examples:
  [references/op-amp-round-1-findings.md](references/op-amp-round-1-findings.md).
- **Rebuild after folding reviews in, and expect three passes.** Every change the reviews earned
  goes through the generators and the whole build. On one board the first board pass showed a
  capacitor moved beside a sensor had overlapped two coil courtyards and blocked the shared
  fault line's one pass, and an ESD diode placed 0.2 mm inside an antenna's keep-out could not be
  reached; the second showed the fault line still in pieces (the new nets shifted the routing
  order: the shared lines now go first); the third was clean. A fix that is not rebuilt is a
  hypothesis.

## A second round before ordering

(ECP5 P31, 2026-10-07.) After the fixes, write a second brief (`DESIGN_REVIEW_PROMPT_2.md` beside
the first, in the op-amp layout, the reviewers in new dated directories), so the rounds sit side
by side. It:

- says what changed since the first round;
- states the board's numbers and the claim "nothing blocks the order" for them to break;
- lists every tool with the command that runs it and where it writes;
- restates the lessons' rules as checks; the lessons added since the first round are the new
  questions.

Reviewers copy anything they want to change into a temporary place (their own directory).
