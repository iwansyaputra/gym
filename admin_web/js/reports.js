// Reports Page Script
document.addEventListener('DOMContentLoaded', async () => {
    if (!auth.requireAuth()) return;

    let financialChart, packageChart, memberGrowthChart, genderChart;

    // Initialize
    setupTabs();
    setupEventListeners();
    initializeCharts();

    // Setup tabs
    function setupTabs() {
        const tabBtns = document.querySelectorAll('.tab-btn');
        const tabContents = document.querySelectorAll('.tab-content');

        tabBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                const tabName = btn.dataset.tab;

                // Remove active class from all
                tabBtns.forEach(b => b.classList.remove('active'));
                tabContents.forEach(c => c.classList.remove('active'));

                // Add active class to clicked
                btn.classList.add('active');
                document.getElementById(`${tabName}-tab`).classList.add('active');
            });
        });
    }

    // Setup event listeners
    function setupEventListeners() {
        // Financial report period
        const financialPeriod = document.getElementById('financialPeriod');
        if (financialPeriod) {
            financialPeriod.addEventListener('change', (e) => {
                const customDateRange = document.getElementById('customDateRange');
                if (customDateRange) {
                    customDateRange.style.display = e.target.value === 'custom' ? 'block' : 'none';
                }
            });
        }

        // Generate financial report
        const generateFinancialBtn = document.getElementById('generateFinancialReport');
        if (generateFinancialBtn) {
            generateFinancialBtn.addEventListener('click', generateFinancialReport);
        }

        // Generate member report
        const generateMemberBtn = document.getElementById('generateMemberReport');
        if (generateMemberBtn) {
            generateMemberBtn.addEventListener('click', generateMemberReport);
        }

        // Export PDF buttons
        const exportFinancialPdf = document.getElementById('exportFinancialPdf');
        const exportMemberPdf = document.getElementById('exportMemberPdf');

        if (exportFinancialPdf) {
            exportFinancialPdf.addEventListener('click', () => exportToPDF('financial'));
        }

        if (exportMemberPdf) {
            exportMemberPdf.addEventListener('click', () => exportToPDF('member'));
        }
    }

    // Initialize charts
    function initializeCharts() {
        // Financial Revenue Chart
        const revenueCtx = document.getElementById('revenueChartReport');
        if (revenueCtx) {
            financialChart = new Chart(revenueCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Pendapatan',
                        data: [],
                        borderColor: 'rgb(14, 165, 233)',
                        backgroundColor: 'rgba(14, 165, 233, 0.1)',
                        tension: 0.4,
                        fill: true
                    }]
                },
                options: getChartOptions('currency')
            });
        }

        // Package Distribution Chart
        const packageCtx = document.getElementById('packageDistChart');
        if (packageCtx) {
            packageChart = new Chart(packageCtx, {
                type: 'doughnut',
                data: {
                    labels: [],
                    datasets: [{
                        data: [],
                        backgroundColor: [
                            'rgba(14, 165, 233, 0.8)',
                            'rgba(168, 85, 247, 0.8)',
                            'rgba(34, 197, 94, 0.8)',
                            'rgba(245, 158, 11, 0.8)'
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: {
                                color: '#cbd5e1',
                                padding: 15
                            }
                        }
                    }
                }
            });
        }

        // Member Growth Chart
        const memberGrowthCtx = document.getElementById('memberGrowthChart');
        if (memberGrowthCtx) {
            memberGrowthChart = new Chart(memberGrowthCtx, {
                type: 'bar',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Member Baru',
                        data: [],
                        backgroundColor: 'rgba(34, 197, 94, 0.8)',
                        borderColor: 'rgb(34, 197, 94)',
                        borderWidth: 1
                    }]
                },
                options: getChartOptions('number')
            });
        }

        // Gender Distribution Chart
        const genderCtx = document.getElementById('genderDistChart');
        if (genderCtx) {
            genderChart = new Chart(genderCtx, {
                type: 'pie',
                data: {
                    labels: ['Laki-laki', 'Perempuan'],
                    datasets: [{
                        data: [0, 0],
                        backgroundColor: [
                            'rgba(14, 165, 233, 0.8)',
                            'rgba(168, 85, 247, 0.8)'
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: {
                                color: '#cbd5e1',
                                padding: 15
                            }
                        }
                    }
                }
            });
        }
    }

    // Get chart options
    function getChartOptions(type) {
        return {
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
                            if (type === 'currency') {
                                return 'Rp ' + (value / 1000000) + 'jt';
                            }
                            return value;
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
        };
    }

    // Generate financial report
    async function generateFinancialReport() {
        try {
            const period = document.getElementById('financialPeriod').value;
            let startDate, endDate;

            if (period === 'custom') {
                startDate = document.getElementById('financialStartDate').value;
                endDate = document.getElementById('financialEndDate').value;
            }

            const response = await api.getAllTransactions({ period, startDate, endDate });

            if (response.success && response.data) {
                const transactions = response.data;

                // Update summary
                const successTransactions = transactions.filter(t => t.status === 'success');
                const totalIncome = successTransactions.reduce((sum, t) => sum + parseFloat(t.amount || 0), 0);
                const avgTransaction = successTransactions.length > 0 ? totalIncome / successTransactions.length : 0;
                const newMembers = new Set(successTransactions.map(t => t.user_id)).size;

                document.getElementById('totalIncome').textContent = formatCurrency(totalIncome);
                document.getElementById('transactionCount').textContent = successTransactions.length;
                document.getElementById('avgTransaction').textContent = formatCurrency(avgTransaction);
                document.getElementById('newMembers').textContent = newMembers;

                // Update revenue chart
                updateFinancialChart(transactions);

                // Update package distribution
                updatePackageChart(transactions);

                // Update table
                updateFinancialTable(transactions);

                showToast('Laporan berhasil di-generate', 'success');
            }
        } catch (error) {
            console.error('Error generating financial report:', error);
            showToast('Gagal generate laporan', 'error');
        }
    }

    // Update financial chart
    function updateFinancialChart(transactions) {
        if (!financialChart) return;

        // Group by date
        const groupedByDate = {};
        transactions.forEach(t => {
            if (t.status === 'success') {
                const date = new Date(t.created_at).toLocaleDateString('id-ID', { day: '2-digit', month: 'short' });
                groupedByDate[date] = (groupedByDate[date] || 0) + parseFloat(t.amount || 0);
            }
        });

        financialChart.data.labels = Object.keys(groupedByDate);
        financialChart.data.datasets[0].data = Object.values(groupedByDate);
        financialChart.update();
    }

    // Update package chart
    function updatePackageChart(transactions) {
        if (!packageChart) return;

        // Group by package
        const groupedByPackage = {};
        transactions.forEach(t => {
            if (t.status === 'success') {
                const pkg = t.package_name || 'Unknown';
                groupedByPackage[pkg] = (groupedByPackage[pkg] || 0) + 1;
            }
        });

        packageChart.data.labels = Object.keys(groupedByPackage);
        packageChart.data.datasets[0].data = Object.values(groupedByPackage);
        packageChart.update();
    }

    // Update financial table
    function updateFinancialTable(transactions) {
        const tbody = document.getElementById('financialTableBody');
        if (!tbody) return;

        if (transactions.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="text-center">Tidak ada data</td></tr>';
            return;
        }

        tbody.innerHTML = transactions.map(t => `
            <tr>
                <td>${formatDate(t.created_at)}</td>
                <td>${t.id}</td>
                <td>${t.user_name || '-'}</td>
                <td>${t.package_name || '-'}</td>
                <td>${t.payment_method || '-'}</td>
                <td>${formatCurrency(t.amount)}</td>
            </tr>
        `).join('');
    }

    // Generate member report
    async function generateMemberReport() {
        try {
            const reportType = document.getElementById('memberReportType').value;
            const period = document.getElementById('memberPeriod').value;

            const response = await api.getAllUsers({ reportType, period });

            if (response.success && response.data) {
                const members = response.data;

                // Calculate stats
                const totalMembers = members.length;
                const activeMembers = members.filter(m => {
                    const days = getDaysRemaining(m.membership_expiry);
                    return days > 0;
                }).length;
                const expiringMembers = members.filter(m => {
                    const days = getDaysRemaining(m.membership_expiry);
                    return days >= 0 && days <= 7;
                }).length;
                const expiredMembers = members.filter(m => {
                    const days = getDaysRemaining(m.membership_expiry);
                    return days < 0;
                }).length;

                // Update summary
                document.getElementById('totalMembersReport').textContent = totalMembers;
                document.getElementById('activeMembersReport').textContent = activeMembers;
                document.getElementById('expiringMembersReport').textContent = expiringMembers;
                document.getElementById('expiredMembersReport').textContent = expiredMembers;

                // Update charts
                updateMemberGrowthChart(members);
                updateGenderChart(members);

                // Update table
                updateMemberTable(members);

                showToast('Laporan berhasil di-generate', 'success');
            }
        } catch (error) {
            console.error('Error generating member report:', error);
            showToast('Gagal generate laporan', 'error');
        }
    }

    // Update member growth chart
    function updateMemberGrowthChart(members) {
        if (!memberGrowthChart) return;

        // Group by month
        const groupedByMonth = {};
        members.forEach(m => {
            const month = new Date(m.created_at).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' });
            groupedByMonth[month] = (groupedByMonth[month] || 0) + 1;
        });

        memberGrowthChart.data.labels = Object.keys(groupedByMonth);
        memberGrowthChart.data.datasets[0].data = Object.values(groupedByMonth);
        memberGrowthChart.update();
    }

    // Update gender chart
    function updateGenderChart(members) {
        if (!genderChart) return;

        const maleCount = members.filter(m => m.gender === 'Laki-laki').length;
        const femaleCount = members.filter(m => m.gender === 'Perempuan').length;

        genderChart.data.datasets[0].data = [maleCount, femaleCount];
        genderChart.update();
    }

    // Update member table
    function updateMemberTable(members) {
        const tbody = document.getElementById('memberReportTableBody');
        if (!tbody) return;

        if (members.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7" class="text-center">Tidak ada data</td></tr>';
            return;
        }

        tbody.innerHTML = members.map(m => {
            const status = getMembershipStatus(m.membership_expiry);
            return `
                <tr>
                    <td>${m.id}</td>
                    <td>${m.name || '-'}</td>
                    <td>${m.email || '-'}</td>
                    <td>${m.package_name || '-'}</td>
                    <td><span class="badge ${status.class}">${status.label}</span></td>
                    <td>${formatDate(m.created_at)}</td>
                    <td>${formatDate(m.membership_expiry)}</td>
                </tr>
            `;
        }).join('');
    }

    // Export to PDF
    function exportToPDF(type) {
        try {
            const { jsPDF } = window.jspdf;
            const doc = new jsPDF();

            if (type === 'financial') {
                doc.text('Laporan Keuangan GymKu', 14, 15);
                doc.text(`Tanggal: ${new Date().toLocaleDateString('id-ID')}`, 14, 22);

                // Add summary
                const totalIncome = document.getElementById('totalIncome').textContent;
                const transactionCount = document.getElementById('transactionCount').textContent;

                doc.text(`Total Pendapatan: ${totalIncome}`, 14, 35);
                doc.text(`Jumlah Transaksi: ${transactionCount}`, 14, 42);

                // Add table
                const table = document.getElementById('financialTable');
                if (table) {
                    doc.autoTable({ html: table, startY: 50 });
                }
            } else {
                doc.text('Laporan Member GymKu', 14, 15);
                doc.text(`Tanggal: ${new Date().toLocaleDateString('id-ID')}`, 14, 22);

                // Add summary
                const totalMembers = document.getElementById('totalMembersReport').textContent;
                const activeMembers = document.getElementById('activeMembersReport').textContent;

                doc.text(`Total Member: ${totalMembers}`, 14, 35);
                doc.text(`Member Aktif: ${activeMembers}`, 14, 42);

                // Add table
                const table = document.getElementById('memberReportTable');
                if (table) {
                    doc.autoTable({ html: table, startY: 50 });
                }
            }

            doc.save(`laporan_${type}_${new Date().toISOString().split('T')[0]}.pdf`);
            showToast('PDF berhasil diunduh', 'success');
        } catch (error) {
            console.error('Error exporting PDF:', error);
            showToast('Gagal export PDF', 'error');
        }
    }
});
