# One relation per row, enforced (CostasLink Response 15)

Read when placing, reserving room for, or checking connector names.

The user: "There should be a big-font silk screen right next to the connector, so it's
obvious what it's for. For example, "TRIG A" seems fine, but "TRIG B" is between two
SMAs and off to the side ... If there are SMAs in a row, their labels should all be in
the same relative orientation ... This consistency requirement needs to be enforced."

The same rule holds on the schematic sheet (pcb-schematic skill, "Labels in a row stand
alike").

## What a row is

Connectors of one footprint in a line. The SMAs along one edge are one row however far
apart; taps and test pads a few millimetres apart are one.

## The relation

- Every name in a row stands on the same side of its own connector, at the same gap,
  centred on its signal pin the same way, at the same angle and size.
- Its limit follows the name the same way, or is printed once for the row when all share
  it.
- Rev A's first try put "TRIG B" above its jack, between two jacks, while "TRIG A" sat
  right of its own. Its test pads' rails alternated above and below. Its window monitors
  had three names above and one below. All three fail the rule.

## Sizes

Big: 1.5 mm for an SMA, 1.0-1.2 mm for a tap or a pad. Long names on a tight pitch
(rails on 4 mm pads, four U.FL at 5.5 mm) stand turned, one column per connector.

## Reserve the room first

- Decide each row's side in the placement plan and reserve its strips **before** the
  small parts are placed (CostasLink `gen/placement.py` `LABEL_ROWS`, `HEADER_LABELS`).
  A label laid after placement finds the room already taken, and rev A's first build
  dropped five SMA names silently.
- A name with no room means moving a part. Never move the one label off the row's
  relation.
- A reserved strip moves the small parts placed by rule, and the move cascades. One strip
  over a selector's middle pin pushed one capacitor and reshuffled seven of the TX
  synthesizer's parts. The synthesizer's rail then failed to route.
  - Measure every moved part against the pin it serves.
  - Pinning a moved part back changes the placer's order and shuffles its neighbours
    instead, so move the strip that caused it.
  - A selector's function name can go below the jumper as well as above.

## The labeller's priorities

- The labeller takes the planned side at a smaller size before any other side at a
  bigger one. J502's name at 1.2 mm on an unplanned side took the room planned for
  JP101's labels.
- Labels placed later (part names, designators) keep 0.8 mm from a connector's name, and
  2 mm along its line: "VCXO" beside "REF OUT" read as one name.

## The check

Check it on the written board, independently of the placer, and fail the release on it
(CostasLink `tools/label_check.py`, run by `make_release.py`):

- Every name must be present, at least 1.0 mm tall (SMA) or 0.9 mm (tap, pad), and its
  own.
- Judge ownership from the name's near end, where a reader ties it to a part, with no
  other body nearly as near.
- Each row must hold one relation.
- A limit left off is a named exemption with its reason, printed on every run.
