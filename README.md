# Hệ Thống Đặt Vé & Giữ Chỗ Chuyên Nghiệp (Airline Booking & Reservation System)

Hệ thống Cơ sở dữ liệu Quản lý Đặt vé và Giữ chỗ Chuyến bay chuẩn hoá 3NF, giải quyết bài toán giữ chỗ thời gian thực, chống trùng ghế, ràng buộc chuyến bay - máy bay và xuất vé điện tử chuẩn IATA.

---

## 📁 Tài nguyên trong Repository

- **[project.sql](project.sql)**: Kịch bản DDL/DML khởi tạo cơ sở dữ liệu `AirlineBooking`, cấu trúc 12 bảng và các ràng buộc khóa chính/ngoại (Thành viên 2).
- **[insert_data.sql](insert_data.sql)**: Kịch bản nạp dữ liệu mẫu chuẩn giáo trình CSDL và Trigger tự động cập nhật trạng thái đặt vé theo Chapter 5 (Thành viên 3).
- **[Chen_ERD.jpg](Chen_ERD.jpg)**: Sơ đồ Thực thể - Mối quan hệ mức khái niệm (Conceptual ERD) theo ký pháp Peter Chen (Thành viên 1).
- **[Relational_Schema.jpg](Relational_Schema.jpg)**: Lược đồ Cơ sở dữ liệu quan hệ mức vật lý (Physical Relational Schema / Data Model) (Thành viên 1 & 2).

---

## 🗺️ PHẦN 1: CÂU CHUYỆN TOÀN CẢNH — "HÀNH TRÌNH TỪ TÌM CHUYẾN ĐẾN XUẤT VÉ"

Để dễ quản lý, bảo trì và mở rộng, hệ thống 12 thực thể này được chia làm **3 khối nghiệp vụ chính**:

```
[Khối 1: Hạ tầng & Tàu bay] ───> [Khối 2: Chuyến bay & Mở bán] ───> [Khối 3: Đặt chỗ & Thanh toán]
(Sân bay, Tuyến, Tàu bay, Ghế gốc)     (Chuyến bay, Giá theo hạng, Ghế mở bán)      (Khách, Giữ chỗ 10p, Trả tiền, Vé)
```

---

## 🏛️ PHẦN 2: GIẢI THÍCH CHI TIẾT 3 KHỐI THỰC THỂ

### 🛫 KHỐI 1: HẠ TẦNG VẬN TẢI & CẤU HÌNH TÀU BAY (Bên trái sơ đồ)
Dữ liệu nền tảng tĩnh, được định nghĩa trước khi lên lịch bay:

1. **`AIRPORT` (Sân bay) & `ROUTE` (Tuyến bay):**
   - Một tuyến bay nối 2 sân bay: Sân bay đi (`DEPARTS`) và Sân bay đến (`ARRIVES`).
   - *Ví dụ:* Tuyến `HAN → SGN`.
2. **`AIRCRAFT` (Máy bay):**
   - Quản lý đội tàu bay (Boeing 787, Airbus A321...).
   - Trường `total_seats` lưu tổng số ghế vật lý của tàu bay.
3. **`SEAT_CLASS` (Hạng ghế):**
   - Định nghĩa các hạng dịch vụ: Thương gia (Business), Phổ thông (Economy)...
4. **`AIRCRAFT_SEAT` (Sơ đồ ghế vật lý của máy bay):**
   - Đại diện cho các ghế cứng gắn trên thân máy bay.
   - Chứa tọa độ không gian: `row_number` (hàng 12), `column_code` (cột A, B, C), `seat_position` (Cửa sổ / Lối đi), và đặc biệt là `block_code` (dãy trái / dãy phải).

---

### ✈️ KHỐI 2: CHUYẾN BAY & MỞ BÁN GHẾ (Ở giữa sơ đồ)
Chuyển đổi lịch trình danh nghĩa thành dữ liệu ghế thực tế để mở bán:

1. **`FLIGHT` (Chuyến bay cụ thể):**
   - Là một chuyến cất cánh cụ thể.
   - *Ví dụ:* Chuyến bay `VN123`, bay tuyến `HAN - SGN` lúc 08:00 ngày 15/11, khai thác bởi máy bay Boeing 787 (`aircraft_id`).
2. **`FLIGHT_CLASS_FARE` (Giá vé theo chuyến và hạng ghế):**
   - Giá vé không cố định theo ghế, mà phụ thuộc vào từng chuyến bay và từng hạng ghế (`FLIGHT` M — N `SEAT_CLASS`).
   - Lưu `base_price` và `currency` (VND/USD).
3. **`FLIGHT_SEAT` (Ghế mở bán trên chuyến bay):**
   - Khi chuyến bay được tạo ra, hệ thống nhân bản sơ đồ ghế của máy bay thành danh sách ghế riêng của chuyến bay đó.
   - Thuộc tính `status` phản ánh trạng thái ghế: Trống (`Available`), Đang giữ (`On Hold`), Đã bán (`Booked`).

---

### 💳 KHỐI 3: ĐẶT VÉ, GIỮ CHỖ 10 PHÚT, THANH TOÁN & XUẤT VÉ (Bên phải sơ đồ)
Vòng đời giao dịch đặt chỗ của khách hàng:

1. **`CUSTOMER` (Người đặt vé):**
   - Khách hàng tạo tài khoản và thực hiện giao dịch (họ tên, email, số điện thoại).
2. **`BOOKING` (Đơn đặt chỗ / Giỏ hàng):**
   - Đại diện cho 1 giao dịch.
   - Chứa `booking_time` (thời điểm bấm Đặt vé), `expiry_time` (hạn chót thanh toán đúng 10 phút), và `status` (`Pending`, `Paid`, `Cancelled`, `Expired`).
   - Nối với `FLIGHT` qua `BOOKED_ON`: Ràng buộc 1 đơn đặt vé chỉ thuộc về 1 chuyến bay duy nhất.
3. **`SEAT_RESERVATION` (Chi tiết giữ chỗ từng ghế & Hành khách):**
   - Một `BOOKING` có thể đặt nhiều ghế cho nhiều hành khách khác nhau (`BOOKING` 1 — N `SEAT_RESERVATION`).
   - Lưu: `passenger_name`, `passenger_id_no` (CCCD/Hộ chiếu), và `fare_snapshot` (giá vé chốt tại thời điểm đặt, tránh rủi ro biến động giá sau này).
4. **`PAYMENT` (Lịch sử thanh toán):**
   - Quan hệ `BOOKING` 1 — N `PAYMENT`: Cho phép lưu vết nhiều lần thử thanh toán nếu khách gặp sự cố lỗi thẻ/OTP thất bại.
5. **`TICKET` (Vé điện tử chính thức):**
   - Chỉ được cấp phát sau khi thanh toán thành công.
   - Chứa `ticket_number` (Mã vé điện tử 13 số chuẩn IATA) và `issued_at`.

---

## 🔒 PHẦN 3: GIẢI THÍCH 6 RÀNG BUỘC CỐT LÕI (CORE CONSTRAINTS)

Các quy tắc kỹ thuật mấu chốt đảm bảo tính toàn vẹn dữ liệu và loại bỏ hoàn toàn lỗi logic nghiệp vụ:

### 1. Quy tắc xuất vé có điều kiện (Conditional Ticket Issuance)
- **Ý nghĩa:** Tránh xuất vé "khống" khi chưa nhận được tiền.
- **Cách thể hiện:** Quan hệ `SEAT_RESERVATION` (1) — `ISSUES` — (0..1) `TICKET`.
- **Cơ chế:** Trong thời gian giữ chỗ (10 phút), reservation có `0` vé. Chỉ khi đơn hàng ghi nhận giao dịch `PAYMENT` thành công (`status = 'Success'`) thì hệ thống mới xuất đúng 1 bản ghi `TICKET` tương ứng (`status = 'Issued'`).

### 2. Độc quyền ghế thời gian thực & Lưu lịch sử giữ chỗ
- **Ý nghĩa:** Ngăn 2 khách hàng giữ trùng 1 ghế tại cùng một thời điểm, nhưng vẫn lưu được lịch sử các lần giữ chỗ bị hủy trong quá khứ.
- **Cách thể hiện:** Quan hệ `FLIGHT_SEAT` (1) — `HOLDS_SEAT` — (N) `SEAT_RESERVATION`.
- **Cơ chế:** Một ghế có thể gắn với nhiều bản ghi reservation trong quá khứ, nhưng tại một thời điểm $T$, một ghế chỉ được phép có tối đa 1 reservation ở trạng thái Active (`'Held'` hoặc `'Confirmed'`). Nếu ghế hết hạn hoặc bị hủy, ghế lập tức được giải phóng cho khách hàng khác.

### 3. Quy tắc 10 phút tự động — Nguồn chân lý duy nhất (Single Source of Truth)
- **Ý nghĩa:** Đảm bảo thời gian thanh toán 10 phút đồng nhất, không bị lệch đồng hồ giữa các bảng.
- **Cách thể hiện:** `BOOKING.expiry_time = booking_time + 10 phút` là mốc giờ chuẩn duy nhất (không lưu lặp lại ở từng reservation).
- **Cơ chế:** Tiến trình nền quét tự động: Nếu sau 10 phút chưa thanh toán thành công, hệ thống thực thi một giao dịch nguyên tử (Atomic Transaction):
  $$\text{BOOKING} \rightarrow \text{'Cancelled'} \quad|\quad \text{SEAT\_RESERVATION} \rightarrow \text{'Expired'} \quad|\quad \text{FLIGHT\_SEAT} \rightarrow \text{'Available'}$$
  Ghế ngay lập tức được trả lại kho mở bán cho khách khác.

### 4. Giải quyết bài toán tìm "3 ghế trống nằm kề nhau" (Tránh lối đi Cabin)
- **Ý nghĩa:** Hàng ghế trên máy bay thường có cấu hình 3-3 (A-B-C [Lối đi] D-E-F). Nếu chọn ghế B, C, D thì dù chữ cái liên tiếp nhưng lại bị ngăn cách bởi lối đi cabin.
- **Cách thể hiện:** Thuộc tính `block_code` trong `AIRCRAFT_SEAT`.
- **Cơ chế:** Ba ghế được coi là kề nhau khi thỏa mãn đồng thời:
  1. Cùng chuyến bay và cùng hàng (`row_number`).
  2. Cùng một dãy ghế (`block_code = 'LEFT'` hoặc `block_code = 'RIGHT'`).
  3. Cột liên tiếp nhau (Ví dụ: A-B-C hoặc D-E-F) và tất cả đều ở trạng thái `status = 'Available'`.

### 5. Ràng buộc tam giác toàn vẹn (Tàu bay – Ghế – Chuyến bay)
- **Ý nghĩa:** Tránh lỗi nghiêm trọng: Mở bán ghế của máy bay A321 trên chuyến bay đang khai thác máy bay Boeing 787.
- **Cách thể hiện:** Khóa ngoại kết hợp (Composite FK) trong bảng `FLIGHT_SEAT`:
  - Tham chiếu đồng thời cặp `(flight_id, aircraft_id)` từ `FLIGHT`.
  - Tham chiếu cặp `(seat_id, aircraft_id)` từ `AIRCRAFT_SEAT`.
- **Cơ chế:** Ép buộc cấp cơ sở dữ liệu: Ghế được đưa vào chuyến bay bắt buộc phải thuộc đúng chiếc máy bay đang thực hiện chuyến bay đó.

### 6. Khóa phạm vi Đơn đặt chỗ thuộc 1 Chuyến bay duy nhất
- **Ý nghĩa:** Mỗi đơn đặt vé (1 transaction) là đặt chỗ cho 1 chặng bay cụ thể.
- **Cách thể hiện:** Quan hệ `FLIGHT` (1) — `BOOKED_ON` — (N) `BOOKING` (`booking.flight_id`).
- **Cơ chế:** Mọi `SEAT_RESERVATION` trong cùng một `BOOKING` đều tự động kế thừa và chỉ được phép trỏ tới các ghế thuộc đúng chuyến bay `flight_id` của đơn hàng đó.
