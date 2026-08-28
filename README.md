# HW05 — Performance Testing

- Student ID: `23127414`
- SUT: EShop (`ttbhanh/eshop-sut`)
- Tool: Apache JMeter 5.6.3
- Status: Technical work complete; awaiting student `dxdiag` and unlisted-video evidence
- Public repository: `https://github.com/luanthuco11/23KTPM4-KTPM-HW5`
- Proposed submission filename after evidence is added: `23127414_HW05_AI_Performance_090.zip`

## Self-assessment

| No. | Criterion | Maximum | Self-assessed |
|---:|---|---:|---:|
| 1 | Task 1 — Load testing | 20 | 20 |
| 2 | Task 1 — Stress testing | 20 | 20 |
| 3 | Task 1 — Spike testing | 20 | 20 |
| 4 | Task 2 — AI analysis and misinterpretation hunt | 10 | 10 |
| 5 | Task 3 — Continuous Performance Testing proposal | 10 | 10 |
| 6 | Agent Skill | 10 | 10, conditional on adding the recorded skill-demo segment |
| | Total of listed rubric rows | 90 | 90 |

The assignment template prints `Total 100`, although its six published row weights sum to 90. The proposed three-digit self-assessed grade is therefore `090`; the student should confirm this interpretation before final submission.

## Selected workflow

```text
Login
→ Search/List products
→ View product detail
→ View cart
→ Add product to cart
→ Checkout
→ View order history
```

Endpoint-group coverage:

| Group | Requests |
|---|---|
| Auth-heavy | `POST /api/login` |
| Read-heavy | `GET /api/products`, `GET /api/products/:id`, `GET /api/cart` |
| Transactional | `POST /api/cart`, `POST /api/checkout` |
| Verification | `GET /api/orders/my-orders` |

## Planned scenarios

| Scenario | Test plan | Distinct JMeter report view | Status |
|---|---|---|---|
| Load | `23127414_Load_20260828.jmx` | Summary Report | Completed — 0% errors; screenshots added |
| Stress | `23127414_Stress_20260828.jmx` | Aggregate Report | Completed — 0% errors; screenshots added |
| Spike | `23127414_Spike_20260829.jmx` | View Results Tree | Completed — 0% errors; screenshots added |
| Soak | `23127414_Soak_20260829.jmx` | Simple Data Writer + HTML Dashboard | Completed — 0% errors; screenshots added |

The suffix identifies the execution campaign. Load uses `20260828`; Spike and Soak use their actual date `20260829`. Stress retained campaign suffix `20260828` although immutable JTL timestamps show it started after midnight on `2026-08-29`; this discrepancy is documented rather than rewriting evidence.

## Current official result summary

### Load — 2026-08-28

- Workload: 20 VUs, 60-second ramp-up, 300-second duration.
- Complete workflows: 1,092; interrupted at scheduler boundary: 20.
- Endpoint samples: 7,715; failures: 0; error rate: 0%.
- Completed workflow throughput: 3.642 workflows/s.
- Approximate endpoint throughput: 25.7 requests/s.
- Checkout p95: 17 ms; login p95: 6 ms.
- E2E p95: 5,628 ms, including seven configured think-time delays.
- Backend working set: 45.75 MB initially, 83.75 MB maximum.

### Stress — campaign ID 20260828, executed 2026-08-29

- Workload: linear ramp to 1,000 VUs over 300 seconds; 420-second scheduler duration.
- Complete workflows: 37,974; interrupted at scheduler boundary: 1,000.
- Endpoint samples: 270,095; failures: 0; error rate: 0%.
- Approximate endpoint throughput: 613.4 requests/s over the resource-monitoring window.
- Login p95: 1,210 ms; checkout p95: 1,289 ms; order-history p95: 1,428 ms.
- E2E p95: 10,389 ms, including seven configured think-time delays.
- Backend reached approximately one logical CPU core and 161.72 MB working set.
- Practical degradation threshold: approximately 800–900 VUs; the system did not crash but exceeded the provisional 500 ms endpoint p95 objective.

### Spike — 2026-08-29

- Workload: 10 baseline VUs for 240 seconds, plus 500 VUs ramped in 5 seconds at t=60 seconds and held for 60 seconds.
- Complete workflows: 5,953; scheduler-interrupted parents: 510.
- Endpoint samples: 43,270; failures: 0; error rate: 0%.
- Checkout p95 over the whole run: 94 ms; worst meaningful 10-second burst p95: 210 ms.
- Checkout p95 recovered to 14 ms in the first 10-second interval after the burst ended.
- Backend working set peaked at 105.97 MB and fell to 59.52 MB by the end.

### Soak/endurance — 2026-08-29

- Workload: 300 VUs, 60-second ramp-up, 900-second total duration.
- Complete workflows: 52,447; scheduler-interrupted parents: 300.
- Endpoint samples: 368,046; failures: 0; error rate: 0%.
- Observed sustained endpoint throughput: approximately 409.5 requests/s; complete workflow throughput: 58.277/s.
- All-run checkout p95: 34 ms; minute-level p95 rose from 13–15 ms early to 81 ms in the final sustained minute.
- Backend working set/private-memory ceilings: 108.09/121.27 MB; final values after load ended: 55.21/66.08 MB.
- Evidence-supported endurance threshold: 300 VUs and about 409.5 endpoint requests/s for 15 minutes on this host. This is the highest tested stable sustained level, not a proven absolute maximum.

## Deliverable map

- `test-plans/`: JMeter plans.
- `data/`: CSV test data and preparation instructions.
- `results/`: raw JTL files and generated HTML dashboards.
- `evidence/`: resource-monitor and hardware evidence.
- `report/`: main report, AI audit, AI critique, and continuous-testing proposal.
- `scripts/`: repeatable preparation, execution, and analysis helpers.
- `docs/`: project plan and SUT baseline notes.
- `agent-skills/eshop-performance-testing/`: reusable, validated Agent Skill and exact JTL analyzer.

## Evidence checklist

- [x] Load HTML Statistics screenshot.
- [x] Load Response Times Over Time screenshot.
- [x] Load Task Manager screenshot and backend resource CSV.
- [x] Stress Statistics, response-time, active-thread and Task Manager screenshots plus backend resource CSV.
- [x] Spike Statistics, active-thread, response-time and Task Manager screenshots plus backend resource CSV.
- [x] Soak Statistics, response-time, active-thread, throughput and Task Manager screenshots plus backend resource CSV.
- [x] Agent Skill implementation and validation on the official Stress JTL.
- [ ] Agent Skill demonstration segment in the unlisted video.
- [x] Hardware specification table for host `MINHLUAN`.
- [ ] Hardware screenshot (`dxdiag`) with hostname `MINHLUAN`.
- [ ] At least six minutes of unlisted YouTube video with the student's Vietnamese narration.
- [ ] Add the unlisted URL to `evidence/video-link.txt` and this README.
- [ ] Push/merge the completed branch to the public repository.
- [ ] Moodle submission.
- [ ] Optional: publish any selected draft from `report/github-issue-drafts.md` and add its URL.

## Submission summary

- Scenarios run: Load, Stress, Spike, plus the required 15-minute Soak/endurance run.
- Endpoint groups: auth-heavy, read-heavy, transactional, plus order-history verification.
- Evidence-supported endurance threshold: 300 VUs, approximately 409.5 endpoint requests/s and 58.277 complete workflows/s for 15 minutes, with 0% errors.
- Practical Stress degradation threshold: approximately 800–900 VUs under the tested linear ramp.
- Published bugs/performance issues: 0; prepared evidence-backed Issue drafts: 3.
- Demo video: pending student upload.

## Source baseline

The clean SUT is cloned locally from `https://github.com/ttbhanh/eshop-sut` and excluded from this repository. See `docs/01-sut-baseline.md` for the pinned commit and reproducibility notes.
