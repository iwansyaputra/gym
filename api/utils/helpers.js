const moment = require('moment');

// Calculate remaining days
const calculateRemainingDays = (endDate) => {
    const today = moment();
    const end = moment(endDate);
    return end.diff(today, 'days');
};

// Check if membership is active
const isMembershipActive = (endDate) => {
    return calculateRemainingDays(endDate) >= 0;
};

// Format currency to IDR
const formatCurrency = (amount) => {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0
    }).format(amount);
};

// Format date to Indonesian format
const formatDate = (date) => {
    return moment(date).locale('id').format('DD MMMM YYYY');
};

module.exports = {
    calculateRemainingDays,
    isMembershipActive,
    formatCurrency,
    formatDate
};
