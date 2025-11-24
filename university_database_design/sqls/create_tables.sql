CREATE SCHEMA IF NOT EXISTS university;
SET search_path TO university, public;

-- DROP TABLES IN CORRECT DEPENDENCY ORDER
DROP TABLE IF EXISTS student_sections CASCADE;
DROP TABLE IF EXISTS timetables CASCADE;
DROP TABLE IF EXISTS sections CASCADE;
DROP TABLE IF EXISTS prerequisites CASCADE;
DROP TABLE IF EXISTS major_courses CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS professors CASCADE;
DROP TABLE IF EXISTS semesters CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS majors CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- Create departments table
CREATE TABLE departments (
    department_id BIGINT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create majors table
CREATE TABLE majors (
    major_id BIGINT PRIMARY KEY,
    department_id BIGINT NOT NULL,
    major_code VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE SET NULL
);

-- Craete students table
CREATE TABLE students (
    student_id BIGINT PRIMARY KEY,
    student_code VARCHAR(20) UNIQUE NOT NULL,
    student_email VARCHAR(100) UNIQUE NOT NULL,
    major_id BIGINT NOT NULL,
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
    professor_sin VARCHAR(9) PRIMARY KEY,
    department_id BIGINT NOT NULL,
    professor_email VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    birthday DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE SET NULL
);

-- Create courses table
CREATE TABLE courses (
    course_id BIGINT PRIMARY KEY,
    prerequisite_course_id BIGINT[],
    course_code VARCHAR(50) NOT NULL,
    required BOOLEAN DEFAULT FALSE,
    description TEXT,
    course_type VARCHAR NOT NULL,
    title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create major_courses table
CREATE TABLE major_courses (
    major_course_id BIGINT PRIMARY KEY,
    course_id BIGINT NOT NULL,
    major_id BIGINT NOT NULL,
    -- credit INT NOT NULL,
    -- required BOOLEAN DEFAULT FALSE,
    -- gpa_requirement FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    FOREIGN KEY (major_id) REFERENCES majors(major_id) ON DELETE CASCADE
);

-- Create prerequisites table (composite relationship table)
CREATE TABLE prerequisites (
    prerequisite_id BIGINT PRIMARY KEY,
    course_id BIGINT NOT NULL,
    prerequisite_course_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    FOREIGN KEY (prerequisite_course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    CONSTRAINT no_self_prerequisite CHECK (course_id <> prerequisite_course_id),
    CONSTRAINT no_duplicate_prerequisite UNIQUE (course_id, prerequisite_course_id)
);

-- Create semesters table
CREATE TABLE semesters (
    semester_id BIGINT PRIMARY KEY,
    name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sections table
CREATE TABLE sections (
    section_id BIGINT PRIMARY KEY,
    major_course_id BIGINT NOT NULL,
    semester_id BIGINT NOT NULL,
    professor_sin VARCHAR(9) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    max_capacity INT NOT NULL,

    FOREIGN KEY (major_course_id) REFERENCES major_courses(major_course_id) ON DELETE CASCADE,
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id) ON DELETE CASCADE,
    FOREIGN KEY (professor_sin) REFERENCES professors(professor_sin) ON DELETE SET NULL
);

-- Create timetables table
CREATE TABLE timetables (
    timetables_id BIGINT PRIMARY KEY,
    section_id BIGINT NOT NULL,
    room VARCHAR(20),
    status VARCHAR NOT NULL,
    schedule_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (section_id) REFERENCES sections(section_id) ON DELETE CASCADE
);

-- Create student_sections table
CREATE TABLE student_sections (
    student_section_id BIGINT PRIMARY KEY,
    student_id BIGINT NOT NULL,
    section_id BIGINT NOT NULL,
    enrollment_date DATE NOT NULL,
    score FLOAT DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(section_id) ON DELETE CASCADE
);

--------------------------------------------------------------------------------------------------------
-- BR: Score on a 4-point scale
-- Rule: Student score range between 0.00 and 4.00
-- Trigger when adding new or updating, check the scores
CREATE OR REPLACE FUNCTION university.check_score_range()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.score IS NOT NULL AND (NEW.score < 0.00 OR NEW.score > 4.00) THEN
        RAISE EXCEPTION 'Invalid score, score must be between 0.00 and 4.00.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER score_validation_trigger
BEFORE INSERT OR UPDATE OF score ON university.student_sections
FOR EACH ROW
EXECUTE FUNCTION university.check_score_range();

--------------------------------------------------------------------------------------------------------
-- BR: Students are only allowed to register for courses included in the curriculum.
-- Rule: The student's major code must match the major code of the registered course.
-- Trigger when adding new or updating student_enrollemnt record, check major eligibility when student enrolls in a class section.
CREATE OR REPLACE FUNCTION university.check_major_eligibility()
RETURNS TRIGGER AS $$
DECLARE
    student_major_id BIGINT;
    major_course_id BIGINT;
BEGIN
    -- Get student major_id
    SELECT major_id INTO student_major_id
    FROM university.students
    WHERE student_id = NEW.student_id;

    -- Get course unit major_id
    SELECT cm.major_id INTO major_course_id
    FROM university.sections AS sect
    JOIN university.major_courses AS cm ON sect.major_course_id = cm.major_course_id
    WHERE sect.section_id = NEW.section_id;

    -- Compare major_ids
    IF student_major_id IS DISTINCT FROM major_course_id THEN
        RAISE EXCEPTION 'Major mismatch: Student major_id does not match Course Unit major_id.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER major_eligibility_check_trigger
BEFORE INSERT OR UPDATE OF student_id, section_id ON university.student_sections
FOR EACH ROW
EXECUTE FUNCTION university.check_major_eligibility();

--------------------------------------------------------------------------------------------------------
-- BR: Students can only register for courses when they satisfy the minimum average score of the subject.
-- Rule: The GPA score of the courses studied must be greater than or equal to the GPA required of the course.
-- Triggered when adding a new student_enrollemnt record, calculates the GPA of the courses studied, compares it with the required GPQ of the course want to register.
-- CREATE OR REPLACE FUNCTION university.check_gpa_prerequisite()
-- RETURNS TRIGGER AS $$
-- DECLARE
--     required_gpa DECIMAL;
--     student_cumulative_gpa DECIMAL;
--     course_title VARCHAR;
-- BEGIN
--     -- Get class section's required GPA
--     SELECT cm.gpa_requirement, c.title
--     INTO required_gpa, course_title
--     FROM university.sections AS sect
--     JOIN university.major_courses AS cm ON sect.major_course_id = cm.major_course_id
--     JOIN university.courses AS c ON cm.course_id = c.course_id
--     WHERE sect.section_id = NEW.section_id;

--     IF required_gpa IS NOT NULL THEN
--         -- Caculate cumulative GPA for the student 
--         SELECT AVG(score)
--         INTO student_cumulative_gpa
--         FROM university.student_sections
--         WHERE student_id = NEW.student_id
--           -- Only courses have score (completed courses)
--           AND score IS NOT NULL;

--         -- Coalesce student_cumulative_gpa to 0.0
--         student_cumulative_gpa := COALESCE(student_cumulative_gpa, 0.0);

--         -- Compare GPA
--         IF student_cumulative_gpa < required_gpa THEN
--             RAISE EXCEPTION 'GPA prerequisite not met for course.';
--         END IF;
--     END IF;
    
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER check_gpa_prerequisite_trigger
-- BEFORE INSERT OR UPDATE OF student_id, section_id ON university.student_sections
-- FOR EACH ROW
-- EXECUTE FUNCTION university.check_gpa_prerequisite();

--------------------------------------------------------------------------------------------------------
-- BR: Students registering for a course must complete the prerequisite courses for the course they want to register for.
-- Rule: Students must complete the prerequisite courses required for the course.
-- Triggered when adding a new or updating student_enrollemnt record, get a list of all the courses the student has taken and compare it with the requirements of the course he/she registered for.
CREATE OR REPLACE FUNCTION university.check_course_prerequisites()
RETURNS TRIGGER AS $$
DECLARE
    target_course_id BIGINT;
    prereq_id BIGINT; 
    prerequisite_course_code VARCHAR;
    prerequisite_course_title VARCHAR;
    completed BOOLEAN;
BEGIN
    SELECT cm.course_id
    INTO target_course_id
    FROM university.sections AS sect
    JOIN university.major_courses AS cm ON sect.major_course_id = cm.major_course_id
    WHERE sect.section_id = NEW.section_id;

    FOR prereq_id IN 
        SELECT prerequisite_course_id
        FROM university.prerequisites
        WHERE course_id = target_course_id
    LOOP
        completed := FALSE;

        SELECT TRUE INTO completed
        FROM university.student_sections AS se
        JOIN university.sections AS sect_old ON se.section_id = sect_old.section_id
        JOIN university.major_courses AS cm_old ON sect_old.major_course_id = cm_old.major_course_id
        
        WHERE se.student_id = NEW.student_id
          AND cm_old.course_id = prereq_id
          AND se.score IS NOT NULL 
        LIMIT 1;

        IF NOT completed THEN
            RAISE EXCEPTION 'Prerequisite course not completed.';
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_prerequisites_trigger
BEFORE INSERT OR UPDATE OF student_id, section_id ON university.student_sections
FOR EACH ROW
EXECUTE FUNCTION university.check_course_prerequisites();

--------------------------------------------------------------------------------------------------------
-- BR: The course type of a course includes only values: General, Fundamental, Specialized
-- Rule: The course_type field in the courses table must be one of the specified values: General, Fundamental, Specialized
-- Triggered when adding a new or updating the course_type of course record.
CREATE OR REPLACE FUNCTION university.validate_course_type()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.course_type IS NOT NULL AND NEW.course_type NOT IN ('General', 'Fundamental', 'Specialized') THEN
        RAISE EXCEPTION 'Invalid course type, course_type must be General, Fundamental, or Specialized.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER course_type_validation_trigger
BEFORE INSERT OR UPDATE OF course_type ON university.courses
FOR EACH ROW
EXECUTE FUNCTION university.validate_course_type();

--------------------------------------------------------------------------------------------------------
-- BR: The status of a timetable includes only values: Scheduled, Cancelled, Complete
-- Rule: The status field in the timetable table must be one of the specified values: Scheduled, Cancelled, Complete
-- Trigger to status value in timetables table
CREATE OR REPLACE FUNCTION university.validate_timetable_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS NOT NULL AND NEW.status NOT IN ('Scheduled', 'Cancelled', 'Complete') THEN
        RAISE EXCEPTION 'Invalid status, status must be Scheduled, Cancelled, or Complete.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER timetable_status_validation_trigger
BEFORE INSERT OR UPDATE OF status ON university.timetables
FOR EACH ROW
EXECUTE FUNCTION university.validate_timetable_status();

--------------------------------------------------------------------------------------------------------
-- BR: Student cannot register for the same course in one semester.
-- Rule: A student cannot enroll in multiple class sections of the same course unit within the same semester.
-- Trigger when adding new or updating student_enrollemnt record, check duplicate course unit in the same semester.
CREATE OR REPLACE FUNCTION university.check_duplicate_course_unit_in_semester()
RETURNS TRIGGER AS $$
DECLARE
    new_semester_id INTEGER;
    new_major_course_id INTEGER;
    existing_enrollments_count INTEGER;
BEGIN
    SELECT sect.semester_id, sect.major_course_id
    INTO new_semester_id, new_major_course_id
    FROM university.sections sect
    WHERE sect.section_id = NEW.section_id;

    SELECT COUNT(*)
    INTO existing_enrollments_count
    FROM university.student_sections AS se
    JOIN university.sections AS sect_existing 
        ON se.section_id = sect_existing.section_id
    WHERE se.student_id = NEW.student_id
        AND sect_existing.semester_id = new_semester_id
        AND sect_existing.major_course_id = new_major_course_id
        AND se.student_section_id != COALESCE(NEW.student_section_id, -1); 

    IF existing_enrollments_count > 0 THEN
        RAISE EXCEPTION 'The course has already been registered.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER before_insert_update_enrollment
BEFORE INSERT OR UPDATE OF section_id, student_id ON university.student_sections
FOR EACH ROW
EXECUTE FUNCTION university.check_duplicate_course_unit_in_semester();

--------------------------------------------------------------------------------------------------------
-- BR: Class section capacity
-- Rule: The number of students enrolled in a class section must not exceed its maximum capacity.
-- Trigger when adding new student_enrollemnt record, check the maximum capacity of the class section semester.
CREATE OR REPLACE FUNCTION university.check_max_capacity()
RETURNS TRIGGER AS $$
DECLARE
    class_max_capacity INTEGER;
    current_enrollment_count INTEGER;
BEGIN
    SELECT sect.max_capacity
    INTO class_max_capacity
    FROM university.sections AS sect
    WHERE sect.section_id = NEW.section_id;

    IF class_max_capacity IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT COUNT(*)
    INTO current_enrollment_count
    FROM university.student_sections AS se
    WHERE se.section_id = NEW.section_id;

    IF current_enrollment_count >= class_max_capacity THEN
        RAISE EXCEPTION 'Class section capacity exceeded.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER before_insert_check_capacity
BEFORE INSERT ON university.student_sections
FOR EACH ROW
EXECUTE FUNCTION university.check_max_capacity();

-- Trigger SIN should be string of numbers only
CREATE OR REPLACE FUNCTION university.check_professor_sin_format()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.professor_sin IS NULL OR NEW.professor_sin !~ '^\d+$' THEN
        RAISE EXCEPTION 'Invalid SIN Format: SIN must contain digits only.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_professor_sin_trigger
BEFORE INSERT OR UPDATE OF professor_sin ON university.professors
FOR EACH ROW
EXECUTE FUNCTION university.check_professor_sin_format();

-- Trigger scheduled_time should be in the semester date range
CREATE OR REPLACE FUNCTION university.check_schedule_time_in_semester_range()
RETURNS TRIGGER AS $$
DECLARE
    semester_start DATE;
    semester_end DATE;
    semester_id_val BIGINT;
BEGIN
    SELECT semester_id
    INTO semester_id_val
    FROM university.sections
    WHERE section_id = NEW.section_id;

    SELECT start_date, end_date
    INTO semester_start, semester_end
    FROM university.semesters
    WHERE semester_id = semester_id_val;

    IF NEW.schedule_time < semester_start::TIMESTAMP OR NEW.schedule_time >= (semester_end + INTERVAL '1 day')::TIMESTAMP THEN
        RAISE EXCEPTION 'Schedule date and time is outside the valid range for the semester.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_schedule_time_trigger
BEFORE INSERT OR UPDATE OF schedule_time, section_id ON university.timetables
FOR EACH ROW
EXECUTE FUNCTION university.check_schedule_time_in_semester_range();

-- Trigger check student email format
CREATE OR REPLACE FUNCTION university.check_student_email_format()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.student_email !~* '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}$' THEN
        RAISE EXCEPTION 'Invalid Email Format';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_student_email_trigger
BEFORE INSERT OR UPDATE OF student_email ON university.students
FOR EACH ROW
EXECUTE FUNCTION university.check_student_email_format();

-- Trigger check professor email format
CREATE OR REPLACE FUNCTION university.check_professor_email_format()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.professor_email !~* '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}$' THEN
        RAISE EXCEPTION 'Invalid Email Format';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_professor_email_trigger
BEFORE INSERT OR UPDATE OF professor_email ON university.professors
FOR EACH ROW
EXECUTE FUNCTION university.check_professor_email_format();
