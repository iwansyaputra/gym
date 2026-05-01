// API Configuration
const API_CONFIG = {
    // Otomatis deteksi IP/Host agar tidak perlu ganti-ganti saat pindah WiFi
    // Jika admin web dibuka dari file:// di browser, gunakan fallback ke IP server.
    BASE_URL: (() => {
        const FALLBACK_API_HOST = 'localhost'; // ✅ IP Server (update jika ganti WiFi)
        const hostname = window.location.hostname;
        // Jika dibuka lewat file://, localhost, atau 127.0.0.1 → pakai IP server langsung
        // Jika dibuka dari IP/host lain (misal dihosting) → pakai hostname itu
        const useFallback = (hostname === '' || hostname === 'localhost' || hostname === '127.0.0.1');
        const apiHost = useFallback ? FALLBACK_API_HOST : hostname;
        const url = `http://${apiHost}:3000/api`;
        console.log('🔗 GymKu API BASE_URL:', url);
        return url;
    })(),

    // Endpoints
    ENDPOINTS: {
        // Auth
        LOGIN: '/auth/login',
        REGISTER: '/auth/register',
        VERIFY_OTP: '/auth/verify-otp',

        // User
        PROFILE: '/user/profile',
        UPDATE_PROFILE: '/user/profile',
        CHANGE_PASSWORD: '/user/change-password',

        // Admin - Members Management
        GET_ALL_USERS: '/admin/users',
        GET_USER: '/user/profile',
        CREATE_USER: '/auth/register',
        UPDATE_USER: '/admin/users',
        DELETE_USER: '/admin/users',

        // Admin - Dashboard
        DASHBOARD_STATS: '/admin/dashboard/stats',

        // Check-in
        CHECKIN_NFC: '/check-in/nfc',
        CHECKIN_HISTORY: '/check-in/history',
        CHECKIN_STATS: '/admin/checkin/stats',

        // Membership
        MEMBERSHIP_INFO: '/membership/info',
        MEMBERSHIP_PACKAGES: '/membership/packages',
        EXTEND_MEMBERSHIP: '/membership/extend',

        // Transactions
        TRANSACTIONS_HISTORY: '/transactions/history',
        TRANSACTION_DETAIL: '/transactions',
        CREATE_TRANSACTION: '/transactions/create',
        CONFIRM_TRANSACTION: '/transactions/confirm',

        // Payment
        CREATE_PAYMENT: '/payment/create',
        PAYMENT_STATUS: '/payment/status',
        PAYMENT_HISTORY: '/payment/history',

        // Promos
        GET_PROMOS: '/promos',
        GET_PROMO: '/promos'
    },

    // Request timeout in milliseconds
    TIMEOUT: 30000,

    // Storage keys
    STORAGE_KEYS: {
        TOKEN: 'admin_token',
        USER: 'admin_user',
        REMEMBER_ME: 'admin_remember_me'
    }
};

// Debug: show actual API URL used by admin web
console.log('GymKu API BASE_URL:', API_CONFIG.BASE_URL);

// Helper function to get full API URL
function getApiUrl(endpoint) {
    return API_CONFIG.BASE_URL + endpoint;
}

// Helper function to format currency
function formatCurrency(amount) {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0
    }).format(amount);
}

// Helper function to format date
function formatDate(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'short',
        year: 'numeric'
    }).format(date);
}

// Helper function to format datetime
function formatDateTime(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }).format(date);
}

// Helper function to calculate days remaining
function getDaysRemaining(expiryDate) {
    if (!expiryDate) return 0;
    const today = new Date();
    const expiry = new Date(expiryDate);
    const diffTime = expiry - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
}

// Helper function to get membership status
function getMembershipStatus(expiryDate, actualStatus = 'active') {
    // Jika status di database adalah pending, maka tampilkan pending
    if (actualStatus === 'pending') {
        return { status: 'pending', label: 'Pending (Belum Bayar)', class: 'badge-warning' };
    }

    // Jika tidak ada data membership sama sekali
    if (actualStatus === 'none' || !expiryDate) {
        return { status: 'none', label: 'Belum Ada Paket', class: 'badge-danger' };
    }

    const daysRemaining = getDaysRemaining(expiryDate);

    if (daysRemaining < 0 || actualStatus === 'expired') {
        return { status: 'expired', label: 'Expired', class: 'badge-danger' };
    } else if (daysRemaining <= 7) {
        return { status: 'expiring', label: 'Akan Expired', class: 'badge-warning' };
    } else {
        return { status: 'active', label: 'Aktif', class: 'badge-success' };
    }
}

// Helper function to show toast notification
function showToast(message, type = 'info') {
    // Create toast element
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    toast.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 1rem 1.5rem;
        background: ${type === 'success' ? 'var(--success-600)' : type === 'error' ? 'var(--danger-600)' : 'var(--primary-600)'};
        color: white;
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow-xl);
        z-index: 10000;
        animation: slideInRight 0.3s ease-out;
    `;

    document.body.appendChild(toast);

    // Remove after 3 seconds
    setTimeout(() => {
        toast.style.animation = 'slideOutRight 0.3s ease-out';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// Add CSS animations for toast
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInRight {
        from {
            transform: translateX(400px);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOutRight {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(400px);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

// Export for use in other files
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        API_CONFIG,
        getApiUrl,
        formatCurrency,
        formatDate,
        formatDateTime,
        getDaysRemaining,
        getMembershipStatus,
        showToast
    };
}
