-- Synthetic: hospital management
-- Tests: ALL patterns combined — self-ref, no PK, junction, deep chain, @sens, multiple FKs

CREATE TABLE Department (
    department_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    building VARCHAR(100) NOT NULL,
    floor INTEGER NOT NULL
);

CREATE TABLE Specialty (
    specialty_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE Doctor (
    doctor_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    license_number VARCHAR(50) NOT NULL UNIQUE,
    department_id INTEGER NOT NULL REFERENCES Department(department_id),
    supervisor_id INTEGER REFERENCES Doctor(doctor_id),
    hired_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_doctor_dept ON Doctor(department_id);
CREATE INDEX idx_doctor_supervisor ON Doctor(supervisor_id);

-- Pure junction: Doctor × Specialty
CREATE TABLE DoctorSpecialty (
    id INTEGER PRIMARY KEY,
    doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id),
    specialty_id INTEGER NOT NULL REFERENCES Specialty(specialty_id),
    UNIQUE(doctor_id, specialty_id)
);

CREATE INDEX idx_ds_doctor ON DoctorSpecialty(doctor_id);
CREATE INDEX idx_ds_specialty ON DoctorSpecialty(specialty_id);

-- NO explicit PRIMARY KEY — identified by SSN (sensitive)
-- Composite unique on (last_name, date_of_birth, ssn) for safety
CREATE TABLE Patient (
    ssn VARCHAR(11) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth TIMESTAMP NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    medical_record_number VARCHAR(50) NOT NULL UNIQUE,
    insurance_id VARCHAR(50),
    UNIQUE(last_name, date_of_birth, ssn)
);

CREATE INDEX idx_patient_name ON Patient(last_name, first_name);

-- Admission: 3 FKs (Patient, Doctor, Department)
-- Depth chain: Department → Doctor → Admission → Treatment
CREATE TABLE Admission (
    admission_id INTEGER PRIMARY KEY,
    patient_ssn VARCHAR(11) NOT NULL REFERENCES Patient(ssn),
    admitting_doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id),
    department_id INTEGER NOT NULL REFERENCES Department(department_id),
    admitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    discharged_at TIMESTAMP,
    diagnosis TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active'
);

CREATE INDEX idx_admission_patient ON Admission(patient_ssn);
CREATE INDEX idx_admission_doctor ON Admission(admitting_doctor_id);
CREATE INDEX idx_admission_dept ON Admission(department_id);
CREATE INDEX idx_admission_status ON Admission(status);

-- Deep chain endpoint: Treatment → Admission → Doctor → Department (4 levels)
CREATE TABLE Treatment (
    treatment_id INTEGER PRIMARY KEY,
    admission_id INTEGER NOT NULL REFERENCES Admission(admission_id),
    treating_doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id),
    treatment_type VARCHAR(100) NOT NULL,
    description TEXT,
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    cost FLOAT
);

CREATE INDEX idx_treatment_admission ON Treatment(admission_id);
CREATE INDEX idx_treatment_doctor ON Treatment(treating_doctor_id);
CREATE INDEX idx_treatment_type ON Treatment(treatment_type);
