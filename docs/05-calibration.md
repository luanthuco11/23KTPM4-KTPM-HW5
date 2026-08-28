# Workload calibration record

Date: 2026-08-28

Calibration runs used shortened durations and were excluded from official result folders. Their purpose was to challenge the AI-proposed workload values before committing to long evidence runs.

## Results

| Calibration | JTL rows | Errors | Login p95 | Checkout p95 | E2E p95 |
|---|---:|---:|---:|---:|---:|
| Load, 20 VUs | 2,290 | 0 | 4 ms | 8 ms | 5,739 ms |
| Stress, 100 VUs | 10,989 | 0 | 5 ms | 7 ms | 5,654 ms |
| Stress, 200 VUs | 22,056 | 0 | 6 ms | 8 ms | 5,654 ms |
| Stress, 500 VUs | 51,174 | 0 | 195 ms | 198 ms | 6,124 ms |
| Spike, 10 baseline + 500 burst | 13,247 | 0 | 372 ms | 393 ms | 6,540 ms |

The E2E percentiles include the intentionally configured 400–1000 ms think time before each of seven endpoint requests. They must not be interpreted as server-only latency.

## Human decision

The initial 200-VU Stress plan was rejected because it produced no meaningful degradation. At 500 VUs, endpoint p95 rose by roughly two orders of magnitude while remaining below the provisional 500 ms threshold. The final Stress plan therefore ramps to 1,000 VUs to locate saturation or failure onset. The final Spike plan uses a 500-VU burst because that level produced a measurable transient response without immediate errors.

The Soak plan sustains 300 VUs for 15 minutes. This sits above the clearly stable 200-VU calibration but below the 500-VU level where latency rose sharply. The official Stress result may justify changing this sustained level before the Soak run; any change must be documented rather than silently edited.

