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

> Every later AI interaction used to design plans or analyse logs must be appended with the exact prompt, full output or a durable transcript link, date/time, and the student's correction notes.
