"""
University Course Registration System API
Main application entry point
"""

import uuid
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List

from database import SessionLocal, engine, Base
from models import Student, Course, Registration
from schemas import (
    StudentCreate, StudentResponse,
    CourseCreate, CourseResponse,
    RegistrationCreate, RegistrationResponse
)

# Create database tables
Base.metadata.create_all(bind=engine)

# Create trigger function to enforce max_capacity when student registers for a course
def create_max_capacity_trigger():
    """Create a database trigger to enforce max_capacity constraint"""
    try:
        with engine.begin() as conn:
            # Create function to check capacity
            conn.execute(text("""
                CREATE OR REPLACE FUNCTION check_course_capacity()
                RETURNS TRIGGER AS $$
                DECLARE
                    current_count INTEGER;
                    max_cap INTEGER;
                BEGIN
                    -- Get current registration count for the course (only active registrations)
                    SELECT COUNT(*) INTO current_count
                    FROM registrations
                    WHERE course_code = NEW.course_code
                    AND status = 'active';
                    
                    -- Get max_capacity for the course
                    SELECT max_capacity INTO max_cap
                    FROM courses
                    WHERE course_code = NEW.course_code;
                    
                    -- Check if adding this registration would exceed capacity
                    IF current_count >= max_cap THEN
                        RAISE EXCEPTION 'Course has reached maximum capacity of % students', max_cap;
                    END IF;
                    
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;
            """))
            
            # Drop trigger if exists
            conn.execute(text("""
                DROP TRIGGER IF EXISTS trigger_check_course_capacity ON registrations;
            """))
            
            # Create trigger (only fires for active registrations)
            conn.execute(text("""
                CREATE TRIGGER trigger_check_course_capacity
                BEFORE INSERT ON registrations
                FOR EACH ROW
                WHEN (NEW.status = 'active')
                EXECUTE FUNCTION check_course_capacity();
            """))
            
        print("Database trigger for max_capacity created successfully")
    except Exception as e:
        print(f"Warning: Could not create trigger (may already exist or database not ready): {e}")

# Create the trigger on startup
create_max_capacity_trigger()

app = FastAPI(
    title="University Course Registration System",
    description="API for students to register for courses",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Dependency to get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Student endpoints
@app.post("/students/", response_model=StudentResponse, status_code=201)
def create_student(student: StudentCreate, db: Session = Depends(get_db)):
    """Create a new student"""
    db_student = Student(**student.dict())
    db.add(db_student)
    db.commit()
    db.refresh(db_student)
    return db_student


@app.get("/students/", response_model=List[StudentResponse])
def get_students(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all students"""
    students = db.query(Student).offset(skip).limit(limit).all()
    return students


@app.get("/students/{student_id}", response_model=StudentResponse)
def get_student(student_id: uuid.UUID, db: Session = Depends(get_db)):
    """Get a specific student by ID"""
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return student


# Course endpoints
@app.post("/courses/", response_model=CourseResponse, status_code=201)
def create_course(course: CourseCreate, db: Session = Depends(get_db)):
    """Create a new course"""
    db_course = Course(**course.dict())
    db.add(db_course)
    db.commit()
    db.refresh(db_course)
    return db_course


@app.get("/courses/", response_model=List[CourseResponse])
def get_courses(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all courses"""
    courses = db.query(Course).offset(skip).limit(limit).all()
    return courses


@app.get("/courses/{course_id}", response_model=CourseResponse)
def get_course(course_id: uuid.UUID, db: Session = Depends(get_db)):
    """Get a specific course by ID"""
    course = db.query(Course).filter(Course.course_id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course


@app.get("/courses/{course_id}/students", response_model=List[StudentResponse])
def get_course_students(course_id: uuid.UUID, db: Session = Depends(get_db)):
    """Get all students registered for a specific course"""
    course = db.query(Course).filter(Course.course_id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    registrations = db.query(Registration).filter(
        Registration.course_code == course.course_code,
        Registration.status == 'active'
    ).all()
    students = [db.query(Student).filter(Student.student_code == reg.student_code).first() for reg in registrations]
    return students


# Registration endpoints
@app.post("/registrations/", response_model=RegistrationResponse, status_code=201)
def register_course(registration: RegistrationCreate, db: Session = Depends(get_db)):
    """Register a student for a course"""
    # Check if student exists
    student = db.query(Student).filter(Student.student_code == registration.student_code).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Check if course exists
    course = db.query(Course).filter(Course.course_code == registration.course_code).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    # Check if already registered
    existing_registration = db.query(Registration).filter(
        Registration.student_code == registration.student_code,
        Registration.course_code == registration.course_code
    ).first()
    
    if existing_registration:
        raise HTTPException(status_code=400, detail="Student is already registered for this course")
    
    # Check if course has available spots (application-level check)
    # Note: Database trigger also enforces this at the database level
    current_registrations = db.query(Registration).filter(
        Registration.course_code == registration.course_code,
        Registration.status == 'active'
    ).count()
    
    if current_registrations >= course.max_capacity:
        raise HTTPException(
            status_code=400, 
            detail=f"Course has reached maximum capacity of {course.max_capacity} students"
        )
    
    # Create registration
    db_registration = Registration(**registration.dict())
    db.add(db_registration)
    db.commit()
    db.refresh(db_registration)
    
    # Load relationships for response
    db_registration.student = student
    db_registration.course = course
    
    return db_registration


@app.get("/registrations/", response_model=List[RegistrationResponse])
def get_registrations(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all registrations"""
    registrations = db.query(Registration).offset(skip).limit(limit).all()
    # Load relationships
    for reg in registrations:
        reg.student = db.query(Student).filter(Student.student_code == reg.student_code).first()
        reg.course = db.query(Course).filter(Course.course_code == reg.course_code).first()
    return registrations


@app.get("/students/{student_id}/registrations", response_model=List[RegistrationResponse])
def get_student_registrations(student_id: uuid.UUID, db: Session = Depends(get_db)):
    """Get all courses a student is registered for"""
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    registrations = db.query(Registration).filter(Registration.student_code == student.student_code).all()
    # Load relationships
    for reg in registrations:
        reg.student = student
        reg.course = db.query(Course).filter(Course.course_code == reg.course_code).first()
    return registrations


@app.delete("/registrations/{registration_id}", status_code=204)
def drop_course(registration_id: uuid.UUID, db: Session = Depends(get_db)):
    """Drop a course registration"""
    registration = db.query(Registration).filter(Registration.id == registration_id).first()
    if not registration:
        raise HTTPException(status_code=404, detail="Registration not found")
    
    db.delete(registration)
    db.commit()
    return None


@app.get("/")
def root():
    """Root endpoint"""
    return {
        "message": "University Course Registration System API",
        "docs": "/docs",
        "version": "1.0.0"
    }
