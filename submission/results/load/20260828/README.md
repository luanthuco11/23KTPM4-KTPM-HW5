# Official Load result — 2026-08-28

- Test plan: `23127414_Load_20260828.jmx`
- 20 VUs; 60-second ramp-up; 300-second duration.
- Raw JTL rows: 8,827.
- Complete E2E workflows: 1,092.
- Scheduler-interrupted E2E parents: 20.
- Endpoint samples: 7,715.
- Failures: 0; error rate: 0%.
- Completed workflow throughput: 3.642 workflows/s.
- Approximate endpoint throughput: 25.7 requests/s.
- Checkout p95: 17 ms.
- E2E p95 including think time: 5,628 ms.
- Backend working-set maximum: 83.75 MB.
- Backend private-memory maximum: 98.90 MB.

Files:

- `23127414_Load_20260828.jtl`: complete raw samples.
- `html-report/`: JMeter HTML Dashboard.
- `metric-summary.csv`: human-reviewed percentile summary.
- `backend-resource-usage.csv`: one-second backend process samples.
- `jmeter.log`: JMeter execution and report-generation log.

This folder does not replace the mandatory screenshot showing the test tool and Task Manager in the same frame.

