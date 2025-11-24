from faker import Faker
import random
import datetime

fake = Faker("en_US")

# Output file
FILE_PATH = "sqls/mock_data.sql"

# Config records
NUM_MAJORS = 7
NUM_STUDENTS = 250
NUM_PROFESSORS = 20
NUM_COURSES = 25
NUM_MAJOR_COURSES = 70
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

course_maping = {
    "calculus_i": {
        "id": 1,
        "name": "Calculus I",
        "code": "calculus_i",
        "prerequisite_course_id": None,
        "course_type": "General",
        "required": True,
    },
    "calculus_ii": {
        "id": 9,
        "name": "Calculus II",
        "code": "calculus_ii",
        "course_type": "Fundamental",
        "required": True,
        "prerequisite_course_id": [1]
    },
    "linear_algebra": {
        "id": 10,
        "name": "Linear Algebra",
        "code": "linear_algebra",
        "course_type": "Fundamental",
        "required": True,
        "prerequisite_course_id": [1]
    },
    "probability_and_statistics": {
        "id": 21,
        "name": "Probability and Statistics",
        "code": "probability_and_statistics",
        "course_type": "Specialized",
        "required": True,
        "prerequisite_course_id": [10]
    },
    "classical_mechanics": {
        "id": 11,
        "name": "Classical Mechanics",
        "code": "classical_mechanics",
        "prerequisite_course_id": [1],
        "required": True,
        "course_type": "Fundamental",
    },
    "electromagnetism": {
        "id": 22,
        "name": "Electromagnetism",
        "code": "electromagnetism",
        "prerequisite_course_id": [11],
        "required": True,
        "course_type": "Specialized"
    },
    "introductory_quantum_physics": {
        "id": 30,
        "name": "Introductory Quantum Physics",
        "code": "introductory_quantum_physics",
        "course_type": "Specialized",
        "required": True,
        "prerequisite_course_id": [22]
    },
    "discrete_mathematics": {
        "id": 2,
        "name": "Discrete Mathematics",
        "code": "discrete_mathematics",
        "prerequisite_course_id": None,
        "required": True,
        "course_type": "General"
    },
    "data_structures_and_algorithms": {
        "id": 12,
        "name": "Data Structures and Algorithms",
        "code": "data_structures_and_algorithms",
        "course_type": "Fundamental",
        "required": True,
        "prerequisite_course_id": [2, 3]
    },
    "introduction_to_programming": {
        "id": 3,
        "name": "Introduction to Programming",
        "code": "introduction_to_programming",
        "prerequisite_course_id": None,
        "required": True,
        "course_type": "General"
    },
    "database_systems": {
        "id": 23,
        "name": "Database Systems",
        "code": "database_systems",
        "course_type": "Specialized",
        "required": True,
        "prerequisite_course_id": [13, 14]
    },
    "computer_architecture": {
        "id": 24,
        "name": "Computer Architecture",
        "code": "computer_architecture",
        "course_type": "Specialized",
        "required": True,
        "prerequisite_course_id": [13]
    },
    "operating_systems": {
        "id": 25,
        "name": "Operating Systems",
        "code": "operating_systems",
        "course_type": "Specialized",
        "required": True,
        "prerequisite_course_id": [13]
    },
    "object_oriented_programming": {
        "id": 14,
        "name": "Object-Oriented Programming",
        "code": "object_oriented_programming",
        "prerequisite_course_id": [3],
        "required": True,
        "course_type": "Fundamental"
    },
    "introduction_to_literary_theory": {
        "id": 4,
        "name": "Introduction to Literary Theory",
        "code": "introduction_to_literary_theory",
        "prerequisite_course_id": None,
        "required": True,
        "course_type": "General"
    },
    "modern_vietnamese_literature": {
        "id": 15,
        "name": "Modern Vietnamese Literature",
        "code": "modern_vietnamese_literature",
        "course_type": "Fundamental",
        "required": True,
        "prerequisite_course_id": [4]
    },
    "literary_language_analysis": {
        "id": 16,
        "name": "Literary Language Analysis",
        "code": "literary_language_analysis",
        "course_type": "Fundamental",
        "required": True,
        "prerequisite_course_id": [4]
    },
    "general_linguistics": {
        "id": 5,
        "name": "General Linguistics",
        "code": "general_linguistics",
        "prerequisite_course_id": None,
        "required": True,
        "course_type": "General"
    },
    "fundamentals_of_cartography": {
        "id": 6,
        "name": "Fundamentals of Cartography",
        "code": "fundamentals_of_cartography",
        "prerequisite_course_id": None,
        "required": True,
        "course_type": "General"
    },
    "physical_geography": {
        "id": 17,
        "name": "Physical Geography",
        "code": "physical_geography",
        "prerequisite_course_id": [6],
        "required": True,
        "course_type": "Fundamental"
    },
        "economic_and_social_geography": {
        "id": 27,
        "name": "Economic and Social Geography",
        "code": "economic_and_social_geography",
        "course_type": "Specialized",
        "required": True,
        "prerequisite_course_id": [17]
    },
    "introduction_to_historical_studies": {
        "id": 7,
        "name": "Introduction to Historical Studies",
        "code": "introduction_to_historical_studies",
        "prerequisite_course_id": None,
        "required": True,
        "course_type": "General"
    },
    "medieval_vietnamese_history": {
        "id": 18,
        "name": "Medieval Vietnamese History",
        "code": "medieval_vietnamese_history",
        "course_type": "Fundamental",
        "required": True,
        "prerequisite_course_id": [7]
    },
    "Modern World History": {
        "id": 19,
        "name": "Modern World History",
        "code": "modern_world_history",
        "prerequisite_course_id": [7],
        "required": True,
        "course_type": "Fundamental"
    },
    "historical_research_methods": {
        "id": 28,
        "name": "Historical Research Methods",
        "code": "historical_research_methods",
        "course_type": "Specialized",
        "required": True,
        "prerequisite_course_id": [19]
    },
    "general_chemistry": {
        "id": 8,
        "name": "General Chemistry",
        "code": "general_chemistry",
        "prerequisite_course_id": None,
        "required": True,
        "course_type": "General"
    },
    "cell_biology": {
        "id": 20,
        "name": "Cell Biology",
        "code": "cell_biology",
        "prerequisite_course_id": [8],
        "required": True,
        "course_type": "Fundamental"
    },
    "genetics": {
        "id": 29,
        "name": "Genetics",
        "code": "genetics",
        "course_type": "Specialized",
        "required": True,
        "prerequisite_course_id": [20]
    }
}

def sql_str(val):
    if val is None:
        return "NULL"
    if isinstance(val, bool):
        return "TRUE" if val else "FALSE"
    if isinstance(val, (int, float)):
        return f"{val:.2f}" if isinstance(val, float) else str(val)
    if isinstance(val, list):
        return f"ARRAY{val}" if isinstance(val, list) else "NULL"
    return "'{}'".format(str(val).replace("'", "''"))


def filter_class_sections_by_major(student_major_id, class_section_list, lookup):
    eligible = []
    for cs in class_section_list:
        entry = lookup.get(cs["major_course_id"])
        if entry and entry.get("major_id") == student_major_id:
            eligible.append(cs)
    return eligible


def write_header_truncate(f):
    f.write("SET search_path TO university, public;\n\n")
    f.write("TRUNCATE TABLE student_sections RESTART IDENTITY CASCADE;\n")
    f.write("TRUNCATE TABLE timetables RESTART IDENTITY CASCADE;\n")
    f.write("TRUNCATE TABLE sections RESTART IDENTITY CASCADE;\n")
    f.write("TRUNCATE TABLE major_courses CASCADE;\n")
    f.write("TRUNCATE TABLE students RESTART IDENTITY CASCADE;\n")
    f.write("TRUNCATE TABLE professors CASCADE;\n")
    f.write("TRUNCATE TABLE semesters CASCADE;\n")
    f.write("TRUNCATE TABLE courses CASCADE;\n")
    f.write("TRUNCATE TABLE majors CASCADE;\n")
    f.write("TRUNCATE TABLE departments CASCADE;\n\n")


def gen_departments(f):
    items = []
    f.write("-- Departments\n")
    for i, name in enumerate(department_names, start=1):
        row = {
            "department_id": i,
            "title": f"{name} Department",
            "description": fake.sentence(),
        }
        items.append(row)
        f.write(
            f"INSERT INTO departments(department_id, title, description) VALUES "
            f"({sql_str(row['department_id'])}, {sql_str(row['title'])}, {sql_str(row['description'])});\n"
        )
    return items


def gen_majors(f, departments):
    items = []
    f.write("\n-- Majors\n")
    for i in range(1, NUM_MAJORS + 1):
        d = random.choice(departments)["department_id"]
        row = {
            "major_id": i,
            "major_code": f"M{i:03d}",
            "department_id": d,
            "title": fake.word().title() + " Major",
            "description": fake.sentence(),
        }
        items.append(row)
        f.write(
            f"INSERT INTO majors(major_id, department_id, major_code, title, description) VALUES "
            f"({sql_str(row['major_id'])}, {sql_str(row['department_id'])}, {sql_str(row['major_code'])}, "
            f"{sql_str(row['title'])}, {sql_str(row['description'])});\n"
        )
    return items


def gen_students(f, majors):
    items = []
    used_emails = set()
    f.write("\n-- Students\n")

    for i in range(1, NUM_STUDENTS + 1):
        while True:
            first = fake.first_name()
            last = fake.last_name()
            email = (
                f"{first.lower()}.{last.lower()}.{random.randint(10,99)}@university.edu"
            )
            if email not in used_emails:
                used_emails.add(email)
                break

        row = {
            "student_id": i,
            "major_id": random.choice(majors)["major_id"],
            "student_code": f"S{i:05d}",
            "student_email": email,
            "first_name": first,
            "last_name": last,
            "birthday": fake.date_of_birth(minimum_age=18, maximum_age=50),
            "enrollment_date": fake.date_between(start_date="-4y", end_date="today"),
        }
        items.append(row)

        f.write(
            f"INSERT INTO students(student_id, student_code, student_email, first_name, last_name, birthday, major_id, enrollment_date) "
            f"VALUES ({sql_str(i)}, {sql_str(row['student_code'])}, {sql_str(email)}, {sql_str(first)}, {sql_str(last)}, "
            f"{sql_str(row['birthday'])}, {sql_str(row['major_id'])}, {sql_str(row['enrollment_date'])});\n"
        )
    return items


def gen_professors(f, departments):
    items = []
    used_emails = set()
    used_sins = set()

    f.write("\n-- Professors\n")

    for i in range(1, NUM_PROFESSORS + 1):
        sin_num = random.randint(0, 999_999_999)
        sin = f"{sin_num:09d}"
        used_sins.add(sin)

        while True:
            first = fake.first_name()
            last = fake.last_name()
            email = f"prof.{first.lower()}.{last.lower()}.{random.randint(10,99)}@university.edu"
            if email not in used_emails:
                used_emails.add(email)
                break

        row = {
            "professor_sin": sin,
            "department_id": random.choice(departments)["department_id"],
            "professor_email": email,
            "first_name": first,
            "last_name": last,
            "birthday": fake.date_of_birth(minimum_age=30, maximum_age=65),
        }
        items.append(row)

        f.write(
            f"INSERT INTO professors(professor_sin, department_id, professor_email, first_name, last_name, birthday)  "
            f"VALUES ({sql_str(sin)}, {sql_str(row['department_id'])}, {sql_str(email)}, {sql_str(first)}, {sql_str(last)}, {sql_str(row['birthday'])});\n"
        )
    return items


def extract_courses_from_mapping(course_mapping, courses_list):
    """
    Recursively extract all courses from the course_mapping structure.
    """
    for course_key, course_data in course_mapping.items():
        courses_list.append({
            "course_id": course_data["id"],
            "course_code": course_data["code"],
            "title": course_data["name"],
            "course_type": course_data.get("course_type", "Specialized"),
            "prerequisite_course_id": course_data.get("prerequisite_course_id", None),
            "description": f"{course_data['name']} {fake.sentence()}",
            "required": course_data["required"],
        })


def gen_courses(f):
    items = []
    f.write("\n-- Courses\n")
    extract_courses_from_mapping(course_maping, items)
    items.sort(key=lambda x: x["course_id"])
    for row in items:
        f.write(
            f"INSERT INTO courses(course_id, course_code, title, course_type, prerequisite_course_id, required, description) "
            f"VALUES ({sql_str(row['course_id'])}, {sql_str(row['course_code'])}, {sql_str(row['title'])}, {sql_str(row['course_type'])}, {sql_str(row['prerequisite_course_id'])}, {sql_str(row['required'])}, {sql_str(row['description'])});\n"
        )
    return items


def gen_major_courses(f, courses, majors):
    items = []
    used = set()
    mc_id = 1

    f.write("\n-- Course Majors\n")

    while mc_id <= NUM_MAJOR_COURSES:
        course = random.choice(courses)
        major = random.choice(majors)

        if (course["course_id"], major["major_id"]) in used:
            continue

        used.add((course["course_id"], major["major_id"]))

        required = random.choice([True, False])
        gpa_req = round(random.uniform(2.5, 4.0), 2)

        row = {
            "major_course_id": mc_id,
            "course_id": course["course_id"],
            "major_id": major["major_id"],
            # "credit": random.choice([2, 3, 4]),
            "required": required if course["course_type"] != "General" else True,
            "gpa_requirement": gpa_req if course["course_type"] != "General" else None,
        }
        items.append(row)

        f.write(
            f"INSERT INTO major_courses(major_course_id, course_id, major_id) VALUES "
            f"({sql_str(mc_id)}, {sql_str(row['course_id'])}, {sql_str(row['major_id'])});\n"
        )

        mc_id += 1

    return items


def gen_semesters(f):
    items = []
    f.write("\n-- Semesters\n")
    start_ref = fake.date_object() - datetime.timedelta(days=365 * 4)

    for i in range(1, NUM_SEMESTERS + 1):
        start = start_ref + datetime.timedelta(days=(i - 1) * 150)
        end = start + datetime.timedelta(days=120)

        row = {
            "semester_id": i,
            "name": f"Semester {i} - {start.year}",
            "start_date": start,
            "end_date": end,
        }
        items.append(row)

        f.write(
            f"INSERT INTO semesters(semester_id, name, start_date, end_date) VALUES "
            f"({sql_str(i)}, {sql_str(row['name'])}, {sql_str(start)}, {sql_str(end)});\n"
        )
    return items


def gen_sections(f, major_courses, semesters, professors):
    items = []
    f.write("\n-- Sections\n")
    section_id = 1

    no_gpa = [cu for cu in major_courses if not cu["gpa_requirement"]]

    while section_id <= NUM_CLASS_SECTIONS:
        row = {
            "section_id": section_id,
            "major_course_id": random.choice(no_gpa)["major_course_id"],
            "semester_id": random.choice(semesters)["semester_id"],
            "professor_sin": random.choice(professors)["professor_sin"],
            "max_capacity": random.randint(20, 60),
        }
        items.append(row)

        f.write(
            f"INSERT INTO sections(section_id, major_course_id, semester_id, professor_sin, max_capacity) VALUES "
            f"({sql_str(section_id)}, {sql_str(row['major_course_id'])}, {sql_str(row['semester_id'])}, "
            f"{sql_str(row['professor_sin'])}, {sql_str(row['max_capacity'])});\n"
        )
        section_id += 1

    return items


def gen_timetables(f, sections, semesters):
    items = []
    f.write("\n-- Timetables\n")

    # map semester_id → (start_date, end_date)
    sem_lookup = {s["semester_id"]: (s["start_date"], s["end_date"]) for s in semesters}

    selected = random.sample(sections, min(NUM_TIMETABLES, len(sections)))
    tid = 1

    for s in selected:
        sem_start, sem_end = sem_lookup[s["semester_id"]]

        for _ in range(random.randint(1, 2)):
            if tid > NUM_TIMETABLES:
                return items

            # random date during semester
            delta_days = (sem_end - sem_start).days
            random_day = sem_start + datetime.timedelta(
                days=random.randint(0, delta_days)
            )

            # random time between 8:00 and 17:00
            random_hour = random.randint(8, 17)
            random_minute = random.choice([0, 15, 30, 45])

            schedule_dt = datetime.datetime(
                random_day.year,
                random_day.month,
                random_day.day,
                random_hour,
                random_minute,
            )

            row = {
                "timetables_id": tid,
                "section_id": s["section_id"],
                "room": f"Room {random.randint(101, 505)}",
                "status": random.choice(["Scheduled", "Cancelled", "Complete"]),
                "schedule_time": schedule_dt,
            }
            items.append(row)

            f.write(
                f"INSERT INTO timetables(timetables_id, section_id, room, status, schedule_time) "
                f"VALUES ({sql_str(tid)}, {sql_str(row['section_id'])}, {sql_str(row['room'])}, "
                f"{sql_str(row['status'])}, {sql_str(row['schedule_time'])});\n"
            )
            tid += 1

    return items


def gen_enrollments(f, students, sections, major_courses):
    f.write("\n-- Student Enrollments\n")

    lookup = {
        cu["major_course_id"]: {
            "gpa_requirement": cu["gpa_requirement"],
            "major_id": cu["major_id"],
        }
        for cu in major_courses
    }

    eligible_sections = [
        cs
        for cs in sections
        if lookup[cs["major_course_id"]]["gpa_requirement"] is None
    ]

    used = set()
    enroll_id = 0

    selected_students = students[:40]

    while enroll_id <= NUM_ENROLLMENTS:
        enroll_id += 1

        stu = random.choice(selected_students)
        sid = stu["student_id"]

        filtered = filter_class_sections_by_major(
            stu["major_id"], eligible_sections, lookup
        )
        if not filtered:
            break

        sec_id = random.choice(filtered)["section_id"]

        if (sid, sec_id) not in used:
            used.add((sid, sec_id))
            score = round(random.uniform(0, 4), 2) if random.random() < 0.7 else 0.00

            f.write(
                f"INSERT INTO student_sections(student_section_id, student_id, section_id, enrollment_date, score) VALUES "
                f"({sql_str(enroll_id)}, {sql_str(sid)}, {sql_str(sec_id)}, {sql_str(fake.date_between(start_date='-3y', end_date='today'))}, "
                f"{sql_str(score)});\n"
            )
            enroll_id += 1


def generate_data():
    try:
        with open(FILE_PATH, "w", encoding="utf-8") as f:
            write_header_truncate(f)

            departments = gen_departments(f)
            majors = gen_majors(f, departments)
            students = gen_students(f, majors)
            professors = gen_professors(f, departments)
            courses = gen_courses(f)
            major_courses = gen_major_courses(f, courses, majors)
            semesters = gen_semesters(f)
            sections = gen_sections(f, major_courses, semesters, professors)
            gen_timetables(f, sections, semesters)
            gen_enrollments(f, students, sections, major_courses)

        print("Data generation completed successfully.")
    except Exception:
        print("Error occurred during data generation.")


if __name__ == "__main__":
    generate_data()
