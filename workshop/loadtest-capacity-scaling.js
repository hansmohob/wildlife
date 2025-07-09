import http from 'k6/http';
import { check, sleep } from 'k6';

// Get ALB URL from environment variable
const ALB_URL = __ENV.ALB_URL || 'http://localhost';
const TARGET_URL = `${ALB_URL}/wildlife`;

export let options = {
  stages: [
    // Aggressive ramp-up to overwhelm data services
    { duration: '1m', target: 200 },    // Quick spike to stress data layer
    { duration: '2m', target: 400 },    // Heavy load on database connections
    { duration: '2m', target: 500 },    // Peak load to trigger capacity scaling
    
    // Sustained high load to force infrastructure scaling
    { duration: '3m', target: 500 },    // Hold peak load
    
    // Quick ramp-down
    { duration: '1m', target: 100 },    // Quick drop
    { duration: '1m', target: 0 },      // Complete drop
  ],
  thresholds: {
    http_req_duration: ['p(95)<5000'], // More lenient for data operations
    http_req_failed: ['rate<0.3'],     // Expect higher failure rate
  },
};

export default function() {
  // Heavy data operations to stress the backend
  let response1 = http.get(`${TARGET_URL}/api/animals`, {
    headers: {
      'User-Agent': 'k6-capacity-scaling-test/1.0',
    },
  });
  
  check(response1, {
    'animals API status is 200': (r) => r.status === 200,
  });
  
  // Multiple data requests to exhaust database connections
  http.get(`${TARGET_URL}/api/sightings`);
  http.get(`${TARGET_URL}/api/animals?limit=100`);
  
  // POST operations to create database load
  const sightingData = {
    animal_id: Math.floor(Math.random() * 10) + 1,
    location: `Test Location ${Math.random()}`,
    sighting_date: new Date().toISOString(),
    notes: `Load test sighting ${Math.random()}`
  };
  
  http.post(`${TARGET_URL}/api/sightings`, JSON.stringify(sightingData), {
    headers: { 'Content-Type': 'application/json' },
  });
  
  // Minimal delay to maintain pressure
  sleep(0.2);
}

export function handleSummary(data) {
  const avgDuration = data.metrics.iteration_duration?.avg || 0;
  const totalReqs = data.metrics.http_reqs?.count || 0;
  const failureRate = data.metrics.http_req_failed?.rate || 0;
  const avgResponseTime = data.metrics.http_req_duration?.avg || 0;
  
  return {
    'stdout': `
🎯 K6 Capacity Scaling Test Results
==================================
Duration: ${avgDuration.toFixed(2)}ms avg
Requests: ${totalReqs} total
Failures: ${(failureRate * 100).toFixed(1)}% failure rate
Response Time: ${avgResponseTime.toFixed(2)}ms avg
`,
  };
}