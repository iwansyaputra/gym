// Login Page Script
document.addEventListener('DOMContentLoaded', () => {
    // Redirect if already authenticated
    auth.redirectIfAuthenticated();

    // Get form elements
    const loginForm = document.getElementById('loginForm');
    const emailInput = document.getElementById('email');
    const passwordInput = document.getElementById('password');
    const rememberMeCheckbox = document.getElementById('rememberMe');
    const togglePasswordBtn = document.getElementById('togglePassword');
    const loginBtn = document.getElementById('loginBtn');
    const errorMessage = document.getElementById('loginError');

    // Toggle password visibility
    if (togglePasswordBtn) {
        togglePasswordBtn.addEventListener('click', () => {
            const type = passwordInput.type === 'password' ? 'text' : 'password';
            passwordInput.type = type;

            // Update icon (optional)
            const icon = togglePasswordBtn.querySelector('.eye-icon');
            if (type === 'text') {
                icon.innerHTML = '<path d="M12 7C9.24 7 7 9.24 7 12C7 14.76 9.24 17 12 17C14.76 17 17 14.76 17 12C17 9.24 14.76 7 12 7ZM12 15C10.34 15 9 13.66 9 12C9 10.34 10.34 9 12 9C13.66 9 15 10.34 15 12C15 13.66 13.66 15 12 15ZM12 4.5C7 4.5 2.73 7.61 1 12C2.73 16.39 7 19.5 12 19.5C17 19.5 21.27 16.39 23 12C21.27 7.61 17 4.5 12 4.5ZM12 17C9.24 17 7 14.76 7 12C7 9.24 9.24 7 12 7C14.76 7 17 9.24 17 12C17 14.76 14.76 17 12 17Z" fill="currentColor"/>';
            } else {
                icon.innerHTML = '<path d="M12 4.5C7 4.5 2.73 7.61 1 12C2.73 16.39 7 19.5 12 19.5C17 19.5 21.27 16.39 23 12C21.27 7.61 17 4.5 12 4.5ZM12 17C9.24 17 7 14.76 7 12C7 9.24 9.24 7 12 7C14.76 7 17 9.24 17 12C17 14.76 14.76 17 12 17ZM12 9C10.34 9 9 10.34 9 12C9 13.66 10.34 15 12 15C13.66 15 15 13.66 15 12C15 10.34 13.66 9 12 9Z" fill="currentColor"/>';
            }
        });
    }

    // Handle form submission
    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        // Hide previous error
        errorMessage.style.display = 'none';

        // Get form values
        const email = emailInput.value.trim();
        const password = passwordInput.value;
        const rememberMe = rememberMeCheckbox.checked;

        // Validate
        if (!email || !password) {
            showError('Email dan password harus diisi');
            return;
        }

        // Show loading state
        setLoading(true);

        try {
            // Call login API
            const response = await api.login(email, password);

            if (response.success) {
                // Check if user is admin
                if (response.data.user.role !== 'admin') {
                    showError('Akses ditolak. Hanya admin yang dapat login ke dashboard ini.');
                    return;
                }

                // Save token and user data
                auth.saveToken(response.data.token, rememberMe);
                auth.saveUser(response.data.user, rememberMe);

                // Show success message
                showToast('Login berhasil! Mengalihkan...', 'success');

                // Redirect to dashboard
                setTimeout(() => {
                    window.location.href = 'dashboard.html';
                }, 500);
            } else {
                showError(response.message || 'Login gagal');
            }
        } catch (error) {
            console.error('Login error:', error);
            showError(error.message || 'Terjadi kesalahan saat login');
        } finally {
            setLoading(false);
        }
    });

    // Helper function to show error
    function showError(message) {
        errorMessage.textContent = message;
        errorMessage.style.display = 'block';

        // Shake animation
        errorMessage.style.animation = 'shake 0.5s';
        setTimeout(() => {
            errorMessage.style.animation = '';
        }, 500);
    }

    // Helper function to set loading state
    function setLoading(loading) {
        const btnText = loginBtn.querySelector('.btn-text');
        const btnLoader = loginBtn.querySelector('.btn-loader');

        if (loading) {
            btnText.style.display = 'none';
            btnLoader.style.display = 'block';
            loginBtn.disabled = true;
            emailInput.disabled = true;
            passwordInput.disabled = true;
        } else {
            btnText.style.display = 'block';
            btnLoader.style.display = 'none';
            loginBtn.disabled = false;
            emailInput.disabled = false;
            passwordInput.disabled = false;
        }
    }

    // Add shake animation CSS
    const style = document.createElement('style');
    style.textContent = `
        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            10%, 30%, 50%, 70%, 90% { transform: translateX(-10px); }
            20%, 40%, 60%, 80% { transform: translateX(10px); }
        }
    `;
    document.head.appendChild(style);
});
