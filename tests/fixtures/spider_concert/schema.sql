-- Spider: concert_singer (adapted)
-- Tests: basic FKs, junction table, core type codes

CREATE TABLE Stadium (
    stadium_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    capacity INTEGER NOT NULL,
    highest_attendance INTEGER,
    average_attendance FLOAT
);

CREATE TABLE Singer (
    singer_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(100) NOT NULL,
    age INTEGER NOT NULL,
    is_male BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE Concert (
    concert_id INTEGER PRIMARY KEY,
    concert_name VARCHAR(255) NOT NULL,
    theme VARCHAR(255),
    stadium_id INTEGER NOT NULL REFERENCES Stadium(stadium_id),
    year INTEGER NOT NULL
);

CREATE INDEX idx_concert_stadium ON Concert(stadium_id);
CREATE INDEX idx_concert_year ON Concert(year);

-- Pure junction table: no payload beyond the two FKs
CREATE TABLE SingerInConcert (
    id INTEGER PRIMARY KEY,
    singer_id INTEGER NOT NULL REFERENCES Singer(singer_id),
    concert_id INTEGER NOT NULL REFERENCES Concert(concert_id),
    UNIQUE(singer_id, concert_id)
);

CREATE INDEX idx_sic_singer ON SingerInConcert(singer_id);
CREATE INDEX idx_sic_concert ON SingerInConcert(concert_id);
