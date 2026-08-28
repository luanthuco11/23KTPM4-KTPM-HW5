# HW05 — Báo cáo kiểm thử hiệu năng EShop

## 1. Thông tin bài làm

- MSSV: `23127414`
- Công cụ: Apache JMeter 5.6.3
- SUT baseline: `85af3ba875c88283615e22cb108f13e2fccaf0e9`
- Ngày chạy chính thức: 28–29/08/2026 (Load và Stress đã hoàn thành)

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

_Đã có ảnh Task Manager của Load; cần bổ sung ảnh dxdiag có cùng hostname và ảnh cho Stress, Spike, Soak._

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

### 7.1 Cấu hình và mục tiêu

- Test plan: `23127414_Stress_20260828.jmx`.
- Campaign ID trong tên file: `20260828`; timestamp JTL thực tế: 00:46:11–00:53:13 ngày 29/08/2026 do lần chạy bắt đầu sau nửa đêm.
- Tải tăng tuyến tính từ 0 lên 1.000 VU trong 300 giây và giữ đến khi scheduler kết thúc ở 420 giây.
- Think time: phân phối đều ngẫu nhiên 400–1000 ms trước mỗi request.
- Report view trong test plan: Aggregate Report; lần chạy chính thức dùng CLI và xuất HTML Dashboard.
- Mục tiêu: tìm vùng tải mà p95 endpoint vượt tiêu chí tạm thời 500 ms, xuất hiện lỗi hoặc throughput không còn tăng tương xứng.

### 7.2 Kết quả tổng hợp

| Label | Samples | Failures | Average | p50 | p90 | p95 | p99 | Max |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Login | 38.810 | 0 | 371,78 ms | 223 ms | 907 ms | 1.210 ms | 1.843 ms | 3.129 ms |
| Search products | 38.662 | 0 | 328,04 ms | 210 ms | 796 ms | 978 ms | 1.479 ms | 2.961 ms |
| Product detail | 38.624 | 0 | 310,64 ms | 207 ms | 746 ms | 893 ms | 1.366 ms | 2.956 ms |
| View cart | 38.599 | 0 | 142,42 ms | 98 ms | 340 ms | 397 ms | 565 ms | 1.192 ms |
| Add to cart | 38.586 | 0 | 154,36 ms | 105 ms | 368 ms | 436 ms | 615 ms | 1.278 ms |
| Checkout | 38.555 | 0 | 396,46 ms | 242 ms | 961 ms | 1.289 ms | 1.994 ms | 3.137 ms |
| Order history | 38.259 | 0 | 415,47 ms | 241 ms | 1.035 ms | 1.428 ms | 2.142 ms | 3.029 ms |
| E2E hoàn chỉnh | 37.974 | 0 | 6.958,76 ms | 6.297 ms | 9.801 ms | 10.389 ms | 11.500 ms | 13.549 ms |

Có 270.095 endpoint sample và 37.974 workflow hoàn chỉnh. Trong cửa sổ giám sát 440,29 giây, throughput endpoint xấp xỉ 613,4 request/giây. Không có lỗi HTTP hoặc assertion. Một nghìn parent transaction còn dang dở ở ranh giới scheduler được loại khỏi thống kê E2E hoàn chỉnh; đây không phải 1.000 functional failure.

### 7.3 Điểm suy giảm theo mức tải

| Phút từ khi bắt đầu | Thread trung bình/cực đại | Checkout samples | Checkout average | Checkout p95 |
|---:|---:|---:|---:|---:|
| 0 | 136 / 201 | 1.164 | 7,6 ms | 11 ms |
| 1 | 312 / 401 | 3.585 | 6,5 ms | 12 ms |
| 2 | 508 / 601 | 5.977 | 13,9 ms | 48 ms |
| 3 | 703 / 802 | 7.616 | 100,5 ms | 255 ms |
| 4 | 899 / 1.000 | 7.277 | 415,1 ms | 698 ms |
| 5 | 1.000 / 1.000 | 6.732 | 719,7 ms | 1.082 ms |
| 6 | 981 / 1.000 | 6.198 | 1.053,7 ms | 2.059 ms |

Checkout p95 vẫn dưới 500 ms đến vùng khoảng 800 VU, sau đó vượt ngưỡng khi tải tiến đến 900–1.000 VU. Đồng thời số checkout/phút giảm từ 7.616 xuống 6.198 dù tải đã tăng, cho thấy hàng đợi và saturation thay vì scaling tuyến tính. Vì ramp tăng liên tục, dữ liệu này chỉ khoanh vùng ngưỡng thực dụng khoảng 800–900 VU; muốn xác định chính xác cần một test bậc thang riêng quanh vùng này.

### 7.4 Tài nguyên backend và kết luận

- 434 mẫu tài nguyên backend trong 440,29 giây.
- CPU tăng 434,84 CPU-second, tương đương trung bình 98,76% của một logical core (8,23% nếu chia trên toàn bộ 12 logical processor).
- Working set: 43,72 MB ban đầu, 156,75 MB cuối, cực đại 161,72 MB.
- Private memory: 54,72 MB ban đầu, 169,52 MB cuối, cực đại 173,94 MB.
- Số thread backend cực đại: 12.

Node.js backend gần bão hòa một logical core trong toàn cửa sổ tải cao, phù hợp với độ trễ và throughput suy giảm. Stress test không làm hệ thống crash và error rate vẫn 0%, nhưng đã thất bại tiêu chí hiệu năng p95 500 ms ở vùng tải cao. Kết luận này là correlation từ dữ liệu hiện có, chưa chứng minh CPU là nguyên nhân duy nhất; database, event loop và client-side load generator cần profiling bổ sung để khẳng định quan hệ nhân quả. Raw JTL, HTML Dashboard, log và CSV tài nguyên nằm trong `results/stress/20260828/`.

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
