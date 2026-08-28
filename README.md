# HW05 — Performance Testing

- Student ID: `23127414`
- SUT: EShop (`ttbhanh/eshop-sut`)
- Tool: Apache JMeter 5.6.3
- Status: In progress

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
| Spike | `23127414_Spike_YYYYMMDD.jmx` | View Results Tree | Pending |
| Soak | `23127414_Soak_YYYYMMDD.jmx` | Simple Data Writer + HTML Dashboard | Pending |

The date in each official filename will be the actual execution date.

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

## Deliverable map

- `test-plans/`: JMeter plans.
- `data/`: CSV test data and preparation instructions.
- `results/`: raw JTL files and generated HTML dashboards.
- `evidence/`: resource-monitor and hardware evidence.
- `report/`: main report, AI audit, AI critique, and continuous-testing proposal.
- `scripts/`: repeatable preparation, execution, and analysis helpers.
- `docs/`: project plan and SUT baseline notes.

## Evidence checklist

- [x] Load HTML Statistics screenshot.
- [x] Load Response Times Over Time screenshot.
- [x] Load Task Manager screenshot and backend resource CSV.
- [x] Stress Statistics, response-time, active-thread and Task Manager screenshots plus backend resource CSV.
- [ ] Spike screenshots and backend resource evidence.
- [ ] Soak screenshots and backend resource evidence.
- Hardware screenshot (`dxdiag`) with the correct hostname.
- At least six minutes of unlisted YouTube video with the student's Vietnamese narration.
- Moodle submission and any account-authenticated GitHub Issue publication.

## Source baseline

The clean SUT is cloned locally from `https://github.com/ttbhanh/eshop-sut` and excluded from this repository. See `docs/01-sut-baseline.md` for the pinned commit and reproducibility notes.
