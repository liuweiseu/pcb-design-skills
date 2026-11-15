# Low-latency and detection links: theory and budgets

From CLAUDE_PCB.md §14 and §13 (CostasLink: PLAN.md section 19, its `sim/` scripts, docs/SYSTEM.md).
Read this when designing a radio, optical or wired link whose figure of merit is latency or
false-alarm rate rather than throughput, when setting detection thresholds, or when choosing a host
FPGA, a SERDES or a channel filter for such a link.

## Noise, thresholds and decisions

- **The decision SNR of a zero-IF arm is P / (kTF B), B its baseband noise bandwidth.**
  - The I noise is the RF noise of both sidebands, 2B wide, so a sign comparator errs with
    probability Q(√snr), not the textbook Q(√(2 Eb/N0)) with Eb/N0 = snr.
  - CostasLink's rates script used the textbook form, and every coherent range was 3 dB optimistic.
  - An RF-level simulation (carrier, white noise, ideal mixer, brick-wall B) settles it in ten lines.
- **A link that idles counts false events per hour, not errors per decision.**
  - Noise carries the idle point over a threshold u σ away at Rice's rate, ν0·exp(−u²/2), with ν0 ≈
    the filter's corner. For one false event an hour at 100 MHz, u = 7.3.
  - A wrong message needs only about 3.7 σ, for 1e-4 of the messages sent.
  - Set the idle-side threshold from the idle, 7.3 σ out, not halfway to the message.
  - The FPGA finds that place by counting each comparator's false events (CFAR, as radar does).
- **For latency, a decision boundary should pass through the idle point, not the origin.**
  - The filtered signal moves from the idle point to the message in a straight line.
  - A boundary through the idle point, or a threshold set from it, is crossed at a fraction of the
    rise that falls as the SNR rises.
  - A line through the origin (sign(I), a phase comparator) is crossed at a fixed fraction whatever
    the SNR: half the rise for a 180° flip.
  - CostasLink's search is `sim/constellations.py`.
- **No receiver decides sooner than t ≥ z²·N0 / P**: the received energy must clear the false-alarm
  threshold z ≈ 7.5 σ (a sequential test at best).
  - CostasLink's board alone gives 85 ps at the bench but 3.1 ns at 3 km; a +20 dB PA makes that
    31 ps.
  - At range, transmitter power is a latency knob before bandwidth, and widening the bandwidth speeds
    a noise-set threshold crossing only as 1/√B.
  - Before buying speed in the radio, find where the time goes: in a responder the clocked FPGA path
    dominates (rev A's decoder ~59 of ~71 ns), and a CML path outside the FPGA is the big step
    (PLAN.md section 19, `sim/latency_roadmap.py`).
- **Where a threshold is set by the noise (CFAR), widening the detection filter speeds the rise but
  moves the threshold out:** the two nearly cancel, so check before widening (§13, `sim/hosts.py`).

## Filters, channels and interference

- **In a latency link, selectivity costs delay at both ends: about order/(2π·f_c) each.**
  - To slot CostasLink into a WiFi channel, a 4th-order filter at both ends adds ~17 ns for 80 MHz
    and ~33 ns for 40 MHz. That turns a 2.4 ns path into 20-36 ns.
  - A one-pole "channel" is cheap but rejects the neighbour by only ~7.5 dB.
  - Get interference immunity from what costs no time: directional antennas, the channel choice,
    gating the receiver to when an event can come, and a decoder that wants a settled vector.
  - Put the idle carrier on the interferer's spectral nulls rather than narrowing (PLAN.md section 19,
    `sim/wifi_channels.py`).
- **A coherent receiver's "RSSI" from an averaging ADC works only when locked.**
  - On a zero-IF arm, unlocked noise and interference average to zero, whatever their power.
  - If the receiver must ever measure the band it is not locked to (an interference survey, a channel
    choice), give it a detector: an RMS or log detector after the channel filter, not a broadband RF
    one at the input.
  - Or use what CostasLink rev A had to fall back on: window comparators with DAC thresholds and a
    counter. Duty against threshold is the amplitude distribution, and its probit line gives σ
    (PLAN.md section 19, `survey()`).

## Rise time and the whole chain

- **A link's rise time is the transmitter's and the receiver's together.**
  - CostasLink's 94 MHz receiver arm rises in 3.9 ns, but the PYNQ's 200 Ω header resistors into
    about 10 pF add 4.4 ns at the transmitter's ladder: 6.6 ns end to end, as if the link were 53 MHz
    wide (`sim/trajectories.py`).
  - Budget the transmitting pins' RC with the arm, and simulate the jump from the idle with every
    pole in it before choosing thresholds and decision delays.
- **Before choosing a faster host, add up every term of the latency chain for each host, the FPGA's
  sampling included** (CostasLink, Prompt 20, `sim/hosts.py`; also in `highspeed-digital`).
  - The Icepi Zero's missing 200 Ω header resistors save 2 ns over the PYNQ-Z2 only if its inputs
    sample at 656 Ms/s (GDDRX2); at the 200 Ms/s its first gateware used, the 5 ns grid gave all of it
    back and tripled the jitter.
  - A carry-chain TDC (CARRY4, CCU2) beats any sampling grid, on any host, without new hardware.
- **Budget the whole chain before buying radio nanoseconds.**
  - In CostasLink's QPV prover, the Pockels driver and cell (25-55 ns) and the photon detector
    (10-60 ns) dwarf a well-made radio path (~25 ns). The responder's antenna cables count
    (3.9 ns/m each way; 10 m is 78 ns).
  - So the radio should be robust (decide on the first edge, veto with a slower, more sensitive path,
    answer "invalid"), not heroic.
  - Links between trusted nodes need precision, not latency. A herald can wait in a fibre coil: 1 km
    is 4.9 µs for ~0.2 dB.
  - (docs/SYSTEM.md, `sim/system_budget.py`.)
- **A transceiver (SERDES) buys throughput and timing resolution, not latency.**
  - It works in words. Even raw, with its buffers bypassed, a decision waits ~6-10 word clocks
    (≈ 15-25 ns at 25 Gb/s, est).
  - Its CDR wants a running, balanced stream, and 100G Ethernet's RS-FEC adds hundreds of ns.
  - An RFSoC's converters are 90-117 ns from DAC to ADC (QICK).
  - The fast path is a combinational LVDS or CML path; the transceiver is the time-stamper and the
    verifier's waveform source.

## Free-space optics

- **In free-space optics, pointing is a latency knob, and the terminal's length is latency.**
  - Étendue fixes the detector: d = θ·D/NA. A photodiode's bandwidth falls with its area, roughly
    10 GHz × (40 µm/d)^1.6. A steadier beam (a fast steering mirror) permits a smaller, faster
    detector.
  - A refractor's 0.55 m from objective to focus is 1.8 ns each way, more than all the fast
    electronics. Give the fast path short dedicated apertures.
  - A metre of fibre is 4.9 ns.
  - Never amplify after the modulation with an EDFA: its 5-30 m of doped fibre is 25-150 ns. Amplify
    the CW light before the modulator, or use an SOA.
  - A 1 mm plastic fibre at a 550 mm focus throws a 1.8 mrad beam, which closes only ~100 m
    (PLAN.md section 19, `sim/optics_roadmap.py`).
