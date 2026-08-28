# HW05 — Báo cáo kiểm thử hiệu năng EShop

## 1. Thông tin bài làm

- MSSV: `23127414`
- Công cụ: Apache JMeter 5.6.3
- SUT baseline: `85af3ba875c88283615e22cb108f13e2fccaf0e9`
- Ngày chạy chính thức: 28–29/08/2026 (Load, Stress, Spike và Soak đã hoàn thành)

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

_Đã có ảnh JMeter Dashboard và Task Manager cho từng lần chạy; cần bổ sung ảnh dxdiag có cùng hostname._

## 3. Workflow và phạm vi endpoint

```text
Login → Search/List → Product detail → View cart → Add to cart
→ Checkout → Order history
```

| Nhóm | Bước trong workflow | Lý do |
|---|---|---|
| Auth-heavy | `POST /api/login` | Mỗi vòng tạo JWT và tra cứu tài khoản; test dùng tài khoản riêng để không kích hoạt lockout ngoài ý muốn |
| Read-heavy | `GET /api/products`, `GET /api/products/:id`, `GET /api/cart` | Tìm kiếm, đọc chi tiết và trạng thái giỏ; product ID được correlation từ kết quả tìm kiếm |
| Transactional | `POST /api/cart`, `POST /api/checkout` | Thay đổi giỏ hàng và ghi đơn hàng SQLite |
| Verification | `GET /api/orders/my-orders` | Xác nhận `orderId` vừa tạo xuất hiện trong lịch sử, tránh coi HTTP 200 là thành công nghiệp vụ |

Cả Load, Stress, Spike và Soak đều dùng đúng chuỗi bảy request trên. Nhờ vậy khác biệt kết quả phản ánh workload model thay vì thay đổi business flow giữa các scenario.

## 4. Quy trình thiết kế có AI hỗ trợ và human review

Quá trình AI-first được chia thành các vòng: đọc đề, chọn workflow, sinh dữ liệu/JMX, smoke, calibration, chạy chính thức, phân tích JTL và challenge kết luận. Chi tiết prompt, thời gian, output và human correction nằm trong `report/ai-audit-report.md`.

| Đầu ra AI ban đầu | Human review | Sửa cuối |
|---|---|---|
| CSV sharing mode `Current thread` | Mỗi thread bắt đầu lại từ dòng đầu, làm nhiều VU dùng chung account/cart | `All threads`, outer loop một lần và inner workflow loop |
| Stress ceiling 200 VU | Calibration 200 VU vẫn 0 lỗi, endpoint p95 chỉ 6–8 ms | Tăng Stress lên 1.000 VU sau calibration 500 VU |
| Dùng trực tiếp số parent transaction | Parent ở cuối scheduler có thể chưa đủ bảy child sample | Chỉ tính E2E hoàn chỉnh khi response message ghi đủ 7 sample |
| Tin percentile HTML mặc định | Stress có hơn 20.000 sample/label nên sliding window làm median/p95 lệch raw JTL | Dùng full JTL; đặt `statistic_window=-1` cho Spike/Soak |
| Có thể gọi CPU là root cause | CPU và latency cùng tăng chỉ tạo correlation | Ghi CPU là bottleneck ứng viên; yêu cầu profiling/A-B test để chứng minh |

Các lỗi kỹ thuật khác được sửa trong smoke gồm tên CLI property có dấu chấm bị Windows batch parse sai và phép nhân Groovy giữa `BigDecimal` với chuỗi CSV. Mỗi giai đoạn được commit riêng, không sửa SUT để làm đẹp kết quả.

## 5. Dữ liệu kiểm thử và correlation

CSV chứa `name,email,password,searchTerm,quantity,shippingAddress`. Load dùng pool 40 tài khoản; Stress 1.200; Spike tách 20 baseline và 600 burst. Soak dùng pool Stress. Mỗi VU lấy một dòng duy nhất và giữ tài khoản đó trong toàn lần chạy vì SUT lưu cart bằng object trong RAM theo user ID.

Correlation theo response thật:

1. Login trích `authToken`, dùng làm Bearer token.
2. Search trích `productId`, `productPrice`, `productName`.
3. Cart payload dùng product đã trích và `quantity` từ CSV.
4. Groovy chuyển cả price/quantity sang `BigDecimal` để tính `total_amount`.
5. Checkout trích `orderId`; order history phải chứa ID này.

Trước mỗi official run, `Reset-And-Prepare.ps1` chỉ dừng PID backend đã ghi, khởi động clean SUT để tái tạo SQLite, rồi đăng ký 1.860 tài khoản qua API. Restart đồng thời reset `login_attempts/locked_until`. Workflow dùng password đúng; bất kỳ lockout nào đều là lỗi dữ liệu/correlation, không bị bỏ qua.

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

Bốn ảnh sinh viên cung cấp tại `evidence/stress/` ghi lại Statistics, Response Times Over Time, Active Threads Over Time và Task Manager tab CPU. Ảnh Active Threads xác nhận ramp tăng đến 1.000 VU; ảnh Response Times cho thấy độ trễ tăng đồng thời với tải.

## 8. Spike test

### 8.1 Cấu hình và mục tiêu

- Test plan: `23127414_Spike_20260829.jmx`.
- Thời gian: 01:09:44–01:13:45 ngày 29/08/2026.
- Baseline: 10 VU, ramp 10 giây, chạy 240 giây.
- Burst: thêm 500 VU tại giây 60, ramp chỉ 5 giây và duy trì 60 giây.
- Tổng tải cực đại: 510 VU.
- Report view trong test plan: View Results Tree; lần chạy chính thức dùng CLI và HTML Dashboard.
- Mục tiêu: đo mức tăng độ trễ tức thời và thời gian hệ thống trở lại baseline sau khi burst kết thúc.

### 8.2 Kết quả tổng hợp

| Label | Samples | Failures | Average | p50 | p90 | p95 | p99 | Max |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Login | 6.400 | 0 | 19,90 ms | 7 ms | 52 ms | 92 ms | 187 ms | 293 ms |
| Search products | 6.324 | 0 | 18,43 ms | 6 ms | 51 ms | 85 ms | 196 ms | 298 ms |
| Product detail | 6.265 | 0 | 18,61 ms | 6 ms | 52 ms | 88 ms | 181 ms | 285 ms |
| View cart | 6.184 | 0 | 9,14 ms | 3 ms | 25 ms | 41 ms | 89 ms | 130 ms |
| Add to cart | 6.114 | 0 | 9,41 ms | 3 ms | 24 ms | 43 ms | 96 ms | 132 ms |
| Checkout | 6.029 | 0 | 22,99 ms | 10 ms | 55 ms | 94 ms | 206 ms | 924 ms |
| Order history | 5.954 | 0 | 21,38 ms | 8 ms | 59 ms | 97 ms | 211 ms | 285 ms |
| E2E hoàn chỉnh | 5.953 | 0 | 5.021,11 ms | 5.016 ms | 5.639 ms | 5.820 ms | 6.100 ms | 6.442 ms |

Toàn bộ lần chạy có 43.270 endpoint sample và 5.953 workflow hoàn chỉnh. Có 510 parent E2E bị scheduler cắt khi các thread burst và baseline kết thúc; chúng được loại khỏi percentile E2E nhưng không được tính thành request failure. Error rate endpoint là 0%.

### 8.3 Tác động của burst và khả năng hồi phục

| Khoảng thời gian | Active threads | Checkout samples | Checkout average | Checkout p95 |
|---|---:|---:|---:|---:|
| 50–59 giây, trước burst | trung bình 10, cực đại 15 | 21 | 9,2 ms | 19 ms |
| 60–69 giây | trung bình 501, cực đại 510 | 602 | 34,8 ms | 86 ms |
| 70–79 giây | 510 | 994 | 38,2 ms | 210 ms |
| 80–89 giây | 510 | 1.027 | 11,6 ms | 31 ms |
| 90–99 giây | 510 | 1.037 | 9,6 ms | 22 ms |
| 100–109 giây | 510 | 1.021 | 25,0 ms | 131 ms |
| 110–119 giây | trung bình 495, cực đại 510 | 986 | 28,4 ms | 119 ms |
| 120–129 giây, burst kết thúc | trung bình 19, cực đại 68 | 28 | 7,0 ms | 14 ms |
| 130–139 giây, baseline | 10 | 21 | 9,9 ms | 19 ms |

Burst làm checkout p95 tăng từ khoảng 19 ms lên cực đại có ý nghĩa 210 ms ở cửa sổ 70–79 giây, nhưng vẫn dưới tiêu chí tạm thời 500 ms. Ngay cửa sổ 10 giây đầu sau khi burst kết thúc, p95 đã trở về 14 ms và cửa sổ kế tiếp là 19 ms; vì vậy recovery time quan sát được là không quá 10 giây theo độ phân giải phân tích. Mẫu checkout 924 ms ở 0–9 giây là một outlier trong chỉ 7 mẫu khởi động, xuất hiện trước burst và không được dùng để quy nguyên nhân cho spike.

### 8.4 Tài nguyên backend và kết luận

- 243 mẫu trong 246,07 giây.
- Working set: 44,74 MB ban đầu, cực đại 105,97 MB, còn 59,52 MB cuối lần chạy.
- Private memory: 56,54 MB ban đầu, cực đại 118,36 MB, còn 69,21 MB cuối lần chạy.
- Burst 60 giây tiêu thụ xấp xỉ 60 CPU-second, tương đương trung bình khoảng một logical core; cửa sổ 10 giây cao nhất đạt khoảng 119% của một logical core.
- Số thread backend cực đại: 14.

Hệ thống hấp thụ spike 10→510 VU mà không có lỗi, p95 endpoint vẫn dưới 500 ms và độ trễ checkout trở lại baseline trong không quá 10 giây sau burst. Memory không trở lại đúng mức ban đầu nhưng đã giảm mạnh từ đỉnh 105,97 MB xuống 59,52 MB; kết quả này phù hợp với thu hồi bộ nhớ sau burst và chưa đủ để kết luận memory leak. Raw JTL, HTML Dashboard và CSV tài nguyên nằm trong `results/spike/20260829/`.

Bốn ảnh tại `evidence/spike/` ghi lại Statistics, bước nhảy trên Active Threads Over Time, Response Times Over Time và Task Manager tab CPU. Tất cả ảnh Load, Stress và Spike đã được chuẩn hóa tên theo MSSV, scenario, ngày chạy/campaign và loại bằng chứng để có thể truy vết trực tiếp.

## 9. Endurance/soak test

### 9.1 Cấu hình và mục tiêu

- Test plan hỗ trợ: `23127414_Soak_20260829.jmx`.
- Thời gian: 01:37:53–01:52:53 ngày 29/08/2026.
- Tải: 300 VU, ramp 60 giây, tổng thời gian scheduler 900 giây; gần 14 phút ở mức 300 VU.
- Think time: phân phối đều ngẫu nhiên 400–1000 ms trước mỗi request.
- Report view hỗ trợ: Simple Data Writer và HTML Dashboard full-window.
- Mục tiêu: xác định mức tải duy trì cao nhất đã kiểm chứng trên máy thật, throughput ổn định, memory ceiling và dấu hiệu suy giảm theo thời gian.

Mức 300 VU được chọn vì calibration 200 VU gần như chưa tạo suy giảm, trong khi 500 VU đã làm p95 tăng rõ. Soak tại điểm giữa giúp tạo áp lực đáng kể nhưng vẫn phù hợp cho quan sát 15 phút.

### 9.2 Kết quả tổng hợp

| Label | Samples | Failures | Average | p50 | p90 | p95 | p99 | Max |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Login | 52.692 | 0 | 10,08 ms | 5 ms | 19 ms | 33 ms | 112 ms | 380 ms |
| Search products | 52.658 | 0 | 8,81 ms | 3 ms | 18 ms | 32 ms | 108 ms | 337 ms |
| Product detail | 52.621 | 0 | 8,98 ms | 3 ms | 18 ms | 32 ms | 110 ms | 372 ms |
| View cart | 52.579 | 0 | 4,19 ms | 2 ms | 7 ms | 13 ms | 48 ms | 152 ms |
| Add to cart | 52.550 | 0 | 4,20 ms | 2 ms | 7 ms | 13 ms | 47 ms | 165 ms |
| Checkout | 52.497 | 0 | 11,86 ms | 7 ms | 20 ms | 34 ms | 110 ms | 697 ms |
| Order history | 52.449 | 0 | 12,89 ms | 7 ms | 24 ms | 38 ms | 117 ms | 355 ms |
| E2E hoàn chỉnh | 52.447 | 0 | 4.962,63 ms | 4.963 ms | 5.562 ms | 5.727 ms | 6.033 ms | 6.713 ms |

Có 368.046 endpoint sample, 52.447 workflow hoàn chỉnh và 0% lỗi. Ba trăm parent transaction bị cắt tại ranh giới scheduler được loại khỏi E2E hoàn chỉnh. HTML Dashboard ghi nhận throughput endpoint tổng hợp xấp xỉ 409,53 request/giây; throughput workflow hoàn chỉnh là 58,277 workflow/giây. E2E time bao gồm bảy think-time nên không đại diện cho server latency.

### 9.3 Độ ổn định theo thời gian

| Phút | Checkout samples | Checkout RPS | Average | p95 | Working set trung bình | CPU tương đương một core |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 3.648 | 60,8 | 7,1 ms | 13 ms | 87,4 MB | 70,3% |
| 5 | 3.643 | 60,7 | 7,6 ms | 15 ms | 94,7 MB | 76,0% |
| 8 | 3.631 | 60,5 | 12,0 ms | 30 ms | 99,2 MB | 91,2% |
| 10 | 3.624 | 60,4 | 13,0 ms | 33 ms | 100,8 MB | 97,0% |
| 12 | 3.584 | 59,7 | 16,6 ms | 54 ms | 102,4 MB | 100,4% |
| 14 | 3.575 | 59,6 | 24,1 ms | 81 ms | 105,9 MB | 106,1% |

Throughput checkout chỉ giảm khoảng 2% từ 60,8 xuống 59,6 request/giây và không có lỗi, nên tải vẫn được phục vụ ổn định. Tuy nhiên p95 tăng từ 13–15 ms lên 81 ms, đồng thời CPU backend tiến đến khoảng một logical core. Đây là degradation theo thời gian ở mức nhẹ nhưng đo được; không nên chỉ nhìn p95 toàn lần chạy 34 ms rồi bỏ qua xu hướng cuối kỳ.

### 9.4 Memory ceiling và endurance threshold

- 901 mẫu tài nguyên trong 913,87 giây.
- Working set: 44,00 MB ban đầu, cực đại 108,09 MB, còn 55,21 MB sau khi tải kết thúc.
- Private memory: 54,76 MB ban đầu, cực đại 121,27 MB, còn 66,08 MB cuối cửa sổ giám sát.
- Trong giai đoạn tải ổn định, working set trung bình tăng từ 87,4 MB ở phút 1 lên 105,9 MB ở phút 14, xấp xỉ 1,4 MB/phút; private memory tăng khoảng 1,2 MB/phút.
- Backend dùng 765,55 CPU-second trong 913,87 giây, trung bình 83,77% của một logical core; những phút cuối đạt khoảng 100–106% của một core.
- Thread/handle cực đại: 13/504.

Memory chưa tạo plateau rõ ràng trong lúc 300 VU còn hoạt động, nhưng giảm mạnh ngay sau khi tải kết thúc. Vì vậy có tín hiệu tích lũy tài nguyên cần test lâu hơn, nhưng không đủ bằng chứng để kết luận memory leak. Trên phần cứng này, ngưỡng endurance **đã được chứng minh** là 300 VU, khoảng 409,5 endpoint request/giây và 58,277 workflow/giây trong 15 phút, với 0% lỗi và memory ceiling quan sát được 108,09 MB working set/121,27 MB private memory. Đây là mức sustained cao nhất đã thử, không phải maximum tuyệt đối; muốn tìm maximum phải chạy thêm nhiều bậc 350/400/450 VU trong cùng thời lượng.

Năm ảnh tại `evidence/soak/` ghi lại Statistics, Response Times Over Time, Active Threads Over Time, Transactions Per Second và Task Manager CPU. Raw JTL, HTML Dashboard và CSV tài nguyên nằm tại `results/soak/20260829/`.

## 10. AI analysis và misinterpretation hunt

### 10.1 HTML percentile không phải percentile chính xác của toàn bộ Stress JTL

JMeter HTML Dashboard mặc định dùng `jmeter.reportgenerator.statistic_window = 20000`, tức cửa sổ trượt 20.000 mẫu để ước lượng percentile. Mỗi endpoint của Stress có hơn 38.000 mẫu, vì vậy bảng Statistics trong ảnh cho Login median 597 ms và p95 1.485 ms, trong khi tính trên toàn bộ raw JTL cho kết quả lần lượt 223 ms và 1.210 ms. Checkout trên ảnh là median 625 ms, p95 1.595,95 ms; toàn bộ JTL cho 242 ms và 1.289 ms.

Đây không phải dữ liệu raw bị hỏng: average, sample count và error rate của HTML vẫn khớp. Một báo cáo kiểm chứng tạm thời được tạo lại từ chính JTL với `statistic_window=-1` và cho Login median/p95 223/1.210 ms, Checkout 242/1.289 ms, khớp `metric-summary.csv`. Do đó báo cáo dùng full JTL làm nguồn sự thật cho percentile, còn ảnh HTML dùng để chứng minh hình dạng tải và kết quả trực quan. Runner đã được sửa để Spike và Soak dùng toàn bộ mẫu khi tạo HTML.

### 10.2 Parent transaction dang dở không phải lỗi request

Stress có 38.974 raw E2E parent nhưng chỉ 37.974 workflow đủ bảy child request. Nếu chỉ nhìn error rate 0% hoặc throughput parent do Dashboard xuất ra, người đọc có thể nhầm 1.000 transaction bị scheduler cắt là workflow hoàn chỉnh. Phân tích raw JTL loại chúng khỏi p95 và throughput E2E hoàn chỉnh, nhưng không chuyển chúng thành functional failure.

## 11. Đánh giá đề xuất tối ưu

Đánh giá chi tiết nằm tại `report/optimization-review.md`. Ba kết luận chính:

1. **Khả thi và ưu tiên:** xóa cart sau checkout; phân trang order history; thêm index `orders(user_id, id DESC)` và index/unique constraint phù hợp cho `users(email)`. Các thay đổi khớp trực tiếp đường đi của workflow và cấu trúc hiện tại.
2. **Cần benchmark/profiling:** SQLite WAL, cache product list, tối ưu JWT và tách JMeter khỏi máy SUT. Chúng có cơ sở nhưng kết quả hiện tại chưa chứng minh lợi ích hoặc root cause.
3. **Không phù hợp/hallucinated trong ngữ cảnh:** “thêm connection pool” như với PostgreSQL, bật nhiều Node worker ngay lập tức, hoặc triển khai Redis/Kubernetes mà không sửa cart in-memory và đo lại. Chúng bỏ qua SQLite single-file và state cục bộ của ứng dụng.

Không proposal nào được coi là đúng chỉ vì AI nêu ra. Thứ tự thực nghiệm đề xuất là: sửa cart + pagination/index, chạy lại Load/Stress cùng dữ liệu, sau đó mới A/B test WAL hoặc thay đổi kiến trúc.

## 12. Continuous Performance Testing

Đề xuất đầy đủ và flowchart nằm tại `report/continuous-performance-testing.md`. Mô hình sử dụng smoke + Load test có chọn lọc trên Pull Request, ba lần chạy để lấy median p95, và Stress/Spike/Soak theo lịch hoặc trước release. Regression được đánh dấu khi p95 tăng hơn 20% đồng thời lệch tuyệt đối trên 50 ms, error rate từ 1%, hoặc throughput giảm trên 15%.

## 13. Issues phát hiện

Chưa tạo Issue trên GitHub vì thao tác đó cần tài khoản và quyết định xuất bản của sinh viên. Nội dung sẵn sàng đăng nằm tại `report/github-issue-drafts.md`, gồm:

- performance degradation khoảng 800–900 VU: checkout p95 vượt 500 ms và backend gần một logical core;
- cart in-memory không được clear sau checkout, phù hợp với xu hướng memory tăng trong Soak;
- order history trả toàn bộ lịch sử và không có index `(user_id, id)`, làm chi phí tăng theo số vòng.

Không ghi “crash” hoặc “HTTP error” vì bốn official run đều 0% lỗi. Functional deviations đã quan sát từ code (login attempts +2/lock 180 giây, checkout tin `total_amount` client) được ghi là issue candidates, không được trình bày như phát hiện performance đã benchmark.

## 14. Kết luận

Workflow E2E hoạt động ổn định ở Load 20 VU và chịu được Spike 10→510 VU với recovery quan sát không quá 10 giây. Stress xác định vùng suy giảm thực dụng khoảng 800–900 VU: checkout p95 từ 255 ms ở vùng cực đại 802 thread tăng lên 698 ms khi tiến đến 1.000, rồi vượt 1 giây khi giữ 1.000 VU. Hệ thống không crash và error rate vẫn 0%, nhưng không đạt tiêu chí p95 500 ms ở tải cao.

Soak chứng minh máy `MINHLUAN` duy trì 300 VU trong 15 phút ở khoảng 409,5 endpoint request/giây và 58,277 workflow/giây, 0% lỗi. Memory ceiling quan sát là 108,09 MB working set/121,27 MB private memory. Throughput chỉ giảm khoảng 2%, nhưng checkout p95 tăng từ 13–15 ms lên 81 ms và memory tăng khi tải còn hoạt động; test dài hơn cần thiết trước khi loại trừ leak.

Bottleneck ứng viên là một logical core của Node.js kết hợp truy vấn/order payload tăng dần và cart in-memory không được clear. Hạn chế gồm JMeter và SUT chạy cùng máy, chỉ một lần official/scenario, Soak chỉ một bậc 300 VU và không có profiler/event-loop lag. Vì vậy kết luận là ngưỡng đã kiểm chứng, không phải công suất tuyệt đối. Hướng tiếp theo: sửa state/cart, pagination + index, profile, rồi chạy A/B trên runner cố định theo pipeline đề xuất.

## 15. AI Critique (200–300 từ)

Trong bài này, AI hữu ích khi xây dựng nhanh cấu trúc JMeter, sinh CSV, correlation JWT–product–order và tổng hợp JTL lớn, nhưng một số kết luận ban đầu sai hoặc chưa đầy đủ. Sai lệch rõ nhất xuất hiện ở Stress test: AI có thể đọc trực tiếp HTML Dashboard và báo Login median 597 ms, p95 1.485 ms, Checkout median 625 ms, p95 1.595,95 ms. Raw JTL lại cho giá trị đúng tương ứng là 223/1.210 ms và 242/1.289 ms. Nguyên nhân là Dashboard mặc định chỉ dùng cửa sổ trượt 20.000 mẫu, trong khi mỗi endpoint có hơn 38.000 mẫu. Khi tạo lại report với statistic_window=-1, số liệu khớp raw JTL. AI cũng có xu hướng coi 1.000 parent transaction bị scheduler cắt là workflow hoàn chỉnh vì error rate vẫn bằng 0%; human review phải kiểm tra response message và chỉ giữ 37.974 flow đủ bảy child request. Ngoài ra, việc CPU gần một logical core và latency cùng tăng chỉ chứng minh correlation, chưa đủ khẳng định CPU là nguyên nhân duy nhất. Các đề xuất “thêm connection pool”, nhiều Node worker hoặc Redis/Kubernetes cũng thiếu ngữ cảnh vì SUT dùng một SQLite connection và cart nằm trong RAM từng process. Tôi học được rằng cộng tác tốt với AI đòi hỏi biến mọi nhận định thành giả thuyết có thể kiểm tra: quay lại raw artifact, hiểu cách công cụ tính metric, đối chiếu mã nguồn và chạy A/B trước khi chấp nhận optimization. AI mạnh ở tốc độ tạo phương án và phát hiện mẫu; con người phải chịu trách nhiệm về mẫu số, ngữ nghĩa nghiệp vụ, giới hạn bằng chứng và kết luận cuối cùng.
