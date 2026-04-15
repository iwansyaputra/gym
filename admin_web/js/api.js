// API Client
class ApiClient {
    constructor() {
        this.baseUrl = API_CONFIG.BASE_URL;
        this.timeout = API_CONFIG.TIMEOUT;
    }

    // Generic request method
    async request(endpoint, options = {}) {
        const url = this.baseUrl + endpoint;
        const headers = {
            'Content-Type': 'application/json',
            ...auth.getAuthHeader(),
            ...options.headers
        };

        const config = {
            method: options.method || 'GET',
            headers,
            ...options
        };

        if (options.body && typeof options.body === 'object') {
            config.body = JSON.stringify(options.body);
        }

        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), this.timeout);

            const response = await fetch(url, {
                ...config,
                signal: controller.signal
            });

            clearTimeout(timeoutId);

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.message || 'Request failed');
            }

            return data;
        } catch (error) {
            if (error.name === 'AbortError') {
                throw new Error('Request timeout');
            }

            // Debug log for failed fetch URL
            console.error('Fetch failed:', url, error);

            // Handle unauthorized
            if (error.message.includes('401') || error.message.includes('Unauthorized')) {
                auth.logout();
            }

            throw error;
        }
    }

    // GET request
    async get(endpoint, params = {}) {
        const queryString = new URLSearchParams(params).toString();
        const url = queryString ? `${endpoint}?${queryString}` : endpoint;
        return this.request(url, { method: 'GET' });
    }

    // POST request
    async post(endpoint, body = {}) {
        return this.request(endpoint, {
            method: 'POST',
            body
        });
    }

    // PUT request
    async put(endpoint, body = {}) {
        return this.request(endpoint, {
            method: 'PUT',
            body
        });
    }

    // DELETE request
    async delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    }

    // Auth endpoints
    async login(email, password) {
        return this.post(API_CONFIG.ENDPOINTS.LOGIN, { email, password });
    }

    async register(userData) {
        return this.post(API_CONFIG.ENDPOINTS.REGISTER, userData);
    }

    // User endpoints
    async getProfile() {
        return this.get(API_CONFIG.ENDPOINTS.PROFILE);
    }

    async updateProfile(userData) {
        return this.put(API_CONFIG.ENDPOINTS.UPDATE_PROFILE, userData);
    }

    async getAllUsers(params = {}) {
        return this.get('/admin/users', params);
    }

    async deleteUser(userId) {
        return this.delete(`/admin/users/${userId}`);
    }

    // Check-in endpoints
    async checkInNFC(nfcId) {
        return this.post(API_CONFIG.ENDPOINTS.CHECKIN_NFC, { nfc_id: nfcId });
    }

    async getCheckInHistory(params = {}) {
        return this.get(API_CONFIG.ENDPOINTS.CHECKIN_HISTORY, params);
    }

    async getCheckInStats(params = {}) {
        return this.get(API_CONFIG.ENDPOINTS.CHECKIN_STATS, params);
    }

    // Membership endpoints
    async getMembershipInfo(userId) {
        return this.get(`${API_CONFIG.ENDPOINTS.MEMBERSHIP_INFO}/${userId}`);
    }

    async getMembershipPackages() {
        return this.get(API_CONFIG.ENDPOINTS.MEMBERSHIP_PACKAGES);
    }

    async extendMembership(packageId) {
        return this.post(API_CONFIG.ENDPOINTS.EXTEND_MEMBERSHIP, { package_id: packageId });
    }

    // Transaction endpoints
    async getTransactions(params = {}) {
        return this.get(API_CONFIG.ENDPOINTS.TRANSACTIONS_HISTORY, params);
    }

    async getAllTransactions(params = {}) {
        return this.get('/admin/transactions', params);
    }

    async getAllCheckIns(params = {}) {
        return this.get('/admin/checkins', params);
    }

    async getRevenueStats(params = {}) {
        return this.get('/admin/revenue/stats', params);
    }

    async getTransactionDetail(transactionId) {
        return this.get(`${API_CONFIG.ENDPOINTS.TRANSACTION_DETAIL}/${transactionId}`);
    }

    async createTransaction(transactionData) {
        return this.post(API_CONFIG.ENDPOINTS.CREATE_TRANSACTION, transactionData);
    }

    // Payment endpoints
    async createPayment(paymentData) {
        return this.post(API_CONFIG.ENDPOINTS.CREATE_PAYMENT, paymentData);
    }

    async getPaymentStatus(paymentId) {
        return this.get(`${API_CONFIG.ENDPOINTS.PAYMENT_STATUS}/${paymentId}`);
    }

    async getPaymentHistory(params = {}) {
        return this.get(API_CONFIG.ENDPOINTS.PAYMENT_HISTORY, params);
    }

    // Promo endpoints
    async getPromos() {
        return this.get(API_CONFIG.ENDPOINTS.GET_PROMOS);
    }

    async getPromo(promoId) {
        return this.get(`${API_CONFIG.ENDPOINTS.GET_PROMO}/${promoId}`);
    }

    // Dashboard stats (you might need to create these endpoints)
    async getDashboardStats() {
        try {
            // Use the new admin dashboard stats endpoint
            const response = await this.get(API_CONFIG.ENDPOINTS.DASHBOARD_STATS);

            if (response.success) {
                return response.data;
            }

            // Fallback to manual calculation if endpoint not available
            const [members, checkins, transactions] = await Promise.all([
                this.getAllUsers(),
                this.getCheckInStats({ period: 'today' }),
                this.getTransactions({ period: 'month' })
            ]);

            return {
                totalMembers: members.data?.length || 0,
                todayCheckins: checkins.data?.today || 0,
                monthlyRevenue: transactions.data?.total || 0,
                expiringMembers: members.data?.filter(m => {
                    const days = getDaysRemaining(m.membership_expiry);
                    return days >= 0 && days <= 7;
                }).length || 0
            };
        } catch (error) {
            console.error('Error fetching dashboard stats:', error);
            return {
                totalMembers: 0,
                todayCheckins: 0,
                monthlyRevenue: 0,
                expiringMembers: 0
            };
        }
    }
}

// Create global API client instance
const api = new ApiClient();

// Export for use in other files
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ApiClient, api };
}
