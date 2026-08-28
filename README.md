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
| Load | `23127414_Load_YYYYMMDD.jmx` | Summary Report | Pending |
| Stress | `23127414_Stress_YYYYMMDD.jmx` | Aggregate Report | Pending |
| Spike | `23127414_Spike_YYYYMMDD.jmx` | View Results Tree | Pending |
| Soak | `23127414_Soak_YYYYMMDD.jmx` | Simple Data Writer + HTML Dashboard | Pending |

The date in each official filename will be the actual execution date.

## Deliverable map

- `test-plans/`: JMeter plans.
- `data/`: CSV test data and preparation instructions.
- `results/`: raw JTL files and generated HTML dashboards.
- `evidence/`: resource-monitor and hardware evidence.
- `report/`: main report, AI audit, AI critique, and continuous-testing proposal.
- `scripts/`: repeatable preparation, execution, and analysis helpers.
- `docs/`: project plan and SUT baseline notes.

## Evidence still requiring the student

- Screenshots showing JMeter and Task Manager in the same frame.
- Hardware screenshot (`dxdiag`) with the correct hostname.
- At least six minutes of unlisted YouTube video with the student's Vietnamese narration.
- Moodle submission and any account-authenticated GitHub Issue publication.

## Source baseline

The clean SUT is cloned locally from `https://github.com/ttbhanh/eshop-sut` and excluded from this repository. See `docs/01-sut-baseline.md` for the pinned commit and reproducibility notes.
