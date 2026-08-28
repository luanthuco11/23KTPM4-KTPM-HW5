# AI Audit Report

## Declaration

I use AI tools for the following tasks.

## Interaction log

### Interaction 1 — Interpret the assignment

- AI tool: OpenAI Codex
- Date: 2026-08-14
- Prompt: Read `2026.HW05.Performance Testing_En.pdf`, translate it into Vietnamese, and explain the required work.
- AI output: Vietnamese translation, deliverable checklist, proposed repository structure, and clarification of ambiguous grading details.
- Human review: The student confirmed the intended interpretation and continued planning.

### Interaction 2 — Review previous homework scope

- AI tool: OpenAI Codex
- Date: 2026-08-28
- Prompt: Read the sibling HW2 submission and identify the flows previously tested.
- AI output: Identified FR-01 registration, FR-11 order history, FR-14 category CRUD, and FR-02 mobile login/lockout; proposed a suitable HW5 workflow.
- Human review: The student approved the proposed end-to-end purchase workflow.

### Interaction 3 — Plan and initialize HW05

- AI tool: OpenAI Codex
- Date and time: 2026-08-28 19:51 +07:00
- Prompt: Begin the work, ask for decisions when necessary, create a plan first, use student ID 23127414, JMeter, and a clean SUT from the lecturer repository; commit every stage.
- AI output: Staged implementation plan; clean SUT baseline; JMeter installation; API smoke-test findings; initial report and audit templates.
- Human review: Pending review of the first committed stage.

### Interaction 4 — Design data-driven JMeter plans

- AI tool: OpenAI Codex
- Date: 2026-08-28
- Prompt: Continue implementing the confirmed workflow with JMeter and commit every stage.
- AI output: Proposed workload parameters, CSV pools, JWT/product/order correlation, assertions, reset scripts, and three distinct report views.
- Human review and corrections: The initial CSV `Current thread` sharing suggestion was found to reuse the first record in every thread. The design was corrected to `All threads`, one outer iteration, and an inner repeated workflow so each virtual user retains one unique account. Smoke testing also found that dotted CLI property names were parsed incorrectly on Windows and that a Groovy checkout calculation had not converted both CSV operands. Both issues were corrected. Final workload values remain hypotheses until calibration runs.

### Interaction 5 — Calibrate workload intensity

- AI tool: OpenAI Codex
- Date: 2026-08-28
- Prompt: Continue implementing and validate whether the proposed Load, Stress, and Spike parameters create the intended workload on the student's hardware.
- AI output: Short calibration executions at 20, 100, 200, and 500 VUs plus a 500-VU spike; JTL percentile summaries and revised workload proposal.
- Human review and corrections: The original 200-VU Stress ceiling was rejected because p95 remained approximately 8 ms with no errors. At 500 VUs, checkout p95 reached 198 ms and the 500-VU spike reached 393 ms. The Stress ceiling was raised to 1,000 VUs and the Spike burst to 500 VUs. Calibration logs are not treated as official evidence.

### Interaction 6 — Propose continuous performance testing

- AI tool: OpenAI Codex
- Date: 2026-08-28
- Prompt: Continue the homework and complete the independent Continuous Performance Testing task.
- AI output: Commit-change decision flow, three-run median p95 comparison, regression gates, baseline governance, artifact policy, false-alarm controls, and cost trade-offs.
- Human review: The proposal uses both a relative and absolute p95 threshold so small millisecond changes are not incorrectly flagged as large percentage regressions. Baseline updates require a reviewed `main` result and never occur automatically from a failing candidate.

### Interaction 7 — Analyse the official Load result

- AI tool: OpenAI Codex
- Date and time: 2026-08-28, after the 20:43–20:48 Load run.
- Prompt: The student reported that the official Load script had finished and asked what to do next.
- AI output: Validated JTL, HTML Dashboard, JMeter log, metric summary, and 301 backend resource samples; calculated percentiles, throughput, and memory range; proposed the Load report section.
- Human review and corrections: Raw JTL contained 1,112 E2E parent samples, but only 1,092 included all seven child requests. Twenty parent transactions were interrupted at the scheduler boundary and were excluded from completed-workflow p95 and throughput. E2E latency was also explicitly separated from backend latency because it includes configured think time.

### Interaction 8 — Analyse the official Stress result

- AI tool: OpenAI Codex
- Date and time: 2026-08-29, after the 00:46–00:53 Stress run.
- Prompt: The student supplied the completed Stress terminal output and asked to continue the staged homework process.
- AI output: Validated the 51 MB raw JTL, HTML Dashboard, JMeter log and 434 backend resource samples; computed endpoint/workflow throughput, percentiles, CPU/memory ranges and minute-level checkout degradation.
- Human review and corrections: The filename retains campaign ID `20260828`, while raw timestamps prove execution occurred after midnight on 2026-08-29. Zero request errors were not misreported as a successful performance result: endpoint p95 exceeded 500 ms around 800–900 VUs, and 1,000 scheduler-interrupted parent transactions were excluded from complete E2E statistics. CPU saturation is treated as a correlation requiring profiling, not a proven sole root cause.

### Interaction 9 — Review Stress screenshots and challenge Dashboard percentiles

- AI tool: OpenAI Codex
- Date and time: 2026-08-29, after the student added four Stress screenshots.
- Prompt: The student reported that the requested Stress screenshots had been added.
- AI output: Validated Statistics, Response Times Over Time, Active Threads Over Time and Task Manager CPU screenshots; detected that HTML percentiles disagreed with the exact JTL summary despite identical sample counts and averages.
- Human review and corrections: Local JMeter configuration revealed the default 20,000-sample percentile sliding window. Regenerating a temporary report from the same immutable JTL with `jmeter.reportgenerator.statistic_window=-1` reproduced the exact full-JTL Login median/p95 (223/1,210 ms) and Checkout median/p95 (242/1,289 ms). The official runner was updated for future scenarios; the original Stress HTML and screenshot were preserved as evidence rather than rewritten.

### Interaction 10 — Analyse the official Spike result

- AI tool: OpenAI Codex
- Date and time: 2026-08-29, after the 01:09–01:13 Spike run.
- Prompt: The student supplied the completed Spike terminal output.
- AI output: Validated raw JTL, full-window HTML Dashboard, execution log and 243 backend resource samples; calculated exact percentiles, 10-second checkout windows, recovery time and CPU/memory behavior.
- Human review and corrections: A 924 ms checkout maximum occurred in a seven-sample startup bucket before the burst, so it was rejected as evidence of spike impact. Recovery was reported as no more than 10 seconds, matching the analysis resolution, rather than claiming an exact instantaneous recovery time. The 510 scheduler-interrupted parent transactions were excluded from completed E2E results and were not misclassified as functional failures.

### Interaction 11 — Clarify and analyse the required endurance/Soak run

- AI tool: OpenAI Codex
- Date and time: 2026-08-29, after the 01:37–01:52 Soak run.
- Prompt: The student asked where Soak was required, requested a detailed recording procedure, supplied the completed terminal result and added five screenshots.
- AI output: Re-read the original PDF and located the explicit 10–15 minute sustained-load requirement; validated the full JTL, HTML, log, 901 backend resource samples and screenshots; calculated exact percentiles, per-minute checkout throughput/latency, CPU utilization and memory growth.
- Human review and corrections: The observed 300-VU result is described as the highest tested stable sustained level, not an absolute hardware maximum. Zero errors and a 34 ms whole-run checkout p95 were not treated as the whole story: minute-level checkout p95 rose from 13–15 ms to 81 ms while working set grew about 1.4 MB/minute. Memory dropped after load ended, so the result is recorded as a resource-growth signal requiring a longer test, not proof of a memory leak.

### Interaction 12 — Classify AI optimization proposals against the SUT code

- AI tool: OpenAI Codex
- Date and time: 2026-08-29, after all official runs completed.
- Prompt: Continue all remaining report sections while the student will provide the video link later.
- AI output: Inspected the lecturer baseline schema/routes and classified cart cleanup, pagination/indexes, WAL/cache/runner isolation, connection pooling, Node clustering and distributed infrastructure proposals; prepared issue drafts and final conclusions.
- Human review and corrections: Recommendations were not accepted by plausibility alone. Cart cleanup and order pagination/indexing map directly to code and measurable trends. WAL/cache require A/B evidence. Generic connection pools, immediate Node clustering and Redis/Kubernetes were rejected as incompatible or unsupported because the current SUT uses one SQLite connection and process-local cart state. CPU remains a correlated bottleneck candidate, not a proven sole cause.

### Interaction 13 — Draft and verify the mandatory AI Critique

- AI tool: OpenAI Codex
- Date and time: 2026-08-29, after the analysis and optimization review.
- Prompt: Continue the remaining homework sections, including the mandatory 200–300-word critique.
- AI output: Drafted a Vietnamese critique grounded in the verified Dashboard sliding-window error, incomplete parent transactions, correlation-versus-causation risk and architecture-incompatible optimization proposals.
- Human review and corrections: The paragraph was measured at 284 whitespace-delimited words, cites the correct full-JTL values, explains why the mistakes occurred, and states the learned human-review principle. It is included both as a standalone deliverable and in the main report.

> Every later AI interaction used to design plans or analyse logs must be appended with the exact prompt, full output or a durable transcript link, date/time, and the student's correction notes.
