USE AirlineBooking;
GO

/* ===================================================================================
   BỘ CÂU TRUY VẤN DỮ LIỆU (QUERIES) - AIRLINE BOOKING & RESERVATION SYSTEM
   Bao gồm các cấp độ từ cơ bản, trung bình đến nâng cao và nghiệp vụ đặc thù
   =================================================================================== */

-- ===================================================================================
-- PHẦN 1: TRUY VẤN CƠ BẢN VÀ LỌC DỮ LIỆU (BASIC SELECT & FILTERING)
-- ===================================================================================

-- Câu 1: Tìm kiếm các chuyến bay khởi hành từ Hà Nội (HAN) đi TP.HCM (SGN) trong ngày 20/11/2026
-- Ý nghĩa: Chức năng tìm kiếm chuyến bay của khách hàng trên giao diện đặt vé
SELECT 
    f.flight_id,
    f.flight_code,
    dep.airport_name AS departure_airport,
    arr.airport_name AS arrival_airport,
    f.departure_time,
    f.arrival_time,
    r.distance_km,
    a.aircraft_model,
    f.status
FROM FLIGHT f
JOIN ROUTE r ON f.route_id = r.route_id
JOIN AIRPORT dep ON r.departure_airport_code = dep.airport_code
JOIN AIRPORT arr ON r.arrival_airport_code = arr.airport_code
JOIN AIRCRAFT a ON f.aircraft_id = a.aircraft_id
WHERE r.departure_airport_code = 'HAN'
  AND r.arrival_airport_code = 'SGN'
  AND CAST(f.departure_time AS DATE) = '2026-11-20'
  AND f.status = 'Scheduled';
GO

-- Câu 2: Xem bảng giá vé theo từng hạng ghế cho chuyến bay VN123
-- Ý nghĩa: Hiển thị tùy chọn hạng ghế và giá vé tương ứng cho người dùng lựa chọn
SELECT 
    f.flight_code,
    sc.class_name,
    fcf.base_price,
    fcf.currency
FROM FLIGHT_CLASS_FARE fcf
JOIN FLIGHT f ON fcf.flight_id = f.flight_id
JOIN SEAT_CLASS sc ON fcf.class_id = sc.class_id
WHERE f.flight_code = 'VN123';
GO


-- ===================================================================================
-- PHẦN 2: TRUY VẤN NỐI BẢNG (JOIN) & CHI TIẾT ĐƠN HÀNG/VÉ ĐIỆN TỬ
-- ===================================================================================

-- Câu 3: Xem sơ đồ tình trạng ghế (Seat Map Status) của chuyến bay VN123
-- Ý nghĩa: Trả về trạng thái từng ghế (Available, On Hold, Booked), vị trí (Cửa sổ/Lối đi/Giữa) để vẽ giao diện chọn chỗ
SELECT 
    aseat.seat_number,
    sc.class_name,
    aseat.row_number,
    aseat.column_code,
    aseat.block_code,
    aseat.seat_position,
    fseat.status AS seat_status
FROM FLIGHT_SEAT fseat
JOIN FLIGHT f ON fseat.flight_id = f.flight_id
JOIN AIRCRAFT_SEAT aseat ON fseat.seat_id = aseat.seat_id AND fseat.aircraft_id = aseat.aircraft_id
JOIN SEAT_CLASS sc ON aseat.class_id = sc.class_id
WHERE f.flight_code = 'VN123'
ORDER BY aseat.row_number, aseat.column_code;
GO

-- Câu 4: Xuất chi tiết vé điện tử chuẩn IATA cho các vé đã được phát hành thành công
-- Ý nghĩa: Cung cấp đầy đủ thông tin hành khách, mã vé điện tử, chuyến bay, giờ bay và số ghế để in Boarding Pass / Gửi Email
SELECT 
    t.ticket_number,
    t.issued_at,
    sr.passenger_name,
    sr.passenger_id_no,
    c.first_name + ' ' + c.last_name AS booker_name,
    c.phone AS booker_phone,
    f.flight_code,
    r.departure_airport_code + ' -> ' + r.arrival_airport_code AS flight_route,
    f.departure_time,
    aseat.seat_number,
    sc.class_name,
    sr.fare_snapshot,
    t.status AS ticket_status
FROM TICKET t
JOIN SEAT_RESERVATION sr ON t.reservation_id = sr.reservation_id
JOIN BOOKING b ON sr.booking_id = b.booking_id
JOIN CUSTOMER c ON b.customer_id = c.customer_id
JOIN FLIGHT f ON b.flight_id = f.flight_id
JOIN ROUTE r ON f.route_id = r.route_id
JOIN FLIGHT_SEAT fs ON sr.flight_seat_id = fs.flight_seat_id
JOIN AIRCRAFT_SEAT aseat ON fs.seat_id = aseat.seat_id AND fs.aircraft_id = aseat.aircraft_id
JOIN SEAT_CLASS sc ON aseat.class_id = sc.class_id
WHERE t.status = 'Issued';
GO


-- ===================================================================================
-- PHẦN 3: GOM NHÓM & THỐNG KÊ (AGGREGATION, GROUP BY, HAVING)
-- ===================================================================================

-- Câu 5: Thống kê số lượng ghế còn trống, đang giữ và đã bán của từng chuyến bay
-- Ý nghĩa: Giúp bộ phận vận hành theo dõi tình trạng mở bán của từng chuyến bay
SELECT 
    f.flight_id,
    f.flight_code,
    COUNT(fs.flight_seat_id) AS total_opened_seats,
    SUM(CASE WHEN fs.status = 'Available' THEN 1 ELSE 0 END) AS available_seats,
    SUM(CASE WHEN fs.status = 'On Hold' THEN 1 ELSE 0 END) AS on_hold_seats,
    SUM(CASE WHEN fs.status = 'Booked' THEN 1 ELSE 0 END) AS booked_seats,
    CAST(ROUND(SUM(CASE WHEN fs.status = 'Booked' THEN 1.0 ELSE 0 END) * 100.0 / COUNT(fs.flight_seat_id), 2) AS DECIMAL(5,2)) AS occupancy_rate_percent
FROM FLIGHT f
JOIN FLIGHT_SEAT fs ON f.flight_id = fs.flight_id
GROUP BY f.flight_id, f.flight_code;
GO

-- Câu 6: Báo cáo tổng doanh thu thực thu theo từng chuyến bay (Chỉ tính các giao dịch thanh toán thành công)
-- Ý nghĩa: Phục vụ phòng kế toán và báo cáo doanh thu tài chính
SELECT 
    f.flight_code,
    r.departure_airport_code + ' - ' + r.arrival_airport_code AS route_name,
    COUNT(DISTINCT b.booking_id) AS successful_bookings_count,
    COUNT(sr.reservation_id) AS total_tickets_sold,
    SUM(p.amount) AS total_revenue_vnd
FROM PAYMENT p
JOIN BOOKING b ON p.booking_id = b.booking_id
JOIN FLIGHT f ON b.flight_id = f.flight_id
JOIN ROUTE r ON f.route_id = r.route_id
LEFT JOIN SEAT_RESERVATION sr ON b.booking_id = sr.booking_id AND sr.status = 'Confirmed'
WHERE p.status = 'Success'
GROUP BY f.flight_code, r.departure_airport_code, r.arrival_airport_code;
GO

-- Câu 7: Tìm những khách hàng đã thực hiện chi tiêu trên 2,000,000 VND (Sử dụng HAVING)
-- Ý nghĩa: Phân loại khách hàng thân thiết / VIP để áp dụng chương trình ưu đãi
SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    c.email,
    c.phone,
    COUNT(b.booking_id) AS paid_bookings_count,
    SUM(b.total_amount) AS total_spent
FROM CUSTOMER c
JOIN BOOKING b ON c.customer_id = b.customer_id
WHERE b.status = 'Paid'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.phone
HAVING SUM(b.total_amount) >= 2000000.00;
GO


-- ===================================================================================
-- PHẦN 4: TRUY VẤN NÂNG CAO & LOGIC NGHIỆP VỤ ĐẶC THÙ (ADVANCED & BUSINESS LOGIC)
-- ===================================================================================

-- Câu 8: Phát hiện các đơn đặt chỗ (Booking) đã quá hạn 10 phút chưa thanh toán
-- Ý nghĩa: Thực thi quy tắc 10 phút (Rule 3 trong README) để tiến trình tự động hủy đơn và giải phóng ghế
SELECT 
    b.booking_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    f.flight_code,
    b.booking_time,
    b.expiry_time,
    b.status AS current_booking_status,
    DATEDIFF(MINUTE, b.expiry_time, '2026-11-20 07:15:00') AS minutes_overdue,
    sr.reservation_id,
    fs.flight_seat_id,
    aseat.seat_number
FROM BOOKING b
JOIN CUSTOMER c ON b.customer_id = c.customer_id
JOIN FLIGHT f ON b.flight_id = f.flight_id
JOIN SEAT_RESERVATION sr ON b.booking_id = sr.booking_id
JOIN FLIGHT_SEAT fs ON sr.flight_seat_id = fs.flight_seat_id
JOIN AIRCRAFT_SEAT aseat ON fs.seat_id = aseat.seat_id AND fs.aircraft_id = aseat.aircraft_id
WHERE b.status = 'Pending'
  AND b.expiry_time < '2026-11-20 07:15:00'; -- Giả lập thời điểm hiện tại của hệ thống
GO

-- Câu 9: Tìm 3 ghế trống nằm kề nhau trên cùng một dãy ghế (Không bị ngăn cách bởi lối đi cabin)
-- Ý nghĩa: Giải quyết bài toán nhóm/gia đình muốn ngồi liền nhau (Rule 4 trong README).
-- Sử dụng Self-JOIN và Subquery cơ bản: cùng chuyến, cùng hàng (row), cùng dãy (block_code: LEFT hoặc RIGHT),
-- cột liên tiếp (A-B-C trên dãy trái hoặc D-E-F trên dãy phải) và đều ở trạng thái 'Available'.
SELECT 
    s1.row_number,
    s1.block_code,
    s1.seat_number AS seat_1,
    s2.seat_number AS seat_2,
    s3.seat_number AS seat_3
FROM 
    (SELECT fs.flight_id, a.row_number, a.block_code, a.column_code, a.seat_number 
     FROM FLIGHT_SEAT fs 
     JOIN AIRCRAFT_SEAT a ON fs.seat_id = a.seat_id AND fs.aircraft_id = a.aircraft_id 
     WHERE fs.status = 'Available') s1
JOIN 
    (SELECT fs.flight_id, a.row_number, a.block_code, a.column_code, a.seat_number 
     FROM FLIGHT_SEAT fs 
     JOIN AIRCRAFT_SEAT a ON fs.seat_id = a.seat_id AND fs.aircraft_id = a.aircraft_id 
     WHERE fs.status = 'Available') s2 
    ON s1.flight_id = s2.flight_id 
   AND s1.row_number = s2.row_number 
   AND s1.block_code = s2.block_code 
   AND ((s1.column_code = 'A' AND s2.column_code = 'B') OR (s1.column_code = 'D' AND s2.column_code = 'E'))
JOIN 
    (SELECT fs.flight_id, a.row_number, a.block_code, a.column_code, a.seat_number 
     FROM FLIGHT_SEAT fs 
     JOIN AIRCRAFT_SEAT a ON fs.seat_id = a.seat_id AND fs.aircraft_id = a.aircraft_id 
     WHERE fs.status = 'Available') s3 
    ON s2.flight_id = s3.flight_id 
   AND s2.row_number = s3.row_number 
   AND s2.block_code = s3.block_code 
   AND ((s2.column_code = 'B' AND s3.column_code = 'C') OR (s2.column_code = 'E' AND s3.column_code = 'F'))
WHERE s1.flight_id = 1
ORDER BY s1.row_number, s1.seat_number;
GO

-- Câu 10: Tìm các hạng vé của các chuyến bay có giá vé cao hơn mức giá vé trung bình của toàn hệ thống
-- Ý nghĩa: Phục vụ phân tích các phân khúc vé cao cấp (Sử dụng Subquery lồng nhau so sánh với hàm tổng hợp AVG)
SELECT 
    f.flight_code,
    sc.class_name,
    fcf.base_price,
    fcf.currency
FROM FLIGHT_CLASS_FARE fcf
JOIN FLIGHT f ON fcf.flight_id = f.flight_id
JOIN SEAT_CLASS sc ON fcf.class_id = sc.class_id
WHERE fcf.base_price > (
    SELECT AVG(base_price) 
    FROM FLIGHT_CLASS_FARE
)
ORDER BY fcf.base_price DESC;
GO
