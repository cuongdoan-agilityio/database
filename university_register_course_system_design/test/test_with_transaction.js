import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter, Trend } from 'k6/metrics';

// Custom metrics
const registrationSuccessRate = new Rate('registration_success');
const registrationFailureRate = new Rate('registration_failure');
const capacityExceededRate = new Rate('capacity_exceeded');
const duplicateRegistrationRate = new Rate('duplicate_registration');
const registrationCounter = new Counter('total_registrations');
const registrationDuration = new Trend('registration_duration');

// Test configuration
export const options = {
  stages: [
    { duration: '1s', target: 400 },
    { duration: '10s', target: 400 },
    { duration: '2s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
  },
};

// Configuration
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';
const COURSE_CODE = __ENV.COURSE_CODE || 'CS101';
const STUDENT_CODES = __ENV.STUDENT_CODES ? __ENV.STUDENT_CODES.split(',') : null;

// Generate student codes if not provided
function generateStudentCodes(count) {
  const codes = [];
  for (let i = 1; i <= count; i++) {
    codes.push(`STU${String(i).padStart(6, '0')}`);
  }
  return codes;
}

// Get student codes
const studentCodes = STUDENT_CODES || generateStudentCodes(200);

export function setup() {
  // Check if course exists
  const courseResponse = http.get(`${BASE_URL}/courses/`);
  if (courseResponse.status !== 200) {
    throw new Error(`Failed to fetch courses: ${courseResponse.status}`);
  }
  
  const courses = JSON.parse(courseResponse.body);
  const course = courses.find(c => c.course_code === COURSE_CODE);
  const registrationsResponse = http.get(`${BASE_URL}/registrations/`);
  let initialCount = 0;

  if (registrationsResponse.status === 200) {
    const registrations = JSON.parse(registrationsResponse.body);
    initialCount = registrations.filter(r => r.course_code === COURSE_CODE && r.status === 'active').length;
  }
  
  return {
    courseCode: COURSE_CODE,
    maxCapacity: course.max_capacity,
    initialCount: initialCount,
    studentCodes: studentCodes,
  };
}

export default function (data) {
  // Each VU (Virtual User) represents one student trying to register
  // Use modulo to handle cases where VU count exceeds student codes
  const studentIndex = (__VU - 1) % data.studentCodes.length;
  const studentCode = data.studentCodes[studentIndex];
  
  const payload = JSON.stringify({
    student_code: studentCode,
    course_code: data.courseCode
  });
  
  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
    tags: {
      name: 'RegisterCourse',
      student_code: studentCode,
    },
  };
  
  // Record start time
  const startTime = Date.now();
  
  // Attempt registration
  const response = http.post(
    `${BASE_URL}/registrations/`,
    payload,
    params
  );
  
  // Calculate duration
  const duration = Date.now() - startTime;
  registrationDuration.add(duration);
  
  // Check response
  const success = check(response, {
    'registration status is 201': (r) => r.status === 201,
    'response time < 2000ms': (r) => r.timings.duration < 2000,
  });
  
  if (response.status === 201) {
    // Successful registration
    registrationSuccessRate.add(1);
    registrationCounter.add(1);
    console.log(`Student ${studentCode} successfully registered`);
  } else {
    // Failed registration
    registrationFailureRate.add(1);

    console.log(`Student ${studentCode} - Error: ${response.status}`);
  }
}

export function teardown(data) {
  // Teardown: Check final registration count
  console.log('\n=== Summary ===');
  console.log(`Course: ${data.courseCode}`);
  console.log(`Max capacity: ${data.maxCapacity}`);
  console.log(`Initial registrations: ${data.initialCount}`);
  
  const registrationsResponse = http.get(`${BASE_URL}/registrations/`);
  if (registrationsResponse.status === 200) {
    const registrations = JSON.parse(registrationsResponse.body);
    const finalCount = registrations.filter(
      r => r.course_code === data.courseCode && r.status === 'active'
    ).length;
    
    console.log(`Final registrations: ${finalCount}`);
    console.log(`New registrations: ${finalCount - data.initialCount}`);
    console.log(`Expected max: ${data.initialCount + data.maxCapacity}`);
    
    if (finalCount <= data.initialCount + data.maxCapacity) {
      console.log('Capacity constraint respected!');
    } else {
      console.log('WARNING: Capacity exceeded!');
    }
  }
}
