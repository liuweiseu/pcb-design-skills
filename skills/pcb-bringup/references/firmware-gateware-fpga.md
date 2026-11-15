# Firmware, gateware and FPGA tools (CLAUDE_PCB.md §9)

## Firmware is part of the design

A board with an MCU or FPGA needs its first firmware written and building before the board
is ordered. That shakes out pin and clock choices: the GPSDO's I2C driver could not *read*
until bring-up (GPSDO r30 #28).

## Gateware before ordering, and its reset state against the board

(CostasLink Response 15.) Writing the safe state (`safe()`: TX muted, loop held, receive) is
what found that the board's own idle was not safe (`pcb-schematic`, "rests where an absent
host leaves it"). Keep a REVA_CHANGES list while writing it, each entry found / what /
change / state.

## FPGA tool facts that cost hours (CostasLink Response 15)

- A Vivado block design's module reference needs a Verilog top, not SystemVerilog.
- Never edit the sources while Vivado builds: the module reference's out-of-context run
  goes stale and the core comes out a black box, with no error.
- Vivado 2024.1 segfaults (exit 139) in synthesis on a function called with a variable
  part-select of a parameter (`morse(CALLSIGN[8*ci +: 8])`): build the table in a generate
  loop with constant indices.
- Yosys merges identical flip-flops even when marked `keep`; a copy of a register per block
  (a register bus near each block, a reset tree) survives only as its own `keep_hierarchy`
  module. Vivado honours either.
- nextpnr's Fmax moves 10 % from seed to seed on a full ECP5: once the paths are pipelined,
  let the Makefile try seeds until one meets the clock rather than chase the last
  nanosecond.
- Every constant compare (`x > 1`, `x <= 1`) may become a carry chain in Yosys; write it as
  a reduction (`|x[31:1]`).
- A block RAM's output on the ECP5 is 5.6 ns clock-to-out: register it.

## Run the host's driver against the RTL

(CostasLink `gateware/driver/test_sim.py`.) Icarus reads commands from one named pipe and
answers on another (`$fscanf`, `$fwrite`, `$fflush`), so the Python that will run the
experiments drives the simulated core with a loopback model. End every command on a falling
edge: a model knob changed between commands otherwise races the model's own rising-edge
process, and a flipped bit or a trigger lands a clock off.

## Test the pin layer against the datasheets on a PC

(GPiBridge `test_wire.c`.) Stub the SDK's GPIO calls and model the chips on the other side
from their function tables. Then check, after every pin change, that no wire has two
drivers and nothing is driven into an unpowered chip. Plant a bug or two to prove the test
can fail.

## Open-drain on an RP2350 (GPiBridge Lite)

Assert by enabling the pin's output, release by making it an input, and set the pad's output
override to LOW (`gpio_set_outover(pin, GPIO_OVERRIDE_LOW)`) so no software path can ever
drive the line high. `gpio_init()` rewrites the pin's whole control register and clears the
override: set it after. A host test that checks, after every pin change, that no output is
on without the override makes the order a tested fact.

## Check the protocol with somebody else's decoder

Record the simulated bus as a VCD and have sigrok-cli's decoder read it back (GPiBridge
`firmware/test/sigrok_check.py`). An engine and a simulator written by the same author share
their misunderstandings; an independent decoder does not.

## Give the board a way to see itself

A spare core sampling its own pins into a VCD is a logic analyser with no wires, and it
answers "how do I probe this?" for most problems.
