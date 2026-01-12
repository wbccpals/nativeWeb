const http = require('http');

const TOTAL_REQUESTS = 2000;
const CONCURRENCY = 50;

let requestsStarted = 0;
let requestsCompleted = 0;
let successfulResponses = 0;
let failedResponses = 0;
const startTime = Date.now();

console.log(`Starting load test: ${TOTAL_REQUESTS} requests with concurrency ${CONCURRENCY}...`);

function makeRequest() {
    if (requestsStarted >= TOTAL_REQUESTS) return;

    requestsStarted++;

    const req = http.request({
        hostname: 'localhost',
        port: 8888,
        path: '/',
        method: 'GET',
        agent: false
    }, (res) => {
        res.on('data', () => { });
        res.on('end', () => {
            successfulResponses++;
            finishRequest();
        });
    });

    req.on('error', (e) => {
        failedResponses++;
        finishRequest();
    });

    req.end();
}

function finishRequest() {
    requestsCompleted++;
    if (requestsCompleted % 100 === 0) {
        process.stdout.write('.');
    }

    if (requestsCompleted === TOTAL_REQUESTS) {
        const totalTime = (Date.now() - startTime) / 1000;
        console.log('\n\n--- Test Results ---');
        console.log(`Total Requests: ${TOTAL_REQUESTS}`);
        console.log(`Successful: ${successfulResponses}`);
        console.log(`Failed: ${failedResponses}`);
        console.log(`Total Time: ${totalTime.toFixed(2)}s`);
        console.log(`Requests Per Second: ${(TOTAL_REQUESTS / totalTime).toFixed(2)}`);
    } else {
        makeRequest();
    }
}

// Start initial pool
for (let i = 0; i < Math.min(CONCURRENCY, TOTAL_REQUESTS); i++) {
    makeRequest();
}
