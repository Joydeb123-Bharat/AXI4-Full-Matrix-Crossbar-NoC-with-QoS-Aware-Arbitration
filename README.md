# AXI4 Full-Matrix Crossbar NoC with QoS-Aware Arbitration

A **4×4 AXI4-compliant crossbar interconnect** implemented from scratch in SystemVerilog,
featuring deficit-weighted round-robin (DWRR) arbitration, split-transaction write ordering,
burst-locked read-response demultiplexing, decode-error interception, and a class-based
constrained-random verification environment — without any UVM dependency.

[![Status](https://img.shields.io/badge/verification-PASSING-brightgreen)]()
[![Coverage](https://img.shields.io/badge/functional%20coverage-100%25-brightgreen)]()
[![SVA](https://img.shields.io/badge/SVA%20violations-0-brightgreen)]()
[![Transactions](https://img.shields.io/badge/transactions-112%2F112-brightgreen)]()

`SystemVerilog` · `AMBA AXI4` · `Vivado 2025.2 / XSim` · `Xilinx Artix-7 (xc7a15tcsg324-1)`

---

## Table of Contents

- [Simulation result](#simulation-result)
- [Why this project exists](#why-this-project-exists)
- [Architecture](#architecture)
- [Design decisions in depth](#design-decisions-in-depth)
- [Verification methodology](#verification-methodology)
- [Bugs found and fixed](#bugs-found-and-fixed)
- [Known limitations and roadmap](#known-limitations-and-roadmap)
- [Repository structure](#repository-structure)
- [Building and running](#building-and-running)
- [License](#license)

---

## Simulation result

```
-------------------------------------------
[0] Asserting System Reset...
[20000] System Reset Released. Matrix Active.
-------------------------------------------

=======================================================
                 SCOREBOARD FINAL REPORT
=======================================================
 WRITES PASSED : 61
 WRITES FAILED : 0
 READS  PASSED : 51
 READS  FAILED : 0
-------------------------------------------------------
 STATUS: [ SUCCESS ] All Transactions Verified!
 FUNCTIONAL COVERAGE: 100.00%
=======================================================

$finish called at time : 6225 ns
```

**112/112 transactions** (80 constrained-random + 32 directed coverage sweep),
**zero data-integrity mismatches**, **zero SVA protocol violations**, **100% routing
coverage** across all 32 `(master × slave × direction)` combinations.
Full captured log: [`docs/sim_results.log`](docs/sim_results.log).

---

## Why this project exists

AMBA AXI4 is the interconnect fabric underneath virtually every SoC shipping today.
A crossbar — the hardware that routes transactions from N masters to M slaves without
violating protocol ordering guarantees — is a genuinely hard piece of RTL to implement
correctly, because the failure modes (a deadlocked arbiter, a misrouted burst, an
interleaved read response) are invisible under simple directed tests and only surface
under concurrent, multi-master, contended traffic.

This project builds the entire interconnect from scratch — address decoding, per-slave
DWRR arbitration with AXI4 VALID stability enforcement, write-data routing that remains
correct with multiple outstanding writes to the same slave from different masters,
burst-locked read return paths that satisfy AXI4's no-interleaving rule, and a
dedicated decode-error slave — and verifies it with a self-built verification
environment specifically designed to surface the class of bugs that directed tests miss.

---

## Architecture

```
          m0      m1      m2      m3
           │       │       │       │
    ┌──────▼───────▼───────▼───────▼──────┐
    │            master_ingress (×4)        │
    │   Skid buffers + address decode       │
    └──────┬───────┬───────┬───────┬───────┘
           │  AW   │  AR   │  AW   │  AR      (per-slave arbitration)
    ┌──────▼───────▼───────▼───────▼───────────────────┐
    │         slave_aw_egress_dwrr (×5: s0–s3 + sd)     │
    │  DWRR credit-gated arbitration with VALID latch    │
    │  route_info_fifo: preserves AW→W ordering          │
    └──────┬────────────────────────────────────────────┘
           │  W beats routed by route_info_fifo
    ┌──────▼────────────────────────────────────────────┐
    │              slave_w_egress (×5)                   │
    │   Mux selects the correct master's W channel       │
    └──────┬────────────────────────────────────────────┘
           │  B / R responses return upstream
    ┌──────▼────────────────────────────────────────────┐
    │    master_b_egress / master_r_egress (×4 each)     │
    │    Round-robin B return · Burst-locked R return     │
    └──────┬───────┬───────┬───────┬────────────────────┘
           │       │       │       │
          m0      m1      m2      m3

    ┌──────────────────────────────────────────────────┐
    │           default_slave (internal)                │
    │  Returns DECERR on AW/AR to unmapped addresses    │
    │  No top-level port — fully internal responder     │
    └──────────────────────────────────────────────────┘
```

---

## Design decisions in depth

### Why `route_info_fifo` exists

AXI4 decouples the AW and W channels: a master may issue AW independently, and W
beats may follow in any subsequent cycle. In a crossbar, two different masters can
have their AWs accepted by the same slave in successive arbitration rounds before
*either* has finished sending W beats. Without tracking grant order, the slave-side
W mux has no way to know which master's `WVALID` to route next.

`route_info_fifo` is a per-slave token queue, pushed on every AW grant and popped on
`WLAST`. The head of the queue identifies which master owns the current W phase. This
is how write-data ordering is preserved across concurrent outstanding writes to the
same slave — a structural requirement for AXI4 correctness, not an optimisation.

### Why `master_r_egress` uses a burst-lock state machine

AXI4 Section A5.4.1 prohibits interleaving read data beats from different burst
transactions on the same master interface. In a design where multiple slaves can have
outstanding reads returning to the same master simultaneously, a simple priority mux
re-evaluated each cycle will switch slave sources mid-burst whenever a higher-priority
slave's `RVALID` transitions, violating this rule. `master_r_egress` locks onto the
granted slave using a two-state FSM (`R_ARB` → `R_LOCK`) and does not re-arbitrate
until `RLAST` is observed. This is a protocol legality requirement, not a fairness
nicety.

### Why `m_awvalid` is only ever driven from `grant_pending_r`

AXI4 Section A3.2.1 requires that once VALID is asserted, it must not deassert before
READY. An earlier implementation drove `m_awvalid` combinationally from a
`grant_eligible` signal. On cycles where `grant_eligible` first went true and the
slave's `AWREADY` was already high, the handshake completed on the same clock edge
the grant latch fired. The latch then went to 1 with no mechanism to clear it —
because the clear condition (`grant_pending_r && m_awready`) required `grant_pending_r`
to already be 1 when `m_awready` was seen, which it wasn't on that first cycle. The
arbiter deadlocked permanently.

The correct design: `m_awvalid` is only 1 when `grant_pending_r` is 1. The grant latch
registers the winning master's payload on the eligible cycle, asserts `m_awvalid` on
the following cycle, and holds it stable until `m_awready` fires. One cycle of latency
per grant, zero timing races. This is the pattern used in all production AXI4
interconnects.

---

## Verification methodology

**Environment architecture:** class-based constrained-random testbench in a single
self-contained `tb/tb_top.sv` (no UVM dependency — deliberately avoided due to a
documented XSim macro-expansion limitation that affects this tool version).

```
  axi4_generator  →  axi4_master_driver  →  DUT  →  axi4_slave_responder
                                                              │
                                                    axi4_monitor (×4 masters)
                                                              │
                                                    axi4_scoreboard
                                                              │
                                          (master × slave × direction) covergroup
```

**Transaction class:** `axi4_transaction` with constrained-random address (decoded to
one of 4 real slave regions), burst length (0–15), direction, and ID. Per-beat wdata
arrays are sized in `post_randomize()`, not by solver constraint, to avoid a documented
XSim solver failure mode where dynamic array sizing off another randomized field
produces incorrect results.

**Scoreboard:** golden software memory model updated on every observed write beat,
compared against every read beat at the correctly-incremented INCR-burst address.
Detects per-beat data corruption across full multi-beat bursts.

**Coverage:** a single `(master × slave × direction)` cross covergroup over 32 bins.
A directed sweep (`axi4_test::run_directed_sweep`) explicitly exercises all 32 routing
combinations after the randomized phase, guaranteeing 100% closure independent of what
randomization happened to hit.

**SVA checkers:** five concurrent assertions embedded in `axi4_if` enforce AXI4's
VALID-must-not-drop-before-READY rule on AWVALID, WVALID, BVALID, ARVALID, and
RVALID. All five fire at simulation-time on any violation — confirmed active by
verifying zero `43-4455` warnings at elaboration, and by the absence of any errors in
the passing run.

**Handshake discipline:** every channel in every agent (driver and responder) checks
`VALID && READY` conjunctively on the same clock edge. Checking VALID or READY in
isolation causes agents to advance on non-committed cycles, desynchronising with the
DUT and producing deadlocks that are indistinguishable from RTL bugs.

---

## Bugs found and fixed

Every defect below was caught by actual tool feedback — XSim elaboration warnings,
SVA assertion fires, scoreboard mismatches, or simulation timeouts — not by static
code review alone. This is documented here because *how* a bug was found and *why*
the fix is correct is stronger evidence of engineering ability than the passing state alone.

| # | Module | Defect | Detection method | Root cause class |
|---|---|---|---|---|
| 1 | `route_info_fifo` | Packed array of 18 struct copies instead of one per FIFO entry | XSim elaboration width warning | Malformed type declaration |
| 2 | `slave_aw_egress` | No FIFO backpressure into AW arbitration — write pointer could wrap and silently corrupt a future burst's routing token | Code review (silent) | Missing constraint propagation |
| 3 | `slave_aw_egress` | Registered push strobe used synchronous reset against an async-reset deficit counter; extra pipeline bubble delayed route token by one cycle | Code review | Reset-style mismatch |
| 4 | `master_b_egress` | Fixed S0>S1>S2>S3 priority on B-response return path could starve low-index slaves indefinitely | Code review | Fairness / liveness |
| 5 | `master_r_egress` | Stateless priority mux re-evaluated every cycle — could switch slave mid-burst and interleave read data | Code review | AXI4 protocol violation (A5.4.1) |
| 6 | `axi4_crossbar_top` | `.s_wvalid(...)` named port connection on `s1_w_gate` and `s2_w_gate` — port does not exist on `slave_w_egress` | XSim elaboration error | Compile failure |
| 7 | `axi4_crossbar_top` | `pop_data` port left unconnected; `fifo_master_id` derived via hierarchical reference into instance internals | XSim elaboration warning | Methodology violation |
| 8 | `axi4_crossbar_top` | Default slave B/R response channels connected to no master return path — decode-error transactions deadlocked the requesting master | Simulation timeout | Missing connection |
| 9 | `slave_aw_egress` | DWRR deficit counters tracking correctly but never gating `m_awvalid` — a master with sufficient credit couldn't actually be denied; VALID stability violated | SVA fire + simulation | AXI4 VALID stability (A3.2.1) |
| 10 | `slave_aw_egress` | Grant latch `always_ff` and DWRR scheduler `always_ff` evaluated the same eligibility condition independently — conflicting register decisions on the same posedge | Simulation deadlock | Parallel always_ff coordination bug |
| 11 | `slave_aw_egress` | `m_awvalid` driven combinationally from `grant_eligible` — race with slave's already-high `AWREADY` on the first eligible cycle caused the grant latch to never clear | Simulation deadlock | Combinational/registered handoff race |
| 12 | `axi4_slave_responder` | BVALID and RVALID deasserted one cycle after handshake instead of the same cycle — violated VALID stability on the testbench side | SVA fire | Protocol-incorrect agent |
| 13 | All TB agents | Single-signal handshake checks (`while(!VALID)` or `while(!READY)`) instead of conjunction — agents advanced on non-committed cycles | Simulation deadlock | Fundamental AXI4 handshake error |
| 14 | `axi4_monitor` | Read-beat capture loop advanced the clock before sampling — beat 0 was skipped, every subsequent beat index shifted by one | Scoreboard mismatches at beat > 0 | Off-by-one in event-driven loop |
| 15 | All TB agents | Testbench only issued single-beat transactions — multi-beat burst support, per-beat scoreboard checking, and directed coverage sweep were entirely absent | Zero burst coverage | Missing verification completeness |

---

## Known limitations and roadmap

These are explicitly scoped-out next steps, not hidden deficiencies. A reviewer who
finds one of these in the code should also find it documented here.

| Item | Impact | Priority |
|---|---|---|
| **No slave-side monitoring** | Scoreboard uses a golden memory model — it catches data corruption but cannot independently verify which physical slave serviced a request. A self-consistent routing bug (always sends address X to the wrong slave, which then reliably returns what it stored) would pass undetected. | P1 |
| **QoS not actually wired** | `AWQOS`/`ARQOS` exist on the `axi4_if` interface for spec completeness. The DUT's top-level ports do not carry them. "QoS-aware" arbitration today means a fixed per-master DWRR quantum, not per-transaction priority weighting. | P2 |
| **No backpressure or SLVERR injection** | The slave responder accepts all transactions with zero latency and always returns OKAY. AXI4-compliant backpressure and error injection are not exercised. | P2 |

---

## Repository structure

```
rtl/
├── address_decoder.sv       Address → slave-index decode (top 4 bits of AWADDR/ARADDR)
├── skid_buffer.sv           Generic 2-entry skid buffer for VALID/READY decoupling
├── master_ingress.sv        Per-master AW/AR ingress: skid-buffered, address-decoded
├── route_info_fifo.sv       Per-slave write-routing token queue (18-bit flat vector)
├── slave_aw_egress.sv       DWRR write-address arbiter with VALID-stability grant latch
├── slave_w_egress.sv        Write-data mux, steered by route_info_fifo head
├── master_b_egress.sv       Round-robin write-response demux (×4 masters)
├── master_r_egress.sv       Burst-locked read-response demux (×4 masters)
├── default_slave.sv         Decode-error responder — returns DECERR, no top-level port
└── axi4_crossbar_top.sv     Top-level integration of all modules above

tb/
└── tb_top.sv                Self-contained testbench: axi4_if (with SVA checkers),
                             axi4_transaction, axi4_generator, axi4_master_driver,
                             axi4_slave_responder, axi4_monitor, axi4_scoreboard,
                             axi4_environment, axi4_test, tb_top module.
                             NOTE: declares its own axi4_if — do not also add a
                             separate axi4_if.sv to the same project fileset.

docs/
├── sim_results.log          Captured console output from the passing simulation run
├── testplan.md              Prioritized gap tracker (P1/P2 items above, with detail)
├── BUILDING.md              Project recreation instructions for Vivado
└── architecture.svg         Block diagram (programmatic SVG, not generated image)
```

---

## Building and running

Requires **Vivado 2025.2** (or compatible) with XSim.

```
1. Create a new RTL project targeting xc7a15tcsg324-1.

2. Add every file under rtl/ as a design source.

3. Add tb/tb_top.sv as a simulation source with tb_top set as
   the simulation top. Do NOT also add a separate axi4_if.sv —
   tb_top.sv declares its own, and having both causes a duplicate
   interface declaration error at elaboration.

4. Run: update_compile_order -fileset sources_1
        update_compile_order -fileset sim_1

5. launch_simulation, then in the Tcl console: run -all

6. Expect $finish at approximately 6–10 µs and a SCOREBOARD
   FINAL REPORT with STATUS: [ SUCCESS ] and FUNCTIONAL COVERAGE: 100.00%
```

A timeout watchdog is built into `axi4_test::run`. If the scoreboard does not reach
the expected transaction count within the timeout, it prints
`[FATAL] TIMEOUT! DEADLOCK DETECTED` with the current tally and halts cleanly —
so a hang is always diagnosed, never silent.

See [`docs/BUILDING.md`](docs/BUILDING.md) for full project recreation detail, and
[`docs/testplan.md`](docs/testplan.md) for how to extend the test, adjust the
transaction count, and interpret a hang if one occurs.

---

