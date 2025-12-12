-- SQL Function: register_student_for_course
-- This function registers a student for a course WITH transaction handling and row-level locking.
-- It uses SELECT FOR UPDATE to prevent race conditions and ensures capacity limits are enforced.

CREATE OR REPLACE FUNCTION register_student_for_course(
    p_student_code TEXT,
    p_course_code TEXT,
    p_status TEXT DEFAULT 'active'
)
RETURNS TABLE (
    registration_id UUID,
    registration_date TIMESTAMPTZ,
    student JSONB,
    course JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_student RECORD;
    v_course RECORD;
    v_existing RECORD;
    v_current_count INT;
    v_max_capacity INT;
    v_uuid UUID := gen_random_uuid();
    v_registration_date TIMESTAMPTZ;
BEGIN
    -- 1. Fetch student (no lock needed, just validation)
    SELECT 
        student_id, student_code, first_name, last_name,
        email, phone, created_at
    INTO v_student
    FROM students
    WHERE student_code = p_student_code;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Student not found' USING ERRCODE = 'P0001';
    END IF;

    -- 2. Lock course row FOR UPDATE to prevent concurrent modifications
    SELECT 
        course_id, course_code, course_name, description,
        credits, max_capacity, instructor, created_at
    INTO v_course
    FROM courses
    WHERE course_code = p_course_code
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Course not found' USING ERRCODE = 'P0001';
    END IF;

    v_max_capacity := v_course.max_capacity;

    -- 3. Lock all active registrations for this course FOR UPDATE
    -- This serializes registration attempts and ensures accurate capacity counting
    PERFORM 1
    FROM registrations
    WHERE course_code = p_course_code
      AND status = 'active'
    FOR UPDATE;

    -- 4. Check if student is already registered (within the locked transaction)
    SELECT id
    INTO v_existing
    FROM registrations
    WHERE student_code = p_student_code
      AND course_code = p_course_code;

    IF FOUND THEN
        RAISE EXCEPTION 'Student is already registered for this course' USING ERRCODE = 'P0001';
    END IF;

    -- 5. Count current registrations (accurate because rows are locked)
    SELECT COUNT(*) INTO v_current_count
    FROM registrations
    WHERE course_code = p_course_code
      AND status = 'active';

    -- 6. Check capacity before inserting
    IF v_current_count >= v_max_capacity THEN
        RAISE EXCEPTION 'Course has reached maximum capacity of % students', v_max_capacity USING ERRCODE = 'P0001';
    END IF;

    -- 7. Insert registration (within the transaction)
    INSERT INTO registrations (
        id, student_code, course_code, status,
        registration_date, created_at, updated_at
    )
    VALUES (
        v_uuid, p_student_code, p_course_code, p_status,
        NOW(), NOW(), NOW()
    )
    RETURNING registrations.registration_date INTO v_registration_date;

    -- 8. Build JSONB responses for student and course
    registration_id := v_uuid;
    registration_date := v_registration_date;
    student := jsonb_build_object(
        'student_id', v_student.student_id,
        'student_code', v_student.student_code,
        'first_name', v_student.first_name,
        'last_name', v_student.last_name,
        'email', v_student.email,
        'phone', v_student.phone,
        'created_at', v_student.created_at
    );
    course := jsonb_build_object(
        'course_id', v_course.course_id,
        'course_code', v_course.course_code,
        'course_name', v_course.course_name,
        'description', v_course.description,
        'credits', v_course.credits,
        'max_capacity', v_course.max_capacity,
        'instructor', v_course.instructor,
        'created_at', v_course.created_at
    );

    RETURN NEXT;
END;
$$;

