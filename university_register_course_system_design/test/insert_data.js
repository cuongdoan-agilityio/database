import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter } from 'k6/metrics';

const studentCreationSuccess = new Rate('student_creation_success');
const studentCreationFailure = new Rate('student_creation_failure');
const courseCreationSuccess = new Rate('course_creation_success');
const courseCreationFailure = new Rate('course_creation_failure');
const studentsCreated = new Counter('students_created');
const coursesCreated = new Counter('courses_created');

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';
const NUM_STUDENTS = parseInt(__ENV.NUM_STUDENTS || '400');
const NUM_COURSES = parseInt(__ENV.NUM_COURSES || '2');
const firstNames = [
    'John', 'Jane', 'Michael', 'Sarah', 'David', 'Emily', 'James', 'Emma', 'Robert', 'Olivia', 'Henry', 'Lucas', 'Ava', 'Mason', 'Sophia', 'Ethan', 'Isabella', 'Logan',
    'Mia', 'Jackson', 'Charlotte', 'Aiden', 'Amelia', 'Harper', 'Oliver', 'Evelyn', 'Elijah', 'Abigail', 'Benjamin', 'Madison', 'Jacob', 'Elizabeth', 'William'
];
const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Trum', 'Ford', 'Nguyen', 'Hall', 'Hill'];
const coursesData = [
    {
        course_code: 'CS101',
        course_name: 'Introduction to Computer Science',
        description: 'An introductory course covering fundamental concepts of computer science including programming basics, algorithms, and data structures.',
        credits: 3,
        max_capacity: 30,
        instructor: 'Dr. Sarah Johnson'
    },
    {
        course_code: 'CS201',
        course_name: 'Calculus I',
        description: 'First course in calculus covering limits, derivatives, and applications of differentiation.',
        credits: 4,
        max_capacity: 30,
        instructor: 'Prof. Michael Chen'
    }
];

// Test configuration
export const options = {
    stages: [
        { duration: '1s', target: 10  },
        { duration: '60s', target: 10 },
        { duration: '2s', target: 0 },
    ],
    thresholds: {
        http_req_duration: ['p(95)<4000'],
        http_req_failed: ['rate<0.3'],
        student_creation_success: ['rate>0.95'],
        course_creation_success: ['rate>0.999'],
    },
};

// Generate student data
function generateStudentData(index) {
    const firstName = firstNames[index % firstNames.length];
    const lastName = lastNames[Math.floor(index / firstNames.length) % lastNames.length];

    return {
        student_code: `STU${String(index).padStart(6, '0')}`,
        first_name: firstName,
        last_name: lastName,
        email: `${firstName.toLowerCase()}.${lastName.toLowerCase()}${index}@university.edu`,
        phone: `555-${String(1000 + (index % 9000)).padStart(4, '0')}`
    };
}

export function setup() {
    return {
        baseUrl: BASE_URL,
        numStudents: NUM_STUDENTS,
        numCourses: NUM_COURSES,
    };
}

export default function (data) {
    // Create course.
    if (__VU <= coursesData.length && __ITER === 0) {
        const courseIndex = __VU - 1;
        if (courseIndex < coursesData.length) {
            createCourse(data.baseUrl, coursesData[courseIndex], courseIndex);
        }
        sleep(0.1);
    }

    // Create students
    const studentIndex = (__ITER * 10) + __VU;

    if (studentIndex <= data.numStudents) {
        createStudent(data.baseUrl, studentIndex);
    }

    sleep(0.1);
}

function createStudent(baseUrl, index) {
    const studentData = generateStudentData(index);
    const payload = JSON.stringify(studentData);

    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
        tags: {
            name: 'CreateStudent',
            student_code: studentData.student_code,
        },
    };

    const response = http.post(`${baseUrl}/students/`, payload, params);

    const success = check(response, {
        'student creation status is 201': (r) => r.status === 201,
        'response has student_id': (r) => {
            if (r.status === 201) {
                try {
                    const body = JSON.parse(r.body);
                    return body.student_id !== undefined;
                } catch (e) {
                    return false;
                }
            }
            return false;
        },
    });

    if (response.status === 201) {
        studentCreationSuccess.add(1);
        studentsCreated.add(1);
        console.log(`Created student: ${studentData.student_code}`);
    } else {
        studentCreationFailure.add(1);
        console.log(`Student with code ${studentData.student_code} already exists or failed to create.`);
    }
}

function createCourse(baseUrl, courseData, index) {
    const payload = JSON.stringify(courseData);

    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
        tags: {
            name: 'CreateCourse',
            course_code: courseData.course_code,
        },
    };

    const response = http.post(`${baseUrl}/courses/`, payload, params);

    const success = check(response, {
        'course creation status is 201': (r) => r.status === 201,
        'response has course_id': (r) => {
            if (r.status === 201) {
                try {
                    const body = JSON.parse(r.body);
                    return body.course_id !== undefined;
                } catch (e) {
                    return false;
                }
            }
            return false;
        },
    });

    if (response.status === 201) {
        courseCreationSuccess.add(1);
        coursesCreated.add(1);
        console.log(`Created course with code ${courseData.course_code}`);
    } else {
        courseCreationFailure.add(1);
        console.log(`Course with code ${courseData.course_code} already exists or failed to create.`);
    }
}

export function teardown(data) {
    // Verify students were created
    const studentsResponse = http.get(`${data.baseUrl}/students/?limit=500`);
    let studentCount = 0;
    if (studentsResponse.status === 200) {
        const students = JSON.parse(studentsResponse.body);
        studentCount = students.length;
        console.log(`Total students in database: ${studentCount}`);
    }

    // Verify courses were created
    const coursesResponse = http.get(`${data.baseUrl}/courses/`);
    let courseCount = 0;
    if (coursesResponse.status === 200) {
        const courses = JSON.parse(coursesResponse.body);
        courseCount = courses.length;
        console.log(`Total courses in database: ${courseCount}`);
    }

    console.log('\n=== Completed ===');
}
