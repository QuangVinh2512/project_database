USE AirlineBooking;
GO

-- xoa du lieu cu theo thu tu khoa ngoai de chay lai khong bi loi
DELETE FROM TICKET;
DELETE FROM PAYMENT;
DELETE FROM SEAT_RESERVATION;
DELETE FROM BOOKING;
DELETE FROM FLIGHT_SEAT;
DELETE FROM FLIGHT_CLASS_FARE;
DELETE FROM FLIGHT;
DELETE FROM AIRCRAFT_SEAT;
DELETE FROM ROUTE;
DELETE FROM CUSTOMER;
DELETE FROM SEAT_CLASS;
DELETE FROM AIRCRAFT;
DELETE FROM AIRPORT;

-- reset lai cac cot identity ve 0
DBCC CHECKIDENT ('AIRCRAFT', RESEED, 0);
DBCC CHECKIDENT ('SEAT_CLASS', RESEED, 0);
DBCC CHECKIDENT ('CUSTOMER', RESEED, 0);
DBCC CHECKIDENT ('ROUTE', RESEED, 0);
DBCC CHECKIDENT ('AIRCRAFT_SEAT', RESEED, 0);
DBCC CHECKIDENT ('FLIGHT', RESEED, 0);
DBCC CHECKIDENT ('FLIGHT_SEAT', RESEED, 0);
DBCC CHECKIDENT ('BOOKING', RESEED, 0);
DBCC CHECKIDENT ('SEAT_RESERVATION', RESEED, 0);
DBCC CHECKIDENT ('PAYMENT', RESEED, 0);
DBCC CHECKIDENT ('TICKET', RESEED, 0);
GO

-- 1. them san bay
INSERT INTO AIRPORT (airport_code, airport_name, city, country) VALUES
('HAN', 'San bay Quoc te Noi Bai', 'Ha Noi', 'Viet Nam'),
('SGN', 'San bay Quoc te Tan Son Nhat', 'TP. Ho Chi Minh', 'Viet Nam'),
('DAD', 'San bay Quoc te Da Nang', 'Da Nang', 'Viet Nam'),
('CXR', 'San bay Quoc te Cam Ranh', 'Khanh Hoa', 'Viet Nam'),
('PQC', 'San bay Quoc te Phu Quoc', 'Kien Giang', 'Viet Nam'),
('BKK', 'San bay Quoc te Suvarnabhumi', 'Bangkok', 'Thai Lan'),
('SIN', 'San bay Quoc te Changi', 'Singapore', 'Singapore'),
('NRT', 'San bay Quoc te Narita', 'Tokyo', 'Nhat Ban');

-- 2. them hang ghe
INSERT INTO SEAT_CLASS (class_name) VALUES
('Thuong gia (Business)'),
('Pho thong (Economy)');

-- 3. them may bay
INSERT INTO AIRCRAFT (aircraft_model, total_seats) VALUES
('Airbus A321-200', 180),
('Boeing 787-9 Dreamliner', 294),
('Airbus A350-900', 305);

-- 4. them cac tuyen bay
INSERT INTO ROUTE (departure_airport_code, arrival_airport_code, distance_km) VALUES
('HAN', 'SGN', 1160),
('SGN', 'HAN', 1160),
('HAN', 'DAD', 630),
('DAD', 'HAN', 630),
('SGN', 'PQC', 300),
('PQC', 'SGN', 300),
('HAN', 'BKK', 990),
('SGN', 'SIN', 1090);
GO

-- 5. tao 180 ghe vat ly cho may bay A321 (id = 1)
-- 4 hang dau la thuong gia, con lai la pho thong, chia 2 day trai phai
DECLARE @aircraft_id INT = 1;
DECLARE @class_business INT, @class_economy INT;
SELECT @class_business = class_id FROM SEAT_CLASS WHERE class_name LIKE '%Business%';
SELECT @class_economy = class_id FROM SEAT_CLASS WHERE class_name LIKE '%Economy%';

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
    CASE WHEN r.row_no <= 4 THEN @class_business ELSE @class_economy END,
    r.row_no,
    c.col,
    c.blk,
    CAST(r.row_no AS VARCHAR(5)) + c.col,
    c.pos
FROM RowsCTE r
CROSS JOIN ColsCTE c
ORDER BY r.row_no, c.col;
GO

-- 6. them chuyen bay
INSERT INTO FLIGHT (flight_code, route_id, aircraft_id, departure_time, arrival_time, status) VALUES
('VN123', 1, 1, DATEADD(HOUR, 4, GETDATE()), DATEADD(HOUR, 6, GETDATE()), 'Scheduled'),
('VN124', 2, 1, DATEADD(DAY, 1, DATEADD(HOUR, 8, CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY, 1, DATEADD(HOUR, 10, CAST(CAST(GETDATE() AS DATE) AS DATETIME))), 'Scheduled'),
('VJ456', 3, 1, DATEADD(HOUR, 2, GETDATE()), DATEADD(HOUR, 3, GETDATE()), 'Scheduled'),
('QH789', 5, 1, DATEADD(DAY, 1, DATEADD(HOUR, 14, CAST(CAST(GETDATE() AS DATE) AS DATETIME))), DATEADD(DAY, 1, DATEADD(HOUR, 15, CAST(CAST(GETDATE() AS DATE) AS DATETIME))), 'Scheduled');

-- gia ve theo chuyen va hang ghe
DECLARE @c_bus INT, @c_eco INT;
SELECT @c_bus = class_id FROM SEAT_CLASS WHERE class_name LIKE '%Business%';
SELECT @c_eco = class_id FROM SEAT_CLASS WHERE class_name LIKE '%Economy%';

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

-- 7. tao danh sach ghe mo ban cho tung chuyen bay
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

-- 8. them khach hang
INSERT INTO CUSTOMER (first_name, last_name, email, phone) VALUES
('Vinh', 'Nguyen Quang', 'quangvinh@gmail.com', '0901234567'),
('An', 'Tran Binh', 'an.tran@yahoo.com', '0912345678'),
('Linh', 'Pham Thuy', 'linh.pham@outlook.com', '0988776655'),
('Cuong', 'Le Quoc', 'cuong.le@gmail.com', '0933445566'),
('Mai', 'Hoang Thanh', 'mai.hoang@company.vn', '0977112233');
GO

-- 9. du lieu mau de test:
-- test case 1: don da thanh toan xong va da xuat ve (ghe 12A va 12B tren chuyen 1)
DECLARE @cust_id1 INT, @fl_id1 INT, @bk_id1 INT;
SELECT @cust_id1 = customer_id FROM CUSTOMER WHERE email = 'quangvinh@gmail.com';
SET @fl_id1 = 1;

DECLARE @fs_id_12A INT, @fs_id_12B INT;
SELECT @fs_id_12A = fs.flight_seat_id 
FROM FLIGHT_SEAT fs 
JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id 
WHERE fs.flight_id = @fl_id1 AND s.seat_number = '12A';

SELECT @fs_id_12B = fs.flight_seat_id 
FROM FLIGHT_SEAT fs 
JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id 
WHERE fs.flight_id = @fl_id1 AND s.seat_number = '12B';

INSERT INTO BOOKING (customer_id, flight_id, booking_time, total_amount, status)
VALUES (@cust_id1, @fl_id1, DATEADD(MINUTE, -30, GETDATE()), 3700000.00, 'Paid');
SET @bk_id1 = SCOPE_IDENTITY();

INSERT INTO SEAT_RESERVATION (booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status)
VALUES 
(@bk_id1, @fs_id_12A, 'Nguyen Quang Vinh', '001202008899', 1850000.00, 'Confirmed'),
(@bk_id1, @fs_id_12B, 'Nguyen Phuong Thao', '001204001122', 1850000.00, 'Confirmed');

DECLARE @res_id1 INT, @res_id2 INT;
SELECT @res_id1 = reservation_id FROM SEAT_RESERVATION WHERE booking_id = @bk_id1 AND flight_seat_id = @fs_id_12A;
SELECT @res_id2 = reservation_id FROM SEAT_RESERVATION WHERE booking_id = @bk_id1 AND flight_seat_id = @fs_id_12B;

UPDATE FLIGHT_SEAT SET status = 'Booked' WHERE flight_seat_id IN (@fs_id_12A, @fs_id_12B);

INSERT INTO PAYMENT (booking_id, transaction_code, amount, payment_method, payment_time, status)
VALUES (@bk_id1, 'VNPAY_TXN_888999111', 3700000.00, 'VNPAY-QR', DATEADD(MINUTE, -25, GETDATE()), 'Success');

INSERT INTO TICKET (reservation_id, ticket_number, issued_at, status)
VALUES 
(@res_id1, '738-2401889901', DATEADD(MINUTE, -25, GETDATE()), 'Issued'),
(@res_id2, '738-2401889902', DATEADD(MINUTE, -25, GETDATE()), 'Issued');

-- test case 2: don dang giu cho trong 10 phut chua het han (ghe 1A chuyen 1)
DECLARE @cust_id2 INT, @bk_id2 INT, @fs_id_1A INT;
SELECT @cust_id2 = customer_id FROM CUSTOMER WHERE email = 'an.tran@yahoo.com';

SELECT @fs_id_1A = fs.flight_seat_id 
FROM FLIGHT_SEAT fs 
JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id 
WHERE fs.flight_id = @fl_id1 AND s.seat_number = '1A';

INSERT INTO BOOKING (customer_id, flight_id, booking_time, total_amount, status)
VALUES (@cust_id2, @fl_id1, DATEADD(MINUTE, -3, GETDATE()), 4500000.00, 'Pending');
SET @bk_id2 = SCOPE_IDENTITY();

INSERT INTO SEAT_RESERVATION (booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status)
VALUES (@bk_id2, @fs_id_1A, 'Tran Binh An', '079201004567', 4500000.00, 'Held');

UPDATE FLIGHT_SEAT SET status = 'On Hold' WHERE flight_seat_id = @fs_id_1A;

-- test case 3: don qua 10 phut chua tra tien de test sp tu dong huy (ghe 18D, 18E chuyen 1)
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

INSERT INTO BOOKING (customer_id, flight_id, booking_time, total_amount, status)
VALUES (@cust_id3, @fl_id1, DATEADD(MINUTE, -25, GETDATE()), 3700000.00, 'Pending');
SET @bk_id3 = SCOPE_IDENTITY();

INSERT INTO SEAT_RESERVATION (booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status)
VALUES 
(@bk_id3, @fs_id_18D, 'Pham Thuy Linh', '036200001234', 1850000.00, 'Held'),
(@bk_id3, @fs_id_18E, 'Pham Quang Minh', '036204005678', 1850000.00, 'Held');

UPDATE FLIGHT_SEAT SET status = 'On Hold' WHERE flight_seat_id IN (@fs_id_18D, @fs_id_18E);

-- test case 4: thanh toan that bai truoc khi thanh cong de the hien quan he 1-n (ghe 15A chuyen 2)
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
VALUES (@bk_id4, @fs_id_15A, 'Le Quoc Cuong', '025201007788', 1900000.00, 'Confirmed');

UPDATE FLIGHT_SEAT SET status = 'Booked' WHERE flight_seat_id = @fs_id_15A;

INSERT INTO PAYMENT (booking_id, transaction_code, amount, payment_method, payment_time, status)
VALUES (@bk_id4, 'NAPAS_ERR_9901', 1900000.00, 'The noi dia NAPAS', DATEADD(MINUTE, -6, GETDATE()), 'Failed');

INSERT INTO PAYMENT (booking_id, transaction_code, amount, payment_method, payment_time, status)
VALUES (@bk_id4, 'VISA_SUCCESS_1102', 1900000.00, 'The tin dung Quoc te (Visa)', DATEADD(MINUTE, -5, GETDATE()), 'Success');

DECLARE @res_id4 INT;
SELECT @res_id4 = reservation_id FROM SEAT_RESERVATION WHERE booking_id = @bk_id4;

INSERT INTO TICKET (reservation_id, ticket_number, issued_at, status)
VALUES (@res_id4, '738-2401889903', DATEADD(MINUTE, -5, GETDATE()), 'Issued');

-- test case 5: set mot so ghe de thanh vien 4 viet query tim 3 ghe lien tiep
-- hang 20 de trong 20A 20B 20C (cung day trai)
-- hang 21 de trong 21B 21C 21D nhung bi ngan boi loi di giua C va D
UPDATE fs
SET fs.status = 'Booked'
FROM FLIGHT_SEAT fs
JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id
WHERE fs.flight_id = 1 AND s.seat_number IN ('21A', '21E', '21F');
GO

-- 10. cac thu tuc xu ly nghiep vu
-- sp tu dong quet va huy cac don pending da qua 10 phut, tra ghe ve available
GO
CREATE OR ALTER PROCEDURE sp_AutoCancelExpiredBookings
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ExpiredBookings TABLE (booking_id INT);

        INSERT INTO @ExpiredBookings (booking_id)
        SELECT booking_id 
        FROM BOOKING
        WHERE status = 'Pending' 
          AND expiry_time < GETDATE();

        IF EXISTS (SELECT 1 FROM @ExpiredBookings)
        BEGIN
            UPDATE fs
            SET fs.status = 'Available'
            FROM FLIGHT_SEAT fs
            INNER JOIN SEAT_RESERVATION sr ON fs.flight_seat_id = sr.flight_seat_id
            INNER JOIN @ExpiredBookings eb ON sr.booking_id = eb.booking_id
            WHERE fs.status = 'On Hold';

            UPDATE sr
            SET sr.status = 'Expired'
            FROM SEAT_RESERVATION sr
            INNER JOIN @ExpiredBookings eb ON sr.booking_id = eb.booking_id
            WHERE sr.status = 'Held';

            UPDATE b
            SET b.status = 'Cancelled'
            FROM BOOKING b
            INNER JOIN @ExpiredBookings eb ON b.booking_id = eb.booking_id;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- sp tao don giu cho tam thoi 10 phut
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

        DECLARE @flight_seat_id INT, @seat_status VARCHAR(20), @fare DECIMAL(18,2);

        SELECT 
            @flight_seat_id = fs.flight_seat_id,
            @seat_status = fs.status,
            @fare = fcf.base_price
        FROM FLIGHT_SEAT fs WITH (UPDLOCK, HOLDLOCK)
        JOIN AIRCRAFT_SEAT s ON fs.seat_id = s.seat_id
        JOIN FLIGHT_CLASS_FARE fcf ON fs.flight_id = fcf.flight_id AND s.class_id = fcf.class_id
        WHERE fs.flight_id = @flight_id AND s.seat_number = @seat_number;

        IF @flight_seat_id IS NULL
        BEGIN
            RAISERROR('Khong tim thay ghe yeu cau tren chuyen bay nay.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @seat_status <> 'Available'
        BEGIN
            RAISERROR('Ghe nay hien khong kha dung (da co nguoi giu hoac da ban).', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO BOOKING (customer_id, flight_id, booking_time, total_amount, status)
        VALUES (@customer_id, @flight_id, GETDATE(), @fare, 'Pending');
        SET @new_booking_id = SCOPE_IDENTITY();

        INSERT INTO SEAT_RESERVATION (booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status)
        VALUES (@new_booking_id, @flight_seat_id, @passenger_name, @passenger_id_no, @fare, 'Held');

        UPDATE FLIGHT_SEAT SET status = 'On Hold' WHERE flight_seat_id = @flight_seat_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- sp nhan thanh toan va xuat ve dien tu
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
            RAISERROR('Khong tim thay ma don dat cho.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @booking_status <> 'Pending'
        BEGIN
            RAISERROR('Don dat cho khong o trang thai cho thanh toan.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @expiry_time < GETDATE()
        BEGIN
            RAISERROR('Don dat cho da qua han 10 phut. Giao dich bi tu choi.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO PAYMENT (booking_id, transaction_code, amount, payment_method, payment_time, status)
        VALUES (@booking_id, @transaction_code, @total_amount, @payment_method, GETDATE(), 'Success');

        UPDATE BOOKING SET status = 'Paid' WHERE booking_id = @booking_id;

        UPDATE SEAT_RESERVATION SET status = 'Confirmed' WHERE booking_id = @booking_id;

        UPDATE fs
        SET fs.status = 'Booked'
        FROM FLIGHT_SEAT fs
        JOIN SEAT_RESERVATION sr ON fs.flight_seat_id = sr.flight_seat_id
        WHERE sr.booking_id = @booking_id;

        INSERT INTO TICKET (reservation_id, ticket_number, issued_at, status)
        SELECT 
            sr.reservation_id,
            '738-' + CAST(2400000000 + sr.reservation_id AS VARCHAR(10)),
            GETDATE(),
            'Issued'
        FROM SEAT_RESERVATION sr
        WHERE sr.booking_id = @booking_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
