# AXI4 Full-Matrix Crossbar NoC with QoS-Aware Arbitration

**A 4×4 AXI4 crossbar interconnect** with full-matrix master-to-slave routing,
deficit-weighted round-robin (DWRR) write arbitration, burst-locked read
arbitration, and decode-error interception — implemented from scratch in
SystemVerilog and verified with a self-built class-based constrained-random
testbench (no UVM dependency).

`SystemVerilog` `AMBA AXI4` `Vivado 2025.2 / XSim` `Xilinx Artix-7`

---

## Table of Contents

- [Why this project exists](#why-this-project-exists)
- [Status at a glance](#status-at-a-glance)
- [Quick start](#quick-start)
- [Architecture](#architecture)
- [Verification methodology](#verification-methodology)
- [Known limitations / roadmap](#known-limitations--roadmap)
- [Repository structure](#repository-structure)
- [Engineering deep-dive: bugs found during bring-up](#engineering-deep-dive-bugs-found-during-bring-up)
- [License](#license)

---

## Why this project exists

AMBA AXI4 is the interconnect protocol underneath essentially every SoC
shipping today. A crossbar is the piece that turns "N masters, M slaves" into
"any master can legally reach any slave, fairly, without violating protocol
ordering rules" — and it's a genuinely hard piece of RTL to get right, because
the failure modes (a deadlock, a starved master, a misrouted burst) are often
invisible until you stress multiple concurrent, contending masters, not in a
simple one-at-a-time smoke test. This project builds one from the ground up —
address decode, per-slave arbitration, write-data routing that survives
concurrent outstanding writes to the same slave, burst-locked read return
paths, and a dedicated decode-error slave — specifically to work through those
failure modes for real, not just get a single directed test to pass.

## Status at a glance

**Functionally verified against a randomized, multi-master, concurrent-traffic
test — with explicit, undisguised gaps documented below.** A hiring manager
reading this repo should trust it *because* the limitations are named, not
because everything is claimed to work.

```
 WRITES PASSED : 49        WRITES FAILED : 0
 READS PASSED  : 31        READS FAILED  : 0
 STATUS: [ SUCCESS ] All Transactions Verified!
 FUNCTIONAL COVERAGE: 95.31%
```
80/80 transactions (20 per master × 4 concurrent masters), zero data-integrity
mismatches. Full captured log: [`docs/sim_results.log`](docs/sim_results.log).

## Quick start

Requires Vivado 2025.2+ with XSim.

```tcl
# 1. New RTL project, part xc7a15tcsg324-1
# 2. Add every file under rtl/ as a design source
# 3. Add tb/tb_top.sv as a simulation source (simulation top: tb_top)
#    Do NOT also add a separate axi4_if.sv - tb_top.sv declares its own,
#    and having both is a duplicate-declaration error at elaboration.
launch_simulation
run -all
```

Expect `$finish` within a few thousand ns and a `SCOREBOARD FINAL REPORT`
block in the console. Full setup detail: [`docs/BUILDING.md`](docs/BUILDING.md).

## Architecture

```
        m0 m1 m2 m3                              s0 s1 s2 s3  (+ default/error slave)
         |  |  |  |                                |  |  |  |
    +----v--v--v--v----+                     +-----v--v--v--v-----+
    |  master_ingress   |  (x4, one/master)   |  slave_aw_egress    | (x5: s0-s3 + default)
    |  - skid buffers    |---- AW/AR -------->|  - DWRR arbitration |
    |  - address_decoder |                     |  - route_info_fifo  |
    +--------------------+                     +---------+-----------+
                                                          | W beats
    +--------------------+                     +---------v----------+
    |  master_b_egress    |<---- B/R ----------|  slave_w_egress      |
    |  master_r_egress     |  (x4, round-robin, |  (x5, routed by       |
    |  (burst-locked reads) |  burst-locked)     |   route_info_fifo)    |
    +----------------------+                     +----------------------+
```

**The two design decisions that matter most, and why:**

- **`route_info_fifo` exists because AW and W are decoupled channels.** A
  master's AW can be granted, then a *different* master's AW to the same
  slave can also be granted, before the first master finishes sending its W
  burst. Without remembering the order AWs were actually granted in, the
  W-data mux has no way to know which master's `WVALID` to route next.
  `route_info_fifo` is that memory — one FIFO per slave, pushed on AW grant,
  popped on `WLAST`.
- **`master_r_egress` burst-locks reads because AXI4 forbids interleaving
  read data from different bursts on one port.** Once a slave is granted the
  read-return path to a given master, the arbiter holds that grant — even if
  a different slave's data becomes ready in the meantime — until `RLAST`.
  This isn't a fairness nicety, it's a protocol legality requirement.

## Verification methodology

Class-based constrained-random environment (generator -> driver -> monitor ->
scoreboard -> environment -> test), deliberately built without a UVM
dependency to work around a documented XSim macro-expansion limitation
encountered during an earlier project. Four concurrent master agents drive
randomized write/read traffic; four slave-side responders (backed by a memory
model) answer them; a scoreboard cross-checks a software memory shadow
against actual `BRESP`/`RDATA` and samples a `(master x slave x direction)`
coverage cross. `axi4_if` embeds SystemVerilog assertions checking AXI4's
VALID-must-not-drop-before-READY rule on all five channels.

Full methodology, current coverage state, and prioritized next steps:
[`docs/testplan.md`](docs/testplan.md).

## Known limitations / roadmap

Named explicitly rather than left for a reviewer to discover:

| Gap | Impact | Tracked in |
|---|---|---|
| SVA checkers' fix not yet re-verified by a run | `sim_results.log` predates a property-typing fix; assertions may not yet be confirmed active | `testplan.md` P0 |
| Testbench only generates single-beat transactions | `route_info_fifo`'s multi-beat-hold behavior and DWRR's cost-weighting are present in RTL but not stressed by the current test | `testplan.md` P1 |
| No slave-side monitoring | Scoreboard catches data corruption, not a self-consistent misrouting bug | `testplan.md` P1 |
| Functional coverage ~95%, not 100% | Random-only traffic doesn't guarantee all 32 cross bins hit | `testplan.md` P1 |
| QoS not actually wired | `AWQOS`/`ARQOS` exist on the interface but not on the DUT's top-level ports; "QoS-aware" today means fixed-quantum DWRR, not per-transaction weighting | `testplan.md` P2 |

## Repository structure

```
rtl/     Synthesizable design, one module per file (see file-level comments
         for each block's role in the diagram above)
tb/      tb_top.sv - single-file class-based testbench (interface with SVA
         checkers, transaction, generator, driver, responder, monitor,
         scoreboard, environment, test, and the top module)
docs/    testplan.md (prioritized gaps + methodology), BUILDING.md (project
         setup), sim_results.log (captured passing run)
```

## Engineering deep-dive: bugs found during bring-up

Documented here deliberately — *how* a bug was found and why the fix is
correct is stronger engineering evidence than a final passing state alone,
and every one of these was caught by actual tool feedback (Vivado XSim
elaboration/simulation), not code review.

**1. Static vs. automatic variable lifetime in a round-robin arbiter.**
A loop variable declared inside a `for`-loop body within a module-level
`always_comb` defaulted to `static` lifetime per IEEE 1800, not a fresh copy
per synthesis-unrolled iteration. It produced the *correct result* here only
because the variable was fully reassigned before every read — legally
unclean despite functioning, and caught by a compiler warning rather than a
functional failure.

**2. DWRR arbiter livelock under downstream backpressure.** The deficit-credit
bookkeeping was correct, but the grant itself was never gated on FIFO-full
backpressure from downstream. A master with sufficient credit whose target
was backed up would stall the *entire* round-robin indefinitely, since no
existing state-machine branch covered that condition — found by tracing the
exact handshake sequence that produces a 60,000,000+ ns "phantom" simulation
hang back to a specific missing `else if`.

**3. Default-slave write-path race under concurrent decode-error traffic.**
The decode-error write path tracked "which master owns this in-flight write"
with a bare combinational signal, correct for exactly one outstanding
decode-error write at a time. Under realistic concurrent multi-master
traffic, this silently misrouted one master's write data into another
master's in-flight transaction — a bug that manifests as an indefinite hang,
not a clean failure, and was root-caused by instrumenting the testbench with
per-master phase tracing rather than blind waveform inspection.

**4. SystemVerilog package compile-order fragility.** A struct type shared
across two files depended on `xvlog`'s file-analysis order, which does not
reliably match module-instantiation order. Resolved by removing the shared
type dependency entirely — a flat bit vector with a documented layout — since
a smaller, more portable design was the actual fix, not fighting the tool
into cooperating with the type-sharing mechanism.

## License

MIT — see `LICENSE` (add before making the repository public).
