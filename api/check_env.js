require('dotenv').config();

console.log('--- Environment Check ---');
console.log('Production Mode:', process.env.MIDTRANS_IS_PRODUCTION);
console.log('Mode Type:', typeof process.env.MIDTRANS_IS_PRODUCTION);

const sk = process.env.MIDTRANS_SERVER_KEY || '';
console.log('Server Key Length:', sk.length);
console.log('Server Key Preview:', sk.substring(0, 5) + '...' + sk.substring(sk.length - 5));

const ck = process.env.MIDTRANS_CLIENT_KEY || '';
console.log('Client Key Length:', ck.length);
console.log('Client Key Preview:', ck.substring(0, 5) + '...' + ck.substring(ck.length - 5));

if (sk.startsWith('SB-')) {
    console.log('WARNING: Key starts with SB- (Sandbox) but config might be set to Production?');
} else if (sk.startsWith('Mid-')) {
    console.log('INFO: Key starts with Mid- (Production).');
} else {
    console.log('WARNING: Key format unrecognized.');
}
