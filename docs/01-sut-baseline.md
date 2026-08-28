# SUT baseline

## Source

- Repository: `https://github.com/ttbhanh/eshop-sut`
- Branch: `main`
- Commit: `85af3ba875c88283615e22cb108f13e2fccaf0e9`
- Commit date: `2026-05-15 08:30:35 +0700`
- Commit subject: `first upload`
- Backend URL: `http://localhost:3000`
- Backend stack: Node.js, Express, SQLite

The clean clone is stored locally at `eshop-sut/` and ignored by the HW5 Git repository so that the lecturer's code is not accidentally copied into the submission history.

## Verified workflow endpoints

| Step | Method and endpoint | Correlated data |
|---|---|---|
| Login | `POST /api/login` | JWT token |
| Product search | `GET /api/products?search=...` | Product ID and price |
| Product detail | `GET /api/products/{id}` | Product attributes |
| View cart | `GET /api/cart` | Current cart state |
| Add to cart | `POST /api/cart` | Success message |
| Checkout | `POST /api/checkout` | Order ID |
| Order history | `GET /api/orders/my-orders` | Created order |

A manual API smoke test completed the entire workflow successfully on 2026-08-28.

## State and data risks discovered during inspection

1. `database.js` drops and recreates the database when the backend starts because it executes initialization when required by `server.js`.
2. Only one normal test user is seeded, which is unsuitable for concurrent virtual users.
3. Cart state is held in an in-memory object keyed by user ID; accounts must not be shared between virtual users.
4. Checkout accepts `total_amount` from the client and creates an order but does not clear the in-memory cart, contrary to the stated requirement.
5. Failed login attempts increase by two and the implemented lock duration is 180 seconds, despite the specification stating increments of one and a 30-second lock.

The performance workflow therefore uses valid credentials only and prepares a dedicated account pool after each backend restart. Functional defects will be documented without modifying the SUT.

