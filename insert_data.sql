USE AirlineBooking;
GO

-- xoa du lieu cu neu chay lai de khong bi trung khoa
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

-- reset id ve 0 de cac bang tu dong danh so tu 1
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

-- 2. them hang ghe (id = 1: Thuong gia, id = 2: Pho thong)
INSERT INTO SEAT_CLASS (class_name) VALUES
('Thuong gia (Business)'),
('Pho thong (Economy)');

-- 3. them may bay (id = 1: A321, id = 2: B787, id = 3: A350)
INSERT INTO AIRCRAFT (aircraft_model, total_seats) VALUES
('Airbus A321-200', 180),
('Boeing 787-9 Dreamliner', 294),
('Airbus A350-900', 305);

-- 4. them cac tuyen bay (id tu 1 den 8)
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

-- 5. them danh sach ghe mau tren may bay A321 (aircraft_id = 1)
-- gom ca hang thuong gia (hang 1) va hang pho thong (hang 12, 18, 20, 21)
-- day trai (LEFT: A, B, C) va day phai (RIGHT: D, E, F)
INSERT INTO AIRCRAFT_SEAT (aircraft_id, class_id, row_number, column_code, block_code, seat_number, seat_position) VALUES
-- hang 1: hang thuong gia (class_id = 1), day trai va phai
(1, 1, 1, 'A', 'LEFT', '1A', 'Window'),
(1, 1, 1, 'B', 'LEFT', '1B', 'Middle'),
(1, 1, 1, 'C', 'LEFT', '1C', 'Aisle'),
(1, 1, 1, 'D', 'RIGHT', '1D', 'Aisle'),
(1, 1, 1, 'E', 'RIGHT', '1E', 'Middle'),
(1, 1, 1, 'F', 'RIGHT', '1F', 'Window'),

-- hang 12: hang pho thong (class_id = 2) de test dat 2 ve da mua
(1, 2, 12, 'A', 'LEFT', '12A', 'Window'),
(1, 2, 12, 'B', 'LEFT', '12B', 'Middle'),
(1, 2, 12, 'C', 'LEFT', '12C', 'Aisle'),
(1, 2, 12, 'D', 'RIGHT', '12D', 'Aisle'),
(1, 2, 12, 'E', 'RIGHT', '12E', 'Middle'),
(1, 2, 12, 'F', 'RIGHT', '12F', 'Window'),

-- hang 18: hang pho thong de test don hang qua han 10 phut
(1, 2, 18, 'A', 'LEFT', '18A', 'Window'),
(1, 2, 18, 'B', 'LEFT', '18B', 'Middle'),
(1, 2, 18, 'C', 'LEFT', '18C', 'Aisle'),
(1, 2, 18, 'D', 'RIGHT', '18D', 'Aisle'),
(1, 2, 18, 'E', 'RIGHT', '18E', 'Middle'),
(1, 2, 18, 'F', 'RIGHT', '18F', 'Window'),

-- hang 20: hang pho thong de test tim 3 ghe ke nhau (20A, 20B, 20C cung day trai)
(1, 2, 20, 'A', 'LEFT', '20A', 'Window'),
(1, 2, 20, 'B', 'LEFT', '20B', 'Middle'),
(1, 2, 20, 'C', 'LEFT', '20C', 'Aisle'),
(1, 2, 20, 'D', 'RIGHT', '20D', 'Aisle'),
(1, 2, 20, 'E', 'RIGHT', '20E', 'Middle'),
(1, 2, 20, 'F', 'RIGHT', '20F', 'Window'),

-- hang 21: hang pho thong de test bay loi di (21B, 21C day trai va 21D day phai)
(1, 2, 21, 'A', 'LEFT', '21A', 'Window'),
(1, 2, 21, 'B', 'LEFT', '21B', 'Middle'),
(1, 2, 21, 'C', 'LEFT', '21C', 'Aisle'),
(1, 2, 21, 'D', 'RIGHT', '21D', 'Aisle'),
(1, 2, 21, 'E', 'RIGHT', '21E', 'Middle'),
(1, 2, 21, 'F', 'RIGHT', '21F', 'Window');
GO

-- 6. them chuyen bay
INSERT INTO FLIGHT (flight_code, route_id, aircraft_id, departure_time, arrival_time, status) VALUES
('VN123', 1, 1, '2026-11-20 08:00:00', '2026-11-20 10:00:00', 'Scheduled'),
('VN124', 2, 1, '2026-11-21 09:00:00', '2026-11-21 11:00:00', 'Scheduled'),
('VJ456', 3, 1, '2026-11-20 14:00:00', '2026-11-20 15:20:00', 'Scheduled'),
('QH789', 5, 1, '2026-11-21 16:00:00', '2026-11-21 17:00:00', 'Scheduled');

-- gia ve theo tung chuyen va hang ghe
INSERT INTO FLIGHT_CLASS_FARE (flight_id, class_id, base_price, currency) VALUES
(1, 1, 4500000.00, 'VND'),
(1, 2, 1850000.00, 'VND'),
(2, 1, 4600000.00, 'VND'),
(2, 2, 1900000.00, 'VND'),
(3, 1, 3200000.00, 'VND'),
(3, 2, 1200000.00, 'VND'),
(4, 1, 2800000.00, 'VND'),
(4, 2, 950000.00, 'VND');
GO

-- 7. them ghe mo ban tren chuyen bay VN123 (flight_id = 1, aircraft_id = 1)
-- map tuong ung voi 30 ghe tren may bay da tao o buoc 5
INSERT INTO FLIGHT_SEAT (flight_id, seat_id, aircraft_id, status) VALUES
-- hang 1: ghe 1 (1A) dang giu cho, cac ghe con lai dang trong
(1, 1, 1, 'On Hold'),
(1, 2, 1, 'Available'),
(1, 3, 1, 'Available'),
(1, 4, 1, 'Available'),
(1, 5, 1, 'Available'),
(1, 6, 1, 'Available'),

-- hang 12: ghe 7 (12A) va 8 (12B) da ban, con lai trong
(1, 7, 1, 'Booked'),
(1, 8, 1, 'Booked'),
(1, 9, 1, 'Available'),
(1, 10, 1, 'Available'),
(1, 11, 1, 'Available'),
(1, 12, 1, 'Available'),

-- hang 18: ghe 16 (18D) va 17 (18E) dang giu cho (nhung da qua han 10 phut chua tra tien)
(1, 13, 1, 'Available'),
(1, 14, 1, 'Available'),
(1, 15, 1, 'Available'),
(1, 16, 1, 'On Hold'),
(1, 17, 1, 'On Hold'),
(1, 18, 1, 'Available'),

-- hang 20: tat ca cac ghe 20A den 20F deu con trong de test tim 3 ghe ke nhau
(1, 19, 1, 'Available'),
(1, 20, 1, 'Available'),
(1, 21, 1, 'Available'),
(1, 22, 1, 'Available'),
(1, 23, 1, 'Available'),
(1, 24, 1, 'Available'),

-- hang 21: cac ghe 21A, 21E, 21F da ban, de lai 21B, 21C, 21D de test bay ngan cach boi loi di
(1, 25, 1, 'Booked'),
(1, 26, 1, 'Available'),
(1, 27, 1, 'Available'),
(1, 28, 1, 'Available'),
(1, 29, 1, 'Booked'),
(1, 30, 1, 'Booked');
GO

-- 8. them khach hang
INSERT INTO CUSTOMER (first_name, last_name, email, phone) VALUES
('Vinh', 'Nguyen Quang', 'quangvinh@gmail.com', '0901234567'),
('An', 'Tran Binh', 'an.tran@yahoo.com', '0912345678'),
('Linh', 'Pham Thuy', 'linh.pham@outlook.com', '0988776655'),
('Cuong', 'Le Quoc', 'cuong.le@gmail.com', '0933445566'),
('Mai', 'Hoang Thanh', 'mai.hoang@company.vn', '0977112233');
GO

-- 9. them don dat ve (booking)
INSERT INTO BOOKING (customer_id, flight_id, booking_time, total_amount, status) VALUES
-- booking 1: khach 1 dat chuyen 1, da thanh toan (Paid)
(1, 1, '2026-11-20 07:00:00', 3700000.00, 'Paid'),

-- booking 2: khach 2 dat chuyen 1, dang cho thanh toan trong 10 phut (Pending)
(2, 1, '2026-11-20 07:45:00', 4500000.00, 'Pending'),

-- booking 3: khach 3 dat chuyen 1, tao luc 06:00 qua han 10 phut chua tra tien (Pending)
(3, 1, '2026-11-20 06:00:00', 3700000.00, 'Pending'),

-- booking 4: khach 4 dat chuyen 2, da thanh toan (Paid)
(4, 2, '2026-11-20 07:30:00', 1900000.00, 'Paid');
GO

-- 10. them chi tiet giu cho va thong tin hanh khach (seat_reservation)
INSERT INTO SEAT_RESERVATION (booking_id, flight_seat_id, passenger_name, passenger_id_no, fare_snapshot, status) VALUES
-- cho booking 1: 2 ghe 12A va 12B (flight_seat_id = 7 va 8)
(1, 7, 'Nguyen Quang Vinh', '001202008899', 1850000.00, 'Confirmed'),
(1, 8, 'Nguyen Phuong Thao', '001204001122', 1850000.00, 'Confirmed'),

-- cho booking 2: 1 ghe 1A (flight_seat_id = 1)
(2, 1, 'Tran Binh An', '079201004567', 4500000.00, 'Held'),

-- cho booking 3: 2 ghe 18D va 18E (flight_seat_id = 16 va 17)
(3, 16, 'Pham Thuy Linh', '036200001234', 1850000.00, 'Held'),
(3, 17, 'Pham Quang Minh', '036204005678', 1850000.00, 'Held'),

-- cho booking 4: 1 ghe (flight_seat_id = 2)
(4, 2, 'Le Quoc Cuong', '025201007788', 1900000.00, 'Confirmed');
GO

-- 11. them lich su thanh toan (payment)
INSERT INTO PAYMENT (booking_id, transaction_code, amount, payment_method, payment_time, status) VALUES
-- booking 1 thanh toan thanh cong
(1, 'VNPAY_TXN_888999111', 3700000.00, 'VNPAY-QR', '2026-11-20 07:05:00', 'Success'),

-- booking 4 thu thanh toan that bai lan 1, lan 2 thanh cong (the hien quan he 1-n)
(4, 'NAPAS_ERR_9901', 1900000.00, 'The noi dia NAPAS', '2026-11-20 07:32:00', 'Failed'),
(4, 'VISA_SUCCESS_1102', 1900000.00, 'The tin dung Quoc te (Visa)', '2026-11-20 07:35:00', 'Success');
GO

-- 12. them ve dien tu (ticket)
-- chi xuat cho cac reservation da xac nhan thanh toan (reservation_id = 1, 2, 6)
INSERT INTO TICKET (reservation_id, ticket_number, issued_at, status) VALUES
(1, '738-2401889901', '2026-11-20 07:05:00', 'Issued'),
(2, '738-2401889902', '2026-11-20 07:05:00', 'Issued'),
(6, '738-2401889903', '2026-11-20 07:35:00', 'Issued');
GO

-- 13. trigger tu dong cap nhat theo dung giao trinh Chapter 5 (Slide trang 45-46)
-- khi co ban ghi thanh toan thanh cong (status = 'Success') duoc insert vao bang PAYMENT
-- trigger tu dong cap nhat trang thai booking sang 'Paid'
GO
CREATE OR ALTER TRIGGER trg_AfterPaymentSuccess
ON PAYMENT
AFTER INSERT
AS
BEGIN
    UPDATE BOOKING
    SET status = 'Paid'
    FROM BOOKING b
    INNER JOIN inserted i ON b.booking_id = i.booking_id
    WHERE i.status = 'Success';
END;
GO
