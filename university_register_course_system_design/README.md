# University Course Registration System API

A RESTful API built with FastAPI that allows students to register for courses at a university.

## Technology Stack

- **FastAPI**: Modern, fast web framework for building APIs
- **SQLAlchemy**: SQL toolkit and ORM
- **PostgreSQL**: Robust relational database
- **Pydantic**: Data validation using Python type annotations

## Installation

1. Create a virtual environment (recommended):
```
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```
pip install -r requirements.txt
```

## Running the Application

1. Build and start the container:
```
docker-compose up --build
```

2. To run in detached mode:
```
docker-compose up -d
```

3. To stop the container:
```
docker-compose down
```

4. To view logs:
```
docker-compose logs -f
```

## API Endpoints

### Students

- `POST /students/` - Create a new student
- `GET /students/` - Get all students (with pagination)
- `GET /students/{student_id}` - Get a specific student
- `GET /students/{student_id}/registrations` - Get all courses a student is registered for

### Courses

- `POST /courses/` - Create a new course
- `GET /courses/` - Get all courses (with pagination)
- `GET /courses/{course_id}` - Get a specific course
- `GET /courses/{course_id}/students` - Get all students registered for a course

### Registrations

- `POST /registrations/` - Register a student for a course
- `GET /registrations/` - Get all registrations (with pagination)
- `DELETE /registrations/{registration_id}` - Drop a course registration

## Example Usage

### 1. Create a Student

```
curl -X POST "http://localhost:8000/students/" \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "STU001",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@university.edu",
    "phone": "123-456-7890"
  }'
```

### 2. Create a Course

```
curl -X POST "http://localhost:8000/courses/" \
  -H "Content-Type: application/json" \
  -d '{
    "course_code": "CS101",
    "course_name": "Introduction to Computer Science",
    "description": "Fundamentals of programming and computer science",
    "credits": 3,
    "max_capacity": 50,
    "instructor": "Dr. Jane Smith"
  }'
```

**Note**: `max_capacity` defaults to 50 if not specified.

### 3. Register a Student for a Course

**Note**: Use the UUID returned when creating the student and course.

```
curl -X POST "http://localhost:8000/registrations/" \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "550e8400-e29b-41d4-a716-446655440000",
    "course_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  }'
```

### 4. Get Student's Registered Courses

```
curl "http://localhost:8000/students/550e8400-e29b-41d4-a716-446655440000/registrations"
```

### 5. Drop a Course

```
curl -X DELETE "http://localhost:8000/registrations/6ba7b811-9dad-11d1-80b4-00c04fd430c8"
```

**Note**: All IDs are UUIDs (Universally Unique Identifiers), not integers. Use the UUIDs returned from the create endpoints.

## Sample Data

Scripts are provided to insert sample data into the database for testing purposes. You can use either:
```
k6 run k6_insert_data.js
```

## Load Testing

A K6 load testing script is provided to test concurrent registration scenarios. This is particularly useful for verifying that the transaction handling correctly prevents exceeding course capacity.

```bash
# Install K6 (if not already installed)
# See k6_README.md for installation instructions

# Run the load test (200 students trying to register for CS101 with capacity 50)
k6 run k6_load_test.js
```