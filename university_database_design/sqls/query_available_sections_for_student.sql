-- ============================================================================
-- Query: Get all sections that a student can enroll in for a given semester
-- ============================================================================
SET search_path TO university, public;

WITH student_info AS (
    SELECT 
        s.student_id,
        s.major_id,
        s.first_name,
        s.last_name,
        s.student_code
    FROM university.students s
    WHERE s.student_id = 30
),
student_completed_courses AS (
    SELECT DISTINCT cm.course_id
    FROM university.student_sections ss
    JOIN university.sections sect ON ss.section_id = sect.section_id
    JOIN university.major_courses cm ON sect.major_course_id = cm.major_course_id
    WHERE ss.student_id = 30
      AND ss.score IS NOT NULL
      AND ss.score >= 1.0
),
student_current_enrollments AS (
    SELECT DISTINCT sect.major_course_id
    FROM university.student_sections ss
    JOIN university.sections sect ON ss.section_id = sect.section_id
    WHERE ss.student_id = 30
      AND sect.semester_id = 2
),
section_enrollment_counts AS (
    SELECT 
        section_id,
        COUNT(*) AS current_enrollment
    FROM university.student_sections
    GROUP BY section_id
)
SELECT 
    si.student_code,
    si.first_name || ' ' || si.last_name AS student_name,
    s.section_id,
    c.course_id,
    c.course_code,
    c.title AS course_title,
    c.course_type,
    p.first_name || ' ' || p.last_name AS professor_name,
    sem.name AS semester_name,
    s.max_capacity,
    m.title as major_title,
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
join university.majors m on cm.major_id  = m.major_id
CROSS JOIN student_info si
LEFT JOIN section_enrollment_counts sec ON s.section_id = sec.section_id
LEFT JOIN student_current_enrollments sce ON s.major_course_id = sce.major_course_id
WHERE s.semester_id = 2
    AND si.major_id = cm.major_id
    AND COALESCE(sec.current_enrollment, 0) < s.max_capacity
    AND (
        c.prerequisite_course_id IS NULL 
        OR array_length(c.prerequisite_course_id, 1) IS NULL
        OR NOT EXISTS (
            SELECT 1
            FROM unnest(c.prerequisite_course_id) AS prereq_id
            WHERE prereq_id NOT IN (SELECT course_id FROM student_completed_courses)
        )
    )
    AND sce.major_course_id IS NULL
ORDER BY c.course_code, c.title, s.section_id;
