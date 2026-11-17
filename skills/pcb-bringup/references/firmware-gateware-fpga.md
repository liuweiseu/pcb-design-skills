# Firmware, gateware and FPGA tools (CLAUDE_PCB.md §9, §31, §33)

## Firmware is part of the design

A board with an MCU or FPGA needs its first firmware written and building before the board
is ordered. That shakes out pin and clock choices: the GPSDO's I2C driver could not *read*
until bring-up (GPSDO r30 #28).

## Bring the board up on a PC before it has power

(GPiBridge Prompt 12, 2026-11-15. The user: "If there is any firmware for this project, write it
and simulate it as best you can before connecting any hardware. This includes one-off things just
for the bringup process.") The evening before the first board was plugged in found seven firmware
faults, none of which the existing host tests could see (GPiBridge `bringup/REVB.md` section 2).
What found them:

- **Put the firmware behind a pseudo-terminal** (`firmware/test/sim_board.c`): everything above
  the vendor SDK, on a model of the chips at its pins, answering on a pty that stands for its USB
  serial port. Then the real host software runs against the real protocol code:
  lab-instrument-control's `Link` and its HP 33120A driver found that a data line over 8192 bytes
  was dropped (a 16,000-point waveform is 32 kB). Test the longest message the host library
  really sends, not the longest the test author thought of.
- **Run each bring-up step against it, with faults planted** (`pytest bringup/`): a good board
  must pass and each fault (no 5 V, a switch stuck on, an open joint, a bridge, a connector turned
  round) must fail the step that is there to catch it, by name. A step that has never failed in
  simulation will not be believed when it fails at the bench.
- **Several simulated boards on one simulated cable, counting bus fights.** Two adapters, both
  started by USB, drove IFC against each other before the test had begun: the firmware now looks
  for another controller before it takes the bus. Count every moment two drivers oppose on a line,
  and require zero.
- **Assert "nothing was touched" as well as "the right thing happened".** The check "this board
  asserted no line while it looked" found that the pads' pull-downs made a listening SN75161B
  assert NRFD, NDAC and SRQ for the moment its 5 V came up. Order pulls and power switches so that
  a powered receiver never sees a floating or wrong-way input.
- **Read every early-return path of a function that drives pins.** `gpib_serial_poll()` skipped
  its transfer with the bus off, then ran the lines that end one, into unpowered chips. Plant the
  bug back to prove the new test sees it (376 breaches).

## The first bugs a board finds are in the code no simulator runs (GPiBridge A1, 2026-11-16)

Every protocol, pin and bring-up step had run against the firmware on a PC; the board's first
morning found two bugs, both in `main.c`'s start-up, watchdog and flash code, which the simulator
stubbed. List the unsimulated code in the firmware's README, and give each of its paths a bench
check that runs on day one:
- a setting written and read back across a reboot **from a fresh power-up**;
- three deliberate reboots in a row;
- the crash failsafe made to fire on purpose (`++t crash`).

## RP2350 and the Pico SDK (2.1.1): two traps found on the bench (GPiBridge A1, 2026-11-16)

- **`watchdog_caused_reboot()` is true after a deliberate `watchdog_reboot()` as well.** A "three
  crashes in a row go to BOOTSEL" failsafe built on it sent the board to BOOTSEL after `++rst` and
  two re-enumerations. Count crashes with `watchdog_enable_caused_reboot()`, which is a timeout of
  the watchdog the firmware enabled (the SDK's mark in SCRATCH4).
- **`flash_safe_execute()` refuses, returning `PICO_ERROR_NOT_PERMITTED` and writing nothing** (an
  assert only in Debug builds), unless the other core is a lockout victim. A core 1 started only
  on demand (a capture) meant no setting was saved in any power-up that had not run one. Start
  core 1 at boot, or build with `PICO_FLASH_ASSUME_CORE1_SAFE=1` if it never runs, and put the
  refusals in the status command, not only on a log nobody reads.

## A check that passes because of what ran before it proves nothing (GPiBridge `bare`, 2026-11-16)

"A setting survives a reboot" passed only because the capture before it had started core 1 (the
`flash_safe_execute()` trap above). Put each check where it depends on nothing earlier in the
step, or run it first.

## When a step fails, compare bytes, and distrust the message (GPiBridge A1, 2026-11-16)

- "Did not come back after a reboot" was the third reboot, not the first; an hour of bisecting the
  wrong one ended when the step's and a hand replay's sent bytes were logged and diffed
  (`GPIBRIDGE_WIRE_LOG`).
- **A wait must say which event it waited for and what it saw.**
- **Two bench facts from the same morning:**
  - closing a USB serial port blocks while the device is hung (the kernel's control transfer
    waits), so time a hang from the event and not from after `close()`;
  - `picotool` called the instant BOOTSEL appears in sysfs is not answered: retry for a few
    seconds.

## Two of your own boards are each other's test fixture: give the firmware a raw mode

(GPiBridge `++t raw`, `bringup/run.py pair`, 2026-11-15.) One board asserts each line alone, the
other must read exactly that line, then the other way, in every driver mode. That walks every
driver, receiver and connector joint of both, and names an open joint, a bridge or a connector
turned round by contact number. A lone board's self-test sees its own receive paths and shorts; it
cannot see the far side of its connector's joints.

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

### More, from ECP5-2ADC-2DAC's bring-up gateware (§31, 2026-11-15)

- `ecppll` fits only its first output exactly: asked for 50, 125 and 25 MHz it gave 52.08 or
  150 MHz for the others. Write the dividers by hand from one VCO that divides to all of them,
  and read the frequencies nextpnr derives.
- Yosys rejects `output reg a = 0, b = 0` in a module's port list (the second name is taken for
  an interface port): one declaration per initialised port.
- A later `IOBUF` line for a port replaces the earlier one in nextpnr's LPF reader, so one
  design's pulls and drive strengths can be a short file appended to the generated one. Count the
  `PULLMODE` words in the `.config` to see that they arrived.
- A block that meets 125 MHz built alone met 98 to 117 MHz inside the full design: ask for a third
  more than the clock when a block is built by itself, and never let an arithmetic compare feed a
  clock enable in the same cycle.

## Read a generated constraint file against each pin's job (ECP5, §31)

A rule that pulls every bidirectional pin up is wrong for a USB device's D+ and D- (a host's 15 k
pull-downs then sit against it) and for a hot-plug input. The ECP5 board's generated constraints
pulled its USB lines up inside the FPGA; writing the USB port's bring-up test found it.

## An ECP5 design can build clean, meet timing, load, and still be dead: count the global clocks (ECP5 board A, 2026-11-16)

- **What happened:** the bring-up design promoted nine clock nets to globals (nine DCCA). It
  loaded over JTAG and drove its pins, yet everything clocked by the TCXO was dead: no UART reply,
  no PLL lock. Every build with eight globals or fewer worked, whichever block was removed
  (nextpnr-0.11.1-83).
- **The fix:** `(* noglobal *)` on clock inputs that only feed frequency counters, leaving five
  globals (ECP5-2ADC-2DAC REVB 16).
- **How it was found, in order:**
  1. an echo bitstream (`assign uart_tx = uart_rx`) proves the USB-UART path both ways;
  2. a minimal UART and register-bus design proves the clock and the bus;
  3. then bisection: drop blocks from the full design until it answers.
- **The rule:** keep the bring-up design's global count low and read it in every build's report (a
  clock that only feeds a counter does not need a global), and keep an echo and a minimal design
  beside the full one. Simulation and co-simulation passed this design every time. Only "load it
  and read the ID on the board" shows this class of fault.

## Gateware written for a bring-up should need the least of its host (AMOD/RF-MOD, §30)

`pmodbench` runs from the host board's oscillator, its serial channel and its Pmod pins: no PLL,
no converter, no memory. It can be used as soon as the host passes power, JTAG and a first
bitstream, whatever its later stages find.

## Run the host's driver against the RTL

(CostasLink `gateware/driver/test_sim.py`.) Icarus reads commands from one named pipe and
answers on another (`$fscanf`, `$fwrite`, `$fflush`), so the Python that will run the
experiments drives the simulated core with a loopback model. End every command on a falling
edge: a model knob changed between commands otherwise races the model's own rising-edge
process, and a flipped bit or a trigger lands a clock off.

### Run the bench procedures against the RTL, live (ECP5, §31)

The driver that will talk to the board talks to the simulator through the two named pipes, and the
procedures run on top of it, branching on what they read.
- **The transport owns time:** its `sleep()` shortens every wait by one factor and its `time()`
  runs that much faster, so timeouts keep their meaning; the counters' gate is a parameter.
- **The bench is knobs:** which source each input's cable comes from, the jumpers, a card, a
  host, a monitor, a link. Models of what sits on each connector need only the behaviour the test
  relies on, but that part true (a card's CRC-16, a host that resets the bus, a PHY on its own
  clock).
- **What the first run found:**
  - a frequency counter's first gate after a clock is switched straddles the switch (read the
    second);
  - a detached USB port with a host's pull-downs is "both lines low" too (zero the reset timer
    after attaching);
  - resynchronising a serial protocol means discarding what the board already sent.

### Play the plan's own calls through the driver into the RTL (§31)

The bring-up's test table lists every call it will make on the host. A test makes each of them, in
order, through the real driver into the simulated FPGA with a model of that board's tile plugged
in. It proves the plan, the driver and the gateware agree before a board is there; it took two
minutes to run and an hour to have.

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

### A check that skips itself when its tool is missing has never run on that machine

(GPiBridge, 2026-11-15.) `sigrok_check.py` said "skipped (no sigrok-cli)" and passed on the bench
PC; installed, sigrok 0.6 named the VCD's channels `gpib.DIO1` where 0.5 said `DIO1`, and 0 of 12
recordings decoded.
- Install every tool a check wants on the bench PC before bench day.
- Make "skipped" a loud line in the build's summary.
- Write files that do not depend on one version's naming (no `$scope` in a VCD meant for sigrok).

## Give the board a way to see itself

A spare core sampling its own pins into a VCD is a logic analyser with no wires, and it
answers "how do I probe this?" for most problems.
