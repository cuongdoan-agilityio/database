# University Course Registration System API

A RESTful API built with FastAPI that allows students to register for courses at a university.

## Features

- **Student Management**: Create and manage student records
- **Course Management**: Create and manage course offerings
- **Course Registration**: Students can register for courses with validation
- **Registration Management**: View registrations, drop courses, and check course capacity

## Technology Stack

- **FastAPI**: Modern, fast web framework for building APIs
- **SQLAlchemy**: SQL toolkit and ORM
- **PostgreSQL**: Robust relational database
- **Pydantic**: Data validation using Python type annotations

## Installation

1. Create a virtual environment (recommended):
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

## Running the Application

### Option 1: Using Docker (Recommended)

#### Using Docker Compose (Easiest)

1. Build and start the container:
```bash
docker-compose up --build
```

2. To run in detached mode:
```bash
docker-compose up -d
```

3. To stop the container:
```bash
docker-compose down
```

4. To view logs:
```bash
docker-compose logs -f
```

#### Using Docker directly

**Note**: When using Docker directly (without docker-compose), you need to have PostgreSQL running separately and configure the connection.

1. Build the Docker image:
```bash
docker build -t university-registration-api .
```

2. Run the container with PostgreSQL connection:
```bash
docker run -d -p 8000:8000 --name university_registration_api \
  -e DATABASE_USER=postgres \
  -e DATABASE_PASSWORD=postgres \
  -e DATABASE_HOST=host.docker.internal \
  -e DATABASE_PORT=5432 \
  -e DATABASE_NAME=university_registration \
  university-registration-api
```

3. To stop the container:
```bash
docker stop university_registration_api
docker rm university_registration_api
```

### Option 2: Local Development

**Prerequisites**: PostgreSQL must be installed and running on your system.

1. Create a virtual environment (recommended):
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Set up PostgreSQL database:
```bash
# Create database (if not exists)
createdb university_registration

# Or using psql:
psql -U postgres -c "CREATE DATABASE university_registration;"
```

4. Set environment variables (optional, defaults are provided):
```bash
# On Linux/Mac:
export DATABASE_USER=postgres
export DATABASE_PASSWORD=postgres
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export DATABASE_NAME=university_registration

# On Windows (PowerShell):
$env:DATABASE_USER="postgres"
$env:DATABASE_PASSWORD="postgres"
$env:DATABASE_HOST="localhost"
$env:DATABASE_PORT="5432"
$env:DATABASE_NAME="university_registration"
```

5. Start the development server:
```bash
uvicorn main:app --reload
```

The API will be available at:
- **API**: http://localhost:8000
- **Interactive API Docs (Swagger)**: http://localhost:8000/docs
- **Alternative API Docs (ReDoc)**: http://localhost:8000/redoc

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

```bash
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

```bash
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

```bash
curl -X POST "http://localhost:8000/registrations/" \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "550e8400-e29b-41d4-a716-446655440000",
    "course_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
  }'
```

### 4. Get Student's Registered Courses

```bash
curl "http://localhost:8000/students/550e8400-e29b-41d4-a716-446655440000/registrations"
```

### 5. Drop a Course

```bash
curl -X DELETE "http://localhost:8000/registrations/6ba7b811-9dad-11d1-80b4-00c04fd430c8"
```

**Note**: All IDs are UUIDs (Universally Unique Identifiers), not integers. Use the UUIDs returned from the create endpoints.

## Database

The application uses **PostgreSQL** as the database. When using Docker Compose, PostgreSQL is automatically set up and configured.

### Database Configuration

The database connection is configured via environment variables:

- `DATABASE_USER` - PostgreSQL username (default: `postgres`)
- `DATABASE_PASSWORD` - PostgreSQL password (default: `postgres`)
- `DATABASE_HOST` - Database host (default: `localhost` or `db` in Docker)
- `DATABASE_PORT` - Database port (default: `5432`)
- `DATABASE_NAME` - Database name (default: `university_registration`)

### Local Development with PostgreSQL

If running locally (without Docker), make sure PostgreSQL is installed and running:

1. Create a database:
```bash
createdb university_registration
```

2. Set environment variables or update `database.py` with your PostgreSQL credentials.

3. The database tables are automatically created when you first run the application.

### Docker Compose

When using `docker-compose up`, PostgreSQL is automatically:
- Started in a separate container
- Configured with the credentials specified in `docker-compose.yaml`
- Connected to the API service
- Data is persisted in a Docker volume (`postgres_data`)

## Database Features

### UUID Primary Keys
All tables use UUID (Universally Unique Identifier) as primary keys instead of auto-incrementing integers. This provides:
- Better distributed system support
- Improved security (non-sequential IDs)
- Global uniqueness

### Course Capacity Management
- **max_capacity Field**: Each course has a `max_capacity` field with a default value of 50
- **Database Trigger**: A PostgreSQL trigger automatically enforces the maximum capacity at the database level
- **Application-Level Check**: The API also checks capacity before allowing registration
- **Active Registrations Only**: Only active registrations count toward the capacity limit

## Validation Features

The API includes several validation checks:

- **Duplicate Registration**: Prevents students from registering for the same course twice
- **Course Capacity**: Checks if a course has available spots before registration (enforced at both application and database levels)
- **Existence Checks**: Validates that students and courses exist before registration
- **Email Validation**: Ensures valid email format for students
- **Database Trigger**: PostgreSQL trigger prevents exceeding max_capacity even if API validation is bypassed

## Project Structure

```
university_register_course_system_design/
├── main.py              # FastAPI application and endpoints
├── models.py            # SQLAlchemy database models
├── schemas.py           # Pydantic schemas for validation
├── database.py          # Database configuration
├── requirements.txt     # Python dependencies
├── Dockerfile           # Docker image configuration
├── docker-compose.yaml  # Docker Compose configuration
├── .dockerignore        # Files to exclude from Docker build
└── README.md           # This file
```

## Development

To extend the API, you can:

1. Add more validation rules in the registration endpoint
2. Implement authentication and authorization
3. Add course prerequisites checking
4. Implement waitlist functionality
5. Add semester/term support
6. Implement grade tracking

## License

This project is provided as-is for educational purposes.

