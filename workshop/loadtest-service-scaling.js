import http from 'k6/http';
import { check, sleep } from 'k6';

// Get ALB URL from environment variable
const ALB_URL = __ENV.ALB_URL || 'http://localhost';
const TARGET_URL = `${ALB_URL}/wildlife`;

export let options = {
  stages: [
    // More aggressive ramp-up to trigger scaling ASAP
    { duration: '30s', target: 150 },   // Quick spike to 150 users
    { duration: '1m', target: 250 },    // Push much higher to ensure CPU > 70%
    { duration: '2m', target: 300 },    // Peak load to trigger multiple scale-outs
    
    // Sustained very high load to see multiple scaling events
    { duration: '4m', target: 300 },    // Hold peak load longer
    
    // Gradual drop to observe scale-in behavior
    { duration: '2m', target: 200 },    // Start scaling down
    { duration: '2m', target: 100 },    // Continue scaling down
    { duration: '1m', target: 50 },     // Light load
    { duration: '1m', target: 0 },      // Complete drop
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'], // 95% of requests under 3s
    http_req_failed: ['rate<0.15'],    // Less than 15% failures
  },
};

export default function() {
  // Make multiple requests to increase CPU load per user
  let response1 = http.get(TARGET_URL, {
    headers: {
      'User-Agent': 'k6-scaling-test/1.0',
    },
  });
  
  // Check response
  check(response1, {
    'status is 200': (r) => r.status === 200,
    'response time < 5s': (r) => r.timings.duration < 5000,
  });
  
  // Add more requests to stress the frontend harder
  http.get(`${TARGET_URL}/api/animals`);
  http.get(`${TARGET_URL}/api/sightings`);
  
  // Add a small delay but keep pressure high
  sleep(0.3);
  
  // Additional request burst to really stress CPU
  http.get(TARGET_URL);
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
🎯 K6 Aggressive Scaling Test Results
===================================
Duration: ${avgDuration.toFixed(2)}ms avg
Requests: ${totalReqs} total
Failures: ${(failureRate * 100).toFixed(1)}% failure rate
Response Time: ${avgResponseTime.toFixed(2)}ms avg

📊 Use these commands to monitor scaling:
- Menu option 22: Check Deployment Status  
- Menu option 23: Show Application URL
- AWS Console: ECS → Clusters → wildlife-ecs → Services → wildlife-frontend-service

🔍 Expected Scaling Behavior:
- 0-2 min: Tasks should scale from 2 → 3 (CPU > 70%)
- 2-4 min: Continue scaling 3 → 4 → 5 (sustained high load)
- 4-9 min: Peak scaling (up to 5 tasks maximum)
- 9-15 min: Gradual scale-down as load decreases
- Final: Return to 2 tasks (minimum capacity)

💡 This test generates ~300 concurrent users at peak with multiple requests per user
   to create sustained high CPU load and trigger multiple scaling events.

🎉 SUCCESS: If you see 4+ containers, the scaling demonstration worked perfectly!
`;
}