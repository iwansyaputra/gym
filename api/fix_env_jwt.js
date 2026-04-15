const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '.env');
let envContent = fs.readFileSync(envPath, 'utf8');

if (!envContent.includes('JWT_EXPIRES_IN')) {
    envContent += '\nJWT_EXPIRES_IN=30d';
    fs.writeFileSync(envPath, envContent);
    console.log('Added JWT_EXPIRES_IN to .env');
} else {
    console.log('JWT_EXPIRES_IN already exists');
}
