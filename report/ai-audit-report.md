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

> Every later AI interaction used to design plans or analyse logs must be appended with the exact prompt, full output or a durable transcript link, date/time, and the student's correction notes.
