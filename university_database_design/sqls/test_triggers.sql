SET search_path TO university, public;

-- Create department
INSERT INTO departments(department_id, title, description) 
VALUES (888, 'Test Department', 'Test department for trigger testing')
ON CONFLICT (department_id) DO NOTHING;

-- Create majors
INSERT INTO majors(major_id, department_id, major_code, title, description)
VALUES 
    (888, 888, 'T888', 'Test Major 1', 'Test major for trigger testing'),
    (889, 888, 'T889', 'Test Major 2', 'Another test major for trigger testing')
ON CONFLICT (major_id) DO NOTHING;

-- Create professor
INSERT INTO professors(professor_sin, department_id, professor_email, first_name, last_name)
VALUES ('888888888', 888, 'test.prof@university.edu', 'Test', 'Professor')
ON CONFLICT (professor_sin) DO NOTHING;

-- Create semester
INSERT INTO semesters(semester_id, name, start_date, end_date)
VALUES (888, 'Test Semester', CURRENT_DATE - 30, CURRENT_DATE + 90)
ON CONFLICT (semester_id) DO NOTHING;

-- Create test courses
INSERT INTO courses(course_id, prerequisite_course_id, course_code, title, course_type, description)
VALUES 
    (801, NULL, 'TEST201', 'Test Course 201', 'General', 'Test course'),
    (802, NULL, 'TEST202', 'Test Course 202', 'Fundamental', 'Test course'),
    (803, NULL, 'TEST203', 'Test Course 203', 'Specialized', 'Test course')
ON CONFLICT (course_id) DO NOTHING;

-- Create major_courses
INSERT INTO major_courses(major_course_id, course_id, major_id)
VALUES 
    (801, 801, 888),
    (802, 802, 888),
    (803, 803, 888)
ON CONFLICT (major_course_id) DO NOTHING;

-- Create sections
INSERT INTO sections(section_id, major_course_id, semester_id, professor_sin, max_capacity)
VALUES 
    (801, 801, 888, '888888888', 5),  -- Small capacity for capacity testing
    (802, 802, 888, '888888888', 10),
    (803, 803, 888, '888888888', 3)
ON CONFLICT (section_id) DO NOTHING;

-- Create students
INSERT INTO students(student_id, student_code, student_email, first_name, last_name, major_id, enrollment_date)
VALUES 
    (801, 'T80001', 'student1.test@university.edu', 'Test', 'Student1', 888, CURRENT_DATE),
    (802, 'T80002', 'student2.test@university.edu', 'Test', 'Student2', 888, CURRENT_DATE),
    (803, 'T80003', 'student3.test@university.edu', 'Test', 'Student3', 889, CURRENT_DATE)  -- Different major
ON CONFLICT (student_id) DO NOTHING;

-- TEST 1: score_validation_trigger - Score Range Validation
DO $$
BEGIN
    RAISE NOTICE '=== TEST 1.1: Valid score (2.5) - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (801, 801, 801, CURRENT_DATE, 2.5);
        RAISE NOTICE '=== TEST 1.1 PASSED ===';
        
        DELETE FROM student_sections WHERE student_section_id = 801;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 1.1 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 1.2: Valid score (0.00) - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (802, 801, 801, CURRENT_DATE, 0.00);
        RAISE NOTICE '=== TEST 1.2 PASSED ===';
        
        DELETE FROM student_sections WHERE student_section_id = 802;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 1.2 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 1.3: Valid score (4.00) - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (803, 801, 801, CURRENT_DATE, 4.00);
        RAISE NOTICE '=== TEST 1.3 PASSED ===';
        
        DELETE FROM student_sections WHERE student_section_id = 803;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 1.3 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 1.4: Invalid score (4.01) - Should FAIL ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (804, 801, 801, CURRENT_DATE, 4.01);
        RAISE NOTICE '=== TEST 1.4 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid score%' THEN
            RAISE NOTICE '=== TEST 1.4 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 1.4 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 1.5: Invalid score (-0.01) - Should FAIL ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (805, 801, 801, CURRENT_DATE, -0.01);
        RAISE NOTICE '=== TEST 1.5 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid score%' THEN
            RAISE NOTICE '=== TEST 1.5 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 1.5 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 1.6: Update score to invalid value (5.0) - Should FAIL ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (806, 801, 801, CURRENT_DATE, 3.0);
        
        UPDATE student_sections SET score = 5.0 WHERE student_section_id = 806;
        RAISE NOTICE '=== TEST 1.6 FAILED ===';
        
        DELETE FROM student_sections WHERE student_section_id = 806;
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid score%' THEN
            RAISE NOTICE '=== TEST 1.6 PASSED ===';
            DELETE FROM student_sections WHERE student_section_id = 806;
        ELSE
            RAISE NOTICE '=== TEST 1.6 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

-- TEST 2: major_eligibility_check_trigger - Major Eligibility
DO $$
BEGIN
    RAISE NOTICE '=== TEST 2.1: Student enrolls in course with matching major - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (807, 801, 801, CURRENT_DATE, NULL);
        RAISE NOTICE '=== TEST 2.1 PASSED ===';
        
        DELETE FROM student_sections WHERE student_section_id = 807;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 2.1 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 2.2: Student enrolls in course with different major - Should FAIL ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (808, 803, 801, CURRENT_DATE, NULL);  -- Student 803 has major 889, course is for major 888
        RAISE NOTICE '=== TEST 2.2 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Major mismatch%' THEN
            RAISE NOTICE '=== TEST 2.2 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 2.2 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

-- TEST 3: course_type_validation_trigger - Course Type Validation
DO $$
BEGIN
    RAISE NOTICE '=== TEST 3.1: Valid course type (General) - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO courses(course_id, prerequisite_course_id, course_code, title, course_type, description)
        VALUES (804, NULL, 'TEST204', 'Test Course 204', 'General', 'Test course');
        RAISE NOTICE '=== TEST 3.1 PASSED ===';
        
        DELETE FROM courses WHERE course_id = 804;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 3.1 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 3.2: Valid course type (Fundamental) - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO courses(course_id, prerequisite_course_id, course_code, title, course_type, description)
        VALUES (805, NULL, 'TEST205', 'Test Course 205', 'Fundamental', 'Test course');
        RAISE NOTICE '=== TEST 3.2 PASSED ===';
        
        DELETE FROM courses WHERE course_id = 805;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 3.2 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 3.3: Valid course type (Specialized) - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO courses(course_id, prerequisite_course_id, course_code, title, course_type, description)
        VALUES (806, NULL, 'TEST206', 'Test Course 206', 'Specialized', 'Test course');
        RAISE NOTICE '=== TEST 3.3 PASSED ===';
        
        DELETE FROM courses WHERE course_id = 806;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 3.3 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 3.4: Invalid course type (Invalid) - Should FAIL ===';
    
    BEGIN
        INSERT INTO courses(course_id, prerequisite_course_id, course_code, title, course_type, description)
        VALUES (807, NULL, 'TEST207', 'Test Course 207', 'Invalid', 'Test course');
        RAISE NOTICE '=== TEST 3.4 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid course type%' THEN
            RAISE NOTICE '=== TEST 3.4 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 3.4 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 3.5: Update course type to invalid value - Should FAIL ===';
    
    BEGIN
        UPDATE courses SET course_type = 'InvalidType' WHERE course_id = 801;
        RAISE NOTICE '=== TEST 3.5 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid course type%' THEN
            RAISE NOTICE '=== TEST 3.5 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 3.5 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

-- TEST 4: timetable_status_validation_trigger - Timetable Status Validation
DO $$
BEGIN
    RAISE NOTICE '=== TEST 4.1: Valid status (Scheduled) - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO timetables(timetables_id, section_id, room, status, schedule_time)
        VALUES (801, 801, 'Room101', 'Scheduled', CURRENT_DATE + 1);
        RAISE NOTICE '=== TEST 4.1 PASSED ===';
        
        DELETE FROM timetables WHERE timetables_id = 801;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 4.1 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 4.2: Valid status (Cancelled) - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO timetables(timetables_id, section_id, room, status, schedule_time)
        VALUES (802, 801, 'Room102', 'Cancelled', CURRENT_DATE + 1);
        RAISE NOTICE '=== TEST 4.2 PASSED ===';
        
        DELETE FROM timetables WHERE timetables_id = 802;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 4.2 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 4.3: Valid status (Complete) - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO timetables(timetables_id, section_id, room, status, schedule_time)
        VALUES (803, 801, 'Room103', 'Complete', CURRENT_DATE + 1);
        RAISE NOTICE '=== TEST 4.3 PASSED ===';
        
        DELETE FROM timetables WHERE timetables_id = 803;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 4.3 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 4.4: Invalid status (Pending) - Should FAIL ===';
    
    BEGIN
        INSERT INTO timetables(timetables_id, section_id, room, status, schedule_time)
        VALUES (804, 801, 'Room104', 'Pending', CURRENT_DATE + 1);
        RAISE NOTICE '=== TEST 4.4 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid status%' THEN
            RAISE NOTICE '=== TEST 4.4 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 4.4 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 4.5: Update status to invalid value - Should FAIL ===';
    
    BEGIN
        INSERT INTO timetables(timetables_id, section_id, room, status, schedule_time)
        VALUES (805, 801, 'Room105', 'Scheduled', CURRENT_DATE + 1);
        
        UPDATE timetables SET status = 'InvalidStatus' WHERE timetables_id = 805;
        RAISE NOTICE '=== TEST 4.5 FAILED ===';
        
        DELETE FROM timetables WHERE timetables_id = 805;
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid status%' THEN
            RAISE NOTICE '=== TEST 4.5 PASSED ===';
            DELETE FROM timetables WHERE timetables_id = 805;
        ELSE
            RAISE NOTICE '=== TEST 4.5 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

-- TEST 5: before_insert_update_enrollment - Duplicate Course in Semester
DO $$
BEGIN
    RAISE NOTICE '=== TEST 5.1: Student enrolls in different course in same semester - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (809, 801, 801, CURRENT_DATE, NULL);
        
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (810, 801, 802, CURRENT_DATE, NULL);  -- Different course, same semester
        RAISE NOTICE '=== TEST 5.1 PASSED ===';
        
        DELETE FROM student_sections WHERE student_section_id IN (809, 810);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 5.1 FAILED: % ===', SQLERRM;
        DELETE FROM student_sections WHERE student_section_id = 809;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 5.2: Student enrolls in same course twice in same semester - Should FAIL ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (811, 801, 801, CURRENT_DATE, NULL);
        
        -- Try to enroll in same course again (different section but same major_course_id)
        -- First create another section for the same course
        INSERT INTO sections(section_id, major_course_id, semester_id, professor_sin, max_capacity)
        VALUES (804, 801, 888, '888888888', 10)
        ON CONFLICT (section_id) DO NOTHING;
        
        BEGIN
            INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
            VALUES (812, 801, 804, CURRENT_DATE, NULL);  -- Same course, same semester
            RAISE NOTICE '=== TEST 5.2 FAILED ===';
        EXCEPTION WHEN OTHERS THEN
            IF SQLERRM LIKE '%already been registered%' THEN
                RAISE NOTICE '=== TEST 5.2 PASSED ===';
            ELSE
                RAISE NOTICE '=== TEST 5.2 FAILED: % ===', SQLERRM;
                RAISE;
            END IF;
        END;
        
        DELETE FROM student_sections WHERE student_section_id = 811;
        DELETE FROM sections WHERE section_id = 804;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 5.2 FAILED: % ===', SQLERRM;
        DELETE FROM student_sections WHERE student_section_id = 811;
        DELETE FROM sections WHERE section_id = 804;
        RAISE;
    END;
END $$;

-- TEST 6: before_insert_check_capacity - Max Capacity Check
DO $$
BEGIN
    RAISE NOTICE '=== TEST 6.1: Enroll students up to capacity - Should SUCCEED ===';
    
    BEGIN
        -- Section 803 has max_capacity of 3
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (813, 801, 803, CURRENT_DATE, NULL);
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (814, 802, 803, CURRENT_DATE, NULL);
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (815, 803, 803, CURRENT_DATE, NULL);
        RAISE NOTICE '=== TEST 6.1 PASSED ===';
        
        DELETE FROM student_sections WHERE student_section_id IN (813, 814, 815);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 6.1 FAILED: % ===', SQLERRM;
        DELETE FROM student_sections WHERE student_section_id IN (813, 814, 815);
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 6.2: Enroll student exceeding capacity - Should FAIL ===';
    
    BEGIN
        -- Section 803 has max_capacity of 3, fill it up
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (816, 801, 803, CURRENT_DATE, NULL);
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (817, 802, 803, CURRENT_DATE, NULL);
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (818, 803, 803, CURRENT_DATE, NULL);
        
        -- Try to enroll one more (should fail)
        BEGIN
            -- Need to create another student first
            INSERT INTO students(student_id, student_code, student_email, first_name, last_name, major_id, enrollment_date)
            VALUES (804, 'T80004', 'student4.test@university.edu', 'Test', 'Student4', 888, CURRENT_DATE)
            ON CONFLICT (student_id) DO NOTHING;
            
            INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
            VALUES (819, 804, 803, CURRENT_DATE, NULL);
            RAISE NOTICE '=== TEST 6.2 FAILED ===';
        EXCEPTION WHEN OTHERS THEN
            IF SQLERRM LIKE '%capacity exceeded%' THEN
                RAISE NOTICE '=== TEST 6.2 PASSED ===';
            ELSE
                RAISE NOTICE '=== TEST 6.2 FAILED: % ===', SQLERRM;
                RAISE;
            END IF;
        END;
        
        DELETE FROM student_sections WHERE student_section_id IN (816, 817, 818, 819);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 6.2 FAILED: % ===', SQLERRM;
        DELETE FROM student_sections WHERE student_section_id IN (816, 817, 818, 819);
        RAISE;
    END;
END $$;

-- TEST 7: check_professor_sin_trigger - Professor SIN Format
DO $$
BEGIN
    RAISE NOTICE '=== TEST 7.1: Valid SIN (digits only) - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO professors(professor_sin, department_id, professor_email, first_name, last_name)
        VALUES ('123456789', 888, 'prof1.test@university.edu', 'Test', 'Prof1');
        RAISE NOTICE '=== TEST 7.1 PASSED ===';
        
        DELETE FROM professors WHERE professor_sin = '123456789';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 7.1 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 7.2: Invalid SIN (contains letters) - Should FAIL ===';
    
    BEGIN
        INSERT INTO professors(professor_sin, department_id, professor_email, first_name, last_name)
        VALUES ('12345678A', 888, 'prof2.test@university.edu', 'Test', 'Prof2');
        RAISE NOTICE '=== TEST 7.2 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid SIN Format%' THEN
            RAISE NOTICE '=== TEST 7.2 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 7.2 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 7.3: Invalid SIN (contains special characters) - Should FAIL ===';
    
    BEGIN
        INSERT INTO professors(professor_sin, department_id, professor_email, first_name, last_name)
        VALUES ('123-456-789', 888, 'prof3.test@university.edu', 'Test', 'Prof3');
        RAISE NOTICE '=== TEST 7.3 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid SIN Format%' THEN
            RAISE NOTICE '=== TEST 7.3 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 7.3 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 7.4: Update SIN to invalid value - Should FAIL ===';
    
    BEGIN
        UPDATE professors SET professor_sin = 'ABC123456' WHERE professor_sin = '888888888';
        RAISE NOTICE '=== TEST 7.4 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid SIN Format%' THEN
            RAISE NOTICE '=== TEST 7.4 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 7.4 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

-- TEST 8: check_schedule_time_trigger - Schedule Time in Semester Range
DO $$
BEGIN
    RAISE NOTICE '=== TEST 8.1: Schedule time within semester range - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO timetables(timetables_id, section_id, room, status, schedule_time)
        VALUES (806, 801, 'Room106', 'Scheduled', CURRENT_DATE);  -- Within semester range
        RAISE NOTICE '=== TEST 8.1 PASSED ===';
        
        DELETE FROM timetables WHERE timetables_id = 806;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 8.1 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 8.2: Schedule time before semester start - Should FAIL ===';
    
    BEGIN
        INSERT INTO timetables(timetables_id, section_id, room, status, schedule_time)
        VALUES (807, 801, 'Room107', 'Scheduled', CURRENT_DATE - 60);  -- Before semester start
        RAISE NOTICE '=== TEST 8.2 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%outside the valid range%' THEN
            RAISE NOTICE '=== TEST 8.2 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 8.2 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 8.3: Schedule time after semester end - Should FAIL ===';
    
    BEGIN
        INSERT INTO timetables(timetables_id, section_id, room, status, schedule_time)
        VALUES (808, 801, 'Room108', 'Scheduled', CURRENT_DATE + 100);  -- After semester end
        RAISE NOTICE '=== TEST 8.3 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%outside the valid range%' THEN
            RAISE NOTICE '=== TEST 8.3 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 8.3 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 8.4: Update schedule_time to invalid value - Should FAIL ===';
    
    BEGIN
        INSERT INTO timetables(timetables_id, section_id, room, status, schedule_time)
        VALUES (809, 801, 'Room109', 'Scheduled', CURRENT_DATE);
        
        UPDATE timetables SET schedule_time = CURRENT_DATE - 60 WHERE timetables_id = 809;
        RAISE NOTICE '=== TEST 8.4 FAILED ===';
        
        DELETE FROM timetables WHERE timetables_id = 809;
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%outside the valid range%' THEN
            RAISE NOTICE '=== TEST 8.4 PASSED ===';
            DELETE FROM timetables WHERE timetables_id = 809;
        ELSE
            RAISE NOTICE '=== TEST 8.4 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

-- TEST 9: check_student_email_trigger - Student Email Format
DO $$
BEGIN
    RAISE NOTICE '=== TEST 9.1: Valid email format - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO students(student_id, student_code, student_email, first_name, last_name, major_id, enrollment_date)
        VALUES (805, 'T80005', 'valid.email@university.edu', 'Test', 'Student5', 888, CURRENT_DATE);
        RAISE NOTICE '=== TEST 9.1 PASSED ===';
        
        DELETE FROM students WHERE student_id = 805;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 9.1 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 9.2: Invalid email (no @) - Should FAIL ===';
    
    BEGIN
        INSERT INTO students(student_id, student_code, student_email, first_name, last_name, major_id, enrollment_date)
        VALUES (806, 'T80006', 'invalidemail.university.edu', 'Test', 'Student6', 888, CURRENT_DATE);
        RAISE NOTICE '=== TEST 9.2 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid Email Format%' THEN
            RAISE NOTICE '=== TEST 9.2 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 9.2 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 9.3: Invalid email (no domain) - Should FAIL ===';
    
    BEGIN
        INSERT INTO students(student_id, student_code, student_email, first_name, last_name, major_id, enrollment_date)
        VALUES (807, 'T80007', 'invalid@', 'Test', 'Student7', 888, CURRENT_DATE);
        RAISE NOTICE '=== TEST 9.3 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid Email Format%' THEN
            RAISE NOTICE '=== TEST 9.3 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 9.3 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 9.4: Update email to invalid format - Should FAIL ===';
    
    BEGIN
        UPDATE students SET student_email = 'invalidemail' WHERE student_id = 801;
        RAISE NOTICE '=== TEST 9.4 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid Email Format%' THEN
            RAISE NOTICE '=== TEST 9.4 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 9.4 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

-- TEST 10: check_professor_email_trigger - Professor Email Format
DO $$
BEGIN
    RAISE NOTICE '=== TEST 10.1: Valid email format - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO professors(professor_sin, department_id, professor_email, first_name, last_name)
        VALUES ('111111111', 888, 'valid.prof@university.edu', 'Test', 'Prof4');
        RAISE NOTICE '=== TEST 10.1 PASSED ===';
        
        DELETE FROM professors WHERE professor_sin = '111111111';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 10.1 FAILED: % ===', SQLERRM;
        RAISE;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 10.2: Invalid email (no @) - Should FAIL ===';
    
    BEGIN
        INSERT INTO professors(professor_sin, department_id, professor_email, first_name, last_name)
        VALUES ('222222222', 888, 'invalidemail.university.edu', 'Test', 'Prof5');
        RAISE NOTICE '=== TEST 10.2 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid Email Format%' THEN
            RAISE NOTICE '=== TEST 10.2 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 10.2 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 10.3: Invalid email (no domain) - Should FAIL ===';
    
    BEGIN
        INSERT INTO professors(professor_sin, department_id, professor_email, first_name, last_name)
        VALUES ('333333333', 888, 'invalid@', 'Test', 'Prof6');
        RAISE NOTICE '=== TEST 10.3 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid Email Format%' THEN
            RAISE NOTICE '=== TEST 10.3 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 10.3 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;

DO $$
BEGIN
    RAISE NOTICE '=== TEST 10.4: Update email to invalid format - Should FAIL ===';
    
    BEGIN
        UPDATE professors SET professor_email = 'invalidemail' WHERE professor_sin = '888888888';
        RAISE NOTICE '=== TEST 10.4 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Invalid Email Format%' THEN
            RAISE NOTICE '=== TEST 10.4 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 10.4 FAILED: % ===', SQLERRM;
            RAISE;
        END IF;
    END;
END $$;
