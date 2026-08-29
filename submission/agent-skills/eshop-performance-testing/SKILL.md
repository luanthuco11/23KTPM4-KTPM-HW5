---
name: eshop-performance-testing
description: Design, execute, and audit JMeter performance tests for EShop-style REST workflows when raw JTL evidence, CSV-isolated users, resource monitoring, or human review of AI performance conclusions is required.
---

# EShop Performance Testing

Produce a reproducible performance result, not only a JMeter plan or dashboard.

## Inspect before designing

- Map one end-to-end workflow across auth-heavy, read-heavy, and transactional endpoints.
- Inspect state ownership and reset behavior. If cart/session state is keyed by user, allocate one CSV account per concurrent VU; do not share credentials unless shared state is intentional.
- Correlate JWT, product/order identifiers, and calculated payload fields from live responses. Add business assertions in addition to HTTP status checks.
- Treat workload values as hypotheses. Smoke first, calibrate on the target hardware, then document why final Load/Stress/Spike parameters changed.

## Preserve trustworthy execution evidence

- Run official measurements in JMeter non-GUI mode. GUI listeners may satisfy distinct-view design requirements but must not add measurement overhead during the run.
- Before each official run, reset only the explicitly scoped SUT/backend and prepare deterministic data. Never delete or overwrite an existing official result directory.
- Preserve the raw JTL, full HTML folder, JMeter log, plan/CSV, execution timestamp, SUT commit, hardware metadata, and one-second samples for the backend process. Whole-machine Task Manager evidence complements but does not replace process-specific samples.
- Generate HTML with `-Jjmeter.reportgenerator.statistic_window=-1` when exact whole-JTL percentiles are required.

## Analyse and challenge

Use [scripts/Analyze-Jtl.ps1](scripts/Analyze-Jtl.ps1) for exact label percentiles. Set `ParentLabel` and `ExpectedChildSamples` to match the workflow.

- Exclude scheduler-cut parent transactions from completed-workflow latency and throughput; do not relabel them as request failures.
- Separate endpoint latency from E2E transaction time when the parent includes think time.
- Compare time buckets, not only whole-run averages, for Stress breakpoints, Spike recovery, and Soak drift.
- Report the highest tested stable level, not an absolute maximum unless multiple sustained levels bound the failure point.
- Treat simultaneous CPU/memory and latency movement as correlation. Require profiling or an A/B change before naming a root cause.

## Review optimization proposals against code

Classify each proposal as feasible, evidence-needed, or incompatible/hallucinated. Verify the actual database, state model, deployment topology, and query path. For SQLite plus process-local state, generic connection pooling, immediate multi-worker scaling, or distributed cache recommendations are not valid without architecture changes and benchmark evidence.

Finish with exact raw values for every corrected AI claim, a reproducible reset/run command, limitations, and the next falsifiable experiment.
