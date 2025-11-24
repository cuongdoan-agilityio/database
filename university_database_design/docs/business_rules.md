## 1. Department & Major Rules
### BR1 — Every major belongs to a department
* Type: Relationship Rule
* Applied By: Database Design (`FOREIGN KEY department_id`)
* Details: A major must reference an existing department. If the department is deleted, the major’s `department_id` becomes NULL.

### BR2 — Every student must belong to a major
* Type: Relationship Rule
* Applied By: Database Design (`FOREIGN KEY major_id`)
* Details: When a major is deleted, the student’s major becomes NULL.

### BR3 — Every professor must belong to a department
* Type: Relationship Rule
* Applied By: Database Design (`FOREIGN KEY department_id`)
* Details: Department deletion sets `department_id` of professors to NULL.

## 2. Course Rules
### BR4 — Course type must be one of 3 allowed values
* Type: Domain Rule
* Applied By: Trigger (`validate_course_type`)
* Details: Only allowed values: `General`, `Fundamental`, `Specialized`.

### BR5 — Courses may have prerequisite courses
* Type: Relationship Rule
* Applied By: Database Design + Application Logic
* Details: Prerequisites stored in separate table and array.

### BR6 — A course cannot be its own prerequisite
* Type: Constraint Rule
* Applied By: Database Design (`CHECK course_id <> prerequisite_course_id`)

## 3. Curriculum (major_courses)
### BR7 — Courses may be assigned to majors
* Type: Relationship Rule
* Applied By: Database Design (`FOREIGN KEY`)

### BR8 — Deleting a major or course removes curriculum links
* Type: Integrity Rule
* Applied By: Database Design (`ON DELETE CASCADE`)

## 4. Sections & Semesters
### BR9 — A class section must belong to a major_course and semester
* Type: Relationship Rule
* Applied By: Database Design

### BR10 — A section must be taught by a professor
* Type: Relationship Rule
* Applied By: Database Design

### BR11 — A section has a maximum student capacity
* Type: Constraint Rule
* Applied By: Trigger (`check_max_capacity`)

### BR12 — Timetable entries must fall within the semester date range
* Type: Validation Rule
* Applied By: Trigger (`check_schedule_time_in_semester_range`)

## 5. Timetable Rules
### BR13 — Timetable status must be one of 3 valid values
* Type: Domain Rule
* Applied By: Trigger (`validate_timetable_status`)
* Details: Only allowed values: `Scheduled`, `Cancelled`, `Complete`.

### BR14 — Timetable belongs to a section
* Type: Relationship Rule
* Applied By: Database Design

## 6. Student Enrollment Rules (student_sections)
### BR15 — Student score must be between 0.00 and 4.00
* Type: Validation Rule
* Applied By: Trigger (`check_score_range`)

### BR16 — Student can only enroll in courses in their major
* Type: Relationship + Validation Rule
* Applied By: Trigger (`check_major_eligibility`)

### BR17 — Student must satisfy all prerequisite courses
* Type: Business Process Rule
* Applied By: Trigger (`check_course_prerequisites`)

### BR18 — Student cannot enroll in same course twice in the same semester
* Type: Validation Rule
* Applied By: Trigger (`check_duplicate_course_unit_in_semester`)

### BR19 — Enrollment must not exceed section capacity
* Type: Constraint Rule
* Applied By: Trigger (`check_max_capacity`)

## 7. Data Format Rules
### BR20 — Professor SIN must contain digits only
* Type: Format Rule
* Applied By: Trigger (`check_professor_sin_format`)

### BR21 — Student emails must follow valid format
* Type: Data Format Rule
* Applied By: Trigger (`check_student_email_format`)

### BR22 — Professor emails must follow valid format
* Type: Data Format Rule
* Applied By: Trigger (`check_professor_email_format`)

## 8. Integrity Rules
### BR23 — Deleting a student deletes all their enrollments
* Type: Integrity Rule
* Applied By: Database Design (`ON DELETE CASCADE`)

### BR24 — Deleting a section deletes related timetables and enrollments
* Type: Integrity Rule
* Applied By: Database Design (`ON DELETE CASCADE`)

### BR25 — Deleting a course or major removes related sections (via major_courses)
* Type: Integrity Rule
* Applied By: Database Design
