# Official Stress result — campaign 20260828

The immutable JTL timestamps show that this run started at 00:46:11 and ended at
00:53:13 on 2026-08-29. The `20260828` suffix is the campaign identifier supplied
to the runner before midnight and is retained to avoid rewriting original evidence.

- Test plan: `23127414_Stress_20260828.jmx`
- Linear ramp to 1,000 VUs over 300 seconds; 420-second scheduler duration.
- Raw JTL samples: 309,069 (endpoint and parent transaction rows).
- Complete E2E workflows: 37,974.
- Scheduler-interrupted E2E parents: 1,000.
- Endpoint samples: 270,095.
- Failures: 0; error rate: 0%.
- Approximate endpoint throughput: 613.4 requests/s over the monitoring window.
- Checkout p95: 1,289 ms.
- E2E p95 including think time: 10,389 ms.
- Backend working-set maximum: 161.72 MB.
- Backend private-memory maximum: 173.94 MB.

Files:

- `23127414_Stress_20260828.jtl`: raw samples.
- `html-report/`: JMeter HTML Dashboard.
- `metric-summary.csv`: human-reviewed percentile summary.
- `backend-resource-usage.csv`: one-second backend process samples.
- `jmeter.log`: JMeter execution and report-generation log.

The screenshot evidence supplied by the student belongs in `evidence/stress/`.
