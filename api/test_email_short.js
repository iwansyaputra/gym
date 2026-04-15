const nodemailer = require('nodemailer');

const config = {
    service: 'gmail',
    auth: {
        user: 'iwantugaskuliah@gmail.com',
        pass: 'rmtw utjw eohl gxhv'
    }
};

const transporter = nodemailer.createTransport(config);

transporter.sendMail({
    from: config.auth.user,
    to: config.auth.user,
    subject: 'Test Short',
    text: 'Test'
}, (error, info) => {
    if (error) {
        console.log('FAIL');
        console.log(error.message);
    } else {
        console.log('SUCCESS');
        console.log(info.response);
    }
});
