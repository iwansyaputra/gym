// Dashboard Page Script
document.addEventListener('DOMContentLoaded', async () => {
    // Check authentication
    if (!auth.requireAuth()) return;

    // Initialize dashboard
    await loadDashboardData();
    initializeCharts();

    // Setup event listeners
    setupEventListeners();
});

// Load dashboard data
async function loadDashboardData() {
    try {
        // Show loading skeletons
        showLoading(true);

        // Fetch dashboard stats
        const stats = await api.getDashboardStats();

        // Update stat cards
        updateStatCards(stats);

        // Load recent activity
        await loadRecentActivity();

        // Load chart data
        await loadChartData();

    } catch (error) {
        console.error('Error loading dashboard:', error);
        showToast('Gagal memuat data dashboard', 'error');
    } finally {
        showLoading(false);
    }
}

// Update stat cards
function updateStatCards(stats) {
    // Total Members
    const totalMembersEl = document.getElementById('totalMembers');
    if (totalMembersEl) {
        animateValue(totalMembersEl, 0, stats.totalMembers, 1000);
    }

    // Today Check-ins
    const todayCheckinsEl = document.getElementById('todayCheckins');
    if (todayCheckinsEl) {
        animateValue(todayCheckinsEl, 0, stats.todayCheckins, 1000);
    }

    // Monthly Revenue
    const monthlyRevenueEl = document.getElementById('monthlyRevenue');
    if (monthlyRevenueEl) {
        monthlyRevenueEl.textContent = formatCurrency(stats.monthlyRevenue);
    }

    // Expiring Members
    const expiringMembersEl = document.getElementById('expiringMembers');
    if (expiringMembersEl) {
        animateValue(expiringMembersEl, 0, stats.expiringMembers, 1000);
    }

    // Update growth percentages (mock data for now)
    const memberGrowthEl = document.getElementById('memberGrowth');
    if (memberGrowthEl) memberGrowthEl.textContent = '+12%';

    const revenueGrowthEl = document.getElementById('revenueGrowth');
    if (revenueGrowthEl) revenueGrowthEl.textContent = '+8%';
}

// Animate number value
function animateValue(element, start, end, duration) {
    const range = end - start;
    const increment = range / (duration / 16);
    let current = start;

    const timer = setInterval(() => {
        current += increment;
        if ((increment > 0 && current >= end) || (increment < 0 && current <= end)) {
            current = end;
            clearInterval(timer);
        }
        element.textContent = Math.floor(current);
    }, 16);
}

// Load recent activity
async function loadRecentActivity() {
    try {
        const response = await api.getAllCheckIns({ limit: 5 });
        const activityList = document.getElementById('recentActivity');

        if (!activityList) return;

        if (response.success && response.data && response.data.length > 0) {
            activityList.innerHTML = response.data.map(activity => `
                <div class="activity-item">
                    <div class="activity-icon">
                        <svg viewBox="0 0 24 24" fill="none">
                            <path d="M12 12C14.21 12 16 10.21 16 8C16 5.79 14.21 4 12 4C9.79 4 8 5.79 8 8C8 10.21 9.79 12 12 12ZM12 14C9.33 14 4 15.34 4 18V20H20V18C20 15.34 14.67 14 12 14Z" fill="currentColor"/>
                        </svg>
                    </div>
                    <div class="activity-content">
                        <div class="activity-title">${activity.user_name || 'Member'} melakukan check-in</div>
                        <div class="activity-time">${formatDateTime(activity.check_in_time)}</div>
                    </div>
                </div>
            `).join('');
        } else {
            activityList.innerHTML = '<p class="text-muted text-center">Belum ada aktivitas</p>';
        }
    } catch (error) {
        console.error('Error loading recent activity:', error);
    }
}

// Initialize charts
let checkinChart, revenueChart;

function initializeCharts() {
    // Check-in Chart
    const checkinCtx = document.getElementById('checkinChart');
    if (checkinCtx) {
        checkinChart = new Chart(checkinCtx, {
            type: 'line',
            data: {
                labels: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
                datasets: [{
                    label: 'Check-in',
                    data: [0, 0, 0, 0, 0, 0, 0],
                    borderColor: 'rgb(14, 165, 233)',
                    backgroundColor: 'rgba(14, 165, 233, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: {
                            color: 'rgba(255, 255, 255, 0.1)'
                        },
                        ticks: {
                            color: '#cbd5e1'
                        }
                    },
                    x: {
                        grid: {
                            display: false
                        },
                        ticks: {
                            color: '#cbd5e1'
                        }
                    }
                }
            }
        });
    }

    // Revenue Chart
    const revenueCtx = document.getElementById('revenueChart');
    if (revenueCtx) {
        revenueChart = new Chart(revenueCtx, {
            type: 'bar',
            data: {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun'],
                datasets: [{
                    label: 'Pendapatan',
                    data: [0, 0, 0, 0, 0, 0],
                    backgroundColor: 'rgba(14, 165, 233, 0.8)',
                    borderColor: 'rgb(14, 165, 233)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: {
                            color: 'rgba(255, 255, 255, 0.1)'
                        },
                        ticks: {
                            color: '#cbd5e1',
                            callback: function (value) {
                                return 'Rp ' + (value / 1000000) + 'jt';
                            }
                        }
                    },
                    x: {
                        grid: {
                            display: false
                        },
                        ticks: {
                            color: '#cbd5e1'
                        }
                    }
                }
            }
        });
    }
}

// Load chart data
async function loadChartData() {
    try {
        // Load check-in data for the week
        const checkinData = await api.getCheckInStats({ period: 'week' });
        if (checkinChart && checkinData.success) {
            const weekData = checkinData.data?.weekly || [12, 19, 15, 25, 22, 30, 28];
            checkinChart.data.datasets[0].data = weekData;
            checkinChart.update();
        }

        // Load revenue data for the last 6 months
        const revenueData = await api.getRevenueStats();
        if (revenueChart && revenueData.success) {
            const monthlyData = revenueData.data?.monthly || [];
            const labels = revenueData.data?.labels || [];

            revenueChart.data.labels = labels;
            revenueChart.data.datasets[0].data = monthlyData;
            revenueChart.update();
        }
    } catch (error) {
        console.error('Error loading chart data:', error);
    }
}

// Setup event listeners
function setupEventListeners() {
    // Week filter for check-in chart
    const weekFilter = document.getElementById('weekFilter');
    if (weekFilter) {
        weekFilter.addEventListener('change', async (e) => {
            const period = e.target.value;
            try {
                const data = await api.getCheckInStats({ period });
                if (checkinChart && data.success) {
                    checkinChart.data.datasets[0].data = data.data?.weekly || [];
                    checkinChart.update();
                }
            } catch (error) {
                console.error('Error updating chart:', error);
            }
        });
    }

    // Revenue filter
    const revenueFilter = document.getElementById('revenueFilter');
    if (revenueFilter) {
        revenueFilter.addEventListener('change', async (e) => {
            const period = e.target.value;
            try {
                const data = await api.getTransactions({ period });
                if (revenueChart && data.success) {
                    revenueChart.data.datasets[0].data = data.data?.monthly || [];
                    revenueChart.update();
                }
            } catch (error) {
                console.error('Error updating chart:', error);
            }
        });
    }
}

// Show/hide loading state
function showLoading(show) {
    const skeletons = document.querySelectorAll('.skeleton-row, .skeleton');
    skeletons.forEach(skeleton => {
        skeleton.style.display = show ? 'block' : 'none';
    });
}
