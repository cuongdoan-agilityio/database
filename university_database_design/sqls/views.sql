-- View: total_students_per_professor
CREATE OR REPLACE VIEW university.total_students_per_professor AS
SELECT
    p.first_name || ' ' || p.last_name AS professor_full_name,
    p.professor_sin,
    COUNT(se.student_enrollment_id) AS total_students_taught
FROM university.professors p
LEFT JOIN university.class_section_semesters css ON p.professor_sin = css.professor_sin
LEFT JOIN university.student_enrollments se ON css.class_section_semester_id = se.class_section_semester_id
GROUP BY p.professor_sin, p.first_name, p.last_name;

-- View: course_popularity
CREATE OR REPLACE VIEW university.course_popularity AS
SELECT
    c.course_id,
    c.course_code,
    c.title AS course_title,
    COUNT(se.student_enrollment_id) AS total_enrollments
FROM university.courses c
JOIN university.course_units cu ON c.course_id = cu.course_id
JOIN university.class_section_semesters css ON cu.course_unit_id = css.course_unit_id
LEFT JOIN university.student_enrollments se ON css.class_section_semester_id = se.class_section_semester_id
GROUP BY c.course_id, c.course_code, c.title;

-- View: student_enrollment_summary
CREATE OR REPLACE VIEW university.student_enrollment_summary AS
SELECT
    s.student_id,
    s.student_code,
    s.first_name || ' ' || s.last_name AS student_full_name,
    COUNT(se.student_enrollment_id) AS total_enrollments,
    MAX(se.enrollment_date) AS last_enrollment_date
FROM
    university.students s
LEFT JOIN
    university.student_enrollments se ON s.student_id = se.student_id
GROUP BY
    s.student_id, s.student_code, s.first_name, s.last_name
ORDER BY
    total_enrollments DESC, student_full_name ASC;

-- View: professor_count_per_department
CREATE OR REPLACE VIEW university.professor_count_per_department AS
SELECT
    d.department_id,
    d.title AS department_name,
    COUNT(p.professor_sin) AS total_professors
FROM
    university.departments d
LEFT JOIN
    university.professors p ON d.department_id = p.department_id
GROUP BY
    d.department_id, d.title
ORDER BY
    total_professors DESC, d.title ASC;