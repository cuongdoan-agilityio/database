# Database Design Practice - University Database Diagram

## Requenments
Design a database to manage teaching information at university: Faculties, professors, students, majors, subjects, semesters, credits.
Designed for learning and practicing database design, business rules, and SQL querying.

## Directory Structure

## Database Overview

The university database diagram includes the following entities:
- **Departments**: Academic departments in the school/university (e.g. Computer Science, Mathematics).
- **Majors**: Fields of study that students choose (e.g. Software Engineering, Biology), usually linked to a Department.
- **Students**: Individual students, with personal information, their major(s).
- **Courses**: Course definitions.
- **Prerequisites**: Rules that define which courses must be completed before taking another course (a relationship between courses).
- **CourseUnits**: CourseUnits: Sub‑units or modules of a course, or credit units associated with a course.
- **Professors**: Professors: Teaching staff (professors, lecturers), linked to Departments, who teach course sections.
- **ClasssSectionSemesters**: A specific section of a course in a particular semester. A professor is responsible for teaching.
- **Semesters**: Academic terms, used to schedule sections.
- **TimeTables**: Schedule data – when (day/time) and where (room) each class section meets.
- **StudentEnrollments**: Records of which students are enrolled in which class‑sections
