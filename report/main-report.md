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

### 6.1 Cấu hình và mục tiêu

- Test plan: `23127414_Load_20260828.jmx`.
- Virtual users: 20.
- Ramp-up: 60 giây.
- Tổng thời gian: 300 giây, từ 20:43:15 đến 20:48:15 ngày 28/08/2026.
- Think time: phân phối đều ngẫu nhiên 400–1000 ms trước mỗi request.
- Report view: Summary Report; kết quả chính thức được chạy bằng CLI và xuất thêm HTML Dashboard.

Mục tiêu của Load test là kiểm tra workflow đầy đủ dưới mức tải ổn định đã được calibration trước đó. Tiêu chí tạm thời là error rate dưới 1% và p95 của từng endpoint dưới 500 ms.

### 6.2 Kết quả

| Label | Samples | Failures | Average | p50 | p90 | p95 | p99 | Max |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Login | 1.110 | 0 | 3,41 ms | 3 ms | 5 ms | 6 ms | 10 ms | 52 ms |
| Search products | 1.108 | 0 | 1,98 ms | 2 ms | 3 ms | 4 ms | 6 ms | 17 ms |
| Product detail | 1.105 | 0 | 1,97 ms | 2 ms | 3 ms | 3 ms | 7 ms | 19 ms |
| View cart | 1.104 | 0 | 2,37 ms | 2 ms | 4 ms | 4 ms | 6 ms | 16 ms |
| Add to cart | 1.099 | 0 | 2,48 ms | 2 ms | 4 ms | 4 ms | 5 ms | 15 ms |
| Checkout | 1.097 | 0 | 8,03 ms | 6 ms | 15 ms | 17 ms | 19 ms | 684 ms |
| Order history | 1.092 | 0 | 3,35 ms | 3 ms | 5 ms | 6 ms | 9 ms | 15 ms |
| E2E hoàn chỉnh | 1.092 | 0 | 4.918,34 ms | 4.933 ms | 5.504 ms | 5.628 ms | 5.919 ms | 6.250 ms |

Tổng cộng có 7.715 endpoint sample, tương đương khoảng 25,7 request/giây. Hệ thống hoàn thành 1.092 workflow, tương đương 3,642 workflow/giây, với error rate 0%. Checkout có một outlier 684 ms nhưng p99 chỉ 19 ms, vì vậy outlier này không đại diện cho phần lớn request và cần theo dõi tiếp trong Stress/Soak thay vì kết luận bottleneck từ một mẫu.

### 6.3 Human review đối với parent transaction

Raw JTL chứa 1.112 parent sample `E2E Purchase Workflow`, nhưng chỉ 1.092 sample có thông báo đủ bảy request. Hai mươi sample còn lại tương ứng 20 thread đang ở giữa vòng lặp khi scheduler kết thúc. Chúng không phải functional failure nhưng cũng không phải workflow hoàn chỉnh. Vì vậy báo cáo sử dụng 1.092 làm mẫu số E2E và throughput 3,642 workflow/giây, không dùng trực tiếp con số 1.112 mà công cụ có thể tổng hợp.

E2E p95 bao gồm bảy think-time delay, nên không được diễn giải là server latency. Chỉ số này đo thời gian trải nghiệm toàn workflow mô phỏng; p95 endpoint mới phù hợp để đánh giá phản hồi backend.

### 6.4 Tài nguyên backend

- Số mẫu tài nguyên: 301.
- Working set: từ 45,75 MB lên 82,70 MB; cực đại 83,75 MB.
- Private memory: từ 54,30 MB lên 97,57 MB; cực đại 98,90 MB.
- Backend dùng thêm 19,92 CPU-second trong khoảng giám sát 304,69 giây.
- Thread backend cực đại: 14.

Memory tăng trong Load test có thể do số đơn hàng và dữ liệu runtime tích lũy; một lần chạy 5 phút chưa đủ để gọi đây là memory leak. Soak test sẽ kiểm tra liệu mức sử dụng có đạt plateau hay tiếp tục tăng không giới hạn.

### 6.5 Kết luận Load

Load test đạt tiêu chí tạm thời: 0% lỗi và tất cả endpoint p95 thấp hơn 20 ms. Với 20 VU, SUT ổn định; chưa có bằng chứng về saturation. Bằng chứng thô và HTML report nằm trong `results/load/20260828/`. Ba ảnh do sinh viên cung cấp tại `evidence/load/` ghi lại bảng Statistics, biểu đồ Response Times Over Time và Task Manager; chuỗi mẫu tài nguyên backend trong suốt lần chạy nằm tại `results/load/20260828/backend-resource-usage.csv`.

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
