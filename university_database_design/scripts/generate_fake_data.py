from faker import Faker
import random
import datetime

fake = Faker("en_US")

# File output
file_path = "sqls/mock_data.sql"

# Config records of each table
NUM_MAJORS = 7
NUM_STUDENTS = 250
NUM_PROFESSORS = 20
NUM_COURSES = 25
NUM_COURSE_MAJORS = 70
NUM_SEMESTERS = 5
NUM_CLASS_SECTIONS = 200
NUM_TIMETABLES = 100
NUM_ENROLLMENTS = 2000
NUM_PREREQUISITES = 30

department_names = [
    "Mathematics",
    "Computer Science",
    "Literature",
    "Geography",
    "Physics",
    "History",
    "Biology",
]


# Helper function wrap SQL value
def sql_str(val):
    if val is None:
        return "NULL"
    if isinstance(val, bool):
        return "TRUE" if val else "FALSE"
    if isinstance(val, (int, float)):
        if isinstance(val, float):
            return "{:.2f}".format(val)
        return str(val)
    return "'{}'".format(str(val).replace("'", "''"))


def filter_class_sections_by_major(
    student_major_id, class_section_list, course_unit_lookup
):
    specific_eligible_sections = []

    for cs in class_section_list:
        course_major_id = cs["course_major_id"]
        lookup_data = course_unit_lookup.get(course_major_id)
        if not lookup_data:
            continue

        course_major_id = lookup_data.get("major_id")
        if course_major_id == student_major_id:
            specific_eligible_sections.append(cs)

    return specific_eligible_sections


def generate_data():

    try:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write("SET search_path TO university, public;\n\n")
            f.write("TRUNCATE TABLE student_sections RESTART IDENTITY CASCADE;\n")
            f.write("TRUNCATE TABLE timetables RESTART IDENTITY CASCADE;\n")
            f.write(
                "TRUNCATE TABLE sections RESTART IDENTITY CASCADE;\n"
            )
            f.write("TRUNCATE TABLE prerequisites CASCADE;\n")
            f.write("TRUNCATE TABLE course_majors CASCADE;\n")
            f.write("TRUNCATE TABLE students RESTART IDENTITY CASCADE;\n")
            f.write("TRUNCATE TABLE professors CASCADE;\n")
            f.write("TRUNCATE TABLE semesters CASCADE;\n")
            f.write("TRUNCATE TABLE courses CASCADE;\n")
            f.write("TRUNCATE TABLE majors CASCADE;\n")
            f.write("TRUNCATE TABLE departments CASCADE;\n\n")

            departments = []
            majors = []
            students = []
            professors = []
            courses = []
            course_majors = []
            semesters = []
            class_sections = []
            timetables = []
            enrollments = []
            prerequisites = set()

            # Generate data for Departments table
            f.write("-- 1. Departments\n")
            for i in range(1, len(department_names) + 1):
                department = {
                    "department_id": i,
                    "title": department_names[i - 1] + " Department",
                    "description": fake.sentence(),
                }
                departments.append(department)
                f.write(
                    f"INSERT INTO departments(department_id, title, description) VALUES ({sql_str(department['department_id'])}, {sql_str(department['title'])}, {sql_str(department['description'])});\n"
                )

            # Generate data for Majors table
            f.write("\n-- Majors\n")
            for i in range(1, NUM_MAJORS + 1):
                major = {
                    "major_id": i,
                    "department_id": random.choice(departments)["department_id"],
                    "major_code": f"M{i:03d}",
                    "title": fake.word().title() + " Major",
                    "description": fake.sentence(),
                }
                majors.append(major)
                f.write(
                    f"INSERT INTO majors(major_id, department_id, major_code, title, description) VALUES ({sql_str(major['major_id'])}, {sql_str(major['department_id'])}, {sql_str(major['major_code'])}, {sql_str(major['title'])}, {sql_str(major['description'])});\n"
                )

            # Generate data for Students table
            f.write("\n-- Students\n")
            used_emails_students = set()
            for i in range(1, NUM_STUDENTS + 1):
                while True:
                    first = fake.first_name()
                    last = fake.last_name()
                    email = f"{first.lower()}.{last.lower()}.{random.randint(10, 99)}@university.edu"
                    if email not in used_emails_students:
                        used_emails_students.add(email)
                        break

                student = {
                    "student_id": i,
                    "student_code": f"S{i:05d}",
                    "student_email": email,
                    "first_name": first,
                    "last_name": last,
                    "birthday": fake.date_of_birth(minimum_age=18, maximum_age=50),
                    "major_id": random.choice(majors)["major_id"],
                    "enrollment_date": fake.date_between(
                        start_date="-4y", end_date="today"
                    ),
                }
                students.append(student)
                f.write(
                    f"INSERT INTO students(student_id, student_code, student_email, first_name, last_name, birthday, major_id, enrollment_date) VALUES ({sql_str(student['student_id'])}, {sql_str(student['student_code'])}, {sql_str(student['student_email'])}, {sql_str(student['first_name'])}, {sql_str(student['last_name'])}, {sql_str(student['birthday'])}, {sql_str(student['major_id'])}, {sql_str(student['enrollment_date'])});\n"
                )

            # Get 40 student to generate enrollments
            list_of_students = students[:40]
            list_of_student_major_ids = [
                student["major_id"] for student in list_of_students
            ]
            unique_student_major_ids_set = set(list_of_student_major_ids)
            majors = [
                major
                for major in majors
                if major["major_id"] in unique_student_major_ids_set
            ]

            # Generate data for Professors table
            f.write("\n-- Professors\n")
            used_emails_professors = set()
            used_sins = set()
            for i in range(1, NUM_PROFESSORS + 1):
                while True:
                    sin = f"P{i:05d}"
                    if sin not in used_sins:
                        used_sins.add(sin)
                        break

                while True:
                    first = fake.first_name()
                    last = fake.last_name()
                    email = f"prof.{first.lower()}.{last.lower()}.{random.randint(10, 99)}@university.edu"
                    if email not in used_emails_professors:
                        used_emails_professors.add(email)
                        break

                professor = {
                    "professor_sin": sin,
                    "department_id": random.choice(departments)["department_id"],
                    "professor_email": email,
                    "first_name": first,
                    "last_name": last,
                    "birthday": fake.date_of_birth(minimum_age=30, maximum_age=65),
                }
                professors.append(professor)
                f.write(
                    f"INSERT INTO professors(professor_sin, department_id, professor_email, first_name, last_name, birthday) VALUES ({sql_str(professor['professor_sin'])}, {sql_str(professor['department_id'])}, {sql_str(professor['professor_email'])}, {sql_str(professor['first_name'])}, {sql_str(professor['last_name'])}, {sql_str(professor['birthday'])});\n"
                )

            # Generate data for Courses table
            f.write("\n-- Courses\n")
            used_course_codes = set()
            for i in range(1, NUM_COURSES + 1):
                while True:
                    code = f"{random.choice(['CS','MA','BI','HI', 'PH', 'GE', 'LI'])}{random.randint(100, 499)}"
                    if code not in used_course_codes:
                        used_course_codes.add(code)
                        break
                course = {
                    "course_id": i,
                    "course_code": code,
                    "title": fake.sentence(nb_words=3).replace(".", ""),
                    "course_type": random.choice(
                        ["General", "Fundamental", "Specialized"]
                    ),
                    "description": fake.sentence(),
                }
                courses.append(course)
                f.write(
                    f"INSERT INTO courses(course_id, course_code, title, course_type, description) VALUES ({sql_str(course['course_id'])}, {sql_str(course['course_code'])}, {sql_str(course['title'])}, {sql_str(course['course_type'])}, {sql_str(course['description'])});\n"
                )

            # Generate data for Course Units table
            f.write("\n-- Course Units\n")
            used_cu_combinations = set()
            cu_id = 1
            while cu_id <= NUM_COURSE_MAJORS:
                course = random.choice(courses)
                course_id = course["course_id"]
                major_id = random.choice(majors)["major_id"]

                if (course_id, major_id) not in used_cu_combinations:
                    used_cu_combinations.add((course_id, major_id))

                    # GPA requirement
                    required = random.choice([True, False])
                    gpa_req = round(random.uniform(2.5, 4.0), 2)

                    cu = {
                        "course_major_id": cu_id,
                        "course_id": course_id,
                        "major_id": major_id,
                        "credit": random.choice([2, 3, 4]),
                        "required": (
                            required if course["course_type"] != "General" else True
                        ),
                        "gpa_requirement": (
                            gpa_req if course["course_type"] != "General" else None
                        ),
                    }
                    course_majors.append(cu)
                    f.write(
                        f"INSERT INTO course_majors(course_major_id, course_id, major_id, credit, required, gpa_requirement) VALUES ({sql_str(cu['course_major_id'])}, {sql_str(cu['course_id'])}, {sql_str(cu['major_id'])}, {sql_str(cu['credit'])}, {sql_str(cu['required'])}, {sql_str(cu['gpa_requirement'])});\n"
                    )
                    cu_id += 1

            # Generate data for Semesters table
            f.write("\n-- Semesters\n")
            start_date_ref = fake.date_object() - datetime.timedelta(days=365 * 4)
            for i in range(1, NUM_SEMESTERS + 1):
                start = start_date_ref + datetime.timedelta(days=(i - 1) * 150)
                end = start + datetime.timedelta(days=120)
                sem = {
                    "semester_id": i,
                    "name": f"Semester {i} - {start.year}",
                    "start_date": start,
                    "end_date": end,
                }
                semesters.append(sem)
                f.write(
                    f"INSERT INTO semesters(semester_id, name, start_date, end_date) VALUES ({sql_str(sem['semester_id'])}, {sql_str(sem['name'])}, {sql_str(sem['start_date'])}, {sql_str(sem['end_date'])});\n"
                )

            # Generate data for Class Section Semesters table
            f.write("\n-- Class Section Semesters\n")
            class_section_id = 1
            while class_section_id <= NUM_CLASS_SECTIONS:
                if not course_majors or not semesters or not professors:
                    break

                no_gpa_course_majors = [
                    cu for cu in course_majors if not cu["gpa_requirement"]
                ]

                cs = {
                    "section_id": class_section_id,
                    "course_major_id": random.choice(no_gpa_course_majors)[
                        "course_major_id"
                    ],
                    "semester_id": random.choice(semesters)["semester_id"],
                    "professor_sin": random.choice(professors)["professor_sin"],
                    "max_capacity": random.randint(20, 60),
                }
                class_sections.append(cs)
                f.write(
                    f"INSERT INTO sections(section_id, course_major_id, semester_id, professor_sin, max_capacity) VALUES ({sql_str(cs['section_id'])}, {sql_str(cs['course_major_id'])}, {sql_str(cs['semester_id'])}, {sql_str(cs['professor_sin'])}, {sql_str(cs['max_capacity'])});\n"
                )
                class_section_id += 1

            # Generate data for Timetables table
            f.write("\n-- Timetables\n")
            timetable_id = 1
            selected_class_sections = random.sample(
                class_sections, min(NUM_TIMETABLES, len(class_sections))
            )

            for cs in selected_class_sections:
                for j in range(random.randint(1, 2)):
                    if timetable_id > NUM_TIMETABLES:
                        break

                    timetable = {
                        "timetables_id": timetable_id,
                        "section_id": cs["section_id"],
                        "room": f"Room {random.randint(101, 505)}",
                        "status": random.choice(["Scheduled", "Cancelled", "Complete"]),
                        "schedule_time": f"{random.randint(8, 17)}:00",
                    }
                    timetables.append(timetable)
                    f.write(
                        f"INSERT INTO timetables(timetables_id, section_id, room, status, schedule_time) VALUES ({sql_str(timetable['timetables_id'])}, {sql_str(timetable['section_id'])}, {sql_str(timetable['room'])}, {sql_str(timetable['status'])}, {sql_str(timetable['schedule_time'])});\n"
                    )
                    timetable_id += 1

            # Generate data for Prerequisites table
            f.write("\n-- Prerequisites\n")
            prereq_count = 0
            
            while prereq_count < NUM_PREREQUISITES:
                course = random.choice(courses)
                course_id = random.choice(courses)["course_id"]
                prereq_id = random.choice(courses)["course_id"]

                if course["course_type"] != "General" and course_id != prereq_id:
                    pair = (course_id, prereq_id)
                    if pair not in prerequisites:
                        prerequisites.add(pair)
                        f.write(
                            f"INSERT INTO prerequisites(prerequisite_id, course_id, prerequisite_course_id) VALUES ({sql_str(prereq_count + 1)}, {sql_str(course_id)}, {sql_str(prereq_id)});\n"
                        )
                        prereq_count += 1

            # Generate data for Student Enrollments table
            cu_gpa_lookup = {
                cu["course_major_id"]: {
                    "gpa_requirement": cu["gpa_requirement"],
                    "major_id": cu["major_id"],
                }
                for cu in course_majors
            }

            eligible_class_sections = [
                cs
                for cs in class_sections
                if cu_gpa_lookup.get(cs["course_major_id"]).get("gpa_requirement")
                is None
            ]

            f.write("\n-- Student Enrollments\n")
            used_enrollments = set()
            enrollment_id = 0

            while enrollment_id <= NUM_ENROLLMENTS:
                enrollment_id += 1
                selected_student = random.choice(list_of_students)
                student_id = selected_student["student_id"]

                valid_eligible_class_section = filter_class_sections_by_major(
                    selected_student["major_id"],
                    eligible_class_sections,
                    cu_gpa_lookup,
                )

                if not valid_eligible_class_section:
                    break
                section_id = random.choice(valid_eligible_class_section)[
                    "section_id"
                ]

                if (student_id, section_id) not in used_enrollments:
                    used_enrollments.add((student_id, section_id))

                    enrollment = {
                        "student_section_id": enrollment_id,
                        "student_id": student_id,
                        "section_id": section_id,
                        "enrollment_date": fake.date_between(
                            start_date="-3y", end_date="today"
                        ),
                        "score": (
                            round(random.uniform(0, 4), 2)
                            if random.random() < 0.7
                            else None
                        ),
                    }
                    enrollments.append(enrollment)
                    f.write(
                        f"INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score) VALUES ({sql_str(enrollment['student_section_id'])}, {sql_str(enrollment['student_id'])}, {sql_str(enrollment['section_id'])}, {sql_str(enrollment['enrollment_date'])}, {sql_str(enrollment['score'])});\n"
                    )
                    enrollment_id += 1

        print("Data generation completed successfully.")
    except Exception:
        print("\nError occurred during data generation.")


if __name__ == "__main__":
    generate_data()
