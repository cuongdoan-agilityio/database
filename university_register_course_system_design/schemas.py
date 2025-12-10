"""
Pydantic schemas for request/response validation
"""

import uuid
from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional


# Student schemas
class StudentBase(BaseModel):
    student_code: str
    first_name: str
    last_name: str
    email: EmailStr
    phone: Optional[str] = None


class StudentCreate(StudentBase):
    pass


class StudentResponse(StudentBase):
    student_id: uuid.UUID
    created_at: datetime
    
    class Config:
        from_attributes = True


# Course schemas
class CourseBase(BaseModel):
    course_code: str
    course_name: str
    description: Optional[str] = None
    credits: int = 3
    max_capacity: int = 50
    instructor: Optional[str] = None


class CourseCreate(CourseBase):
    pass


class CourseResponse(CourseBase):
    course_id: uuid.UUID
    created_at: datetime
    
    class Config:
        from_attributes = True


# Registration schemas
class RegistrationBase(BaseModel):
    student_code: str
    course_code: str
    status: str = "active"


class RegistrationCreate(RegistrationBase):
    pass


class RegistrationResponse(RegistrationBase):
    id: uuid.UUID
    registration_date: datetime
    student: Optional[StudentResponse] = None
    course: Optional[CourseResponse] = None
    
    class Config:
        from_attributes = True
