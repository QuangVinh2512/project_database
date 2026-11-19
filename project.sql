CREATE DATABASE AirlineBooking;
GO

USE AirlineBooking;
GO

-- Sân bay
CREATE TABLE AIRPORT(
	airport_code CHAR(3) PRIMARY KEY,
	airport_name NVARCHAR(100) NOT NULL,
	city NVARCHAR(50) NOT NULL,
	country NVARCHAR(50) NOT NULL
);

-- Máy bay
CREATE TABLE AIRCRAFT(
	aircraft_id INT IDENTITY(1,1) PRIMARY KEY,
	aircraft_model VARCHAR(50) NOT NULL,
	total_seats INT NOT NULL
);

-- Hạng ghế
CREATE TABLE SEAT_CLASS(
	class_id INT IDENTITY(1,1) PRIMARY KEY,
	class_name NVARCHAR(30) NOT NULL UNIQUE
);

-- Khách hàng
CREATE TABLE CUSTOMER(
	customer_id INT IDENTITY(1,1) PRIMARY KEY,
	first_name NVARCHAR(50) NOT NULL,
	last_name NVARCHAR(50) NOT NULL,
	email VARCHAR(100) NOT NULL UNIQUE,
	phone VARCHAR(20)
);

-- Tuyến bay
CREATE TABLE ROUTE(
	route_id INT IDENTITY(1,1) PRIMARY KEY,
	departure_airport_code CHAR(3) NOT NULL,
	arrival_airport_code CHAR(3) NOT NULL,
	distance_km INT NOT NULL,

	CONSTRAINT fk_route_departure_airport
	FOREIGN KEY (departure_airport_code)
	REFERENCES AIRPORT(airport_code),

	CONSTRAINT fk_route_arrival_airport
	FOREIGN KEY (arrival_airport_code)
	REFERENCES AIRPORT(airport_code)
);

-- Ghế vật lý trên máy bay
CREATE TABLE AIRCRAFT_SEAT(
	seat_id INT IDENTITY(1,1) PRIMARY KEY,
	aircraft_id INT NOT NULL,
	class_id INT NOT NULL,
	row_number INT NOT NULL,
	column_code CHAR(1) NOT NULL,
	block_code VARCHAR(10) NOT NULL,
	seat_number VARCHAR(10) NOT NULL,
	seat_position VARCHAR(20) NOT NULL,

	CONSTRAINT fk_aircraft_seat_aircraft
	FOREIGN KEY (aircraft_id)
	REFERENCES AIRCRAFT(aircraft_id),

	CONSTRAINT fk_aircraft_seat_class
	FOREIGN KEY (class_id)
	REFERENCES SEAT_CLASS(class_id),

	CONSTRAINT uq_aircraft_seat_number
	UNIQUE (aircraft_id, seat_number),

	CONSTRAINT uq_aircraft_seat_aircraft
	UNIQUE (seat_id, aircraft_id)
);

-- Chuyến bay
CREATE TABLE FLIGHT(
	flight_id INT IDENTITY(1,1) PRIMARY KEY,
	flight_code VARCHAR(10) NOT NULL,
	route_id INT NOT NULL,
	aircraft_id INT NOT NULL,
	departure_time DATETIME NOT NULL,
	arrival_time DATETIME NOT NULL,
	status VARCHAR(20) NOT NULL,

	CONSTRAINT fk_flight_route
	FOREIGN KEY (route_id)
	REFERENCES ROUTE(route_id),

	CONSTRAINT fk_flight_aircraft
	FOREIGN KEY (aircraft_id)
	REFERENCES AIRCRAFT(aircraft_id),

	CONSTRAINT uq_flight_aircraft
	UNIQUE (flight_id, aircraft_id)
);

-- Giá vé theo chuyến bay và hạng ghế
CREATE TABLE FLIGHT_CLASS_FARE(
	flight_id INT NOT NULL,
	class_id INT NOT NULL,
	base_price DECIMAL(18,2) NOT NULL,
	currency CHAR(3) NOT NULL,

	CONSTRAINT pk_flight_class_fare
	PRIMARY KEY (flight_id, class_id),

	CONSTRAINT fk_flight_class_fare_flight
	FOREIGN KEY (flight_id)
	REFERENCES FLIGHT(flight_id),

	CONSTRAINT fk_flight_class_fare_class
	FOREIGN KEY (class_id)
	REFERENCES SEAT_CLASS(class_id)
);

-- Ghế trên từng chuyến bay
CREATE TABLE FLIGHT_SEAT(
	flight_seat_id INT IDENTITY(1,1) PRIMARY KEY,
	flight_id INT NOT NULL,
	seat_id INT NOT NULL,
	aircraft_id INT NOT NULL,
	status VARCHAR(20) NOT NULL,

	CONSTRAINT fk_flight_seat_aircraft
	FOREIGN KEY (aircraft_id)
	REFERENCES AIRCRAFT(aircraft_id),

	CONSTRAINT fk_flight_seat_flight
	FOREIGN KEY (flight_id, aircraft_id)
	REFERENCES FLIGHT(flight_id, aircraft_id),

	CONSTRAINT fk_flight_seat_seat
	FOREIGN KEY (seat_id, aircraft_id)
	REFERENCES AIRCRAFT_SEAT(seat_id, aircraft_id),

	CONSTRAINT uq_flight_seat
	UNIQUE (flight_id, seat_id)
);

-- Đơn đặt chỗ
CREATE TABLE BOOKING(
	booking_id INT IDENTITY(1,1) PRIMARY KEY,
	customer_id INT NOT NULL,
	flight_id INT NOT NULL,
	booking_time DATETIME NOT NULL,
	expiry_time AS DATEADD(MINUTE, 10, booking_time),
	total_amount DECIMAL(18,2) NOT NULL,
	status VARCHAR(20) NOT NULL,

	CONSTRAINT fk_booking_customer
	FOREIGN KEY (customer_id)
	REFERENCES CUSTOMER(customer_id),

	CONSTRAINT fk_booking_flight
	FOREIGN KEY (flight_id)
	REFERENCES FLIGHT(flight_id)
);

-- Giữ chỗ và thông tin hành khách
CREATE TABLE SEAT_RESERVATION(
	reservation_id INT IDENTITY(1,1) PRIMARY KEY,
	booking_id INT NOT NULL,
	flight_seat_id INT NOT NULL,
	passenger_name NVARCHAR(100) NOT NULL,
	passenger_id_no VARCHAR(30) NOT NULL,
	fare_snapshot DECIMAL(18,2) NOT NULL,
	status VARCHAR(20) NOT NULL,

	CONSTRAINT fk_seat_reservation_booking
	FOREIGN KEY (booking_id)
	REFERENCES BOOKING(booking_id),

	CONSTRAINT fk_seat_reservation_flight_seat
	FOREIGN KEY (flight_seat_id)
	REFERENCES FLIGHT_SEAT(flight_seat_id)
);

-- Các lần thanh toán
CREATE TABLE PAYMENT(
	payment_id INT IDENTITY(1,1) PRIMARY KEY,
	booking_id INT NOT NULL,
	transaction_code VARCHAR(50) NOT NULL UNIQUE,
	amount DECIMAL(18,2) NOT NULL,
	payment_method NVARCHAR(50) NOT NULL,
	payment_time DATETIME NOT NULL,
	status VARCHAR(20) NOT NULL,

	CONSTRAINT fk_payment_booking
	FOREIGN KEY (booking_id)
	REFERENCES BOOKING(booking_id)
);

-- Vé điện tử
CREATE TABLE TICKET(
	ticket_id INT IDENTITY(1,1) PRIMARY KEY,
	reservation_id INT NOT NULL UNIQUE,
	ticket_number VARCHAR(20) NOT NULL UNIQUE,
	issued_at DATETIME NOT NULL,
	status VARCHAR(20) NOT NULL,

	CONSTRAINT fk_ticket_reservation
	FOREIGN KEY (reservation_id)
	REFERENCES SEAT_RESERVATION(reservation_id)
);