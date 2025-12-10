"""
Database models
"""

import uuid
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text, UniqueConstraint, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class Student(Base):
    """
    Student model
    """
    __tablename__ = "students"
    
    student_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    student_code = Column(String(50), unique=True, index=True, nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    phone = Column(String(20), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationship
    registrations = relationship("Registration", back_populates="student", cascade="all, delete-orphan")


class Course(Base):
    """
    Course model
    """
    __tablename__ = "courses"
    
    course_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    course_code = Column(String(20), unique=True, index=True, nullable=False)
    course_name = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    credits = Column(Integer, nullable=False, default=3)
    max_capacity = Column(Integer, nullable=False, default=50)
    instructor = Column(String(200), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationship
    registrations = relationship("Registration", back_populates="course", cascade="all, delete-orphan")
    
    # Check constraint to ensure max_capacity is positive
    __table_args__ = (
        CheckConstraint('max_capacity > 0', name='check_max_capacity_positive'),
    )


class Registration(Base):
    """
    Registration model - links students to courses
    """
    __tablename__ = "registrations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    student_code = Column(String(50), ForeignKey("students.student_code"), nullable=False)
    course_code = Column(String(20), ForeignKey("courses.course_code"), nullable=False)
    registration_date = Column(DateTime(timezone=True), server_default=func.now())
    status = Column(String(20), default="active")  # active, dropped, completed
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    student = relationship("Student", back_populates="registrations")
    course = relationship("Course", back_populates="registrations")
    
    # Unique constraint: a student can only register for a course once
    __table_args__ = (
        UniqueConstraint('student_code', 'course_code', name='unique_student_course'),
    )
