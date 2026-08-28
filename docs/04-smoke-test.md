# JMeter smoke-test record

Date: 2026-08-28

## Scope

Each generated plan was executed in JMeter 5.6.3 CLI mode with shortened duration and reduced virtual users. The purpose was structural and functional validation, not performance measurement.

| Plan | Smoke VUs | Duration | Successful JTL rows | Failed rows |
|---|---:|---:|---:|---:|
| Load | 1 | 12 s | 18 | 0 |
| Stress | 2 | 12 s | 39 | 0 |
| Spike | 1 baseline + 2 burst | 15 s | 43 | 0 |

All seven workflow requests completed and the JWT, product fields, calculated checkout payload, order ID, and order-history verification were exercised.

## Problems found and corrected

1. The Windows JMeter launcher parsed dotted CLI override names incorrectly. Override properties now use underscore names.
2. The first checkout Groovy expression left the CSV quantity as a string. Both price and quantity are now converted to `BigDecimal` before multiplication.
3. An initial failed Load smoke file was discarded from evidence after the defects were corrected. It is not an official result and is excluded from Git.

## Conclusion

The corrected Load, Stress, and Spike plans are syntactically valid and functionally ready for calibration. Smoke results must not be presented as official performance results.

