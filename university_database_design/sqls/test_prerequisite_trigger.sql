SET search_path TO university, public;

-- Create department
INSERT INTO departments(department_id, title, description) 
VALUES (999, 'Test Department', 'Test department for prerequisite testing')
ON CONFLICT (department_id) DO NOTHING;

-- Create major
INSERT INTO majors(major_id, department_id, major_code, title, description)
VALUES (999, 999, 'T999', 'Test Major', 'Test major for prerequisite testing')
ON CONFLICT (major_id) DO NOTHING;

-- Create professor
INSERT INTO professors(professor_sin, department_id, professor_email, first_name, last_name)
VALUES ('999999999', 999, 'test.prof@university.edu', 'Test', 'Professor')
ON CONFLICT (professor_sin) DO NOTHING;

-- Create semester
INSERT INTO semesters(semester_id, name, start_date, end_date)
VALUES (999, 'Test Semester', CURRENT_DATE - 30, CURRENT_DATE + 90)
ON CONFLICT (semester_id) DO NOTHING;

-- Create test courses
-- Course 1: Base course with no prerequisites
INSERT INTO courses(course_id, prerequisite_course_id, course_code, title, course_type, description)
VALUES (901, NULL, 'TEST101', 'Test Course 101 - No Prerequisites', 'General', 'Test course with no prerequisites')
ON CONFLICT (course_id) DO UPDATE SET prerequisite_course_id = NULL;

-- Course 2: Has Course 1 as prerequisite
INSERT INTO courses(course_id, prerequisite_course_id, course_code, title, course_type, description)
VALUES (902, ARRAY[901]::BIGINT[], 'TEST102', 'Test Course 102 - Requires TEST101', 'Fundamental', 'Test course requiring TEST101')
ON CONFLICT (course_id) DO UPDATE SET prerequisite_course_id = ARRAY[901]::BIGINT[];

-- Course 3: Has Course 1 and Course 2 as prerequisites
INSERT INTO courses(course_id, prerequisite_course_id, course_code, title, course_type, description)
VALUES (903, ARRAY[901, 902]::BIGINT[], 'TEST103', 'Test Course 103 - Requires TEST101 and TEST102', 'Specialized', 'Test course requiring both TEST101 and TEST102')
ON CONFLICT (course_id) DO UPDATE SET prerequisite_course_id = ARRAY[901, 902]::BIGINT[];

-- Course 4: Another base course
INSERT INTO courses(course_id, prerequisite_course_id, course_code, title, course_type, description)
VALUES (904, NULL, 'TEST104', 'Test Course 104 - No Prerequisites', 'General', 'Another test course with no prerequisites')
ON CONFLICT (course_id) DO UPDATE SET prerequisite_course_id = NULL;

-- Create major_courses
INSERT INTO major_courses(major_course_id, course_id, major_id)
VALUES 
    (901, 901, 999),
    (902, 902, 999),
    (903, 903, 999),
    (904, 904, 999)
ON CONFLICT (major_course_id) DO NOTHING;

-- Create sections
INSERT INTO sections(section_id, major_course_id, semester_id, professor_sin, max_capacity)
VALUES 
    (901, 901, 999, '999999999', 50),  -- Section for Course 901
    (902, 902, 999, '999999999', 50),  -- Section for Course 902
    (903, 903, 999, '999999999', 50),  -- Section for Course 903
    (904, 904, 999, '999999999', 50)   -- Section for Course 904
ON CONFLICT (section_id) DO NOTHING;

-- Create students
INSERT INTO students(student_id, student_code, student_email, first_name, last_name, major_id, enrollment_date)
VALUES 
    (901, 'T00001', 'student1.test@university.edu', 'Test', 'Student1', 999, CURRENT_DATE),
    (902, 'T00002', 'student2.test@university.edu', 'Test', 'Student2', 999, CURRENT_DATE),
    (903, 'T00003', 'student3.test@university.edu', 'Test', 'Student3', 999, CURRENT_DATE),
    (904, 'T00004', 'student4.test@university.edu', 'Test', 'Student4', 999, CURRENT_DATE)
ON CONFLICT (student_id) DO NOTHING;

-- TEST 1: Student enrolls in course with NO prerequisites - Should SUCCEED
DO $$
BEGIN
    RAISE NOTICE '===TEST 1: Student enrolls in course with NO prerequisites - Should SUCCEED ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (901, 901, 901, CURRENT_DATE, NULL);
        RAISE NOTICE '=== TEST 1 PASSED ===';
        
        -- Clean up
        DELETE FROM student_sections WHERE student_section_id = 901;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 1 FAILED ===';
        RAISE;
    END;
END $$;

-- TEST 2: Student enrolls in course WITH prerequisites but has NOT completed them - Should FAIL
DO $$
BEGIN
    RAISE NOTICE '=== TEST 2: Student enrolls in course WITH prerequisites but has NOT completed them - Should FAIL ===';
    
    BEGIN
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (902, 902, 902, CURRENT_DATE, NULL);
        
        RAISE NOTICE '== TEST 2 FAILED ===';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%Prerequisite course not completed%' THEN
            RAISE NOTICE '=== TEST 2 PASSED ===';
        ELSE
            RAISE NOTICE '=== TEST 2 FAILED ===';
            RAISE;
        END IF;
    END;
END $$;

-- TEST 3: Student enrolls in course WITH prerequisites and has completed them with grade >= 1.0 - Should SUCCEED
DO $$
BEGIN
    RAISE NOTICE '=== TEST 3: Student enrolls in course WITH prerequisites and has completed them with grade >= 1.0 - Should SUCCEED ===';
    
    BEGIN
        -- First, student 3 completes Course 901 with grade 2.5
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (903, 903, 901, CURRENT_DATE - 10, 2.5);
        
        -- Now student 3 should be able to enroll in Course 902
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (904, 903, 902, CURRENT_DATE, NULL);
        
        RAISE NOTICE '=== TEST 3 PASSED ===';
        
        -- Clean up
        DELETE FROM student_sections WHERE student_section_id IN (903, 904);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 3 FAILED ===';
        RAISE;
    END;
END $$;

-- TEST 4: Student enrolls in course WITH prerequisites but grade < 1.0 - Should FAIL
DO $$
BEGIN
    RAISE NOTICE '=== TEST 4: Student enrolls in course WITH prerequisites but grade < 1.0 - Should FAIL ===';
    
    BEGIN
        -- First, student 4 completes Course 901 with grade 0.5 (below 1.0)
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (905, 904, 901, CURRENT_DATE - 10, 0.5);
        
        -- Now student 4 tries to enroll in Course 902 - should fail
        BEGIN
            INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
            VALUES (906, 904, 902, CURRENT_DATE, NULL);
            
            RAISE NOTICE '=== TEST 4 FAILED ===';
        EXCEPTION WHEN OTHERS THEN
            IF SQLERRM LIKE '%Prerequisite course not completed%' THEN
                RAISE NOTICE '=== TEST 4 PASSED ===';
            ELSE
                RAISE NOTICE '=== TEST 4 FAILED ===';
                RAISE;
            END IF;
        END;
        
        -- Clean up
        DELETE FROM student_sections WHERE student_section_id = 905;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 4 FAILED ===';
        RAISE;
    END;
END $$;

-- TEST 5: Student enrolls in course with grade exactly 1.0 - Should SUCCEED
DO $$
BEGIN
    RAISE NOTICE '=== TEST 5: Student enrolls in course with grade exactly 1.0 - Should SUCCEED ===';
    
    BEGIN
        -- Student 3 completes Course 901 with grade exactly 1.0
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (907, 903, 901, CURRENT_DATE - 10, 1.0);
        
        -- Now student 3 should be able to enroll in Course 902
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (908, 903, 902, CURRENT_DATE, NULL);
        
        RAISE NOTICE '=== TEST 5 PASSED ===';
        
        -- Clean up
        DELETE FROM student_sections WHERE student_section_id IN (907, 908);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 5 FAILED ===';
        RAISE;
    END;
END $$;

-- TEST 6: Student enrolls in course with MULTIPLE prerequisites (both completed) - Should SUCCEED
DO $$
BEGIN
    RAISE NOTICE '=== TEST 6: Student enrolls in course with MULTIPLE prerequisites (both completed) - Should SUCCEED ===';
    
    BEGIN
        -- Student 3 completes Course 901 with grade 2.0
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (909, 903, 901, CURRENT_DATE - 20, 2.0);
        
        -- Student 3 completes Course 902 with grade 3.0
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (910, 903, 902, CURRENT_DATE - 10, 3.0);
        
        -- Now student 3 should be able to enroll in Course 903 (requires both 901 and 902)
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (911, 903, 903, CURRENT_DATE, NULL);
        
        RAISE NOTICE '=== TEST 6 PASSED ===';
        
        -- Clean up
        DELETE FROM student_sections WHERE student_section_id IN (909, 910, 911);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 6 FAILED ===';
        RAISE;
    END;
END $$;

-- TEST 7: Student enrolls in course with MULTIPLE prerequisites (one missing) - Should FAIL
DO $$
BEGIN
    RAISE NOTICE '=== TEST 7: Student enrolls in course with MULTIPLE prerequisites (one missing) - Should FAIL ===';
    
    BEGIN
        -- Student 2 completes Course 901 with grade 2.0
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (912, 902, 901, CURRENT_DATE - 20, 2.0);
        
        -- Student 2 does NOT complete Course 902
        -- Now student 2 tries to enroll in Course 903 - should fail
        BEGIN
            INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
            VALUES (913, 902, 903, CURRENT_DATE, NULL);
            
            RAISE NOTICE '=== TEST 7 FAILED ===';
        EXCEPTION WHEN OTHERS THEN
            IF SQLERRM LIKE '%Prerequisite course not completed%' THEN
                RAISE NOTICE '=== TEST 7 PASSED ===';
            ELSE
                RAISE NOTICE '=== TEST 7 FAILED ===';
                RAISE;
            END IF;
        END;
        
        -- Clean up
        DELETE FROM student_sections WHERE student_section_id = 912;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 7 FAILED ===';
        RAISE;
    END;
END $$;

-- TEST 8: Course with NULL prerequisite_course_id array - Should SUCCEED
DO $$
BEGIN
    RAISE NOTICE '=== TEST 8: Course with NULL prerequisite_course_id array - Should SUCCEED ===';
    
    BEGIN
        -- Student 1 enrolls in Course 904 (which has NULL prerequisites)
        INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score)
        VALUES (914, 901, 904, CURRENT_DATE, NULL);
        
        RAISE NOTICE '=== TEST 8 PASSED ===';
        
        -- Clean up
        DELETE FROM student_sections WHERE student_section_id = 914;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '=== TEST 8 FAILED ===';
        RAISE;
    END;
END $$;