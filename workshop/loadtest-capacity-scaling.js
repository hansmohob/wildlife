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
    { duration: '3m', target: 500 },    // Peak load to trigger capacity scaling
    
    // Sustained very high load to force infrastructure scaling
    { duration: '5m', target: 500 },    // Hold peak load longer
    
    // Gradual drop to observe scale-in behavior
    { duration: '2m', target: 300 },    // Start scaling down
    { duration: '2m', target: 150 },    // Continue scaling down
    { duration: '1m', target: 50 },     // Light load
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
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, options) {
  const avgDuration = data.metrics.iteration_duration?.avg || 0;
  const totalReqs = data.metrics.http_reqs?.count || 0;
  const failureRate = data.metrics.http_req_failed?.rate || 0;
  const avgResponseTime = data.metrics.http_req_duration?.avg || 0;
  
  return `
🎯 K6 Capacity Scaling Test Results
==================================
Duration: ${avgDuration.toFixed(2)}ms avg
Requests: ${totalReqs} total
Failures: ${(failureRate * 100).toFixed(1)}% failure rate
Response Time: ${avgResponseTime.toFixed(2)}ms avg

📊 Expected Capacity Scaling Behavior:
- 0-3 min: Heavy load on data services
- 3-8 min: ECS attempts to scale containers (may fail due to MongoDB locks)
- 8-11 min: Infrastructure scaling as ECS requests more capacity
- 11-17 min: Gradual scale-down
- Final: Return to baseline capacity

🔍 Troubleshooting: If containers fail to start, check CloudWatch logs
   and use ECS exec to investigate running containers.

🎉 SUCCESS: Watch both container scaling attempts AND infrastructure scaling!
`;
}
