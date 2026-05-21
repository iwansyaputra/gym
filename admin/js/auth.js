// Authentication Manager
class AuthManager {
    constructor() {
        this.token = this.getToken();
        this.user = this.getUser();
    }

    // Save token to storage
    saveToken(token, rememberMe = false) {
        if (rememberMe) {
            localStorage.setItem(API_CONFIG.STORAGE_KEYS.TOKEN, token);
            localStorage.setItem(API_CONFIG.STORAGE_KEYS.REMEMBER_ME, 'true');
        } else {
            sessionStorage.setItem(API_CONFIG.STORAGE_KEYS.TOKEN, token);
        }
        this.token = token;
    }

    // Get token from storage
    getToken() {
        return localStorage.getItem(API_CONFIG.STORAGE_KEYS.TOKEN) ||
            sessionStorage.getItem(API_CONFIG.STORAGE_KEYS.TOKEN);
    }

    // Save user data to storage
    saveUser(user, rememberMe = false) {
        const userData = JSON.stringify(user);
        if (rememberMe) {
            localStorage.setItem(API_CONFIG.STORAGE_KEYS.USER, userData);
        } else {
            sessionStorage.setItem(API_CONFIG.STORAGE_KEYS.USER, userData);
        }
        this.user = user;
    }

    // Get user data from storage
    getUser() {
        const userData = localStorage.getItem(API_CONFIG.STORAGE_KEYS.USER) ||
            sessionStorage.getItem(API_CONFIG.STORAGE_KEYS.USER);
        return userData ? JSON.parse(userData) : null;
    }

    // Check if user is authenticated
    isAuthenticated() {
        return !!this.token && !!this.user;
    }

    // Logout
    logout() {
        localStorage.removeItem(API_CONFIG.STORAGE_KEYS.TOKEN);
        localStorage.removeItem(API_CONFIG.STORAGE_KEYS.USER);
        localStorage.removeItem(API_CONFIG.STORAGE_KEYS.REMEMBER_ME);
        sessionStorage.removeItem(API_CONFIG.STORAGE_KEYS.TOKEN);
        sessionStorage.removeItem(API_CONFIG.STORAGE_KEYS.USER);
        this.token = null;
        this.user = null;
        window.location.href = 'index.html';
    }

    // Get authorization header
    getAuthHeader() {
        return this.token ? { 'Authorization': `Bearer ${this.token}` } : {};
    }

    // Check if user is admin (you can customize this logic)
    isAdmin() {
        // For now, we'll assume all authenticated users are admins
        // You can add role checking here if your API supports it
        return this.isAuthenticated();
    }

    // Redirect to login if not authenticated
    requireAuth() {
        if (!this.isAuthenticated()) {
            window.location.href = 'index.html';
            return false;
        }
        return true;
    }

    // Redirect to dashboard if already authenticated
    redirectIfAuthenticated() {
        if (this.isAuthenticated()) {
            window.location.href = 'dashboard.html';
        }
    }
}

// Create global auth instance
const auth = new AuthManager();

// Setup logout buttons on all pages
document.addEventListener('DOMContentLoaded', () => {
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', (e) => {
            e.preventDefault();
            if (confirm('Apakah Anda yakin ingin logout?')) {
                auth.logout();
            }
        });
    }

    // Display admin name if element exists
    const adminNameElements = document.querySelectorAll('#adminName');
    if (adminNameElements.length > 0 && auth.user) {
        adminNameElements.forEach(el => {
            el.textContent = auth.user.name || auth.user.email || 'Admin';
        });
    }

    // Setup menu toggle for mobile
    const menuToggle = document.getElementById('menuToggle');
    const sidebar = document.getElementById('sidebar');
    if (menuToggle && sidebar) {
        menuToggle.addEventListener('click', () => {
            sidebar.classList.toggle('active');
        });

        // Close sidebar when clicking outside on mobile
        document.addEventListener('click', (e) => {
            if (window.innerWidth <= 768) {
                if (!sidebar.contains(e.target) && !menuToggle.contains(e.target)) {
                    sidebar.classList.remove('active');
                }
            }
        });
    }
});

// Export for use in other files
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { AuthManager, auth };
}
