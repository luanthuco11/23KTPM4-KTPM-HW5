# GitHub Issue drafts

Các draft này chưa được xuất bản. Sinh viên cần đăng bằng tài khoản của mình nếu muốn đưa link Issue vào báo cáo.

## Draft 1 — Performance degrades above approximately 800–900 concurrent users

### Evidence

- Official Stress plan: `23127414_Stress_20260828.jmx`.
- 0 request failures, but checkout p95 increased from 255 ms near 700–802 threads to 698 ms while approaching 1,000 threads.
- At sustained 1,000 VUs, checkout p95 exceeded 1 second and completed checkout throughput declined.
- Backend consumed approximately one logical CPU core.
- Screenshot: `evidence/stress/23127414_Stress_20260828_ResponseTimesOverTime.png`.
- Raw evidence: `results/stress/20260828/`.

### Expected

Endpoint p95 remains below the provisional 500 ms target and throughput does not decline as concurrency approaches the supported limit.

### Suggested investigation

Profile the Node event loop and route/database time; inspect the growing order-history query and in-memory cart behavior before applying infrastructure changes.

## Draft 2 — Cart state grows indefinitely because checkout does not clear the cart

### Evidence

`POST /api/cart` pushes each body into `userCarts[userId]`. `POST /api/checkout` inserts an order but never clears that array. The 300-VU Soak run showed backend working set growing during sustained load before dropping after the workload ended.

### Expected

After successful checkout, purchased items are removed from the cart, and long-running workflows do not retain every previous cart item in process memory.

### Suggested fix and verification

Clear the authenticated user's cart only after the order insert succeeds. Re-run functional assertions plus the same 300-VU/15-minute Soak and compare memory slope.

## Draft 3 — Order history query grows without pagination or a supporting user/order index

### Evidence

`GET /api/orders/my-orders` executes `SELECT * FROM orders WHERE user_id = ? ORDER BY id DESC`. The schema has no index on `orders.user_id`, and every performance iteration creates another order before reading the entire history.

### Expected

The API returns a bounded page, with newest orders first, using a query plan supported by an index such as `(user_id, id DESC)`.

### Suggested verification

Capture `EXPLAIN QUERY PLAN`, response bytes and p95 before/after pagination and indexing using the same dataset and workload.
