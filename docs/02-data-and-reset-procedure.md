# Test-data and reset procedure

## Why isolated accounts are required

The SUT stores carts in memory and keys them by authenticated user ID. Reusing one account across concurrent JMeter threads would combine multiple virtual users into one cart and invalidate workflow measurements. The plans therefore set `Sharing mode = All threads`, run the outer thread-group loop once, and repeat the workflow inside a nested loop. Each virtual user consumes one unique CSV row and retains it for the run.

## CSV fields

| Field | Purpose |
|---|---|
| `name` | Account preparation and traceability |
| `email` | Login credential unique to the scenario and VU |
| `password` | Valid synthetic password |
| `searchTerm` | Data-driven product search |
| `quantity` | Data-driven cart payload |
| `shippingAddress` | Data-driven checkout payload |

JWT, product ID, product price, and order ID are extracted from live responses rather than supplied by CSV.

## Clean preparation before every official run

From the HW5 repository root:

```powershell
.\scripts\Reset-And-Prepare.ps1
```

This procedure:

1. Stops only the backend process recorded by this project.
2. Starts the clean lecturer SUT.
3. Lets the SUT recreate and reseed SQLite.
4. Registers all synthetic performance accounts through `POST /api/register`.

Restarting the backend also resets `login_attempts` and `locked_until`. This is the documented account-lockout reset procedure required between runs. The performance workflow always submits valid passwords, so a lockout indicates test-data or correlation failure and must not be ignored.

## Post-run cleanup

```powershell
.\scripts\Stop-Sut.ps1
```

Runtime PID and log files are local-only and excluded from Git.
