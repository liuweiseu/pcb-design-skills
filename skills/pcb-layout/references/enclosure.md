# Enclosures, housings and screws: the detail

Read this when a board goes into a box, an extrusion or a printed housing, or when a vendor's 3D
model or a screw stack must be checked.

- **Design for a real enclosure and check it against its drawing.** ECP5 was 8 mm short of its
  Hammond extrusion, so the SMAs would not have reached the end plate (ECP5 #2).
- **Check part heights against the floor and slot positions** (ECP5 #4).
- **Behind an end plate,** faces must stand past the board edge by the plate's thickness (ECP5 R9).
- **Ask for the vendor's 3D model, and slice it** (FreeCAD: `shape.common()` with thin boxes; a
  `BoundBox` of curved faces is loose, `distToShape` is exact). NorComp's plug model showed what its
  drawing does not: pins 1.0 mm wide for their first 0.5 mm (a press fit in the recommended 1.00 mm
  hole), and the insulator flaring out in the last 0.1 mm under the flange, 0.13 mm from a housing
  opening drawn from the body's nominal size. Then put the vendor's model in the housing check
  itself, in the position assembly gives it, when the file is present.
- **Follow the force through the screws.** A plate made 0.2 mm thinner than a plug's flange height,
  "so the flange always bears", left the board resting on the plug 0.2 mm up, which the lid's screws
  would have pressed down, bending the board. Make the stack-up nominally exact and let the
  tolerances fall either way.
- **Check each screw's length against its stack** (GPiBridge, 2026-10-06): from the head's seat,
  through every part it passes, to the tip, which must stop inside its pilot hole with thread enough
  to hold. The M2 x 10 first specified would have bottomed out 0.7 mm early in a 3.5 mm plate;
  M2 x 8 leaves 1.7 mm of thread and 1.3 mm to spare. Compute it in the housing script and fail the
  build on a bad length. Size counterbores for the widest head that will be bought (an M2 pan head
  is up to 4.0 mm), as printed.
- **Measure engraved text's strokes**, not its height. DejaVu Sans Bold at 2.6 mm has 0.42 mm
  horizontal bars, under MJF's 0.5 mm guideline for engraved detail.
- **A board that grows past its host is fine** when the host's holes stay put: the Icepi adapter
  grew 15 mm past the Icepi Zero's end for a right-angle Pmod socket, with the module above ending
  short of it (§18).
