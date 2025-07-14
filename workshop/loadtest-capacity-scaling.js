import http from 'k6/http';
import { check, sleep } from 'k6';

// Get ALB URL from environment variable
const ALB_URL = __ENV.ALB_URL || 'http://localhost';
const TARGET_URL = `${ALB_URL}/wildlife`;

export let options = {
  stages: [
    // Aggressive ramp-up to force media service beyond 7 task capacity
    { duration: '30s', target: 500 },   // Quick spike to 300 users
    { duration: '30s', target: 1000 },    // Push to 600 users
    { duration: '30s', target: 1500 },    // Peak load to force 5-6 media tasks
    
    // Sustained very high load to trigger EC2 capacity scaling
    { duration: '6m', target: 2000 },   // Maximum load to exceed EC2 capacity
    
    // Gradual ramp-down to observe scaling behavior
    { duration: '1m', target: 500 },    // Gradual drop
    { duration: '1m', target: 100 },    // Quick drop
    { duration: '30s', target: 0 },      // Complete drop
  ],
  thresholds: {
    http_req_duration: ['p(95)<4000'], // More lenient for higher load
    http_req_failed: ['rate<0.2'],     // Expect some failures under heavy load
  },
};

export default function() {
  // Make multiple requests to increase CPU load per user
  let response1 = http.get(`${TARGET_URL}/api/sightings`, {
    headers: {
      'User-Agent': 'k6-capacity-scaling-test/1.0',
    },
  });
  
  // Check response
  check(response1, {
    'status is 200': (r) => r.status === 200,
    'response time < 5s': (r) => r.timings.duration < 5000,
  });
  
  // Add more requests to stress the media service harder
  http.get(`${TARGET_URL}/api/sightings?limit=50`);
  http.post(`${TARGET_URL}/api/sightings`, {
    species: `Load Test Species ${Math.random()}`,
    habitat: 'Forest',
    latitude: (-20.2759 + (Math.random() - 0.5) * 0.1).toString(),
    longitude: (57.5704 + (Math.random() - 0.5) * 0.1).toString(),
    count: (Math.floor(Math.random() * 10) + 1).toString(),
    description: `Load test sighting - ${new Date().toISOString()}`
  });
  
  // Add a small delay but keep pressure high
  sleep(0.1);
  
  // Additional request burst to really stress CPU
  http.get(`${TARGET_URL}/api/images/sightings/20250714/test_image_${Math.floor(Math.random() * 10)}.jpg`);
}