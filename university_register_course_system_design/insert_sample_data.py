"""
Script to insert sample data into the database
Inserts 200 students and 2 courses
"""

import sys
from faker import Faker
from sqlalchemy.exc import IntegrityError
from database import SessionLocal, engine
from models import Student, Course, Base

# Initialize Faker
fake = Faker()

# Create tables if they don't exist
Base.metadata.create_all(bind=engine)

def create_students(db, count=200):
    """Create sample students"""
    print(f"Creating {count} students...")
    students = []
    created = 0
    skipped = 0
    
    for i in range(1, count + 1):
        # Generate unique student code
        student_code = f"STU{i:06d}"
        
        # Check if student already exists
        existing = db.query(Student).filter(Student.student_code == student_code).first()
        if existing:
            students.append(existing)
            skipped += 1
            continue
        
        # Generate student data
        first_name = fake.first_name()
        last_name = fake.last_name()
        # Ensure unique email
        email = f"{first_name.lower()}.{last_name.lower()}{i}@{fake.domain_name()}"
        phone = fake.phone_number()[:20]  # Limit to 20 characters
        
        student = Student(
            student_code=student_code,
            first_name=first_name,
            last_name=last_name,
            email=email,
            phone=phone
        )
        
        try:
            db.add(student)
            db.commit()
            db.refresh(student)
            students.append(student)
            created += 1
            
            # Progress indicator
            if i % 50 == 0:
                print(f"  Progress: {i}/{count} students processed...")
        except IntegrityError:
            db.rollback()
            # If email conflict, try with different email
            email = f"{first_name.lower()}.{last_name.lower()}{i}{fake.random_int(1000, 9999)}@{fake.domain_name()}"
            student.email = email
            try:
                db.add(student)
                db.commit()
                db.refresh(student)
                students.append(student)
                created += 1
            except IntegrityError:
                db.rollback()
                skipped += 1
                continue
    
    print(f"✓ Successfully created {created} students ({skipped} skipped - already existed or conflicts)")
    return students


def create_courses(db):
    """Create 2 sample courses"""
    print("Creating 2 courses...")
    
    courses_data = [
        {
            "course_code": "CS101",
            "course_name": "Introduction to Computer Science",
            "description": "An introductory course covering fundamental concepts of computer science including programming basics, algorithms, and data structures.",
            "credits": 3,
            "max_capacity": 50,
            "instructor": "Dr. Sarah Johnson"
        },
        {
            "course_code": "MATH201",
            "course_name": "Calculus I",
            "description": "First course in calculus covering limits, derivatives, and applications of differentiation.",
            "credits": 4,
            "max_capacity": 50,
            "instructor": "Prof. Michael Chen"
        }
    ]
    
    courses = []
    for course_data in courses_data:
        # Check if course already exists
        existing = db.query(Course).filter(Course.course_code == course_data["course_code"]).first()
        if existing:
            print(f"  Course {course_data['course_code']} already exists, skipping...")
            courses.append(existing)
            continue
        
        course = Course(**course_data)
        courses.append(course)
        db.add(course)
    
    try:
        db.commit()
        print(f"✓ Successfully created {len([c for c in courses if c.id])} courses")
        return courses
    except IntegrityError as e:
        db.rollback()
        print(f"✗ Error creating courses: {e}")
        return []


def main():
    """Main function to insert sample data"""
    print("=" * 60)
    print("Sample Data Insertion Script")
    print("=" * 60)
    print()
    
    db = SessionLocal()
    
    try:
        # Create courses first
        courses = create_courses(db)
        print()
        
        # Create students
        students = create_students(db, count=200)
        print()
        
        # Summary
        print("=" * 60)
        print("Summary:")
        print(f"  - Courses created: {len(courses)}")
        print(f"  - Students created: {len(students)}")
        print("=" * 60)
        print()
        print("Sample data insertion completed successfully!")
        
        # Print some sample data
        if courses:
            print("\nSample Courses:")
            for course in courses:
                print(f"  - {course.course_code}: {course.course_name} (Capacity: {course.max_capacity})")
        
        if students:
            print(f"\nSample Students (first 5):")
            for student in students[:5]:
                print(f"  - {student.student_code}: {student.first_name} {student.last_name} ({student.email})")
        
    except Exception as e:
        print(f"✗ An error occurred: {e}")
        db.rollback()
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    main()

