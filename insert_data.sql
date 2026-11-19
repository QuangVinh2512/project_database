-- =====================================================================================
-- HỆ THỐNG ĐẶT VÉ MÁY BAY & GIỮ CHỖ (AIRLINE BOOKING & RESERVATION SYSTEM)
-- PHẦN CỦA THÀNH VIÊN 3: DỮ LIỆU MẪU (DATA INSERTION) & TỰ ĐỘNG HÓA NGHIỆP VỤ (AUTOMATION)
-- =====================================================================================
-- Bao gồm:
-- 1. Insert dữ liệu danh mục tĩnh (Sân bay, Hạng ghế, Máy bay, Tuyến bay).
-- 2. Sinh tự động hàng trăm ghế vật lý (AIRCRAFT_SEAT) với tọa độ hàng, cột, block (LEFT/RIGHT).
-- 3. Tạo các chuyến bay (FLIGHT) và cấu hình bảng giá vé theo hạng (FLIGHT_CLASS_FARE).
-- 4. Nhân bản tự động hàng ngàn ghế mở bán (FLIGHT_SEAT) theo chuyến bay.
-- 5. Tạo dữ liệu Khách hàng (CUSTOMER).
-- 6. Dữ liệu thử nghiệm thực tế (Test Scenarios):
--    - Kịch bản A: Đặt vé & thanh toán thành công -> Đã xuất vé IATA (Ticket Issued).
--    - Kịch bản B: Đang giữ chỗ thời gian thực (< 10 phút, trạng thái On Hold).
--    - Kịch bản C: "CỐ TÌNH BỎ QUÊN GIỎ HÀNG" (> 10 phút, để test hủy tự động).
--    - Kịch bản D: Thanh toán thất bại nhiều lần (Failed attempts) trước khi thành công.
--    - Kịch bản E: Cấu hình sẵn dữ liệu ghế trống để Thành viên 4 test "Tìm 3 ghế kề nhau".
-- 7. Stored Procedure & Automation Script:
--    - sp_AutoCancelExpiredBookings: Quét & hủy nguyên tử đơn hàng quá hạn 10 phút.
--    - sp_CreateBooking: Đặt chỗ an toàn (Atomic Hold).
--    - sp_ProcessPaymentAndIssueTicket: Thanh toán & Xuất vé chuẩn IATA.
-- =====================================================================================

USE AirlineBooking;
GO

-- Xóa dữ liệu cũ nếu muốn chạy lại từ đầu (theo thứ tự khóa ngoại)
-- EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";
-- EXEC sp_MSforeachtable "DELETE FROM ?";
-- EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all";
-- GO

PRINT N'>>> BƯỚC 1: INSERT DỮ LIỆU HẠ TẦNG (AIRPORT, SEAT_CLASS, AIRCRAFT, ROUTE)';
-- 1. SÂN BAY (AIRPORT)
INSERT INTO AIRPORT (airport_code, airport_name, city, country) VALUES
('HAN', N'Sân bay Quốc tế Nội Bài', N'Hà Nội', N'Việt Nam'),
('SGN', N'Sân bay Quốc tế Tân Sơn Nhất', N'TP. Hồ Chí Minh', N'Việt Nam'),
('DAD', N'Sân bay Quốc tế Đà Nẵng', N'Đà Nẵng', N'Việt Nam'),
('CXR', N'Sân bay Quốc tế Cam Ranh', N'Khánh Hòa', N'Việt Nam'),
('PQC', N'Sân bay Quốc tế Phú Quốc', N'Kiên Giang', N'Việt Nam'),
('BKK', N'Sân bay Quốc tế Suvarnabhumi', N'Bangkok', N'Thái Lan'),
('SIN', N'Sân bay Quốc tế Changi', N'Singapore', N'Singapore'),
('NRT', N'Sân bay Quốc tế Narita', N'Tokyo', N'Nhật Bản');

-- 2. HẠNG GHẾ (SEAT_CLASS)
INSERT INTO SEAT_CLASS (class_name) VALUES
(N'Thương gia (Business)'),
(N'Phổ thông đặc biệt (Premium Economy)'),
(N'Phổ thông (Economy)');

-- 3. MÁY BAY (AIRCRAFT)
-- Giả lập 3 tàu bay với cấu hình ghế thực tế
INSERT INTO AIRCRAFT (aircraft_model, total_seats) VALUES
('Airbus A321-200', 180),   -- 30 hàng x 6 ghế = 180 ghế
('Boeing 787-9 Dreamliner', 294),
('Airbus A350-900', 305);

-- 4. TUYẾN BAY (ROUTE)
INSERT INTO ROUTE (departure_airport_code, arrival_airport_code, distance_km) VALUES
('HAN', 'SGN', 1160), -- route_id = 1
('SGN', 'HAN', 1160), -- route_id = 2
('HAN', 'DAD', 630),  -- route_id = 3
('DAD', 'HAN', 630),  -- route_id = 4
('SGN', 'PQC', 300),  -- route_id = 5
('PQC', 'SGN', 300),  -- route_id = 6
('HAN', 'BKK', 990),  -- route_id = 7
('SGN', 'SIN', 1090); -- route_id = 8
GO

-- =====================================================================================
PRINT N'>>> BƯỚC 2: TỰ ĐỘNG SINH 180 GHẾ VẬT LÝ CHO TÀU BAY A321 (AIRCRAFT_SEAT)';
-- =====================================================================================
-- Máy bay A321 (aircraft_id = 1):
-- - Hàng 1 đến 4: Hạng Thương gia (class_id = 1)
-- - Hàng 5 đến 30: Hạng Phổ thông (class_id = 3)
-- - Cấu hình 3 - 3:
--   Dãy trái (block_code = 'LEFT'):  Cột A (Window), B (Middle), C (Aisle)
--   Dãy phải (block_code = 'RIGHT'): Cột D (Aisle), E (Middle), F (Window)

DECLARE @aircraft_id INT = 1;
DECLARE @class_business INT, @class_economy INT;
SELECT @class_business = class_id FROM SEAT_CLASS WHERE class_name LIKE N'%Business%';
SELECT @class_economy = class_id FROM SEAT_CLASS WHERE class_name LIKE N'%Phổ thông (Economy)%';

WITH RowsCTE AS (
    SELECT 1 AS row_no
    UNION ALL
    SELECT row_no + 1 FROM RowsCTE WHERE row_no < 30
),
ColsCTE AS (
    SELECT 'A' AS col, 'LEFT' AS blk, 'Window' AS pos
    UNION ALL SELECT 'B', 'LEFT', 'Middle'
    UNION ALL SELECT 'C', 'LEFT', 'Aisle'
    UNION ALL SELECT 'D', 'RIGHT', 'Aisle'
    UNION ALL SELECT 'E', 'RIGHT', 'Middle'
    UNION ALL SELECT 'F', 'RIGHT', 'Window'
)
INSERT INTO AIRCRAFT_SEAT (aircraft_id, class_id, row_number, column_code, block_code, seat_number, seat_position)
SELECT 
    @aircraft_id,
    CASE WHEN r.row_no <= 4 THEN @class_business ELSE @class_economy END AS class_id,
    r.row_no AS row_number,
    c.col AS column_code,
    c.blk AS block_code,
    CAST(r.row_no AS VARCHAR(5)) + c.col AS seat_number,
    c.pos AS seat_position
FROM RowsCTE r
CROSS JOIN ColsCTE c
ORDER BY r.row_no, c.col;
GO

-- =====================================================================================
PRINT N'>>> BƯỚC 3: TẠO CHUYẾN BAY (FLIGHT) & CẤU HÌNH GIÁ VÉ (FLIGHT_CLASS_FARE)';
-- =====================================================================================
-- Giả lập các chuyến bay trong ngày hôm nay và các ngày tới:
INSERT INTO FLIGHT (flight_code, route_id, aircraft_id, departure_time, arrival_time, status) VALUES
-- Chuyến 1: HAN -> SGN (Hôm nay, khởi hành chiều nay)
('VN123', 1, 1, DATEADD(HOUR, 4, GETDATE()), DATEADD(HOUR, 6, GETDATE()), 'Scheduled'),
-- Chuyến 2: SGN -> HAN (Sáng mai)
('VN124', 2, 1, DATEADD(DAY, 1, DATEADD(HOUR, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY, 1, DATEADD(HOUR, 10, CAST(CAST(GETDATE() AS DATE) AS DATETIME))), 'Scheduled'),
-- Chuyến 3: HAN -> DAD (Đà Nẵng chiều nay)
('VJ456', 3, 1, DATEADD(HOUR, 2, GETDATE()), DATEADD(HOUR, 3, GETDATE()), 'Scheduled'),
-- Chuyến 4: SGN -> PQC (Phú Quốc ngày mai)
('QH789', 5, 1, DATEADD(DAY, 1, DATEADD(HOUR, 14, CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY, 1, DATEADD(HOUR, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME))), 'Scheduled');

-- Cấu hình giá vé theo chuyến bay và hạng ghế (Quy tắc 1)
DECLARE @c_bus INT, @c_eco INT;
SELECT @c_bus = class_id FROM SEAT_CLASS WHERE class_name LIKE N'%Business%';
SELECT @c_eco = class_id FROM SEAT_CLASS WHERE class_name LIKE N'%Phổ thông (Economy)%';

INSERT INTO FLIGHT_CLASS_FARE (flight_id, class_id, base_price, currency) VALUES
(1, @c_bus, 4500000.00, 'VND'),
(1, @c_eco, 1850000.00, 'VND'),
(2, @c_bus, 4600000.00, 'VND'),
(2, @c_eco, 1900000.00, 'VND'),
(3, @c_bus, 3200000.00, 'VND'),
(3, @c_eco, 1200000.00, 'VND'),
(4, @c_bus, 2800000.00, 'VND'),
(4, @c_eco, 950000.00, 'VND');
GO

-- =====================================================================================
PRINT N'>>> BƯỚC 4: NHÂN BẢN TOÀN BỘ GHẾ CHO CÁC CHUYẾN BAY (FLIGHT_SEAT)';
-- =====================================================================================
-- Với mỗi chuyến bay, nhân bản 180 ghế từ AIRCRAFT_SEAT sang FLIGHT_SEAT
-- Mặc định toàn bộ là 'Available'
INSERT INTO FLIGHT_SEAT (flight_id, seat_id, aircraft_id, status)
SELECT 
    f.flight_id,
    s.seat_id,
    s.aircraft_id,
    'Available'
FROM FLIGHT f
INNER JOIN AIRCRAFT_SEAT s ON f.aircraft_id = s.aircraft_id
ORDER BY f.flight_id, s.seat_id;
GO

-- =====================================================================================
PRINT N'>>> BƯỚC 5: INSERT KHÁCH HÀNG (CUSTOMER)';
-- =====================================================================================
INSERT INTO CUSTOMER (first_name, last_name, email, phone) VALUES
(N'Vinh', N'Nguyễn Quang', 'quangvinh@gmail.com', '0901234567'),
(N'An', N'Trần Bình', 'an.tran@yahoo.com', '0912345678'),
(N'Linh', N'Phạm Thùy', 'linh.pham@outlook.com', '0988776655'),
(N'Cường', N'Lê Quốc', 'cuong.le@gmail.com', '0933445566'),
(N'Mai', N'Hoàng Thanh', 'mai.hoang@company.vn', '0977112233');
GO

-- =====================================================================================
PRINT N'>>> BƯỚC 6: TẠO CÁC KỊCH BẢN THỬ NGHIỆM ĐẶC THÙ (TEST SCENARIOS)';
-- =====================================================================================

-- -------------------------------------------------------------------------------------
-- KỊCH BẢN 1: ĐẶT VÉ & THANH TOÁN THÀNH CÔNG -> ĐÃ XUẤT VÉ ĐIỆN TỬ IATA (TICKET ISSUED)
-- Khách: Vinh Nguyễn đặt 2 vé trên chuyến bay 1 (VN123), ghế 12A và 12B (Phổ thông).
-- -------------------------------------------------------------------------------------
DECLARE @cust_id1 INT, @fl_id1 INT, @bk_id1 INT;
SELECT @cust_id1 = customer_id FROM CUSTOMER WHERE email = 'quangvinh@gmail.com';
SET @fl_id1 = 1;

-- Lấy ID 2 ghế 12A, 12B trên chuyến 1
DECLARE @fs_id_12A INT, @fs_id_12B INT;
SELECT @fs_id_12A = fs.flight_seat_id 
FROM FLIGHT_SEAT fs 
JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id 
WHERE fs.flight_id = @fl_id1 AND s.seat_number = '12A';

SELECT @fs_id_12B = fs.flight_seat_id 
FROM FLIGHT_SEAT fs 
JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id 
WHERE fs.flight_id = @fl_id1 AND s.seat_number = '12B';

-- Tạo Booking (Đặt cách đây 30 phút, tổng tiền 3,700,000 VND)
INSERT INTO BOOKING (customer_id, flight_id, booking_time, total_amount, status)
VALUES (@cust_id1, @fl_id1, DATEADD(MINUTE, -30, GETDATE()), 3700000.00, 'Paid');
SET @bk_id1 = SCOPE_IDENTITY();

-- Tạo 2 Seat Reservations
INSERT INTO SEAT_RESERVATION (booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status)
VALUES 
(@bk_id1, @fs_id_12A, N'Nguyễn Quang Vinh', '001202008899', 1850000.00, 'Confirmed'),
(@bk_id1, @fs_id_12B, N'Nguyễn Phương Thảo', '001204001122', 1850000.00, 'Confirmed');

DECLARE @res_id1 INT, @res_id2 INT;
SELECT @res_id1 = reservation_id FROM SEAT_RESERVATION WHERE booking_id = @bk_id1 AND flight_seat_id = @fs_id_12A;
SELECT @res_id2 = reservation_id FROM SEAT_RESERVATION WHERE booking_id = @bk_id1 AND flight_seat_id = @fs_id_12B;

-- Cập nhật ghế máy bay sang 'Booked'
UPDATE FLIGHT_SEAT SET status = 'Booked' WHERE flight_seat_id IN (@fs_id_12A, @fs_id_12B);

-- Thanh toán thành công
INSERT INTO PAYMENT (booking_id, transaction_code, amount, payment_method, payment_time, status)
VALUES (@bk_id1, 'VNPAY_TXN_888999111', 3700000.00, N'VNPAY-QR', DATEADD(MINUTE, -25, GETDATE()), 'Success');

-- Xuất vé điện tử 13 số chuẩn IATA (738 là mã hãng VN)
INSERT INTO TICKET (reservation_id, ticket_number, issued_at, status)
VALUES 
(@res_id1, '738-2401889901', DATEADD(MINUTE, -25, GETDATE()), 'Issued'),
(@res_id2, '738-2401889902', DATEADD(MINUTE, -25, GETDATE()), 'Issued');


-- -------------------------------------------------------------------------------------
-- KỊCH BẢN 2: ĐANG GIỮ CHỖ THỜI GIAN THỰC (ACTIVE HOLD < 10 PHÚT)
-- Khách: An Trần đặt ghế Thương gia 1A trên chuyến 1 cách đây 3 phút, đang nhập thẻ.
-- -------------------------------------------------------------------------------------
DECLARE @cust_id2 INT, @bk_id2 INT, @fs_id_1A INT;
SELECT @cust_id2 = customer_id FROM CUSTOMER WHERE email = 'an.tran@yahoo.com';

SELECT @fs_id_1A = fs.flight_seat_id 
FROM FLIGHT_SEAT fs 
JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id 
WHERE fs.flight_id = @fl_id1 AND s.seat_number = '1A';

-- Tạo booking đặt cách đây 3 phút (còn 7 phút nữa mới hết hạn)
INSERT INTO BOOKING (customer_id, flight_id, booking_time, total_amount, status)
VALUES (@cust_id2, @fl_id1, DATEADD(MINUTE, -3, GETDATE()), 4500000.00, 'Pending');
SET @bk_id2 = SCOPE_IDENTITY();

INSERT INTO SEAT_RESERVATION (booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status)
VALUES (@bk_id2, @fs_id_1A, N'Trần Bình An', '079201004567', 4500000.00, 'Held');

-- Ghế chuyển sang 'On Hold'
UPDATE FLIGHT_SEAT SET status = 'On Hold' WHERE flight_seat_id = @fs_id_1A;


-- -------------------------------------------------------------------------------------
-- KỊCH BẢN 3: "CỐ TÌNH BỎ QUÊN GIỎ HÀNG" (> 10 PHÚT CHƯA THANH TOÁN)
-- ĐÂY LÀ ĐIỂM NHẤN ĂN ĐIỂM CỦA THÀNH VIÊN 3:
-- Tạo đơn cách đây 25 phút, hết hạn cách đây 15 phút nhưng chưa hủy.
-- Dùng để TEST Stored Procedure tự động hủy (sp_AutoCancelExpiredBookings).
-- Ghế đặt: 18D, 18E chuyến 1.
-- -------------------------------------------------------------------------------------
DECLARE @cust_id3 INT, @bk_id3 INT, @fs_id_18D INT, @fs_id_18E INT;
SELECT @cust_id3 = customer_id FROM CUSTOMER WHERE email = 'linh.pham@outlook.com';

SELECT @fs_id_18D = fs.flight_seat_id 
FROM FLIGHT_SEAT fs 
JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id 
WHERE fs.flight_id = @fl_id1 AND s.seat_number = '18D';

SELECT @fs_id_18E = fs.flight_seat_id 
FROM FLIGHT_SEAT fs 
JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id 
WHERE fs.flight_id = @fl_id1 AND s.seat_number = '18E';

-- Booking tạo cách đây 25 phút
INSERT INTO BOOKING (customer_id, flight_id, booking_time, total_amount, status)
VALUES (@cust_id3, @fl_id1, DATEADD(MINUTE, -25, GETDATE()), 3700000.00, 'Pending');
SET @bk_id3 = SCOPE_IDENTITY();

INSERT INTO SEAT_RESERVATION (booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status)
VALUES 
(@bk_id3, @fs_id_18D, N'Phạm Thùy Linh', '036200001234', 1850000.00, 'Held'),
(@bk_id3, @fs_id_18E, N'Phạm Quang Minh', '036204005678', 1850000.00, 'Held');

-- Tạm thời đặt ghế là 'On Hold' để chuẩn bị test quét tự động
UPDATE FLIGHT_SEAT SET status = 'On Hold' WHERE flight_seat_id IN (@fs_id_18D, @fs_id_18E);


-- -------------------------------------------------------------------------------------
-- KỊCH BẢN 4: THANH TOÁN THẤT BẠI NHIỀU LẦN (FAILED ATTEMPTS) RỒI MỚI THÀNH CÔNG
-- Minh họa quan hệ 1 - N giữa BOOKING và PAYMENT
-- Khách: Cường Lê đặt ghế 15A chuyến 2.
-- -------------------------------------------------------------------------------------
DECLARE @cust_id4 INT, @fl_id2 INT, @bk_id4 INT, @fs_id_15A INT;
SELECT @cust_id4 = customer_id FROM CUSTOMER WHERE email = 'cuong.le@gmail.com';
SET @fl_id2 = 2;

SELECT @fs_id_15A = fs.flight_seat_id 
FROM FLIGHT_SEAT fs 
JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id 
WHERE fs.flight_id = @fl_id2 AND s.seat_number = '15A';

INSERT INTO BOOKING (customer_id, flight_id, booking_time, total_amount, status)
VALUES (@cust_id4, @fl_id2, DATEADD(MINUTE, -8, GETDATE()), 1900000.00, 'Paid');
SET @bk_id4 = SCOPE_IDENTITY();

INSERT INTO SEAT_RESERVATION (booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status)
VALUES (@bk_id4, @fs_id_15A, N'Lê Quốc Cường', '025201007788', 1900000.00, 'Confirmed');

UPDATE FLIGHT_SEAT SET status = 'Booked' WHERE flight_seat_id = @fs_id_15A;

-- Lần 1: Sai OTP hoặc thẻ hết hạn -> Failed
INSERT INTO PAYMENT (booking_id, transaction_code, amount, payment_method, payment_time, status)
VALUES (@bk_id4, 'NAPAS_ERR_9901', 1900000.00, N'Thẻ nội địa NAPAS', DATEADD(MINUTE, -6, GETDATE()), 'Failed');

-- Lần 2: Đổi sang Visa thanh toán thành công -> Success
INSERT INTO PAYMENT (booking_id, transaction_code, amount, payment_method, payment_time, status)
VALUES (@bk_id4, 'VISA_SUCCESS_1102', 1900000.00, N'Thẻ tín dụng Quốc tế (Visa)', DATEADD(MINUTE, -5, GETDATE()), 'Success');

DECLARE @res_id4 INT;
SELECT @res_id4 = reservation_id FROM SEAT_RESERVATION WHERE booking_id = @bk_id4;

INSERT INTO TICKET (reservation_id, ticket_number, issued_at, status)
VALUES (@res_id4, '738-2401889903', DATEADD(MINUTE, -5, GETDATE()), 'Issued');


-- -------------------------------------------------------------------------------------
-- KỊCH BẢN 5: CHUẨN BỊ DỮ LIỆU ĐỂ THÀNH VIÊN 4 TRUY VẤN "TÌM 3 GHẾ KỀ NHAU"
-- Trên Chuyến bay 1 (VN123):
-- - Hàng 20: Ghế 20A, 20B, 20C (dãy LEFT) ĐANG HOÀN TOÀN TRỐNG ('Available') -> KẾT QUẢ ĐẠT!
-- - Hàng 21: Ghế 21A Booked, 21B Available, 21C Available, 21D Available, 21E Booked.
--   -> Chú ý: 21B, 21C (dãy LEFT) và 21D (dãy RIGHT) dù liên tiếp chữ cái B-C-D nhưng BỊ NGĂN BỞI LỐI ĐI!
--   -> Thuật toán của Thành viên 4 dựa trên block_code sẽ loại trừ trường hợp này!
-- -------------------------------------------------------------------------------------
UPDATE fs
SET fs.status = 'Booked'
FROM FLIGHT_SEAT fs
JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id
WHERE fs.flight_id = 1 AND s.seat_number IN ('21A', '21E', '21F');
GO

-- =====================================================================================
PRINT N'>>> BƯỚC 7: XÂY DỰNG STORED PROCEDURE TỰ ĐỘNG HÓA NGHIỆP VỤ (AUTOMATION)';
-- =====================================================================================

-- -------------------------------------------------------------------------------------
-- THỦ TỤC 1: sp_AutoCancelExpiredBookings
-- Mục đích: Quét tất cả các đơn Pending mà đã quá 10 phút (expiry_time < GETDATE()).
-- Thực thi Transaction nguyên tử:
--   1. BOOKING -> 'Cancelled'
--   2. SEAT_RESERVATION -> 'Expired'
--   3. FLIGHT_SEAT -> 'Available' (giải phóng ghế ngay lập tức)
-- -------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_AutoCancelExpiredBookings
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Tìm danh sách booking quá hạn
        DECLARE @ExpiredBookings TABLE (booking_id INT);

        INSERT INTO @ExpiredBookings (booking_id)
        SELECT booking_id 
        FROM BOOKING
        WHERE status = 'Pending' 
          AND expiry_time < GETDATE();

        DECLARE @Count INT;
        SELECT @Count = COUNT(*) FROM @ExpiredBookings;

        IF @Count > 0
        BEGIN
            -- 1. Trả lại ghế máy bay về Available
            UPDATE fs
            SET fs.status = 'Available'
            FROM FLIGHT_SEAT fs
            INNER JOIN SEAT_RESERVATION sr ON fs.flight_seat_id = sr.flight_seat_id
            INNER JOIN @ExpiredBookings eb ON sr.booking_id = eb.booking_id
            WHERE fs.status = 'On Hold';

            -- 2. Đổi trạng thái reservation thành Expired
            UPDATE sr
            SET sr.status = 'Expired'
            FROM SEAT_RESERVATION sr
            INNER JOIN @ExpiredBookings eb ON sr.booking_id = eb.booking_id
            WHERE sr.status = 'Held';

            -- 3. Hủy Booking
            UPDATE b
            SET b.status = 'Cancelled'
            FROM BOOKING b
            INNER JOIN @ExpiredBookings eb ON b.booking_id = eb.booking_id;

            PRINT N'Đã hủy thành công ' + CAST(@Count AS NVARCHAR(10)) + N' đơn đặt chỗ quá hạn 10 phút và trả lại ghế trống.';
        END
        ELSE
        BEGIN
            PRINT N'Không có đơn hàng nào bị quá hạn.';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- -------------------------------------------------------------------------------------
-- THỦ TỤC 2: sp_CreateBooking
-- Mục đích: Đặt chỗ an toàn 1 ghế cho khách hàng trong 10 phút (Single Seat Hold).
-- Ngăn ngừa Race Condition (tranh chấp đặt ghế đồng thời).
-- -------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_CreateBooking
    @customer_id INT,
    @flight_id INT,
    @seat_number VARCHAR(10),
    @passenger_name NVARCHAR(100),
    @passenger_id_no VARCHAR(30),
    @new_booking_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Tìm flight_seat_id và kiểm tra tình trạng
        DECLARE @flight_seat_id INT, @seat_status VARCHAR(20), @fare DECIMAL(18,2);

        SELECT 
            @flight_seat_id = fs.flight_seat_id,
            @seat_status = fs.status,
            @fare = fcf.base_price
        FROM FLIGHT_SEAT fs WITH (UPDLOCK, HOLDLOCK) -- Khóa bản ghi để chống trùng ghế
        JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id
        JOIN FLIGHT_CLASS_FARE fcf ON fs.flight_id = fcf.flight_id AND s.class_id = fcf.class_id
        WHERE fs.flight_id = @flight_id AND s.seat_number = @seat_number;

        IF @flight_seat_id IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy ghế yêu cầu trên chuyến bay này.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @seat_status <> 'Available'
        BEGIN
            RAISERROR(N'Ghế này hiện không khả dụng (đã có người giữ hoặc đã bán).', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 1. Tạo Booking mới (hạn 10 phút)
        INSERT INTO BOOKING (customer_id, flight_id, booking_time, total_amount, status)
        VALUES (@customer_id, @flight_id, GETDATE(), @fare, 'Pending');
        SET @new_booking_id = SCOPE_IDENTITY();

        -- 2. Giữ chỗ trong SEAT_RESERVATION
        INSERT INTO SEAT_RESERVATION (booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status)
        VALUES (@new_booking_id, @flight_seat_id, @passenger_name, @passenger_id_no, @fare, 'Held');

        -- 3. Cập nhật ghế thành 'On Hold'
        UPDATE FLIGHT_SEAT SET status = 'On Hold' WHERE flight_seat_id = @flight_seat_id;

        COMMIT TRANSACTION;
        PRINT N'Tạo đơn đặt chỗ #' + CAST(@new_booking_id AS NVARCHAR(10)) + N' thành công! Hạn thanh toán 10 phút.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- -------------------------------------------------------------------------------------
-- THỦ TỤC 3: sp_ProcessPaymentAndIssueTicket
-- Mục đích: Nhận thanh toán và tự động xuất vé điện tử IATA cho đơn hàng.
-- -------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ProcessPaymentAndIssueTicket
    @booking_id INT,
    @transaction_code VARCHAR(50),
    @payment_method NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @booking_status VARCHAR(20), @total_amount DECIMAL(18,2), @expiry_time DATETIME;
        SELECT 
            @booking_status = status,
            @total_amount = total_amount,
            @expiry_time = expiry_time
        FROM BOOKING WITH (UPDLOCK)
        WHERE booking_id = @booking_id;

        IF @booking_status IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy mã đơn đặt chỗ.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @booking_status <> 'Pending'
        BEGIN
            RAISERROR(N'Đơn đặt chỗ không ở trạng thái chờ thanh toán.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @expiry_time < GETDATE()
        BEGIN
            RAISERROR(N'Đơn đặt chỗ đã quá hạn 10 phút. Giao dịch bị từ chối.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 1. Lưu bản ghi thanh toán thành công
        INSERT INTO PAYMENT (booking_id, transaction_code, amount, payment_method, payment_time, status)
        VALUES (@booking_id, @transaction_code, @total_amount, @payment_method, GETDATE(), 'Success');

        -- 2. Cập nhật BOOKING -> Paid
        UPDATE BOOKING SET status = 'Paid' WHERE booking_id = @booking_id;

        -- 3. Cập nhật SEAT_RESERVATION -> Confirmed
        UPDATE SEAT_RESERVATION SET status = 'Confirmed' WHERE booking_id = @booking_id;

        -- 4. Cập nhật FLIGHT_SEAT -> Booked
        UPDATE fs
        SET fs.status = 'Booked'
        FROM FLIGHT_SEAT fs
        JOIN SEAT_RESERVATION sr ON fs.flight_seat_id = sr.flight_seat_id
        WHERE sr.booking_id = @booking_id;

        -- 5. Xuất vé điện tử TICKET (Chuẩn IATA 13 số: 738 + 10 số ngẫu nhiên/tuần tự)
        INSERT INTO TICKET (reservation_id, ticket_number, issued_at, status)
        SELECT 
            sr.reservation_id,
            '738-' + CAST(2400000000 + sr.reservation_id AS VARCHAR(10)),
            GETDATE(),
            'Issued'
        FROM SEAT_RESERVATION sr
        WHERE sr.booking_id = @booking_id;

        COMMIT TRANSACTION;
        PRINT N'Thanh toán thành công và đã xuất vé điện tử IATA cho đơn hàng #' + CAST(@booking_id AS NVARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT N'=====================================================================================';
PRINT N'HOÀN TẤT BƠM DỮ LIỆU & TỰ ĐỘNG HÓA! TỔNG HỢP TRẠNG THÁI HIỆN TẠI:';
SELECT 'AIRPORT' AS TableName, COUNT(*) AS TotalRows FROM AIRPORT
UNION ALL SELECT 'AIRCRAFT', COUNT(*) FROM AIRCRAFT
UNION ALL SELECT 'AIRCRAFT_SEAT', COUNT(*) FROM AIRCRAFT_SEAT
UNION ALL SELECT 'FLIGHT', COUNT(*) FROM FLIGHT
UNION ALL SELECT 'FLIGHT_SEAT', COUNT(*) FROM FLIGHT_SEAT
UNION ALL SELECT 'CUSTOMER', COUNT(*) FROM CUSTOMER
UNION ALL SELECT 'BOOKING', COUNT(*) FROM BOOKING
UNION ALL SELECT 'SEAT_RESERVATION', COUNT(*) FROM SEAT_RESERVATION
UNION ALL SELECT 'PAYMENT', COUNT(*) FROM PAYMENT
UNION ALL SELECT 'TICKET', COUNT(*) FROM TICKET;
GO
