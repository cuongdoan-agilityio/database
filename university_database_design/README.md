# Database Design Practice - University Database Diagram

## Requenments
Design a database to manage teaching information at university: Faculties, professors, students, majors, subjects, semesters, credits.
Designed for learning and practicing database design, business rules, and SQL querying.

## Directory Structure

```
├───Diagram
│   │   database.d2
│   └───udb.png
├───Scripts
│   └───generate_fake_data.py
└───sqls
    │   create_tables.sql
    │   examples_query_data.sql
    │   mock_data.sql
    └───views.sql
```

## How to run database
- Clone code from [source](https://github.com/cuongdoan-agilityio/database)
- Checkout to branch [feat/practice](https://github.com/cuongdoan-agilityio/database/tree/feat/practice)
- cd to `university_database_design` folder
- Create python env: `python -m venv venv`
- Activate env `source venv/Scripts/activate`
- Install package: `pip install -r requirements.txt`
- Start PostgreSQL: `docker compose up -d`

## Database

### The university database diagram includes the following entities:
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

### ERD
- [link](https://github.com/cuongdoan-agilityio/database/blob/feat/practice/university_database_design/diagram/udb.png)

### Business Rules
- Student score range between 0.00 and 4.00
- Course gpa requirement score range between 0.00 and 4.00
- The student's major code must match the major code of the registered course.
- The GPA score of the courses studied must be greater than or equal to the GPA required of the course.
- tudents must complete the prerequisite courses required for the course.
- The course_type field in the courses table must be one of the specified values: General, Fundamental, Specialized
- The status field in the timetable table must be one of the specified values: Scheduled, Cancelled, Complete
- A student cannot enroll in multiple class sections of the same course unit within the same semester.
- The number of students enrolled in a class section must not exceed its maximum capacity.

### Exmaple queries
- Please check files of `sqls` folder