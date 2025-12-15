"""
University Course Registration System API
Main application entry point
"""

import uuid
from fastapi import FastAPI, HTTPException
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import text, select, func
from sqlalchemy.exc import IntegrityError
from typing import List

from database import SessionLocal, engine
from models import Student, Course, Registration
from schemas import (
    StudentCreate, StudentResponse,
    CourseCreate, CourseResponse,
    RegistrationCreate, RegistrationResponse
)

from schemas import (
    RegistrationCreate,
    RegistrationResponse,
    StudentCreate,
    StudentResponse,
    CourseCreate,
    CourseResponse,
)

from models import Course, Student, Base, Registration

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="University Course Registration System",
    description="API for students to register for courses",
    version="1.0.0"
)


# Student endpoints
@app.post(
    "/students/",
    response_model=StudentResponse,
    status_code=201
)
def create_student(student: StudentCreate):
    """
    Create a new student
    """

    session: Session = SessionLocal()
    try:
        session.begin()
        db_student = Student(**student.dict())
        session.add(db_student)

        session.commit()
        session.refresh(db_student)
        return db_student

    except HTTPException:
        session.rollback()
        raise
    finally:
        session.close()


@app.get(
    "/students/",
    response_model=List[StudentResponse]
)
def get_students(skip: int = 0, limit: int = 100):
    """
    Get all students
    """

    session: Session = SessionLocal()
    try:
        stmt = select(Student).offset(skip).limit(limit)

        students = session.scalars(stmt).all()
        return students

    finally:
        session.close()


@app.get(
    "/students/{student_id}",
    response_model=StudentResponse
)
def get_student(student_id: uuid.UUID):
    """
    Get a specific student by ID
    """

    session: Session = SessionLocal()
    try:
        stmt = select(Student).where(Student.student_id == student_id)
        student = session.scalar(stmt)
        if not student:
            raise HTTPException(status_code=404, detail="Student not found")
        return student

    finally:
        session.close()


# Course endpoints
@app.post(
    "/courses/",
    response_model=CourseResponse,
    status_code=201
)
def create_course(course: CourseCreate):
    """
    Create a new course
    """

    session: Session = SessionLocal()
    try:
        session.begin()
        db_course = Course(**course.dict())
        session.add(db_course)

        session.commit()
        session.refresh(db_course)
        return db_course

    except HTTPException:
        session.rollback()
        raise
    finally:
        session.close()


@app.get(
    "/courses/",
    response_model=List[CourseResponse]
)
def get_courses(skip: int = 0, limit: int = 100):
    """
    Get all courses
    """

    session: Session = SessionLocal()
    try:
        stmt = select(Course).offset(skip).limit(limit)

        courses = session.scalars(stmt).all()
        return courses

    finally:
        session.close()


@app.get(
    "/courses/{course_id}",
    response_model=CourseResponse
)
def get_course(course_id: uuid.UUID):
    """
    Get a specific course by ID
    """

    session: Session = SessionLocal()
    try:
        stmt = select(Course).where(Course.course_id == course_id)
        course = session.scalar(stmt)
        if not course:
            raise HTTPException(status_code=404, detail="Course not found")
        return course
    finally:
        session.close()


@app.get(
    "/courses/{course_id}/students",
    response_model=List[StudentResponse]
)
def get_course_students(course_id: uuid.UUID):
    """
    Get all students registered for a specific course
    """

    session: Session = SessionLocal()
    try:
        stmt = (
            select(Student)
            .join(Registration, Registration.student_code == Student.student_id)
            .where(Registration.course_id == course_id)
        )

        students = session.scalars(stmt).all()
        return students

    finally:
        session.close()


@app.post(
    "/registrations_with_transaction/",
    response_model=RegistrationResponse,
    status_code=201,
)
def register_course_with_transaction(registration: RegistrationCreate):
    """
    Register a student for a course with transaction & row-level locking.
    """

    session: Session = SessionLocal()
    try:
        session.begin()

        course = session.execute(
            select(Course)
            .where(Course.course_code == registration.course_code)
            .with_for_update()
        ).scalar_one_or_none()

        if not course:
            raise HTTPException(status_code=404, detail="Course not found")

        current = session.scalar(
            select(func.count())
            .select_from(Registration)
            .where(Registration.course_code == registration.course_code)
        )

        if current >= course.max_capacity:
            raise HTTPException(status_code=409, detail="Class full")

        db_registration = Registration(
            student_code=registration.student_code,
            course_code=registration.course_code,
            status="active",
        )
        session.add(db_registration)

        session.commit()

        stmt = (
            select(Registration)
            .options(
                selectinload(Registration.student),
                selectinload(Registration.course),
            )
            .where(Registration.id == db_registration.id)
        )

        db_registration = session.execute(stmt).scalar_one()

        return db_registration

    except IntegrityError:
        session.rollback()
        raise HTTPException(status_code=409, detail="Already registered")

    except HTTPException:
        session.rollback()
        raise

    finally:
        session.close()


@app.post(
    "/registrations_without_transaction/",
    response_model=RegistrationResponse,
    status_code=201,
)
def register_course_without_transaction(registration: RegistrationCreate):
    """
    Register a student for a course without transaction handling.
    """
    
    session: Session = SessionLocal()
    try:
        course = session.execute(
            select(Course).where(Course.course_code == registration.course_code)
        ).scalar_one_or_none()

        if not course:
            raise HTTPException(status_code=404, detail="Course not found")

        current = session.scalar(
            select(func.count())
            .select_from(Registration)
            .where(Registration.course_code == registration.course_code)
        )

        session.execute(text("SELECT pg_sleep(0.05)"))

        if current >= course.max_capacity:
            raise HTTPException(status_code=409, detail="Class full")

        db_registration = Registration(
            student_code=registration.student_code,
            course_code=registration.course_code,
            status="active",
        )
        session.add(db_registration)
        session.commit()

        stmt = (
            select(Registration)
            .options(
                selectinload(Registration.student),
                selectinload(Registration.course),
            )
            .where(Registration.id == db_registration.id)
        )

        db_registration = session.execute(stmt).scalar_one()

        return db_registration

    except IntegrityError:
        session.rollback()
        raise HTTPException(status_code=409, detail="Already registered")

    finally:
        session.close()


@app.get("/registrations/", response_model=List[RegistrationResponse])
def get_registrations(skip: int = 0, limit: int = 100):
    """
    Get all registrations.
    """

    session: Session = SessionLocal()
    try:
        stmt = (
            select(Registration)
            .options(
                selectinload(Registration.student),
                selectinload(Registration.course),
            )
            .offset(skip)
            .limit(limit)
        )

        registrations = session.scalars(stmt).all()
        return registrations

    finally:
        session.close()


@app.get("/")
def root():
    """
    Root endpoint
    """

    return {
        "message": "University Course Registration System API",
        "docs": "/docs",
        "version": "1.0.0"
    }
