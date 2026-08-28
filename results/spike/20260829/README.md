# Official Spike result — 2026-08-29

- Test plan: `23127414_Spike_20260829.jmx`.
- 10 baseline VUs for 240 seconds.
- 500 additional VUs ramped in 5 seconds at t=60 seconds and held for 60 seconds.
- Raw JTL rows: 49,733.
- Complete E2E workflows: 5,953.
- Scheduler-interrupted E2E parents: 510.
- Endpoint samples: 43,270.
- Failures: 0; error rate: 0%.
- Checkout p95 over the whole run: 94 ms.
- Worst meaningful 10-second burst checkout p95: 210 ms.
- Observed checkout recovery: no more than 10 seconds at the chosen resolution.
- Backend working-set maximum: 105.97 MB; final: 59.52 MB.
- Backend private-memory maximum: 118.36 MB; final: 69.21 MB.

Files:

- `23127414_Spike_20260829.jtl`: raw samples.
- `html-report/`: JMeter HTML Dashboard generated with the full percentile window.
- `metric-summary.csv`: exact full-JTL percentile summary.
- `backend-resource-usage.csv`: one-second backend process samples.
- `jmeter.log`: JMeter execution and report-generation log.

The screenshot evidence supplied by the student belongs in `evidence/spike/`.
