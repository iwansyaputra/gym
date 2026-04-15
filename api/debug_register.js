
const http = require('http');

const data = JSON.stringify({
    nama: "Test User Debug",
    email: "test_debug_" + Date.now() + "@email.com",
    hp: "08999999999",
    password: "password123",
    alamat: "Jl. Testing API",
    jenis_kelamin: "Laki-laki",
    tanggal_lahir: "1990-01-01",
    is_admin_action: true // Simulate admin creating member
});

const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/register',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
    }
};

console.log('Sending Registration Request:', data);

const req = http.request(options, (res) => {
    let responseBody = '';

    res.on('data', (chunk) => {
        responseBody += chunk;
    });

    res.on('end', () => {
        console.log(`Status Code: ${res.statusCode}`);
        console.log('Response Body:', responseBody);
    });
});

req.on('error', (error) => {
    console.error('Request Error:', error);
});

req.write(data);
req.end();
