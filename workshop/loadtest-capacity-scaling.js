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
  // Multiple concurrent requests to overwhelm the service
  const requests = [];
  
  // Create 10 concurrent GET requests per VU to really stress the system
  for (let i = 0; i < 10; i++) {
    requests.push(['GET', `${TARGET_URL}/api/animals?limit=100&offset=${i * 10}`, null, {
      headers: { 'User-Agent': 'k6-capacity-scaling-test/1.0' }
    }]);
    
    requests.push(['GET', `${TARGET_URL}/api/sightings?limit=50&offset=${i * 5}`, null, {
      headers: { 'User-Agent': 'k6-capacity-scaling-test/1.0' }
    }]);
  }
  
  // POST operations to create database write load
  for (let i = 0; i < 5; i++) {
    const sightingData = {
      species: `Load Test Species ${Math.random()}`,
      habitat: 'Forest',
      latitude: -20.2759 + (Math.random() - 0.5) * 0.1,
      longitude: 57.5704 + (Math.random() - 0.5) * 0.1,
      count: Math.floor(Math.random() * 10) + 1,
      timestamp: new Date().toISOString()
    };
    
    requests.push(['POST', `${TARGET_URL}/api/sightings`, JSON.stringify(sightingData), {
      headers: { 'Content-Type': 'application/json' }
    }]);
  }
  
  // Execute all requests concurrently
  http.batch(requests);
  
  // Minimal delay to maintain maximum pressure
  sleep(0.1);
}

// Removed custom handleSummary - using default k6 output which shows all metrics properly