import http from 'k6/http';
import { check, sleep } from 'k6';

// Get ALB URL from environment variable
const ALB_URL = __ENV.ALB_URL || 'http://localhost';
const TARGET_URL = `${ALB_URL}/wildlife`;

export let options = {
  stages: [
    // Aggressive ramp-up to trigger scaling Media service scaling
    { duration: '30s', target: 150 },   // Quick spike to 150 users
    { duration: '1m', target: 250 },    // Push much higher to ensure CPU > 70%
    { duration: '2m', target: 300 },    // Peak load to trigger multiple scale-outs
    
    // Sustained high load to see scaling events
    { duration: '4m', target: 300 },    // Hold peak load
    
    // Quick ramp-down
    { duration: '1m', target: 100 },    // Quick drop
    { duration: '1m', target: 50 },     // Light load
    { duration: '30s', target: 0 },     // Complete drop
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'], // 95% of requests under 3s
    http_req_failed: ['rate<0.15'],    // Less than 15% failures
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
  sleep(0.3);
  
  // Additional request burst to really stress CPU
  http.get(`${TARGET_URL}/api/images/sightings/20250714/test_image_${Math.floor(Math.random() * 10)}.jpg`);
}