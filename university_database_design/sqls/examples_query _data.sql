-- Example Query: Retrieve all professors in the 'Mathematics Department'
SELECT 
    university.professors.professor_sin, 
    university.professors.first_name, 
    university.professors.last_name, 
    university.professors.professor_email
FROM university.professors
JOIN university.departments ON university.professors.department_id = university.departments.department_id
WHERE 
    university.departments.title = 'Mathematics Department';

-- Count the number of courses offered in each semester
SELECT
    s.semester_id,
    s.name AS semester_name,
    COUNT(css.class_section_semester_id) AS total_class_sections,
    COUNT(DISTINCT css.course_unit_id) AS total_unique_courses_offered
    COUNT(DISTINCT cu.course_id) AS total_course
FROM university.semesters s
LEFT JOIN university.class_section_semesters css ON s.semester_id = css.semester_id
LEFT JOIN university.course_units cu ON css.course_unit_id = cu.course_unit_id
GROUP BY s.semester_id, s.name
ORDER BY s.semester_id;

-- Find all students who are enrolled in more than 2 courses
SELECT
    s.student_id,
    s.student_code,
    s.first_name,
    s.last_name,
    COUNT(css.course_unit_id) AS total_courses_enrolled
FROM university.students s
JOIN university.student_enrollments se ON s.student_id = se.student_id
JOIN university.class_section_semesters css ON se.class_section_semester_id = css.class_section_semester_id
GROUP BY s.student_id, s.student_code, s.first_name, s.last_name
-- HAVING COUNT(cs.student_enrollment_id) > 2
HAVING COUNT(css.course_unit_id) > 2
ORDER BY total_courses_enrolled DESC, s.last_name ASC;

-- List all active timetable entries with professor name, course name, semester, and room
SELECT
    p.first_name || ' ' || p.last_name AS professor_full_name,
    c.title AS course_name,
    s.name AS semester_name,
    t.room,
    t.schedule_time
FROM university.timetables t
JOIN university.class_section_semesters css ON t.class_section_semester_id = css.class_section_semester_id
JOIN university.professors p ON css.professor_sin = p.professor_sin
JOIN university.course_units cu ON css.course_unit_id = cu.course_unit_id
JOIN university.courses c ON cu.course_id = c.course_id
JOIN university.semesters s ON css.semester_id = s.semester_id
WHERE t.status = 'Scheduled'
ORDER BY s.semester_id DESC, p.last_name, c.title;

-- Rank courses by their total enrollments and show the ranking
SELECT
    DENSE_RANK() OVER (ORDER BY COUNT(se.student_enrollment_id) DESC) AS enrollment_rank,
    c.course_code,
    c.title AS course_title,
    COUNT(se.student_enrollment_id) AS total_enrollments
FROM university.courses c
JOIN university.course_units cu ON c.course_id = cu.course_id
JOIN university.class_section_semesters css ON cu.course_unit_id = css.course_unit_id
LEFT JOIN university.student_enrollments se ON css.class_section_semester_id = se.class_section_semester_id
GROUP BY c.course_id, c.course_code, c.title
ORDER BY enrollment_rank ASC, total_enrollments DESC;

-- Calculate the enrollment percentage for each class (enrolled students / max capacity * 100)
SELECT
    s.name AS semester_name,
    c.title AS course_title,

    css.max_capacity,
    COALESCE(COUNT(se.student_enrollment_id), 0) AS enrolled_students,

    ROUND(
        (COALESCE(COUNT(se.student_enrollment_id), 0) * 100.0 / NULLIF(css.max_capacity, 0))::NUMERIC,
        2
    ) AS enrollment_percentage_numeric,

    CASE
        WHEN css.max_capacity IS NULL OR css.max_capacity = 0 THEN 'N/A'
        ELSE
            ROUND((COALESCE(COUNT(se.student_enrollment_id), 0) * 100.0 / css.max_capacity)::NUMERIC, 2) || '%'
    END AS enrollment_percentage
FROM
    university.class_section_semesters css
JOIN
    university.course_units cu ON css.course_unit_id = cu.course_unit_id
JOIN
    university.courses c ON cu.course_id = c.course_id
JOIN university.semesters s ON css.semester_id = s.semester_id
LEFT JOIN university.student_enrollments se ON css.class_section_semester_id = se.class_section_semester_id
GROUP BY s.name, c.title, css.max_capacity
ORDER BY enrollment_percentage_numeric DESC;

SELECT
    p.first_name,
    p.last_name,
    p.professor_sin,
    p.professor_email,
    p.department_id,
    p.created_at::DATE AS hire_date
FROM
    university.professors p
WHERE
    p.created_at >= (CURRENT_DATE - INTERVAL '0 years')
ORDER BY
    p.created_at DESC;

-- Retrieve all students who have NOT enrolled in any courses
SELECT
    s.student_id,
    s.student_code,
    s.first_name,
    s.last_name,
    m.title AS major_title,
    s.enrollment_date
FROM
    university.students s
LEFT JOIN
    university.student_enrollments se ON s.student_id = se.student_id
LEFT JOIN
    university.majors m ON s.major_id = m.major_id
WHERE
    se.student_enrollment_id IS NULL
ORDER BY
    s.enrollment_date ASC;

-- Retrieve total students taught by each professor using the view
SELECT
    professor_full_name,
    total_students_taught,
    professor_sin
FROM
    university.total_students_per_professor
ORDER BY
    total_students_taught DESC;

-- Get the top 5 professors with the highest number of students taught
SELECT
    professor_full_name,
    total_students_taught
FROM
    university.total_students_per_professor
ORDER BY
    total_students_taught DESC
LIMIT 5;

-- Get the top 10 student enrollments from the student_enrollment_summary view
SELECT 
    student_full_name, 
    total_enrollments
FROM 
    university.student_enrollment_summary
ORDER BY 
    total_enrollments DESC
LIMIT 10;

-- Retrieve professor count per department using the view
SELECT * FROM university.professor_count_per_department
ORDER BY total_professors DESC;