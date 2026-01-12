const http = require('http');

function makeRequest(path, label) {
    const options = {
        hostname: 'localhost',
        port: 8888,
        path: path,
        method: 'GET'
    };

    const req = http.request(options, (res) => {
        let data = '';

        console.log(`\n[${label}] Status Code: ${res.statusCode}`);
        console.log(`[${label}] Headers: ${JSON.stringify(res.headers)}`);

        res.on('data', (chunk) => {
            data += chunk;
        });

        res.on('end', () => {
            console.log(`[${label}] Body: ${data}`);
        });
    });

    req.on('error', (error) => {
        console.error(`[${label}] Error: ${error.message}`);
    });

    req.end();
}

console.log("Testing Assembly");
//HTML page
makeRequest('/', 'HTML PAGE');

//API endpoint
setTimeout(() => {
    makeRequest('/api/health', 'API ENDPOINT');
}, 500);
