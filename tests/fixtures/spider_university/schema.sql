-- Spider: college_2 (adapted)
-- Tests: deep FK chain (5+ levels), multiple FKs per entity, junction tables at depth

CREATE TABLE Department (
    department_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    building VARCHAR(100) NOT NULL,
    budget FLOAT NOT NULL
);

CREATE TABLE Instructor (
    instructor_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    department_id INTEGER NOT NULL REFERENCES Department(department_id),
    salary FLOAT NOT NULL
);

CREATE INDEX idx_instructor_dept ON Instructor(department_id);

CREATE TABLE Student (
    student_id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    department_id INTEGER NOT NULL REFERENCES Department(department_id),
    total_credits INTEGER NOT NULL DEFAULT 0,
    advisor_id INTEGER REFERENCES Instructor(instructor_id)
);

CREATE INDEX idx_student_dept ON Student(department_id);
CREATE INDEX idx_student_advisor ON Student(advisor_id);

CREATE TABLE Course (
    course_id VARCHAR(20) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    department_id INTEGER NOT NULL REFERENCES Department(department_id),
    credits INTEGER NOT NULL
);

CREATE INDEX idx_course_dept ON Course(department_id);

CREATE TABLE Section (
    section_id INTEGER PRIMARY KEY,
    course_id VARCHAR(20) NOT NULL REFERENCES Course(course_id),
    semester VARCHAR(20) NOT NULL,
    year INTEGER NOT NULL,
    building VARCHAR(100),
    room_number VARCHAR(20),
    time_slot VARCHAR(20)
);

CREATE INDEX idx_section_course ON Section(course_id);
CREATE INDEX idx_section_semester ON Section(semester, year);

-- Junction: Student × Section (depth 3 from Department)
CREATE TABLE Enrollment (
    id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES Student(student_id),
    section_id INTEGER NOT NULL REFERENCES Section(section_id),
    grade VARCHAR(2),
    UNIQUE(student_id, section_id)
);

CREATE INDEX idx_enrollment_student ON Enrollment(student_id);
CREATE INDEX idx_enrollment_section ON Enrollment(section_id);

-- Prerequisite: self-referencing junction on Course
CREATE TABLE Prerequisite (
    id INTEGER PRIMARY KEY,
    course_id VARCHAR(20) NOT NULL REFERENCES Course(course_id),
    prereq_id VARCHAR(20) NOT NULL REFERENCES Course(course_id),
    UNIQUE(course_id, prereq_id)
);
