const http = require('http');

const data = JSON.stringify({
    nama: "Test User API",
    email: "test_api_v1@email.com",
    password: "password123",
    hp: "081234567890",
    jenis_kelamin: "Laki-laki",
    tanggal_lahir: "1995-05-20",
    alamat: "Jl. Testing API No. 1"
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

console.log('Testing Registration API...');

const req = http.request(options, res => {
    console.log(`Status Code: ${res.statusCode}`);

    let responseData = '';
    res.on('data', chunk => {
        responseData += chunk;
    });

    res.on('end', () => {
        console.log('Response Body:', responseData);
        try {
            const json = JSON.parse(responseData);
            if (json.success) {
                console.log('\n✅ Registration Successful!');
            } else {
                console.log('\n❌ Registration Failed:', json.message);
            }
        } catch (e) {
            console.log('Error parsing JSON');
        }
    });
});

req.on('error', error => {
    console.error('Error:', error);
});

req.write(data);
req.end();
