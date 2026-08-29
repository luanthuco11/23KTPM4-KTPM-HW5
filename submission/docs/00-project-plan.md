# HW05 implementation plan

## Confirmed decisions

- Student ID: `23127414`.
- Tool: Apache JMeter 5.6.3.
- SUT source: lecturer repository `https://github.com/ttbhanh/eshop-sut`.
- Workflow: login, product discovery, product detail, cart, checkout, order history.
- Git practice: one focused commit for every material stage.

## Stages and commit checkpoints

1. Scaffold the submission repository and record the SUT baseline.
2. Add repeatable test-data preparation and reset procedures.
3. Add CSV data and the correlated end-to-end workflow design.
4. Add and validate the Load test plan.
5. Add and validate the Stress test plan.
6. Add and validate the Spike test plan.
7. Run and document a full smoke test.
8. Execute each official scenario and commit its raw evidence separately.
9. Execute the 10–15-minute soak test and derive the local threshold.
10. Add AI log analysis, human corrections, and optimization feasibility review.
11. Add the continuous-performance-testing proposal and flowchart.
12. Complete report exports, evidence checklist, commit log, and submission archive.

## Execution principles

- Do not modify the lecturer's SUT to make tests pass.
- Prepare test accounts through public APIs after every backend restart.
- Use unique accounts per virtual user to prevent shared cart and lockout state.
- Correlate JWT, product ID, price, and order ID from live responses.
- Use assertions for HTTP status, required response fields, and workflow continuity.
- Run official measurements in JMeter CLI mode.
- Preserve full raw JTL logs and generate HTML reports from them.
- Record observed defects separately from performance conclusions.

## Human-only evidence

The student must personally record the resource-monitor screenshots, hardware screenshot, Vietnamese narration, YouTube upload, and Moodle submission. These artifacts must not be fabricated or AI-generated.

