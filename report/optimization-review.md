# Đánh giá đề xuất tối ưu của AI

## Tiêu chí phân loại

- **Khả thi:** khớp code hiện tại và có đường kiểm chứng rõ.
- **Cần bằng chứng thêm:** hợp lý về kỹ thuật nhưng JTL/resource CSV chưa chứng minh root cause hoặc mức lợi ích.
- **Hallucinated/không phù hợp:** giả định thành phần không tồn tại hoặc bỏ qua ràng buộc kiến trúc SUT.

## Bảng đánh giá

| Đề xuất AI | Phân loại | Human review và cách kiểm chứng |
|---|---|---|
| Clear cart sau checkout | Khả thi, ưu tiên cao | `userCarts[userId]` nhận thêm item mỗi vòng nhưng checkout không xóa. Soak cho thấy memory tăng khi tải còn chạy. Sửa rồi so sánh slope memory và p95 trên cùng 300 VU/15 phút. |
| Phân trang `GET /api/orders/my-orders` | Khả thi, ưu tiên cao | Endpoint đang `SELECT *` toàn bộ order của user; response tăng sau mỗi checkout. Thêm `limit/cursor`, nhưng assertion cần tìm order mới ở trang đầu. So sánh bytes, p95 và CPU theo phút. |
| Index `orders(user_id, id DESC)` | Khả thi, ưu tiên cao | Schema chỉ có primary key `id`; query lọc `user_id` và sort `id DESC` mỗi vòng. Dùng `EXPLAIN QUERY PLAN` trước/sau và A/B Stress/Soak. |
| Index hoặc unique constraint cho `users(email)` | Khả thi | Login tra `email` mỗi vòng nhưng schema không index. Unique constraint còn ngăn account trùng; phải kiểm tra dữ liệu/migration trước khi áp dụng. |
| Parameterize product search | Khả thi về correctness/security | Search hiện ghép `LIKE '%${searchQuery}%'`. Parameterization ngăn injection nhưng không tự làm `%term%` nhanh hơn; không được quảng bá là performance fix nếu chưa benchmark. |
| Bật SQLite WAL | Cần bằng chứng thêm | Có workload đọc/ghi đồng thời nên WAL có thể giảm contention. Tuy nhiên app dùng một `sqlite3.Database`, official runs không có `SQLITE_BUSY`, và CPU mới là correlation mạnh. Cần A/B cùng workload, error/p95 và journal checkpoint policy. |
| Cache product list/detail | Cần bằng chứng thêm | Product seed chỉ có 5 dòng; caching có thể giảm lặp query nhưng chưa chắc giải quyết order-history/checkout. Profile thời gian theo route trước khi thêm invalidation complexity. |
| Tách load generator khỏi SUT | Cần bằng chứng thêm, nên làm để tăng độ tin cậy | JMeter và backend cùng máy có thể cạnh tranh CPU/RAM. Đây cải thiện phép đo, không phải tối ưu code. So sánh runner riêng trước khi tuyên bố giới hạn server. |
| Thêm database connection pool | Không phù hợp với kiến trúc hiện tại | SUT dùng một SQLite file và một `sqlite3.Database`, không phải PostgreSQL/MySQL service. Pool chung chung có thể tăng lock contention; cần đổi kiến trúc DB trước khi đề xuất này có nghĩa. |
| Chạy nhiều Node worker ngay lập tức | Không khả thi nếu chưa sửa state | `userCarts` là object trong process; nhiều worker tạo cart khác nhau theo request. SQLite write contention cũng chưa được xử lý. Cluster chỉ được xem xét sau khi externalize state và test consistency. |
| Thêm Redis/Kubernetes autoscaling | Hallucinated/quá mức | Không có Redis, distributed session hay deployment topology trong SUT. Autoscale nhiều instance sẽ làm cart in-memory sai trước khi giải quyết bottleneck. Không có dữ liệu chi phí/lợi ích để biện minh. |

## Thứ tự thử nghiệm

1. Clear cart đúng nghiệp vụ và phân trang order history.
2. Thêm index có mục tiêu; kiểm tra query plan.
3. Chạy lại Load/Stress/Soak cùng seed, hardware và JMeter plan.
4. Profile CPU/event-loop và route timing nếu p95 vẫn tăng.
5. Chỉ sau đó A/B WAL, cache hoặc thay đổi kiến trúc.

Mỗi optimization chỉ được chấp nhận khi error rate/assertion không xấu đi và median của ba lần chạy cho p95/throughput cải thiện vượt nhiễu đo.
