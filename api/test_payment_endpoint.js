const http = require('http');

// 1. Login Function to get Token
function loginAndTestPayment() {
    const loginData = JSON.stringify({
        email: "test_api_v1@email.com",
        password: "password123"
    });

    const loginOptions = {
        hostname: 'localhost',
        port: 3000,
        path: '/api/auth/login',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': loginData.length
        }
    };

    console.log('1. Trying to Login...');
    const loginReq = http.request(loginOptions, res => {
        let responseData = '';
        res.on('data', chunk => responseData += chunk);
        res.on('end', () => {
            try {
                const json = JSON.parse(responseData);
                if (json.success) {
                    const token = json.data.token;
                    console.log('✅ Login Successful! Got Token.');
                    testPaymentEndpoint(token);
                } else {
                    console.log('❌ Login Failed:', json.message);
                    console.log('Using dummy token for endpoint check...');
                    // Even if login fails (maybe user doesn't exist), let's try endpoint check 
                    // It should return 401 Unauthorized, NOT 404 Not Found
                    testPaymentEndpoint('dummy_token');
                }
            } catch (e) {
                console.log('Error parsing login response');
            }
        });
    });
    loginReq.write(loginData);
    loginReq.end();
}

// 2. Test Payment Endpoint
function testPaymentEndpoint(token) {
    const paymentData = JSON.stringify({
        paket: "bulanan",
        harga: 250000
    });

    const paymentOptions = {
        hostname: 'localhost',
        port: 3000,
        path: '/api/payment/create',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + token,
            'Content-Length': paymentData.length
        }
    };

    console.log('\n2. Testing POST /api/payment/create...');
    const paymentReq = http.request(paymentOptions, res => {
        console.log(`Status Code: ${res.statusCode} ${res.statusCode === 404 ? '(NOT FOUND)' : ''}`);

        let responseData = '';
        res.on('data', chunk => responseData += chunk);
        res.on('end', () => {
            console.log('Response Body:', responseData);
            if (res.statusCode === 404) {
                console.log('\n❌ ERROR: Endpoint /api/payment/create NOT FOUND on server!');
            } else if (res.statusCode === 200) {
                console.log('\n✅ SUCCESS: Endpoint found and working!');
            } else if (res.statusCode === 401) {
                console.log('\n✅ ENDPOINT EXISTS (Got 401 Unauthorized) - Server route is working, just need valid token.');
            } else {
                console.log(`\nEndpoint responded with status ${res.statusCode}. Route exists.`);
            }
        });
    });

    paymentReq.on('error', (e) => {
        console.error('Connection Error:', e);
    });

    paymentReq.write(paymentData);
    paymentReq.end();
}

loginAndTestPayment();
