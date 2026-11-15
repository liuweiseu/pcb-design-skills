# Generators, scripted edits and renames

Companion to SKILL.md §2. Read it before a scripted edit of a source or document, before
renaming boards, tiles, nets or files, and when writing generator code.

## Scripted edits

- **Bound every scripted edit of a hand-written document by the thing it replaces.** A table
  copied from a generated file ends at its last row, not at the next `##` heading. Keep a
  scratch copy of the document before the edit and diff after it. CostasLink's PLAN.md lost 70
  lines of prose after a refreshed table (Response 10). The project had never been committed,
  and the text came back only from the session transcript.
- **Never replace a string you have not proved non-empty** (AMOD-2/RF-MOD-2, 2026-10-25). A
  scripted edit computed `old` as a slice that came out empty, and `s.replace("", new)` inserted
  `new` between every character of a 50 kB board module. It was recovered by striding the
  corrupt text (`s[L::L+1]` with `L = len(new)`), but every scripted edit now asserts `old` is
  non-empty and occurs exactly once, and a scratchpad copy is taken before each one.
- **Write the final expression, not a placeholder** (AMOD-C/M/B, 2026-10-28). `X if False else Y`
  left in while iterating reads as logic and is dead code; write Y, or a TODO the build fails on.

## Renames

- **Give a family of boards one letter each, and name a tile by its letter and a number, in
  lower case** (AMOD-and-RFMOD Prompt 19, the user: "If we can have a nice, well justified
  single-letter designator for each board, it would make everything much more clear", and "D11,
  Q11, C11, etc look like a reference designators for diodes, transistors, and capacitors. d11,
  q11, and c11 don't look like obvious electronics or PCB things."). The letter is the initial of
  what the board is about; board names keep their capitals, ports are capitals, titles mixed
  case.
- **A rename must never move a name onto something else.** Keep every letter on its board and
  retire, never reuse, the names that go: then a reference missed in the update points at
  nothing instead of at the wrong tile. Reassigning A from the active board to the passive one,
  or renumbering a board with gaps, would have turned every stale "A4" or "R5" into a silent
  error. Avoid letters that already mean something on the boards (s11 is a reflection
  coefficient) and letters that read as digits (i, l, o). The same holds for board names: see
  "Give a new board a new name" in SKILL.md.
- **Rename with a tokenizer, not a regular expression.** The same two characters were tile
  names, USB-C pin names ("A4": "VBUS"), local net names ("N1", "P1"), a 4046's R1 and C1, a
  paper size (an A1 sheet), a PBM header ("P1\n") and the reel suffix of part numbers
  (ADL5350ACPZ-R7). Change a whole-string token only where the code makes it a tile (the tile
  constructor's first argument, the silk number, the keys of the per-tile dicts), change prose
  by word with a list of protected phrases, then grep the diff for a changed token glued to a
  hyphen or a part number. Net names built on the tile name ("/X3_V33") hide from a
  word-boundary search: search for the name followed by an underscore too.
- **A document can hold two numberings**: rename only the as-built sections (see
  build-system.md, "Generated documents").
- **Rename the file with its references** (AMOD-C/M/B, 2026-10-28). An appendix's text was
  changed to new board names and its images kept the old file names: three broken pictures,
  found a day later. After any rename, loop over every referenced file and check it exists.

## Build stages and determinism

- **Keep rebuilds deterministic**: an unchanged design gives byte-identical schematic and board
  files, and fitted PDFs too (Ghostscript's `-dOmitInfoDate -dOmitID -dOmitXMP`). Then a
  refactor is checked for free by comparing the outputs byte for byte (SKILL.md, "A second board
  from the same pipeline").
- **Run the stage that consumes your edit.** A later stage that reads an earlier stage's output
  (the pcb stage reading the tiles' JSON written by the sch stage) builds stale content when run
  alone: run both (`--stage sch --stage pcb`).
- **Run the full build after every block**, not at the end: a moved part moves what was behind
  it, and only the checks see it (AMOD jacks, 2026-10-25).
