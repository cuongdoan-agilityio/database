CREATE SCHEMA IF NOT EXISTS university;
SET search_path TO university, public;

-- DROP TABLES IN CORRECT DEPENDENCY ORDER
DROP TABLE IF EXISTS student_enrollments CASCADE;
DROP TABLE IF EXISTS timetables CASCADE;
DROP TABLE IF EXISTS class_section_semesters CASCADE;
DROP TABLE IF EXISTS prerequisites CASCADE;
DROP TABLE IF EXISTS course_units CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS professors CASCADE;
DROP TABLE IF EXISTS semesters CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS majors CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- Create departments table
CREATE TABLE departments (
    department_id BIGINT PRIMARY KEY,
    title VARCHAR,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create majors table
CREATE TABLE majors (
    major_id BIGINT PRIMARY KEY,
    department_id BIGINT,
    major_code VARCHAR,
    title VARCHAR,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE SET NULL
);

-- Craete students table
CREATE TABLE students (
    student_id BIGSERIAL PRIMARY KEY,
    student_code VARCHAR UNIQUE,
    student_email VARCHAR UNIQUE NOT NULL,
    major_id BIGINT,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    enrollment_date DATE NOT NULL,
    birthday DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (major_id) REFERENCES majors(major_id) ON DELETE SET NULL
);

-- Create professors table
CREATE TABLE professors (
    professor_sin VARCHAR PRIMARY KEY,
    department_id BIGINT,
    professor_email VARCHAR UNIQUE NOT NULL,
    first_name VARCHAR NOT NULL,
    last_name VARCHAR NOT NULL,
    birthday DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE SET NULL
);

-- Create courses table
CREATE TABLE courses (
    course_id BIGINT PRIMARY KEY,
    course_code VARCHAR,
    description TEXT,
    title VARCHAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create course_units table
CREATE TABLE course_units (
    course_unit_id BIGINT PRIMARY KEY,
    course_id BIGINT REFERENCES courses(course_id),
    major_id BIGINT REFERENCES majors(major_id),
    credit INT,
    required BOOLEAN,
    gpa_requirement FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    FOREIGN KEY (major_id) REFERENCES majors(major_id) ON DELETE CASCADE
);

-- Create prerequisites table (composite relationship table)
CREATE TABLE prerequisites (
    course_id BIGINT,
    prerequisite_course_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (course_id, prerequisite_course_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    FOREIGN KEY (prerequisite_course_id) REFERENCES courses(course_id) ON DELETE CASCADE
);

-- Create semesters table
CREATE TABLE semesters (
    semester_id BIGINT PRIMARY KEY,
    name VARCHAR,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create class_section_semesters table
CREATE TABLE class_section_semesters (
    class_section_semester_id BIGSERIAL PRIMARY KEY,
    course_unit_id BIGINT,
    semester_id BIGINT,
    professor_sin VARCHAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (course_unit_id) REFERENCES course_units(course_unit_id) ON DELETE CASCADE,
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id) ON DELETE CASCADE,
    FOREIGN KEY (professor_sin) REFERENCES professors(professor_sin) ON DELETE SET NULL
);

-- Create timetables table
CREATE TABLE timetables (
    timetables_id BIGSERIAL PRIMARY KEY,
    class_section_semester_id BIGINT REFERENCES class_section_semesters(class_section_semester_id),
    room VARCHAR,
    status VARCHAR,
    schedule_time VARCHAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (class_section_semester_id) REFERENCES class_section_semesters(class_section_semester_id) ON DELETE CASCADE
);

-- Create student_enrollments table
CREATE TABLE student_enrollments (
    student_enrollment_id BIGSERIAL PRIMARY KEY,
    student_id BIGINT REFERENCES students(student_id),
    class_section_semester_id BIGINT REFERENCES class_section_semesters(class_section_semester_id),
    enrollment_date DATE,
    score FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (class_section_semester_id) REFERENCES class_section_semesters(class_section_semester_id) ON DELETE CASCADE
);