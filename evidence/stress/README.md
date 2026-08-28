# Stress visual evidence

These are real screenshots supplied by the student after the official Stress run.
They are not AI-generated or reconstructed.

| File | Evidence shown |
|---|---|
| `image.png` | JMeter HTML Dashboard — Statistics table |
| `image copy.png` | JMeter HTML Dashboard — Response Times Over Time |
| `image copy 2.png` | JMeter HTML Dashboard — Active Threads Over Time, showing the ramp to 1,000 VUs |
| `image copy 3.png` | Windows Task Manager — CPU graph, processor model, 6 cores/12 logical processors and memory summary |

The Statistics screenshot uses JMeter's default 20,000-sample sliding window for
percentile estimation. Therefore its percentile values differ from the exact full-JTL
values in `metric-summary.csv`; sample counts, averages and error rates remain valid.
The report documents this distinction instead of silently treating the screenshot
percentiles as exact.

The automatic backend process record is already stored at
`results/stress/20260828/backend-resource-usage.csv`.
