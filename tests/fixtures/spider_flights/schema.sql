-- Spider: flight_2 (adapted)
-- Tests: no explicit PK, composite unique, two FKs to same entity

CREATE TABLE Airport (
    airport_code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL
);

CREATE TABLE Airline (
    airline_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    abbreviation VARCHAR(10) NOT NULL UNIQUE,
    country VARCHAR(100) NOT NULL
);

CREATE TABLE Flight (
    flight_id INTEGER PRIMARY KEY,
    airline_id INTEGER NOT NULL REFERENCES Airline(airline_id),
    flight_number VARCHAR(20) NOT NULL,
    origin VARCHAR(10) NOT NULL REFERENCES Airport(airport_code),
    destination VARCHAR(10) NOT NULL REFERENCES Airport(airport_code),
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP NOT NULL
);

CREATE INDEX idx_flight_airline ON Flight(airline_id);
CREATE INDEX idx_flight_origin ON Flight(origin);
CREATE INDEX idx_flight_dest ON Flight(destination);
CREATE INDEX idx_flight_times ON Flight(departure_time, arrival_time);

-- NO explicit PRIMARY KEY — identified by composite (flight_id + leg_number)
CREATE TABLE FlightLeg (
    flight_id INTEGER NOT NULL REFERENCES Flight(flight_id),
    leg_number INTEGER NOT NULL,
    origin VARCHAR(10) NOT NULL REFERENCES Airport(airport_code),
    destination VARCHAR(10) NOT NULL REFERENCES Airport(airport_code),
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP NOT NULL,
    UNIQUE(flight_id, leg_number)
);

CREATE INDEX idx_leg_flight ON FlightLeg(flight_id);

CREATE TABLE Reservation (
    reservation_id INTEGER PRIMARY KEY,
    flight_id INTEGER NOT NULL REFERENCES Flight(flight_id),
    passenger_name VARCHAR(255) NOT NULL,
    seat VARCHAR(10),
    booking_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(passenger_name, flight_id, booking_date)
);

CREATE INDEX idx_reservation_flight ON Reservation(flight_id);
CREATE INDEX idx_reservation_passenger ON Reservation(passenger_name);
