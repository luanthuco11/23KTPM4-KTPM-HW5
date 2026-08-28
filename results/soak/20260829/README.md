# Official Soak/endurance result — 2026-08-29

- Test plan: `23127414_Soak_20260829.jmx`.
- 300 VUs; 60-second ramp-up; 900-second total scheduler duration.
- Raw JTL rows: 420,793.
- Complete E2E workflows: 52,447.
- Scheduler-interrupted E2E parents: 300.
- Endpoint samples: 368,046.
- Failures: 0; error rate: 0%.
- Observed sustained endpoint throughput: approximately 409.5 requests/s.
- Complete workflow throughput: 58.277 workflows/s.
- Checkout p95 over the whole run: 34 ms.
- Final sustained-minute checkout p95: 81 ms.
- Backend working-set maximum/final: 108.09/55.21 MB.
- Backend private-memory maximum/final: 121.27/66.08 MB.

Evidence-supported threshold: 300 VUs and approximately 409.5 endpoint requests/s
for 15 minutes on this host. This is the highest tested stable sustained workload,
not a proven absolute maximum.

Files:

- `23127414_Soak_20260829.jtl`: raw samples.
- `html-report/`: JMeter HTML Dashboard generated with the full percentile window.
- `metric-summary.csv`: exact full-JTL percentile summary.
- `backend-resource-usage.csv`: one-second backend process samples.
- `jmeter.log`: JMeter execution and report-generation log.

The real screenshots supplied by the student are stored in `evidence/soak/`.
