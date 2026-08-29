# AI-assisted test design and human review

## End-to-end workflow

Every performance scenario executes the same business workflow:

```text
POST /api/login
→ GET /api/products?search={CSV searchTerm}
→ GET /api/products/{correlated productId}
→ GET /api/cart
→ POST /api/cart
→ POST /api/checkout
→ GET /api/orders/my-orders
```

The complete sequence is wrapped in a JMeter Transaction Controller so the JTL contains both endpoint samples and an end-to-end parent measurement.

## Correlation

| Source response | Extracted variable | Consumer |
|---|---|---|
| Login JSON | `authToken` | Bearer header on authenticated requests |
| Product-search JSON | `productId` | Detail and cart requests |
| Product-search JSON | `productPrice` | Cart and calculated checkout total |
| Product-search JSON | `productName` | Cart payload |
| Checkout JSON | `orderId` | Order-history verification assertion |

## Workload model — initial hypotheses

These values are starting hypotheses, not final hardware thresholds. They will be reviewed after smoke and calibration runs.

| Scenario | Model | Duration | Purpose |
|---|---|---:|---|
| Load | 20 VUs ramped over 60 seconds | 5 minutes | Validate stable expected traffic |
| Stress | Linear ramp to 1,000 VUs over 300 seconds | 7 minutes | Find saturation and failure onset |
| Spike | 10-VU baseline plus 500 VUs in 5 seconds at t=60s | 4 minutes | Observe sudden-load degradation and recovery |
| Soak | 300 sustained VUs ramped over 60 seconds | 15 minutes | Check sustained stability and resource growth |

A uniform random think time of 400–1000 ms applies before each request. This creates variation and prevents perfectly synchronized request loops.

## Human review corrections to the initial AI design

1. **CSV sharing correction.** The initial suggestion used `Current thread` sharing. That makes every thread begin at the first row and therefore reuses the same account. It was corrected to `All threads`, with one outer thread-group iteration and an inner infinite workflow loop. Each thread consumes exactly one unique row and retains it for the run.
2. **Account-pool correction.** The SUT seeds only one user and stores carts per user in memory. A separate account pool is registered after every restart to avoid cross-VU cart contamination.
3. **Lockout handling.** Invalid-login traffic was excluded from the E2E performance flow. A wrong password would increment the SUT counter incorrectly by two and lock the account for 180 seconds. Valid-login assertions now expose any credential failure immediately.
4. **Live correlation instead of hard-coded IDs.** Product and order identifiers are extracted from responses. This prevents a stale seed assumption from producing misleading successes or failures.
5. **Assertions strengthened.** HTTP 200 alone is insufficient. Login token, cart success, checkout success, and the new order's presence in history are also asserted.
6. **Report-view overhead recognized.** The three required GUI listeners are distinct, but official measurements are executed in CLI mode and preserved in raw JTL plus HTML dashboards. View Results Tree is used only for the short Spike scenario because it retains detailed samples and can consume client memory.
7. **CLI override correction.** Dotted property names were parsed incorrectly by the Windows batch launcher (`load.threads` became property `load` with value `.threads=...`). Scenario override keys were changed to underscore form such as `load_threads`.
8. **Checkout calculation correction.** The first Groovy expression multiplied a `BigDecimal` by an unconverted string from CSV. Both operands are now explicitly converted to `BigDecimal` before calculating `total_amount`.
9. **Stress intensity correction.** Calibration at 100 and 200 VUs produced no errors and almost no latency increase. The final stress ceiling was raised to 1,000 VUs; a 500-VU calibration already showed a clear p95 increase, so the higher ramp is justified as a search for the actual break point.

## Distinct report views

- Load: Summary Report.
- Stress: Aggregate Report.
- Spike: View Results Tree.

The supporting Soak plan uses Simple Data Writer and does not alter the three distinct required views.

## Provisional stability criteria

A load level is treated as stable only when all of the following hold:

- Error rate is below 1%.
- Endpoint p95 is below 500 ms.
- Backend memory does not show sustained unbounded growth.
- Throughput does not collapse as concurrency increases.
- After a spike, endpoint p95 and active threads return toward the pre-spike baseline.
