# HW05 — Báo cáo kiểm thử hiệu năng EShop

## 1. Thông tin bài làm

- MSSV: `23127414`
- Công cụ: Apache JMeter 5.6.3
- SUT baseline: `85af3ba875c88283615e22cb108f13e2fccaf0e9`
- Ngày chạy chính thức: _Chưa chạy_

## 2. Môi trường kiểm thử

| Thành phần | Thông số |
|---|---|
| Hostname | `MINHLUAN` |
| CPU | Intel Core i5-11400H, 6 nhân/12 luồng, 2.70 GHz |
| RAM | 15.77 GB |
| Hệ điều hành | Windows 11 Home Single Language, 10.0.26200 |
| Java | OpenJDK 21.0.11 LTS |
| Node.js | v22.16.0 |
| JMeter | 5.6.3 |

_Cần bổ sung ảnh dxdiag có cùng hostname và ảnh Task Manager trong từng lần chạy._

## 3. Workflow và phạm vi endpoint

```text
Login → Search/List → Product detail → View cart → Add to cart
→ Checkout → Order history
```

_Giải thích ánh xạ auth-heavy, read-heavy và transactional._

## 4. Quy trình thiết kế có AI hỗ trợ và human review

_Ghi prompt theo từng bước, đầu ra AI, lỗi hoặc thiếu sót và cách sửa._

## 5. Dữ liệu kiểm thử và correlation

_Mô tả CSV account pool, JWT extraction, product/order correlation và reset procedure._

## 6. Load test

_Tham số, lý do lựa chọn, ảnh bằng chứng, kết quả, p50/p90/p95/p99, throughput, error rate và tài nguyên._

## 7. Stress test

_Các bậc tải, điểm suy giảm, ảnh bằng chứng và ngưỡng thất bại._

## 8. Spike test

_Tải nền, mức spike, thời gian hồi phục, ảnh bằng chứng và kết quả._

## 9. Endurance/soak test

_Kết quả chạy 10–15 phút và ngưỡng ổn định trên phần cứng thực tế._

## 10. AI analysis và misinterpretation hunt

_Đối chiếu từng nhận định AI với giá trị đúng trong JTL._

## 11. Đánh giá đề xuất tối ưu

_Phân loại khả thi, cần bằng chứng thêm hoặc hallucinated._

## 12. Continuous Performance Testing

Đề xuất đầy đủ và flowchart nằm tại `report/continuous-performance-testing.md`. Mô hình sử dụng smoke + Load test có chọn lọc trên Pull Request, ba lần chạy để lấy median p95, và Stress/Spike/Soak theo lịch hoặc trước release. Regression được đánh dấu khi p95 tăng hơn 20% đồng thời lệch tuyệt đối trên 50 ms, error rate từ 1%, hoặc throughput giảm trên 15%.

## 13. Issues phát hiện

_Liên kết GitHub Issues và bằng chứng, nếu có._

## 14. Kết luận

_Tóm tắt ngưỡng phần cứng, bottleneck, hạn chế và hướng cải tiến._
