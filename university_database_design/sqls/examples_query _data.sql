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
    COUNT(sect.section_id) AS total_class_sections,
    COUNT(DISTINCT sect.course_major_id) AS total_unique_courses_offered,
    COUNT(DISTINCT cm.course_id) AS total_course
FROM university.semesters s
LEFT JOIN university.sections sect ON s.semester_id = sect.semester_id
LEFT JOIN university.course_majors cm ON sect.course_major_id = cm.course_major_id
GROUP BY s.semester_id, s.name
ORDER BY s.semester_id;

-- Find all students who are enrolled in more than 2 courses
SELECT
    s.student_id,
    s.student_code,
    s.first_name,
    s.last_name,
    COUNT(sect.course_major_id) AS total_courses_enrolled
FROM university.students s
JOIN university.student_sections ss ON s.student_id = ss.student_id
JOIN university.sections sect ON ss.section_id = sect.section_id
GROUP BY s.student_id, s.student_code, s.first_name, s.last_name
HAVING COUNT(sect.course_major_id) > 2
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
JOIN university.course_majors cm ON sect.course_major_id = cm.course_major_id
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
JOIN university.course_majors cm ON c.course_id = cm.course_id
JOIN university.sections sect ON cm.course_major_id = sect.course_major_id
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
    university.course_majors cm ON sect.course_major_id = cm.course_major_id
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

-- Get all available sections for a student to enroll in a given semester
SET search_path TO university, public;

WITH student_info AS (
    SELECT 
        s.student_id,
        s.major_id,
        COALESCE(AVG(ss.score), 0.0) AS cumulative_gpa
    FROM students s
    LEFT JOIN student_sections ss ON s.student_id = ss.student_id
        AND ss.score IS NOT NULL
    WHERE s.student_id = 42 -- :student_id
    GROUP BY s.student_id, s.major_id
),
student_completed_courses AS (
    SELECT DISTINCT cm.course_id
    FROM student_sections ss
    JOIN sections sect ON ss.section_id = sect.section_id
    JOIN course_majors cm ON sect.course_major_id = cm.course_major_id
    WHERE ss.student_id = 42 -- :student_id
      AND ss.score IS NOT NULL
),
student_current_enrollments AS (
    SELECT DISTINCT sect.course_major_id
    FROM student_sections ss
    JOIN sections sect ON ss.section_id = sect.section_id
    WHERE ss.student_id = 42 -- :student_id
      AND sect.semester_id = 2 -- :semester_id
),
section_enrollment_counts AS (
    SELECT 
        section_id,
        COUNT(*) AS current_enrollment
    FROM student_sections
    GROUP BY section_id
)

SELECT DISTINCT
    s.section_id,
    c.course_id,
    c.title AS course_title,
    p.first_name || ' ' || p.last_name AS professor_name,
    sem.name AS semester_name
    -- cm.gpa_requirement
FROM sections s
JOIN course_majors cm ON s.course_major_id = cm.course_major_id
JOIN courses c ON cm.course_id = c.course_id
join professors p ON s.professor_sin = p.professor_sin
JOIN semesters sem ON s.semester_id = sem.semester_id
CROSS JOIN student_info si
LEFT JOIN section_enrollment_counts sec ON s.section_id = sec.section_id

LEFT JOIN student_current_enrollments sect_enrolled
    ON s.course_major_id = sect_enrolled.course_major_id

WHERE s.semester_id = 2 -- :semester_id
    AND si.major_id = cm.major_id
    AND COALESCE(sec.current_enrollment, 0) < s.max_capacity
    AND (cm.gpa_requirement IS NULL OR si.cumulative_gpa >= cm.gpa_requirement)
    AND NOT EXISTS (
        SELECT 1 
        FROM prerequisites pr
        WHERE pr.course_id = c.course_id
          AND pr.prerequisite_course_id NOT IN (
              SELECT course_id FROM student_completed_courses
          )
    )
    AND sect_enrolled.course_major_id IS NULL
ORDER BY c.course_id, s.section_id;