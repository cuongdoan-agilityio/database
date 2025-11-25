-- Example Query: Retrieve all professors in the 'Mathematics Department'
SELECT 
    p.professor_sin, 
    p.first_name, 
    p.last_name, 
    p.professor_email
FROM university.professors p
JOIN university.departments d ON p.department_id = d.department_id
WHERE 
    d.title = 'Mathematics Department';

-- Count the number of courses offered in each semester
SELECT
    s.semester_id,
    s.name AS semester_name,
    COUNT(sect.section_id) AS total_class_sections,
    COUNT(DISTINCT sect.major_course_id) AS total_unique_courses,
    COUNT(DISTINCT cm.course_id) AS total_course
FROM university.semesters s
LEFT JOIN university.sections sect ON s.semester_id = sect.semester_id
LEFT JOIN university.major_courses cm ON sect.major_course_id = cm.major_course_id
GROUP BY s.semester_id, s.name
ORDER BY s.semester_id;

-- Find all students who are enrolled in more than 2 courses
SELECT
    s.student_id,
    s.student_code,
    s.first_name || ' ' || s.last_name AS student_name,
    COUNT(sect.major_course_id) AS total_courses_enrolled
FROM university.students s
JOIN university.student_sections ss ON s.student_id = ss.student_id
JOIN university.sections sect ON ss.section_id = sect.section_id
GROUP BY s.student_id, s.student_code, s.first_name, s.last_name
HAVING COUNT(sect.major_course_id) > 2
ORDER BY total_courses_enrolled DESC, s.last_name ASC;

-- List all active timetable entries with professor name, course name, semester, and room
SELECT
    p.first_name || ' ' || p.last_name AS professor_full_name,
    c.title AS course_name,
    s.name AS semester_name,
    t.room,
    t.schedule_time
FROM university.timetables t
JOIN university.sections sect ON t.section_id = sect.section_id
JOIN university.professors p ON sect.professor_sin = p.professor_sin
JOIN university.major_courses cm ON sect.major_course_id = cm.major_course_id
JOIN university.courses c ON cm.course_id = c.course_id
JOIN university.semesters s ON sect.semester_id = s.semester_id
WHERE t.status = 'Scheduled'
ORDER BY s.semester_id DESC, p.last_name, c.title;

-- Rank courses by their total enrollments and show the ranking
SELECT
    DENSE_RANK() OVER (ORDER BY COUNT(ss.student_section_id) DESC) AS enrollment_rank,
    c.course_code,
    c.title AS course_title,
    COUNT(ss.student_section_id) AS total_enrollments
FROM university.courses c
JOIN university.major_courses cm ON c.course_id = cm.course_id
JOIN university.sections sect ON cm.major_course_id = sect.major_course_id
LEFT JOIN university.student_sections ss ON sect.section_id = ss.section_id
GROUP BY c.course_id, c.course_code, c.title
ORDER BY enrollment_rank ASC, total_enrollments DESC;

-- Calculate the enrollment percentage for each class (enrolled students / max capacity * 100)
SELECT
    s.name AS semester_name,
    c.title AS course_title,

    sect.max_capacity,
    COALESCE(COUNT(ss.student_section_id), 0) AS enrolled_students,
    ROUND(
        (COALESCE(COUNT(ss.student_section_id), 0) * 100.0 / NULLIF(sect.max_capacity, 0))::NUMERIC,
        2
    ) AS enrollment_percentage_numeric,

    CASE
        WHEN sect.max_capacity IS NULL OR sect.max_capacity = 0 THEN 'N/A'
        ELSE
            ROUND((COALESCE(COUNT(ss.student_section_id), 0) * 100.0 / sect.max_capacity)::NUMERIC, 2) || '%'
    END AS enrollment_percentage
FROM
    university.sections sect
JOIN
    university.major_courses cm ON sect.major_course_id = cm.major_course_id
JOIN
    university.courses c ON cm.course_id = c.course_id
JOIN university.semesters s ON sect.semester_id = s.semester_id
LEFT JOIN university.student_sections ss ON sect.section_id = ss.section_id
GROUP BY s.name, c.title, sect.max_capacity
ORDER BY enrollment_percentage_numeric DESC;

-- Retrieve all professors hired in the last 10 years
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
    p.created_at >= (CURRENT_DATE - INTERVAL '10 years')
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
FROM university.students s
LEFT JOIN university.student_sections ss ON s.student_id = ss.student_id
LEFT JOIN university.majors m ON s.major_id = m.major_id
WHERE ss.student_section_id IS NULL
ORDER BY s.enrollment_date ASC;

-- Retrieve total students taught by each professor using the view
SELECT
    professor_full_name,
    total_students_taught,
    professor_sin
FROM university.total_students_per_professor
ORDER BY total_students_taught DESC;

-- Get the top 5 professors with the highest number of students taught
SELECT professor_full_name, total_students_taught
FROM university.total_students_per_professor
ORDER BY total_students_taught DESC
LIMIT 5;

-- Get the top 10 student enrollments from the student_enrollment_summary view
SELECT student_full_name, total_enrollments
FROM university.student_enrollment_summary
ORDER BY total_enrollments DESC
LIMIT 10;

-- Retrieve professor count per department using the view
SELECT * FROM university.professor_count_per_department
ORDER BY total_professors DESC;

-- Query: Get all sections that a student can enroll in for a given semester
-- This query checks:
-- 1. Major eligibility (student's major must match section's major)
-- 2. Prerequisites (student must have completed all prerequisites with score >= 1.0)
-- 3. Capacity (section must have available spots)
-- 4. Duplicate enrollment (student cannot enroll in same course in same semester)
-- Usage: Replace :student_id and :semester_id with actual values

SET search_path TO university, public;

WITH student_info AS (
    SELECT 
        s.student_id,
        s.major_id,
        s.first_name,
        s.last_name,
        s.student_code
    FROM university.students s
    WHERE s.student_id = :student_id  -- Replace with actual student_id
),
student_completed_courses AS (
    -- Get all courses the student has completed with score >= 1.0 (passing grade)
    SELECT DISTINCT cm.course_id
    FROM university.student_sections ss
    JOIN university.sections sect ON ss.section_id = sect.section_id
    JOIN university.major_courses cm ON sect.major_course_id = cm.major_course_id
    WHERE ss.student_id = :student_id  -- Replace with actual student_id
      AND ss.score IS NOT NULL
      AND ss.score >= 1.0  -- Minimum passing grade
),
student_current_enrollments AS (
    -- Get courses the student is already enrolled in for this semester
    SELECT DISTINCT sect.major_course_id
    FROM university.student_sections ss
    JOIN university.sections sect ON ss.section_id = sect.section_id
    WHERE ss.student_id = :student_id  -- Replace with actual student_id
      AND sect.semester_id = :semester_id  -- Replace with actual semester_id
),
section_enrollment_counts AS (
    -- Count current enrollments for each section
    SELECT 
        section_id,
        COUNT(*) AS current_enrollment
    FROM university.student_sections
    GROUP BY section_id
),
sections_with_prerequisites_met AS (
    -- Check if student has met prerequisites for each section
    SELECT 
        sect.section_id,
        c.course_id,
        CASE 
            WHEN c.prerequisite_course_id IS NULL OR array_length(c.prerequisite_course_id, 1) IS NULL THEN TRUE
            ELSE (
                -- Check if ALL prerequisites are in the student's completed courses list
                SELECT bool_and(prereq_id IN (SELECT course_id FROM student_completed_courses))
                FROM unnest(c.prerequisite_course_id) AS prereq_id
            )
        END AS prerequisites_met
    FROM university.sections sect
    JOIN university.major_courses cm ON sect.major_course_id = cm.major_course_id
    JOIN university.courses c ON cm.course_id = c.course_id
)

SELECT 
    si.student_code,
    si.first_name || ' ' || si.last_name AS student_name,
    s.section_id,
    c.course_id,
    c.course_code,
    c.title AS course_title,
    c.course_type,
    c.description AS course_description,
    p.professor_sin,
    p.first_name || ' ' || p.last_name AS professor_name,
    p.professor_email,
    sem.semester_id,
    sem.name AS semester_name,
    sem.start_date AS semester_start_date,
    sem.end_date AS semester_end_date,
    s.max_capacity,
    COALESCE(sec.current_enrollment, 0) AS current_enrollment,
    (s.max_capacity - COALESCE(sec.current_enrollment, 0)) AS available_spots,
    CASE 
        WHEN COALESCE(sec.current_enrollment, 0) >= s.max_capacity THEN 'Full'
        ELSE 'Available'
    END AS enrollment_status
FROM university.sections s
JOIN university.major_courses cm ON s.major_course_id = cm.major_course_id
JOIN university.courses c ON cm.course_id = c.course_id
JOIN university.professors p ON s.professor_sin = p.professor_sin
JOIN university.semesters sem ON s.semester_id = sem.semester_id
CROSS JOIN student_info si
LEFT JOIN section_enrollment_counts sec ON s.section_id = sec.section_id
LEFT JOIN student_current_enrollments sce ON s.major_course_id = sce.major_course_id
LEFT JOIN sections_with_prerequisites_met swp ON s.section_id = swp.section_id

WHERE s.semester_id = :semester_id  -- Replace with actual semester_id
    -- Check major eligibility: student's major must match section's major
    AND si.major_id = cm.major_id
    -- Check capacity: section must have available spots
    AND COALESCE(sec.current_enrollment, 0) < s.max_capacity
    -- Check prerequisites: student must have completed all prerequisites with score >= 1.0
    AND (swp.prerequisites_met = TRUE OR swp.prerequisites_met IS NULL)
    -- Check duplicate enrollment: student cannot enroll in same course in same semester
    AND sce.major_course_id IS NULL

ORDER BY c.course_code, c.title, s.section_id;
