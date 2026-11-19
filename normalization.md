# BÁO CÁO PHÂN TÍCH CHUẨN HÓA DỮ LIỆU (DATABASE NORMALIZATION)
**Đề tài:** Hệ Thống Đặt Vé & Giữ Chỗ Chuyến Bay (Airline Booking & Reservation System)  
**Mục tiêu:** Chứng minh lược đồ cơ sở dữ liệu đạt dạng chuẩn 3 (3NF - Third Normal Form) và BCNF (Boyce-Codd Normal Form), loại bỏ hoàn toàn các dị thường dữ liệu (dị thường thêm, sửa, xóa).

---

## 1. TỔNG QUAN VỀ LƯỢC ĐỒ VÀ KÝ HIỆU
Cơ sở dữ liệu gồm 13 lược đồ quan hệ:
1. `AIRPORT (airport_code, airport_name, city, country)`
2. `AIRCRAFT (aircraft_id, aircraft_model, total_seats)`
3. `SEAT_CLASS (class_id, class_name)`
4. `CUSTOMER (customer_id, first_name, last_name, email, phone)`
5. `ROUTE (route_id, departure_airport_code, arrival_airport_code, distance_km)`
6. `AIRCRAFT_SEAT (seat_id, aircraft_id, class_id, row_number, column_code, block_code, seat_number, seat_position)`
7. `FLIGHT (flight_id, flight_code, route_id, aircraft_id, departure_time, arrival_time, status)`
8. `FLIGHT_CLASS_FARE (flight_id, class_id, base_price, currency)`
9. `FLIGHT_SEAT (flight_seat_id, flight_id, seat_id, aircraft_id, status)`
10. `BOOKING (booking_id, customer_id, flight_id, booking_time, expiry_time, total_amount, status)`
11. `SEAT_RESERVATION (reservation_id, booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status)`
12. `PAYMENT (payment_id, booking_id, transaction_code, amount, payment_method, payment_time, status)`
13. `TICKET (ticket_id, reservation_id, ticket_number, issued_at, status)`

*Quy ước:*
- Các thuộc tính gạch chân hoặc đại diện khóa chính được viết in hoa/đậm.
- Ký hiệu $\rightarrow$ biểu thị phụ thuộc hàm (Functional Dependency - FD).

---

## 2. PHÂN TÍCH DẠNG CHUẨN 1 (1NF - FIRST NORMAL FORM)

### 2.1. Điều kiện 1NF
Một quan hệ đạt 1NF nếu và chỉ nếu:
1. Tất cả các thuộc tính đều chứa các giá trị nguyên tố (Atomic values), không chứa thuộc tính đa trị (Multivalued attributes).
2. Không chứa thuộc tính phức hợp (Composite attributes) lồng nhau không tách rời.
3. Không có nhóm lặp (Repeating groups).

### 2.2. Kiểm chứng trong hệ thống
- **Thuộc tính nguyên tố:**
  - Không lưu danh sách ghế dưới dạng chuỗi gộp (ví dụ: không lưu `"1A, 1B, 1C"` trong một cột của đơn đặt chỗ), mà mỗi ghế giữ chỗ được tách thành một bản ghi riêng trong `SEAT_RESERVATION`.
  - Họ và tên khách hàng được tách thành `first_name`, `last_name` (hoặc `passenger_name` là chuỗi họ tên đầy đủ nguyên tố cho từng vé).
  - Tọa độ ghế tách rời: `row_number` (hàng), `column_code` (cột), `block_code` (dãy), `seat_position` (vị trí cửa sổ/lối đi).
- **Không có nhóm lặp:** Mỗi chuyến bay không lưu mảng các lần thanh toán, mà mỗi giao dịch thanh toán là một dòng độc lập trong bảng `PAYMENT`.

$$\Rightarrow \mathbf{Kết\ luận:}\ \text{Tất cả 13 bảng đều đạt dạng chuẩn 1 (1NF).}$$

---

## 3. PHÂN TÍCH DẠNG CHUẨN 2 (2NF - SECOND NORMAL FORM)

### 3.1. Điều kiện 2NF
Một quan hệ đạt 2NF nếu và chỉ nếu:
1. Quan hệ đã đạt 1NF.
2. Mọi thuộc tính không khóa (Non-prime attributes) phải **phụ thuộc hàm đầy đủ** (Full Functional Dependency) vào toàn bộ khóa chính, nghĩa là không phụ thuộc vào một phần của bất kỳ khóa ứng viên nào (No Partial Dependency).

> *Lưu ý quan trọng:* Đối với các bảng có khóa chính là **khóa đơn (Single-attribute Primary Key)**, quan hệ đó **tự động đạt 2NF** vì không thể tồn tại tập con thực sự của một khóa đơn.

### 3.2. Kiểm chứng các quan hệ có khóa đơn
Các quan hệ sau có khóa chính gồm duy nhất 1 thuộc tính:
- `AIRPORT`: Khóa `{airport_code}` $\rightarrow$ Tự động đạt 2NF.
- `AIRCRAFT`: Khóa `{aircraft_id}` $\rightarrow$ Tự động đạt 2NF.
- `SEAT_CLASS`: Khóa `{class_id}` $\rightarrow$ Tự động đạt 2NF.
- `CUSTOMER`: Khóa `{customer_id}` $\rightarrow$ Tự động đạt 2NF.
- `ROUTE`: Khóa `{route_id}` $\rightarrow$ Tự động đạt 2NF.
- `AIRCRAFT_SEAT`: Khóa `{seat_id}` $\rightarrow$ Tự động đạt 2NF.
- `FLIGHT`: Khóa `{flight_id}` $\rightarrow$ Tự động đạt 2NF.
- `FLIGHT_SEAT`: Khóa `{flight_seat_id}` $\rightarrow$ Tự động đạt 2NF.
- `BOOKING`: Khóa `{booking_id}` $\rightarrow$ Tự động đạt 2NF.
- `SEAT_RESERVATION`: Khóa `{reservation_id}` $\rightarrow$ Tự động đạt 2NF.
- `PAYMENT`: Khóa `{payment_id}` $\rightarrow$ Tự động đạt 2NF.
- `TICKET`: Khóa `{ticket_id}` $\rightarrow$ Tự động đạt 2NF.

### 3.3. Kiểm chứng quan hệ có khóa kết hợp (Composite Key): `FLIGHT_CLASS_FARE`
- **Tập thuộc tính:** `{flight_id, class_id, base_price, currency}`
- **Khóa chính:** `{flight_id, class_id}`
- **Các thuộc tính không khóa:** `base_price`, `currency`
- **Tập phụ thuộc hàm:**
  $$\{flight\_id, class\_id\} \rightarrow base\_price$$
  $$\{flight\_id, class\_id\} \rightarrow currency$$
- **Kiểm tra tính đầy đủ:**
  - `flight_id` $\not\rightarrow$ `base_price`: Giá vé phụ thuộc vào hạng ghế (hạng Thương gia khác hạng Phổ thông trên cùng chuyến bay).
  - `class_id` $\not\rightarrow$ `base_price`: Hạng Phổ thông trên chuyến bay ngắn (Hà Nội - Đà Nẵng) có giá khác chuyến bay dài (Hà Nội - Tokyo).
  - `base_price` bắt buộc phải phụ thuộc đồng thời vào cả `{flight_id, class_id}`.
  - Do đó, không tồn tại phụ thuộc hàm bộ phận.

$$\Rightarrow \mathbf{Kết\ luận:}\ \text{Tất cả 13 bảng đều đạt dạng chuẩn 2 (2NF).}$$

---

## 4. PHÂN TÍCH DẠNG CHUẨN 3 (3NF - THIRD NORMAL FORM)

### 4.1. Điều kiện 3NF
Một quan hệ đạt 3NF nếu và chỉ nếu:
1. Quan hệ đã đạt 2NF.
2. Không có thuộc tính không khóa nào phụ thuộc **bắc cầu** (Transitive Dependency) vào khóa chính.
*(Định nghĩa hình thức: Với mọi phụ thuộc hàm không tầm thường $X \rightarrow Y$, thì hoặc $X$ là một siêu khóa (Superkey), hoặc $Y$ là một thuộc tính khóa (Prime attribute)).*

### 4.2. Kiểm chứng chi tiết từng bảng

#### 1. `AIRPORT (airport_code, airport_name, city, country)`
- Khóa chính: `{airport_code}`
- FDs:
  - $airport\_code \rightarrow \{airport\_name, city, country\}$
- Phân tích: Một thành phố có thể có nhiều sân bay (ví dụ Tokyo có cả Narita và Haneda), do đó $city \not\rightarrow airport\_code$, $city \not\rightarrow country$ (nhiều thành phố trùng tên ở các nước khác nhau). Không có phụ thuộc bắc cầu $airport\_code \rightarrow city \rightarrow country$.
- $\Rightarrow$ **Đạt 3NF.**

#### 2. `AIRCRAFT (aircraft_id, aircraft_model, total_seats)`
- Khóa chính: `{aircraft_id}`
- FDs:
  - $aircraft\_id \rightarrow \{aircraft\_model, total\_seats\}$
- Phân tích: Cùng model tàu bay nhưng hãng hàng không có thể cấu hình số ghế khác nhau tùy thuộc vào tỷ lệ ghế thương gia/phổ thông. $aircraft\_model \not\rightarrow total\_seats$.
- $\Rightarrow$ **Đạt 3NF.**

#### 3. `ROUTE (route_id, departure_airport_code, arrival_airport_code, distance_km)`
- Khóa chính: `{route_id}`, Khóa ứng viên: `{departure_airport_code, arrival_airport_code}`
- FDs:
  - $route\_id \rightarrow \{departure\_airport\_code, arrival\_airport\_code, distance\_km\}$
  - $\{departure\_airport\_code, arrival\_airport\_code\} \rightarrow \{route\_id, distance\_km\}$
- Phân tích: Vế trái của các FDs đều là siêu khóa (Superkey).
- $\Rightarrow$ **Đạt 3NF (và BCNF).**

#### 4. `AIRCRAFT_SEAT (seat_id, aircraft_id, class_id, row_number, column_code, block_code, seat_number, seat_position)`
- Khóa chính: `{seat_id}`
- Khóa ứng viên: `{aircraft_id, seat_number}`, `{aircraft_id, row_number, column_code}`
- FDs:
  - $seat\_id \rightarrow \{aircraft\_id, class\_id, row\_number, column\_code, block\_code, seat\_number, seat\_position\}$
  - $\{aircraft\_id, seat\_number\} \rightarrow seat\_id$
- Phân tích: Thuộc tính `seat_position` (Window/Aisle) phụ thuộc vào tọa độ không gian gắn với chiếc máy bay cụ thể. Vế trái luôn là siêu khóa.
- $\Rightarrow$ **Đạt 3NF.**

#### 5. `FLIGHT (flight_id, flight_code, route_id, aircraft_id, departure_time, arrival_time, status)`
- Khóa chính: `{flight_id}`
- FDs:
  - $flight\_id \rightarrow \{flight\_code, route\_id, aircraft\_id, departure\_time, arrival\_time, status\}$
- Phân tích: Mã chuyến bay (VD: `VN123`) lặp lại theo lịch trình hàng ngày, nhưng chuyến bay cụ thể gắn với một ngày giờ cất cánh duy nhất xác định bởi `flight_id`. Không có phụ thuộc bắc cầu giữa các thuộc tính không khóa.
- $\Rightarrow$ **Đạt 3NF.**

#### 6. `FLIGHT_CLASS_FARE (flight_id, class_id, base_price, currency)`
- Khóa chính: `{flight_id, class_id}`
- FDs:
  - $\{flight\_id, class\_id\} \rightarrow \{base\_price, currency\}$
- Phân tích: Vế trái là khóa chính. Không có thuộc tính không khóa nào suy ra thuộc tính không khóa khác.
- $\Rightarrow$ **Đạt 3NF.**

#### 7. `FLIGHT_SEAT (flight_seat_id, flight_id, seat_id, aircraft_id, status)`
- Khóa chính: `{flight_seat_id}`
- Khóa ứng viên: `{flight_id, seat_id}`
- FDs:
  - $flight\_seat\_id \rightarrow \{flight\_id, seat\_id, aircraft\_id, status\}$
  - $\{flight\_id, seat\_id\} \rightarrow \{flight\_seat\_id, status\}$
- Phân tích: Vế trái của mọi FD đều là khóa ứng viên.
- $\Rightarrow$ **Đạt 3NF.**

#### 8. `BOOKING (booking_id, customer_id, flight_id, booking_time, expiry_time, total_amount, status)`
- Khóa chính: `{booking_id}`
- FDs:
  - $booking\_id \rightarrow \{customer\_id, flight\_id, booking_time, expiry\_time, total\_amount, status\}$
- Phân tích: `expiry_time` là thuộc tính dẫn xuất tính toán (`booking_time + 10 phút`), không tạo nên dị thường lưu trữ. Không có sự phụ thuộc bắc cầu giữa các thuộc tính phi khóa.
- $\Rightarrow$ **Đạt 3NF.**

#### 9. `SEAT_RESERVATION (reservation_id, booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status)`
- Khóa chính: `{reservation_id}`
- FDs:
  - $reservation\_id \rightarrow \{booking\_id, flight\_seat\_id, passenger\_name, passenger\_id\_no, fare\_snapshot, status\}$
- Phân tích:
  - `fare_snapshot` là giá vé tại thời điểm đặt (chốt giá), cố ý lưu giữ vết lịch sử tài chính, không phụ thuộc động vào bảng giá hiện tại.
  - Thông tin hành khách (`passenger_name`, `passenger_id_no`) gắn liền với lượt đặt ghế cụ thể này.
- $\Rightarrow$ **Đạt 3NF.**

#### 10. `PAYMENT (payment_id, booking_id, transaction_code, amount, payment_method, payment_time, status)`
- Khóa chính: `{payment_id}`, Khóa ứng viên: `{transaction_code}`
- FDs:
  - $payment\_id \rightarrow \{booking\_id, transaction\_code, amount, payment\_method, payment\_time, status\}$
  - $transaction\_code \rightarrow \{payment\_id, ...\}$
- Phân tích: Vế trái đều là siêu khóa.
- $\Rightarrow$ **Đạt 3NF.**

#### 11. `TICKET (ticket_id, reservation_id, ticket_number, issued_at, status)`
- Khóa chính: `{ticket_id}`
- Khóa ứng viên: `{reservation_id}`, `{ticket_number}`
- FDs:
  - $ticket\_id \rightarrow \{reservation\_id, ticket\_number, issued\_at, status\}$
  - $reservation\_id \rightarrow \{ticket\_id, ticket\_number, issued\_at, status\}$
  - $ticket\_number \rightarrow \{ticket\_id, reservation\_id, issued\_at, status\}$
- Phân tích: Mọi vế trái đều là khóa ứng viên.
- $\Rightarrow$ **Đạt 3NF (và BCNF).**

$$\Rightarrow \mathbf{Kết\ luận:}\ \text{Toàn bộ 13 bảng trong hệ thống đều đạt chuẩn 3NF và BCNF.}$$

---

## 5. BẢNG TỔNG HỢP KIỂM CHỨNG CHUẨN HÓA

| STT | Lược đồ quan hệ | Khóa chính (PK) / Khóa ứng viên (CK) | 1NF | 2NF | 3NF | BCNF | Ghi chú loại bỏ dị thường |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `AIRPORT` | `airport_code` |  |  |  |  | Khóa đơn, không phụ thuộc bắc cầu |
| 2 | `AIRCRAFT` | `aircraft_id` |  |  |  |  | Tách thông tin máy bay độc lập với chuyến bay |
| 3 | `SEAT_CLASS` | `class_id`, `class_name` |  |  |  |  | Chuẩn hóa danh mục hạng ghế |
| 4 | `CUSTOMER` | `customer_id`, `email` |  |  |  |  | Tách thông tin khách đặt độc lập với hành khách bay |
| 5 | `ROUTE` | `route_id`, `{departure, arrival}` |  |  |  |  | Tránh lặp thông tin khoảng cách giữa các sân bay |
| 6 | `AIRCRAFT_SEAT` | `seat_id`, `{aircraft_id, seat_number}` |  |  |  |  | Tách sơ đồ ghế tĩnh độc lập với chuyến bay |
| 7 | `FLIGHT` | `flight_id` |  |  |  |  | Mỗi chuyến bay cất cánh là một thực thể độc lập |
| 8 | `FLIGHT_CLASS_FARE` | `{flight_id, class_id}` |  |  |  |  | Phụ thuộc hàm đầy đủ vào khóa kết hợp |
| 9 | `FLIGHT_SEAT` | `flight_seat_id`, `{flight_id, seat_id}` |  |  |  |  | Ghế mở bán theo từng chuyến cụ thể |
| 10 | `BOOKING` | `booking_id` |  |  |  |  | Lưu giao dịch đơn đặt chỗ, mốc giờ 10 phút duy nhất |
| 11 | `SEAT_RESERVATION` | `reservation_id` |  |  |  |  | Lưu chi tiết từng ghế và hành khách của đơn |
| 12 | `PAYMENT` | `payment_id`, `transaction_code` |  |  |  |  | Lưu vết thanh toán độc lập (cho phép thử lại nhiều lần) |
| 13 | `TICKET` | `ticket_id`, `reservation_id`, `ticket_number` |  |  |  |  | Tách vé điện tử riêng, chỉ tạo khi thanh toán xong |

---

## 6. ĐÁNH GIÁ CÁC DỊ THƯỜNG DỮ LIỆU ĐÃ ĐƯỢC GIẢI QUYẾT (ANOMALIES RESOLVED)

1. **Dị thường thêm (Insertion Anomaly):**
   - Có thể tạo sân bay, máy bay, tuyến bay mới mà chưa cần phải có chuyến bay nào khai thác.
   - Có thể thêm khách hàng mới vào hệ thống mà khách chưa cần phải phát sinh đơn đặt vé nào.
2. **Dị thường xóa (Deletion Anomaly):**
   - Khi hủy một đơn đặt chỗ (`BOOKING`), chỉ các dòng trong `BOOKING` và `SEAT_RESERVATION` bị ảnh hưởng; thông tin về khách hàng (`CUSTOMER`), chuyến bay (`FLIGHT`), và ghế máy bay (`AIRCRAFT_SEAT`) vẫn tồn tại nguyên vẹn.
3. **Dị thường cập nhật (Update Anomaly):**
   - Khi giá vé cơ bản của hạng ghế trên một chuyến bay thay đổi, chỉ cần cập nhật đúng 1 bản ghi trong bảng `FLIGHT_CLASS_FARE`, không cần cập nhật ở từng ghế hay từng đơn hàng.
   - Khi một sân bay đổi tên, chỉ cập nhật 1 dòng duy nhất trong bảng `AIRPORT`.
