# Kịch bản video demo HW05

Mục tiêu: video dài **ít nhất 6 phút**, có giọng thuyết minh tiếng Việt của sinh viên và được tải lên YouTube ở chế độ **Unlisted**. Có thể ghép các đoạn đã quay khi chạy từng scenario; không cần chạy lại chỉ để tạo một video liên tục.

## Nội dung đề xuất (khoảng 7–9 phút)

### 1. Giới thiệu (30–45 giây)

- Hiển thị repository và nói mã sinh viên `23127414`.
- Giới thiệu SUT EShop và E2E flow: đăng nhập → tìm sản phẩm → xem chi tiết → xem giỏ → thêm giỏ → checkout → kiểm tra lịch sử đơn hàng.
- Nêu ba nhóm endpoint: auth-heavy, read-heavy và transactional.

### 2. Thiết kế JMeter (60–90 giây)

- Mở một JMX bằng JMeter GUI để cho thấy CSV Data Set Config, HTTP requests, correlation token/product/order và assertions.
- Chỉ nhanh ba listener khác nhau: Summary Report, Aggregate Report và View Results Tree.
- Mở thư mục `test-plans/` để cho thấy đủ Load, Stress và Spike theo đúng quy tắc đặt tên.

### 3. Bằng chứng chạy test (3–4 phút)

Với mỗi Load, Stress và Spike, hiển thị đoạn quay lúc test đang chạy sao cho **JMeter/terminal và Task Manager xuất hiện cùng khung hình**. Sau đó mở HTML Dashboard hoặc ảnh evidence và nói ngắn gọn:

- **Load:** 20 VU trong 5 phút, 0% lỗi, 1.092 workflow hoàn chỉnh; endpoint p95 đều dưới 20 ms.
- **Stress:** ramp đến 1.000 VU, 0% request lỗi nhưng latency vượt tiêu chí; vùng suy giảm thực tế khoảng 800–900 VU. Phân biệt 37.974 workflow hoàn chỉnh với 1.000 parent bị scheduler cắt.
- **Spike:** từ 10 lên 510 VU, 0% lỗi; checkout p95 theo cửa sổ xấu nhất khoảng 210 ms và phục hồi trong không quá 10 giây.

Nếu dùng đoạn Soak đã quay, giới thiệu đây là yêu cầu endurance bổ sung: 300 VU trong 15 phút, 0% lỗi, khoảng 409,5 endpoint request/giây và 58,277 workflow/giây. Không tuyên bố 300 VU là maximum tuyệt đối; đây chỉ là mức sustained cao nhất đã kiểm thử.

### 4. AI analysis và kiểm chứng (60–90 giây)

- Mở `report/main-report.md`, phần Stress và AI Critique.
- Giải thích Dashboard mặc định dùng `statistic_window=20000`, nên percentile của label có hơn 20.000 mẫu có thể khác raw JTL.
- Nêu số đã kiểm chứng từ raw JTL: Login p95 1.210 ms, Checkout p95 1.289 ms; không xem parent bị ngắt là workflow hoàn chỉnh.
- Nêu một đề xuất khả thi và một đề xuất bị bác bỏ, ví dụ index cho order history là hợp lý; thêm nhiều Node worker ngay lập tức không phù hợp vì cart đang nằm trong RAM của từng process.

### 5. Demo Agent Skill (45–60 giây)

Mở terminal tại thư mục HW5 và chạy:

```powershell
powershell -ExecutionPolicy Bypass -File .\agent-skills\eshop-performance-testing\scripts\Analyze-Jtl.ps1 -JtlPath .\results\stress\20260828\23127414_Stress_20260828.jtl
```

Cho thấy kết quả Login p95 1.210 ms, Checkout p95 1.289 ms, 37.974 parent hoàn chỉnh và 1.000 parent bị ngắt. Giải thích ngắn rằng skill tái sử dụng quy trình đọc raw JTL, kiểm tra sample con và tránh diễn giải sai Dashboard.

### 6. Kết luận (30–45 giây)

- Tóm tắt Load ổn định, Stress cho thấy degradation nhưng không có lỗi, Spike phục hồi tốt và Soak ổn định ở mức đã thử.
- Nêu giới hạn: CPU/latency hiện chỉ là correlation, muốn khẳng định nguyên nhân cần profiling hoặc benchmark A/B.
- Cho thấy checklist và xác nhận raw JTL, HTML Dashboard, ảnh evidence, AI Audit, AI Critique và Git log đều có trong repository.

## Sau khi tải video

1. Chọn YouTube visibility là **Unlisted**, không chọn Private.
2. Mở link bằng cửa sổ ẩn danh để chắc chắn người chấm xem được.
3. Ghi URL thật vào `evidence/video-link.txt` và mục Demo video trong `README.md`.
4. Review Markdown, tự convert tài liệu cuối sang PDF, rồi mới đóng gói ZIP.

