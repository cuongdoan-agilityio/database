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
    course_type VARCHAR,
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

-- Function check student score range between 0.00 and 4.00
CREATE OR REPLACE FUNCTION university.check_score_range()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.score IS NOT NULL AND (NEW.score < 0.00 OR NEW.score > 4.00) THEN
        RAISE EXCEPTION 'Invalid score, score must be between 0.00 and 4.00.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for score validation
CREATE TRIGGER score_validation_trigger
BEFORE INSERT OR UPDATE OF score ON university.student_enrollments
FOR EACH ROW
EXECUTE FUNCTION university.check_score_range();


-- Function check course GPA prerequisite value range between 0.00 and 4.00
CREATE OR REPLACE FUNCTION university.check_gpa_range()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.gpa_requirement IS NOT NULL AND (NEW.gpa_requirement < 0.00 OR NEW.gpa_requirement > 4.00) THEN
        RAISE EXCEPTION 'Invalid gpa prerequisite, must be between 0.00 and 4.00.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for gpa validation
CREATE TRIGGER gpa_validation_trigger
BEFORE INSERT OR UPDATE OF gpa_requirement ON university.course_units
FOR EACH ROW
EXECUTE FUNCTION university.check_gpa_range();

-- Function check major eligibility when student enrolls in a class section
CREATE OR REPLACE FUNCTION university.check_major_eligibility()
RETURNS TRIGGER AS $$
DECLARE
    student_major_id BIGINT;
    course_major_id BIGINT;
BEGIN
    -- Get student major_id
    SELECT major_id INTO student_major_id
    FROM university.students
    WHERE student_id = NEW.student_id;

    -- Get course unit major_id
    SELECT cu.major_id INTO course_major_id
    FROM university.class_section_semesters AS css
    JOIN university.course_units AS cu ON css.course_unit_id = cu.course_unit_id
    WHERE css.class_section_semester_id = NEW.class_section_semester_id;

    -- Compare major_ids
    IF student_major_id IS DISTINCT FROM course_major_id THEN
        RAISE EXCEPTION 'Major mismatch: Student major_id does not match Course Unit major_id.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for major eligibility check
CREATE TRIGGER major_eligibility_check_trigger
BEFORE INSERT OR UPDATE OF student_id, class_section_semester_id ON university.student_enrollments
FOR EACH ROW
EXECUTE FUNCTION university.check_major_eligibility();


CREATE OR REPLACE FUNCTION university.check_gpa_prerequisite()
RETURNS TRIGGER AS $$
DECLARE
    required_gpa DECIMAL;
    student_cumulative_gpa DECIMAL;
    course_title VARCHAR;
BEGIN
    -- Get class section's required GPA
    SELECT cu.gpa_requirement, c.title
    INTO required_gpa, course_title
    FROM university.class_section_semesters AS css
    JOIN university.course_units AS cu ON css.course_unit_id = cu.course_unit_id
    JOIN university.courses AS c ON cu.course_id = c.course_id
    WHERE css.class_section_semester_id = NEW.class_section_semester_id;

    IF required_gpa IS NOT NULL THEN
        -- Caculate cumulative GPA for the student 
        SELECT AVG(score)
        INTO student_cumulative_gpa
        FROM university.student_enrollments
        WHERE student_id = NEW.student_id
          -- Only courses have score (completed courses)
          AND score IS NOT NULL;

        -- Coalesce student_cumulative_gpa to 0.0
        student_cumulative_gpa := COALESCE(student_cumulative_gpa, 0.0);

        -- Compare GPA
        IF student_cumulative_gpa < required_gpa THEN
            RAISE EXCEPTION 'GPA prerequisite not met for course.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_gpa_prerequisite_trigger
BEFORE INSERT OR UPDATE OF student_id, class_section_semester_id ON university.student_enrollments
FOR EACH ROW
EXECUTE FUNCTION university.check_gpa_prerequisite();


CREATE OR REPLACE FUNCTION university.check_course_prerequisites()
RETURNS TRIGGER AS $$
DECLARE
    target_course_id BIGINT;
    -- Đổi tên biến lặp từ prerequisite_course_id thành prereq_id để tránh mơ hồ
    prereq_id BIGINT; 
    prerequisite_course_code VARCHAR;
    prerequisite_course_title VARCHAR;
    completed BOOLEAN;
BEGIN
    SELECT cu.course_id
    INTO target_course_id
    FROM university.class_section_semesters AS css
    JOIN university.course_units AS cu ON css.course_unit_id = cu.course_unit_id
    WHERE css.class_section_semester_id = NEW.class_section_semester_id;

    -- Lặp qua mỗi ID khóa học tiên quyết (sử dụng prereq_id)
    FOR prereq_id IN 
        SELECT prerequisite_course_id
        FROM university.prerequisites
        WHERE course_id = target_course_id
    LOOP
        completed := FALSE;

        -- Kiểm tra xem sinh viên đã hoàn thành (có điểm số) khóa học tiên quyết này chưa
        SELECT TRUE INTO completed
        FROM university.student_enrollments AS se
        JOIN university.class_section_semesters AS css_old ON se.class_section_semester_id = css_old.class_section_semester_id
        JOIN university.course_units AS cu_old ON css_old.course_unit_id = cu_old.course_unit_id
        
        WHERE se.student_id = NEW.student_id
          AND cu_old.course_id = prereq_id -- *** SỬ DỤNG BIẾN ĐÃ ĐỔI TÊN ***
          AND se.score IS NOT NULL 
        LIMIT 1;

        IF NOT completed THEN
            SELECT course_code, title INTO prerequisite_course_code, prerequisite_course_title
            FROM university.courses
            WHERE course_id = prereq_id;

            RAISE EXCEPTION 'Lỗi đăng ký: Sinh viên chưa hoàn thành khóa học tiên quyết "%" (Mã: %).', 
            prerequisite_course_title, prerequisite_course_code;
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_prerequisites_trigger
BEFORE INSERT OR UPDATE OF student_id, class_section_semester_id ON university.student_enrollments
FOR EACH ROW
EXECUTE FUNCTION university.check_course_prerequisites();

-- Trigger to check value of course_type in courses table
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

-- Trigger each professor only teach one course