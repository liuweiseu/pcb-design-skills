# Design review brief template

Copy to `design_reviews/DESIGN_REVIEW_PROMPT.md` (or `DESIGN_REVIEW_PROMPT_2.md` for a second
round) and fill every `<...>`. Keep the order: the bold "only files count" block comes first,
before the ground rules. Delete these two paragraphs from the copy.

---

# Design review: <BOARD NAME> rev <A>, round <N>

**Nothing you say in the chat will be read or kept. Your review exists only if it is a file in
your directory.**

**Creating your directory and writing into it is REQUIRED. It is not a change to the project.
"Do not modify the project" means do not touch files outside your own directory; it never means
"do not write anything".**

**Your report file is `design_reviews/<YYYY-MM-DD>_<Model-Version>/REPORT.md`.** Create it now
and write your verdict and findings table into it first; then fill in the rest as you go.

## Ground rules

- Your directory: `design_reviews/<YYYY-MM-DD>_<Model-Version>/`, named with today's date and
  your model's name and version (letters, digits, dots, hyphens and underscores only; e.g.
  `2026-10-24_Claude-Fable-5.1`). Name it for the model that is actually running.
- Many reviewers work at the same time. Only ever create or modify files inside your own
  directory.
- The project is at commit `<COMMIT SHA>`. Do not edit it, and do not run the build in place:
  the author may have it open in KiCad. The build rewrites:
  - `<path>`: <what>
  - `<path>`: <what>
  - <...every generated file and directory...>
- To build, run a tool, or try a change, copy the project into your directory first:

  ```sh
  rsync -a --exclude .git --exclude build/ --exclude datasheets/ --exclude design_reviews/ \
        ./ design_reviews/<YYYY-MM-DD>_<Model-Version>/project/
  ```

  `/design_reviews/*/project/` is gitignored; everything else you leave in your directory is
  kept.
- Put proposed fixes as patches (diffs against `<COMMIT SHA>`) in your directory, tested in your
  copy where you can.

## The board

<What it is, who it is for, what it must do. The board's key numbers: supply, currents, gains,
frequencies, dimensions, layer count, part count, cost.>

## The claim to break

<One sentence, with the board's own numbers. Round 1 e.g.: "This board works first time at
<numbers>." Second round: "Nothing blocks the order.">

## <Second round only> What changed since round <N-1>

<Each change, with the finding that earned it and where it is now in the files.>

## Things to attack (answer each by number)

1. <Subsystem or question>. Read: `<file>`, `<datasheet>`.
2. <...> Read: `<file>`.
3. <...>

## Rules this project follows, as checks

You cannot read the lessons these come from; check the board against each.

- [ ] <Rule restated as a check, with its threshold, e.g. "ERC 0 and DRC 0 errors and 0
  unconnected on the shipped file with zones filled".>
- [ ] <Every symbol pin against the datasheet's pin figure.>
- [ ] <Every LCSC code's description matches value and package; stock is the free count.>
- [ ] <Every probe loop: what a scope ground clip there does, in watts per resistor.>
- [ ] <...the verification gates and board-specific rules; in a second round, the lessons
  added since round 1 first...>

## Tools

| command | what it does | what it writes, and where |
|---|---|---|
| `<command>` | <...> | <path> |
| `<command>` | <...> | <path> |

## Already known or decided (do not spend time on these)

- <Known issue or decision, and why.>
- <...>

## Your report: `REPORT.md` sections

1. **Verdict**: <e.g. order / order after fixes / do not order>, in one paragraph.
2. **Findings table**: number, severity (blocker / major / minor / note), place, one line.
3. **Each finding in full**: severity, place (file, sheet, reference, coordinates), evidence
   (datasheet numbers, simulation, measurement, command output), fix, confidence.
4. **The questions under "Things to attack", answered by number.**
5. **What you checked and found right.**
6. **What you could not check**, and why.
7. **Publishing concerns** (licences, copyrighted material, absolute paths, personal data).
8. **Patches**: list the patch files in your directory and what each does.
