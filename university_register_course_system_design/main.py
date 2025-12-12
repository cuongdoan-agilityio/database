"""
University Course Registration System API
Main application entry point
"""

import uuid
import os
from pathlib import Path
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, OperationalError
from typing import List
import json

from database import SessionLocal, engine, Base
from models import Student, Course, Registration
from schemas import (
    StudentCreate, StudentResponse,
    CourseCreate, CourseResponse,
    RegistrationCreate, RegistrationResponse
)

# Create database tables
Base.metadata.create_all(bind=engine)

def load_sql_file(file_path: str) -> str:
    """
    Load SQL file content
    """

    sql_dir = Path(__file__).parent / "sql"
    full_path = sql_dir / file_path
    if not full_path.exists():
        raise FileNotFoundError(f"SQL file not found: {full_path}")
    return full_path.read_text(encoding='utf-8')


def create_sql_functions():
    """
    Create SQL functions for course registration
    """

    try:
        with engine.begin() as conn:
            # Create function WITH transaction and locking
            sql_with_transaction = load_sql_file("register_course_with_transaction.sql")
            conn.execute(text(sql_with_transaction))
            
            # Create function WITHOUT transaction
            sql_without_transaction = load_sql_file("register_course_without_transaction.sql")
            conn.execute(text(sql_without_transaction))
    except Exception as e:
        print(f"Warning: Could not create SQL functions (may already exist or database not ready): {e}")

# Create SQL functions on startup
create_sql_functions()

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
    students = db.query(Student).order_by(Student.student_code).offset(skip).limit(limit).all()
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

@app.post("/registrations/", response_model=RegistrationResponse, status_code=201)
def register_course(registration: RegistrationCreate, db: Session = Depends(get_db)):
    """
    Register a student for a course WITH transaction handling.
    Uses PostgreSQL function with row-level locking (SELECT FOR UPDATE) to prevent race conditions.
    This endpoint properly enforces capacity limits even under high concurrent load.
    """

    try:
        with engine.connect() as conn:
            trans = conn.begin()
            
            try:
                # Call the SQL function that handles transaction and locking
                result = conn.execute(
                    text("""
                        SELECT * FROM register_student_for_course(
                            :student_code,
                            :course_code
                        )
                    """),
                    {
                        "student_code": registration.student_code,
                        "course_code": registration.course_code
                    }
                ).mappings().fetchone()
                
                if not result:
                    trans.rollback()
                    raise HTTPException(status_code=500, detail="Registration function returned no result")
                
                # Commit the transaction
                trans.commit()
                
                # Parse JSONB fields from the result
                student_data = result['student']
                course_data = result['course']
                
                # Convert JSONB to dict (it may already be a dict or need parsing)
                if isinstance(student_data, str):
                    student_data = json.loads(student_data)
                if isinstance(course_data, str):
                    course_data = json.loads(course_data)
                
                # Build response
                return {
                    "id": result['registration_id'],
                    "student_code": registration.student_code,
                    "course_code": registration.course_code,
                    "status": registration.status,
                    "registration_date": result['registration_date'],
                    "student": {
                        "student_id": uuid.UUID(str(student_data['student_id'])),
                        "student_code": student_data['student_code'],
                        "first_name": student_data['first_name'],
                        "last_name": student_data['last_name'],
                        "email": student_data['email'],
                        "phone": student_data.get('phone'),
                        "created_at": student_data['created_at']
                    },
                    "course": {
                        "course_id": uuid.UUID(str(course_data['course_id'])),
                        "course_code": course_data['course_code'],
                        "course_name": course_data['course_name'],
                        "description": course_data.get('description'),
                        "credits": course_data['credits'],
                        "max_capacity": course_data['max_capacity'],
                        "instructor": course_data.get('instructor'),
                        "created_at": course_data['created_at']
                    }
                }
                
            except HTTPException:
                trans.rollback()
                raise
            except Exception as e:
                trans.rollback()
                # Check if it's a PostgreSQL exception with error code P0001
                error_str = str(e)
                if "P0001" in error_str or "Student not found" in error_str or "Course not found" in error_str:
                    raise HTTPException(status_code=404, detail=error_str)
                elif "already registered" in error_str.lower() or "maximum capacity" in error_str.lower():
                    raise HTTPException(status_code=400, detail=error_str)
                else:
                    raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {error_str}")
                
    except HTTPException:
        raise
    except IntegrityError as e:
        error_msg = str(e.orig)
        if "unique_student_course" in error_msg.lower():
            raise HTTPException(
                status_code=400,
                detail="Student is already registered for this course"
            )
        elif "maximum capacity" in error_msg.lower():
            raise HTTPException(
                status_code=400,
                detail=f"Course has reached maximum capacity. {error_msg}"
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Database constraint violation: {error_msg}"
            )
    except OperationalError as e:
        raise HTTPException(
            status_code=503,
            detail="Database operation failed. Please try again."
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"An unexpected error occurred: {str(e)}"
        )

@app.post("/registrations_without_transaction/", response_model=RegistrationResponse, status_code=201)
def register_course_without_transaction(registration: RegistrationCreate, db: Session = Depends(get_db)):
    """
    Register a student for a course WITHOUT transaction handling.
    This endpoint demonstrates the race condition problem - capacity may be exceeded
    under high concurrent load because there's no locking or transaction isolation.
    Uses PostgreSQL function without locking to demonstrate race conditions.
    """
    try:
        with engine.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
            # Call the SQL function that does NOT use transactions or locking
            result = conn.execute(
                text("""
                    SELECT * FROM register_student_for_course_without_transaction(
                        :student_code,
                        :course_code
                    )
                """),
                {
                    "student_code": registration.student_code,
                    "course_code": registration.course_code
                }
            ).mappings().fetchone()
            
            if not result:
                raise HTTPException(status_code=500, detail="Registration function returned no result")
            
            # Parse JSONB fields from the result
            student_data = result['student']
            course_data = result['course']
            
            # Convert JSONB to dict (it may already be a dict or need parsing)
            if isinstance(student_data, str):
                student_data = json.loads(student_data)
            if isinstance(course_data, str):
                course_data = json.loads(course_data)
            
            # Build response
            return {
                "id": result['registration_id'],
                "student_code": registration.student_code,
                "course_code": registration.course_code,
                "status": registration.status,
                "registration_date": result['registration_date'],
                "student": {
                    "student_id": uuid.UUID(str(student_data['student_id'])),
                    "student_code": student_data['student_code'],
                    "first_name": student_data['first_name'],
                    "last_name": student_data['last_name'],
                    "email": student_data['email'],
                    "phone": student_data.get('phone'),
                    "created_at": student_data['created_at']
                },
                "course": {
                    "course_id": uuid.UUID(str(course_data['course_id'])),
                    "course_code": course_data['course_code'],
                    "course_name": course_data['course_name'],
                    "description": course_data.get('description'),
                    "credits": course_data['credits'],
                    "max_capacity": course_data['max_capacity'],
                    "instructor": course_data.get('instructor'),
                    "created_at": course_data['created_at']
                }
            }
        
    except HTTPException:
        raise
    except Exception as e:
        # Check if it's a PostgreSQL exception with error code P0001
        error_str = str(e)
        if "P0001" in error_str or "Student not found" in error_str or "Course not found" in error_str:
            raise HTTPException(status_code=404, detail=error_str)
        elif "already registered" in error_str.lower() or "maximum capacity" in error_str.lower():
            raise HTTPException(status_code=400, detail=error_str)
        else:
            raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {error_str}")
    except IntegrityError as e:
        error_msg = str(e.orig)
        if "unique_student_course" in error_msg.lower():
            raise HTTPException(
                status_code=400,
                detail="Student is already registered for this course"
            )
        elif "maximum capacity" in error_msg.lower():
            raise HTTPException(
                status_code=400,
                detail=f"Course has reached maximum capacity. {error_msg}"
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Database constraint violation: {error_msg}"
            )
    except OperationalError as e:
        raise HTTPException(
            status_code=503,
            detail="Database operation failed. Please try again."
        )


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
