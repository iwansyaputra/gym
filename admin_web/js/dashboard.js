// Dashboard Page Script
document.addEventListener('DOMContentLoaded', async () => {
    // Check authentication
    if (!auth.requireAuth()) return;

    // Initialize charts first (empty), then load data
    initializeCharts();
    setupEventListeners();

    // Load all dashboard data from the same DB as transactions/reports
    await loadDashboardData();
});

// ===== LOAD DASHBOARD DATA =====
async function loadDashboardData() {
    try {
        showLoading(true);

        // Ambil data dari endpoint yang sama dengan transactions.html & reports.html
        const [transactionsRes, usersRes, checkinsRes] = await Promise.allSettled([
            api.getAllTransactions(),
            api.getAllUsers(),
            api.getAllCheckIns({ limit: 10 })
        ]);

        const transactions = (transactionsRes.status === 'fulfilled' && transactionsRes.value.success)
            ? transactionsRes.value.data || []
            : [];

        const users = (usersRes.status === 'fulfilled' && usersRes.value.success)
            ? usersRes.value.data || []
            : [];

        const checkins = (checkinsRes.status === 'fulfilled' && checkinsRes.value.success)
            ? checkinsRes.value.data || []
            : [];

        // Hitung stats dari data real
        const stats = calculateStats(transactions, users, checkins);

        // Update tampilan
        updateStatCards(stats);
        updateCheckinChart(checkins);
        updateRevenueChart(transactions);
        renderRecentActivity(checkins, transactions);

    } catch (error) {
        console.error('Error loading dashboard:', error);
        showToast('Gagal memuat data dashboard', 'error');
    } finally {
        showLoading(false);
    }
}

// ===== HITUNG STATISTIK DARI DATA REAL =====
function calculateStats(transactions, users, checkins) {
    // Total member
    const totalMembers = users.length;

    // Check-in hari ini
    const today = new Date().toDateString();
    const todayCheckins = checkins.filter(c => {
        const checkinDate = new Date(c.check_in_time || c.created_at).toDateString();
        return checkinDate === today;
    }).length;

    // Pendapatan bulan ini (dari transaksi success)
    const now = new Date();
    const thisMonth = now.getMonth();
    const thisYear = now.getFullYear();

    const monthlyRevenue = transactions
        .filter(t => {
            if (t.status !== 'success') return false;
            const tDate = new Date(t.tanggal_transaksi || t.created_at);
            return tDate.getMonth() === thisMonth && tDate.getFullYear() === thisYear;
        })
        .reduce((sum, t) => sum + parseFloat(t.jumlah || t.amount || 0), 0);

    // Member yang akan expired dalam 7 hari
    const expiringMembers = users.filter(m => {
        const days = getDaysRemaining(m.membership_expiry);
        return days >= 0 && days <= 7;
    }).length;

    // Hitung pertumbuhan member bulan ini vs bulan lalu
    const lastMonth = thisMonth === 0 ? 11 : thisMonth - 1;
    const lastMonthYear = thisMonth === 0 ? thisYear - 1 : thisYear;

    const thisMonthNewMembers = users.filter(u => {
        const d = new Date(u.created_at);
        return d.getMonth() === thisMonth && d.getFullYear() === thisYear;
    }).length;
    const lastMonthNewMembers = users.filter(u => {
        const d = new Date(u.created_at);
        return d.getMonth() === lastMonth && d.getFullYear() === lastMonthYear;
    }).length;

    const memberGrowthPct = lastMonthNewMembers > 0
        ? Math.round(((thisMonthNewMembers - lastMonthNewMembers) / lastMonthNewMembers) * 100)
        : (thisMonthNewMembers > 0 ? 100 : 0);

    // Hitung pertumbuhan revenue bulan ini vs bulan lalu
    const lastMonthRevenue = transactions
        .filter(t => {
            if (t.status !== 'success') return false;
            const tDate = new Date(t.tanggal_transaksi || t.created_at);
            return tDate.getMonth() === lastMonth && tDate.getFullYear() === lastMonthYear;
        })
        .reduce((sum, t) => sum + parseFloat(t.jumlah || t.amount || 0), 0);

    const revenueGrowthPct = lastMonthRevenue > 0
        ? Math.round(((monthlyRevenue - lastMonthRevenue) / lastMonthRevenue) * 100)
        : (monthlyRevenue > 0 ? 100 : 0);

    return {
        totalMembers,
        todayCheckins,
        monthlyRevenue,
        expiringMembers,
        memberGrowthPct,
        revenueGrowthPct
    };
}

// ===== UPDATE STAT CARDS =====
function updateStatCards(stats) {
    const totalMembersEl = document.getElementById('totalMembers');
    if (totalMembersEl) animateValue(totalMembersEl, 0, stats.totalMembers, 1000);

    const todayCheckinsEl = document.getElementById('todayCheckins');
    if (todayCheckinsEl) animateValue(todayCheckinsEl, 0, stats.todayCheckins, 1000);

    const monthlyRevenueEl = document.getElementById('monthlyRevenue');
    if (monthlyRevenueEl) monthlyRevenueEl.textContent = formatCurrency(stats.monthlyRevenue);

    const expiringMembersEl = document.getElementById('expiringMembers');
    if (expiringMembersEl) animateValue(expiringMembersEl, 0, stats.expiringMembers, 1000);

    // Growth indicators (dari data real)
    const memberGrowthEl = document.getElementById('memberGrowth');
    if (memberGrowthEl) {
        const sign = stats.memberGrowthPct >= 0 ? '+' : '';
        memberGrowthEl.textContent = `${sign}${stats.memberGrowthPct}%`;
    }

    const revenueGrowthEl = document.getElementById('revenueGrowth');
    if (revenueGrowthEl) {
        const sign = stats.revenueGrowthPct >= 0 ? '+' : '';
        revenueGrowthEl.textContent = `${sign}${stats.revenueGrowthPct}%`;
    }
}

// ===== ANIMATE NUMBER =====
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

// ===== CHART CHECK-IN (dari data checkins real) =====
function updateCheckinChart(checkins) {
    if (!checkinChart) return;

    // Group check-in per hari dalam 7 hari terakhir
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const dayLabels = [];
    const dayCounts = [];

    for (let i = 6; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const dayName = days[d.getDay()];
        const dateStr = d.toDateString();

        const count = checkins.filter(c => {
            return new Date(c.check_in_time || c.created_at).toDateString() === dateStr;
        }).length;

        dayLabels.push(dayName);
        dayCounts.push(count);
    }

    checkinChart.data.labels = dayLabels;
    checkinChart.data.datasets[0].data = dayCounts;
    checkinChart.update();
}

// ===== CHART REVENUE (dari data transaksi real) =====
function updateRevenueChart(transactions) {
    if (!revenueChart) return;

    // Group pendapatan per bulan, 6 bulan terakhir
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    const labels = [];
    const revenues = [];
    const now = new Date();

    for (let i = 5; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const month = d.getMonth();
        const year = d.getFullYear();

        labels.push(monthNames[month]);

        const monthRevenue = transactions
            .filter(t => {
                if (t.status !== 'success') return false;
                const tDate = new Date(t.tanggal_transaksi || t.created_at);
                return tDate.getMonth() === month && tDate.getFullYear() === year;
            })
            .reduce((sum, t) => sum + parseFloat(t.jumlah || t.amount || 0), 0);

        revenues.push(monthRevenue);
    }

    revenueChart.data.labels = labels;
    revenueChart.data.datasets[0].data = revenues;
    revenueChart.update();
}

// ===== RENDER RECENT ACTIVITY =====
function renderRecentActivity(checkins, transactions) {
    const activityList = document.getElementById('recentActivity');
    if (!activityList) return;

    // Gabungkan check-in terbaru dengan transaksi terbaru
    const activities = [];

    // Ambil 5 check-in terbaru
    const recentCheckins = [...checkins]
        .sort((a, b) => new Date(b.check_in_time || b.created_at) - new Date(a.check_in_time || a.created_at))
        .slice(0, 5)
        .map(c => ({
            type: 'checkin',
            name: c.user_name || 'Member',
            time: c.check_in_time || c.created_at,
            label: 'melakukan check-in'
        }));

    // Ambil 5 transaksi terbaru (hanya success)
    const recentTx = [...transactions]
        .filter(t => t.status === 'success')
        .sort((a, b) => new Date(b.tanggal_transaksi || b.created_at) - new Date(a.tanggal_transaksi || a.created_at))
        .slice(0, 5)
        .map(t => ({
            type: 'transaction',
            name: t.user_name || 'Member',
            time: t.tanggal_transaksi || t.created_at,
            label: `membeli paket ${t.package_name || ''}`,
            amount: t.jumlah || t.amount
        }));

    // Gabungkan & urutkan berdasarkan waktu terbaru
    activities.push(...recentCheckins, ...recentTx);
    activities.sort((a, b) => new Date(b.time) - new Date(a.time));

    const top5 = activities.slice(0, 8);

    if (top5.length === 0) {
        activityList.innerHTML = '<p class="text-muted text-center">Belum ada aktivitas</p>';
        return;
    }

    activityList.innerHTML = top5.map(act => {
        const iconPath = act.type === 'checkin'
            ? 'M12 12C14.21 12 16 10.21 16 8C16 5.79 14.21 4 12 4C9.79 4 8 5.79 8 8C8 10.21 9.79 12 12 12ZM12 14C9.33 14 4 15.34 4 18V20H20V18C20 15.34 14.67 14 12 14Z'
            : 'M11.8 10.9C9.53 10.31 8.8 9.7 8.8 8.75C8.8 7.66 9.81 6.9 11.5 6.9C13.28 6.9 13.94 7.75 14 9H16.21C16.14 7.28 15.09 5.7 13 5.19V3H10V5.16C8.06 5.58 6.5 6.84 6.5 8.77C6.5 11.08 8.41 12.23 11.2 12.9C13.7 13.5 14.2 14.38 14.2 15.31C14.2 16 13.71 17.1 11.5 17.1C9.44 17.1 8.63 16.18 8.52 15H6.32C6.44 17.19 8.08 18.42 10 18.83V21H13V18.85C14.95 18.48 16.5 17.35 16.5 15.3C16.5 12.46 14.07 11.49 11.8 10.9Z';

        const iconColor = act.type === 'checkin' ? 'activity-icon-checkin' : 'activity-icon-transaction';
        const amountStr = act.amount ? ` • ${formatCurrency(act.amount)}` : '';

        return `
            <div class="activity-item">
                <div class="activity-icon ${iconColor}">
                    <svg viewBox="0 0 24 24" fill="none">
                        <path d="${iconPath}" fill="currentColor"/>
                    </svg>
                </div>
                <div class="activity-content">
                    <div class="activity-title"><strong>${act.name}</strong> ${act.label}${amountStr}</div>
                    <div class="activity-time">${formatDateTime(act.time)}</div>
                </div>
            </div>
        `;
    }).join('');
}

// ===== INITIALIZE CHARTS =====
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
                plugins: { legend: { display: false } },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: 'rgba(255, 255, 255, 0.1)' },
                        ticks: { color: '#cbd5e1' }
                    },
                    x: {
                        grid: { display: false },
                        ticks: { color: '#cbd5e1' }
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
                plugins: { legend: { display: false } },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: 'rgba(255, 255, 255, 0.1)' },
                        ticks: {
                            color: '#cbd5e1',
                            callback: function (value) {
                                return 'Rp ' + (value / 1000000).toFixed(1) + 'jt';
                            }
                        }
                    },
                    x: {
                        grid: { display: false },
                        ticks: { color: '#cbd5e1' }
                    }
                }
            }
        });
    }
}

// ===== SETUP EVENT LISTENERS =====
function setupEventListeners() {
    // Week filter untuk chart check-in
    const weekFilter = document.getElementById('weekFilter');
    if (weekFilter) {
        weekFilter.addEventListener('change', async (e) => {
            try {
                const period = e.target.value;
                const res = await api.getAllCheckIns({ period });
                if (res.success && res.data) {
                    updateCheckinChart(res.data);
                }
            } catch (error) {
                console.error('Error updating checkin chart:', error);
            }
        });
    }

    // Revenue filter
    const revenueFilter = document.getElementById('revenueFilter');
    if (revenueFilter) {
        revenueFilter.addEventListener('change', async (e) => {
            try {
                const months = e.target.value === '12months' ? 12 : 6;
                const res = await api.getAllTransactions();
                if (res.success && res.data) {
                    updateRevenueChartWithMonths(res.data, months);
                }
            } catch (error) {
                console.error('Error updating revenue chart:', error);
            }
        });
    }
}

// Revenue chart dengan jumlah bulan dinamis
function updateRevenueChartWithMonths(transactions, months) {
    if (!revenueChart) return;

    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    const labels = [];
    const revenues = [];
    const now = new Date();

    for (let i = months - 1; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const month = d.getMonth();
        const year = d.getFullYear();

        labels.push(monthNames[month]);

        const monthRevenue = transactions
            .filter(t => {
                if (t.status !== 'success') return false;
                const tDate = new Date(t.tanggal_transaksi || t.created_at);
                return tDate.getMonth() === month && tDate.getFullYear() === year;
            })
            .reduce((sum, t) => sum + parseFloat(t.jumlah || t.amount || 0), 0);

        revenues.push(monthRevenue);
    }

    revenueChart.data.labels = labels;
    revenueChart.data.datasets[0].data = revenues;
    revenueChart.update();
}

// ===== SHOW/HIDE LOADING =====
function showLoading(show) {
    const skeletons = document.querySelectorAll('.skeleton-row, .skeleton');
    skeletons.forEach(skeleton => {
        skeleton.style.display = show ? 'block' : 'none';
    });
}
