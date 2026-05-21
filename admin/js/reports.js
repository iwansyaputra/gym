// Reports Page Script
document.addEventListener('DOMContentLoaded', async () => {
    if (!auth.requireAuth()) return;

    let financialChart, packageChart, memberGrowthChart, genderChart;
    let allTransactions = [];
    let allMembers = [];

    // Initialize
    setupTabs();
    setupEventListeners();
    initializeCharts();

    // Auto-load data on page open (sama seperti transactions.js)
    await loadFinancialData();
    await loadMemberData();

    // === AUTO-LOAD FUNCTIONS ===

    async function loadFinancialData() {
        try {
            const response = await api.getAllTransactions();

            if (response.success && response.data) {
                allTransactions = response.data;
                updateFinancialSummary(allTransactions);
                updateFinancialChart(allTransactions);
                updatePackageChart(allTransactions);
                updateFinancialTable(allTransactions);
            }
        } catch (error) {
            console.error('Error loading financial data:', error);
            showToast('Gagal memuat data keuangan', 'error');
        }
    }

    async function loadMemberData() {
        try {
            const response = await api.getAllUsers();

            if (response.success && response.data) {
                allMembers = response.data;
                updateMemberSummary(allMembers);
                updateMemberGrowthChart(allMembers);
                updateGenderChart(allMembers);
                updateMemberTable(allMembers);
            }
        } catch (error) {
            console.error('Error loading member data:', error);
            showToast('Gagal memuat data member', 'error');
        }
    }

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

        const exportMemberIndividualBtn = document.getElementById('exportMemberIndividualBtn');
        if (exportMemberIndividualBtn) {
            exportMemberIndividualBtn.addEventListener('click', openExportMemberModal);
        }

        const closeExportMemberModal = document.getElementById('closeExportMemberModal');
        const cancelExportMemberBtn = document.getElementById('cancelExportMemberBtn');
        const confirmExportMemberBtn = document.getElementById('confirmExportMemberBtn');

        if (closeExportMemberModal) closeExportMemberModal.addEventListener('click', () => { document.getElementById('exportMemberModal').classList.remove('active'); });
        if (cancelExportMemberBtn) cancelExportMemberBtn.addEventListener('click', () => { document.getElementById('exportMemberModal').classList.remove('active'); });
        if (confirmExportMemberBtn) confirmExportMemberBtn.addEventListener('click', exportMemberReportExcel);
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

    // === HELPER: get amount from transaction (support both field names) ===
    function getAmount(t) {
        return parseFloat(t.jumlah || t.amount || 0);
    }

    // === HELPER: get date from transaction (support both field names) ===
    function getTransactionDate(t) {
        return t.tanggal_transaksi || t.created_at;
    }

    // === HELPER: get payment method (support both field names) ===
    function getPaymentMethod(t) {
        return t.metode_pembayaran || t.payment_method || '-';
    }

    // === UPDATE FINANCIAL SUMMARY ===
    function updateFinancialSummary(transactions) {
        const successTransactions = transactions.filter(t => t.status === 'success');
        const totalIncome = successTransactions.reduce((sum, t) => sum + getAmount(t), 0);
        const avgTransaction = successTransactions.length > 0 ? totalIncome / successTransactions.length : 0;
        const newMembers = new Set(successTransactions.map(t => t.user_id)).size;

        document.getElementById('totalIncome').textContent = formatCurrency(totalIncome);
        document.getElementById('transactionCount').textContent = successTransactions.length;
        document.getElementById('avgTransaction').textContent = formatCurrency(avgTransaction);
        document.getElementById('newMembers').textContent = newMembers;
    }

    // Generate financial report (filter by period)
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

                updateFinancialSummary(transactions);
                updateFinancialChart(transactions);
                updatePackageChart(transactions);
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
                const rawDate = getTransactionDate(t);
                const date = new Date(rawDate).toLocaleDateString('id-ID', { day: '2-digit', month: 'short' });
                groupedByDate[date] = (groupedByDate[date] || 0) + getAmount(t);
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
                <td>${formatDate(getTransactionDate(t))}</td>
                <td>${t.id}</td>
                <td>${t.user_name || '-'}</td>
                <td>${t.package_name || '-'}</td>
                <td>${getPaymentMethod(t)}</td>
                <td>${formatCurrency(getAmount(t))}</td>
            </tr>
        `).join('');
    }

    // === UPDATE MEMBER SUMMARY ===
    function updateMemberSummary(members) {
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

        document.getElementById('totalMembersReport').textContent = totalMembers;
        document.getElementById('activeMembersReport').textContent = activeMembers;
        document.getElementById('expiringMembersReport').textContent = expiringMembers;
        document.getElementById('expiredMembersReport').textContent = expiredMembers;
    }

    // Generate member report (filter by type & period)
    async function generateMemberReport() {
        try {
            const reportType = document.getElementById('memberReportType').value;
            const period = document.getElementById('memberPeriod').value;

            const response = await api.getAllUsers({ reportType, period });

            if (response.success && response.data) {
                const members = response.data;

                updateMemberSummary(members);
                updateMemberGrowthChart(members);
                updateGenderChart(members);
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

                const totalIncome = document.getElementById('totalIncome').textContent;
                const transactionCount = document.getElementById('transactionCount').textContent;

                doc.text(`Total Pendapatan: ${totalIncome}`, 14, 35);
                doc.text(`Jumlah Transaksi: ${transactionCount}`, 14, 42);

                const table = document.getElementById('financialTable');
                if (table) doc.autoTable({ html: table, startY: 50 });
            } else {
                doc.text('Laporan Member GymKu', 14, 15);
                doc.text(`Tanggal: ${new Date().toLocaleDateString('id-ID')}`, 14, 22);

                const totalMembers = document.getElementById('totalMembersReport').textContent;
                const activeMembers = document.getElementById('activeMembersReport').textContent;

                doc.text(`Total Member: ${totalMembers}`, 14, 35);
                doc.text(`Member Aktif: ${activeMembers}`, 14, 42);

                const table = document.getElementById('memberReportTable');
                if (table) doc.autoTable({ html: table, startY: 50 });
            }

            doc.save(`laporan_${type}_${new Date().toISOString().split('T')[0]}.pdf`);
            showToast('PDF berhasil diunduh', 'success');
        } catch (error) {
            console.error('Error exporting PDF:', error);
            showToast('Gagal export PDF', 'error');
        }
    }

    // Open Export Member Modal
    async function openExportMemberModal() {
        const modal = document.getElementById('exportMemberModal');
        const select = document.getElementById('exportMemberSelect');
        
        select.innerHTML = '<option value="">Memuat member...</option>';
        modal.classList.add('active');

        try {
            const response = await api.getAllUsers({ limit: 10000 });
            if (response.success && response.data) {
                if (response.data.length === 0) {
                    select.innerHTML = '<option value="">Tidak ada member tersedia</option>';
                    return;
                }
                
                select.innerHTML = '<option value="">-- Pilih Member --</option>' + 
                    response.data.map(u => `<option value="${u.id}">${u.name} (${u.email})</option>`).join('');
            } else {
                select.innerHTML = '<option value="">Gagal memuat member</option>';
            }
        } catch (error) {
            console.error('Error loading members for export:', error);
            select.innerHTML = '<option value="">Gagal memuat member</option>';
            showToast('Gagal memuat daftar member', 'error');
        }
    }

    // Process Member Report Export to Excel
    async function exportMemberReportExcel() {
        const select = document.getElementById('exportMemberSelect');
        const periodSelect = document.getElementById('exportMemberPeriod');
        const userId = select.value;
        const userName = select.options[select.selectedIndex]?.text.split(' (')[0] || 'Member';
        const period = periodSelect ? periodSelect.value : 'all';

        if (!userId) {
            showToast('Pilih member terlebih dahulu', 'warning');
            return;
        }

        try {
            const btn = document.getElementById('confirmExportMemberBtn');
            const originalText = btn.textContent;
            btn.textContent = 'Memproses...';
            btn.disabled = true;

            const response = await api.getMemberFullHistory(userId);
            
            if (response.success && response.data) {
                // Filter based on period
                let data = response.data;
                if (period === 'month') {
                    const now = new Date();
                    const currentMonth = now.getMonth();
                    const currentYear = now.getFullYear();
                    
                    const filterByCurrentMonth = (dateStr) => {
                        const d = new Date(dateStr);
                        return d.getMonth() === currentMonth && d.getFullYear() === currentYear;
                    };

                    data = {
                        checkins: (data.checkins || []).filter(c => filterByCurrentMonth(c.check_in_time)),
                        transactions: (data.transactions || []).filter(t => filterByCurrentMonth(t.tanggal_transaksi)),
                        wallet_history: (data.wallet_history || []).filter(w => filterByCurrentMonth(w.created_at))
                    };
                }

                await generateMemberReportXLSX(userName, data, period);
                document.getElementById('exportMemberModal').classList.remove('active');
                showToast('Laporan berhasil diexport', 'success');
            } else {
                showToast('Gagal mengambil data laporan member', 'error');
            }

            btn.textContent = originalText;
            btn.disabled = false;
        } catch (error) {
            console.error('Error exporting member report:', error);
            showToast('Terjadi kesalahan saat mengexport laporan', 'error');
            
            const btn = document.getElementById('confirmExportMemberBtn');
            btn.textContent = 'Download Laporan (XLS)';
            btn.disabled = false;
        }
    }

    // Generate proper XLSX using ExcelJS to avoid warning
    async function generateMemberReportXLSX(memberName, data, period = 'all') {
        const { checkins = [], transactions = [], wallet_history = [] } = data;
        const totalSpent = transactions.reduce((sum, t) => sum + parseFloat(t.jumlah || t.amount || 0), 0);
        const periodLabel = period === 'month' ? 'Bulan Ini' : 'Semua Waktu';

        // Initialize workbook and worksheet
        const workbook = new ExcelJS.Workbook();
        workbook.creator = 'GymKu';
        const sheet = workbook.addWorksheet('Laporan Member', { views: [{ showGridLines: false }] });

        // Set default column widths
        sheet.columns = [
            { width: 15 }, { width: 25 }, { width: 20 },
            { width: 20 }, { width: 15 }, { width: 15 }
        ];

        // Styles
        const titleFill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4CAF50' } };
        const subtitleFill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE2EFDA' } };
        const headerFill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF2F2F2' } };
        const borderAll = {
            top: { style: 'thin' }, left: { style: 'thin' },
            bottom: { style: 'thin' }, right: { style: 'thin' }
        };

        // Function to apply borders to a range
        const applyBorder = (row, col) => {
            const cell = sheet.getCell(row, col);
            cell.border = borderAll;
            return cell;
        };

        // Title
        sheet.mergeCells('A1:F1');
        const titleCell = sheet.getCell('A1');
        titleCell.value = 'LAPORAN AKTIVITAS MEMBER';
        titleCell.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 14 };
        titleCell.fill = titleFill;
        titleCell.alignment = { horizontal: 'center', vertical: 'middle' };
        titleCell.border = borderAll;

        // Info
        sheet.mergeCells('C2:F2');
        sheet.getCell('A2').value = 'Nama Member:';
        sheet.getCell('C2').value = memberName;
        sheet.getCell('C2').font = { bold: true };
        
        sheet.mergeCells('C3:F3');
        sheet.getCell('A3').value = 'Periode Laporan:';
        sheet.getCell('C3').value = periodLabel;
        sheet.getCell('C3').font = { bold: true };

        sheet.mergeCells('C4:F4');
        sheet.getCell('A4').value = 'Tanggal Unduh:';
        sheet.getCell('C4').value = formatDateTime(new Date().toISOString());

        for (let r = 2; r <= 4; r++) {
            for (let c = 1; c <= 6; c++) applyBorder(r, c);
            sheet.mergeCells(`A${r}:B${r}`);
        }

        // Empty row
        sheet.addRow([]);

        // Ringkasan
        let r = 6;
        sheet.mergeCells(`A${r}:F${r}`);
        const sumTitle = sheet.getCell(`A${r}`);
        sumTitle.value = `RINGKASAN (${periodLabel.toUpperCase()})`;
        sumTitle.font = { bold: true };
        sumTitle.fill = subtitleFill;
        sumTitle.border = borderAll;

        const addSummaryRow = (label, value, isBold = false) => {
            r++;
            sheet.getCell(`A${r}`).value = label;
            sheet.getCell(`C${r}`).value = value;
            if (isBold) sheet.getCell(`C${r}`).font = { bold: true };
            sheet.mergeCells(`A${r}:B${r}`);
            sheet.mergeCells(`C${r}:F${r}`);
            for (let c = 1; c <= 6; c++) applyBorder(r, c);
        };

        addSummaryRow('Total Check-in:', `${checkins.length} kali`);
        addSummaryRow('Total Transaksi:', transactions.length);
        addSummaryRow('Total Top-up:', wallet_history.filter(w => w.jenis === 'topup').length);
        addSummaryRow('Total Pengeluaran:', `Rp ${totalSpent.toLocaleString('id-ID')}`, true);

        // Checkin History
        r += 2;
        sheet.mergeCells(`A${r}:F${r}`);
        const checkTitle = sheet.getCell(`A${r}`);
        checkTitle.value = 'RIWAYAT CHECK-IN';
        checkTitle.font = { bold: true };
        checkTitle.fill = subtitleFill;
        checkTitle.border = borderAll;

        r++;
        if (checkins.length > 0) {
            sheet.getCell(`A${r}`).value = 'No';
            sheet.getCell(`B${r}`).value = 'Waktu Check-in';
            sheet.getCell(`C${r}`).value = 'Status';
            sheet.mergeCells(`C${r}:F${r}`);
            for (let c = 1; c <= 6; c++) {
                const cell = applyBorder(r, c);
                cell.font = { bold: true };
                cell.fill = headerFill;
            }
            
            checkins.forEach((c, index) => {
                r++;
                sheet.getCell(`A${r}`).value = index + 1;
                sheet.getCell(`B${r}`).value = formatDateTime(c.check_in_time);
                sheet.getCell(`C${r}`).value = 'Berhasil';
                sheet.mergeCells(`C${r}:F${r}`);
                for (let col = 1; col <= 6; col++) applyBorder(r, col);
            });
        } else {
            sheet.mergeCells(`A${r}:F${r}`);
            sheet.getCell(`A${r}`).value = 'Tidak ada riwayat check-in';
            for (let col = 1; col <= 6; col++) applyBorder(r, col);
        }

        // Transactions History
        r += 2;
        sheet.mergeCells(`A${r}:F${r}`);
        const transTitle = sheet.getCell(`A${r}`);
        transTitle.value = 'RIWAYAT TRANSAKSI PAKET';
        transTitle.font = { bold: true };
        transTitle.fill = subtitleFill;
        transTitle.border = borderAll;

        r++;
        if (transactions.length > 0) {
            ['ID Transaksi', 'Tanggal', 'Paket', 'Metode', 'Jumlah', 'Status'].forEach((v, i) => {
                const cell = applyBorder(r, i + 1);
                cell.value = v;
                cell.font = { bold: true };
                cell.fill = headerFill;
            });
            
            transactions.forEach(t => {
                r++;
                const statusLabel = t.status === 'success' ? 'Berhasil' : t.status === 'pending' ? 'Pending' : 'Gagal';
                sheet.getCell(`A${r}`).value = t.id;
                sheet.getCell(`B${r}`).value = formatDateTime(t.tanggal_transaksi);
                sheet.getCell(`C${r}`).value = t.package_name || '-';
                sheet.getCell(`D${r}`).value = t.metode_pembayaran || '-';
                const amtCell = sheet.getCell(`E${r}`);
                amtCell.value = parseFloat(t.jumlah || t.amount || 0);
                amtCell.numFmt = '#,##0';
                sheet.getCell(`F${r}`).value = statusLabel;
                for (let col = 1; col <= 6; col++) applyBorder(r, col);
            });
        } else {
            sheet.mergeCells(`A${r}:F${r}`);
            sheet.getCell(`A${r}`).value = 'Tidak ada riwayat transaksi';
            for (let col = 1; col <= 6; col++) applyBorder(r, col);
        }

        // Wallet History
        r += 2;
        sheet.mergeCells(`A${r}:F${r}`);
        const walletTitle = sheet.getCell(`A${r}`);
        walletTitle.value = 'RIWAYAT SALDO & TOP-UP';
        walletTitle.font = { bold: true };
        walletTitle.fill = subtitleFill;
        walletTitle.border = borderAll;

        r++;
        if (wallet_history.length > 0) {
            sheet.getCell(`A${r}`).value = 'Tanggal';
            sheet.getCell(`B${r}`).value = 'Jenis';
            sheet.getCell(`C${r}`).value = 'Jumlah';
            sheet.getCell(`D${r}`).value = 'Keterangan';
            sheet.mergeCells(`D${r}:F${r}`);
            for (let c = 1; c <= 6; c++) {
                const cell = applyBorder(r, c);
                cell.font = { bold: true };
                cell.fill = headerFill;
            }
            
            wallet_history.forEach(w => {
                r++;
                const jenisLabel = w.jenis === 'topup' ? 'Top-up' : w.jenis === 'payment' ? 'Pembayaran' : w.jenis;
                sheet.getCell(`A${r}`).value = formatDateTime(w.created_at);
                sheet.getCell(`B${r}`).value = jenisLabel;
                const wAmt = sheet.getCell(`C${r}`);
                wAmt.value = parseFloat(w.jumlah || 0);
                wAmt.numFmt = '#,##0';
                sheet.getCell(`D${r}`).value = w.keterangan || '-';
                sheet.mergeCells(`D${r}:F${r}`);
                for (let col = 1; col <= 6; col++) applyBorder(r, col);
            });
        } else {
            sheet.mergeCells(`A${r}:F${r}`);
            sheet.getCell(`A${r}`).value = 'Tidak ada riwayat saldo';
            for (let col = 1; col <= 6; col++) applyBorder(r, col);
        }

        // Write and Download
        const buffer = await workbook.xlsx.writeBuffer();
        const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        const safeName = memberName.replace(/[^a-zA-Z0-9]/g, '_').toLowerCase();
        const periodFileLabel = period === 'month' ? 'Bulan_Ini' : 'Semua';
        a.download = `Laporan_Member_${safeName}_${periodFileLabel}_${new Date().toISOString().split('T')[0]}.xlsx`;
        a.click();
        window.URL.revokeObjectURL(url);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  K-MEANS CLUSTERING — Analisis frekuensi check-in member
    // ═══════════════════════════════════════════════════════════════════════════

    let kmeansBarChart = null;
    let kmeansPieChart = null;
    let kmeansResults  = [];   // hasil clustering tersimpan untuk filter tabel

    // Warna per klaster (maksimal 4 klaster)
    const CLUSTER_COLORS = [
        { bg: 'rgba(34,197,94,0.85)',  border: 'rgb(34,197,94)',   text: '#22c55e' },   // hijau  – paling rajin
        { bg: 'rgba(14,165,233,0.85)', border: 'rgb(14,165,233)',  text: '#0ea5e9' },   // biru
        { bg: 'rgba(245,158,11,0.85)', border: 'rgb(245,158,11)',  text: '#f59e0b' },   // kuning
        { bg: 'rgba(239,68,68,0.85)',  border: 'rgb(239,68,68)',   text: '#ef4444' },   // merah  – paling jarang
    ];

    // ── K-Means Algorithm (pure JS, 1-D data) ──────────────────────────────
    function runKMeans(data, k, maxIter = 100) {
        if (data.length === 0 || k <= 0) return [];
        k = Math.min(k, data.length);

        // Inisialisasi centroid: ambil k nilai terdistribusi merata
        const sorted = [...data].sort((a, b) => a - b);
        let centroids = Array.from({ length: k }, (_, i) =>
            sorted[Math.floor((i * sorted.length) / k)]
        );

        let assignments = new Array(data.length).fill(0);

        for (let iter = 0; iter < maxIter; iter++) {
            // Assignment step — setiap titik ke centroid terdekat
            let changed = false;
            assignments = data.map((val, idx) => {
                const nearest = centroids.reduce((bestIdx, c, ci) =>
                    Math.abs(val - c) < Math.abs(val - centroids[bestIdx]) ? ci : bestIdx, 0);
                if (nearest !== assignments[idx]) changed = true;
                return nearest;
            });

            if (!changed) break; // Konvergen

            // Update step — hitung ulang centroid
            centroids = centroids.map((_, ci) => {
                const members = data.filter((_, idx) => assignments[idx] === ci);
                return members.length > 0
                    ? members.reduce((s, v) => s + v, 0) / members.length
                    : centroids[ci];
            });
        }

        return assignments;
    }

    // ── Generate label klaster berdasarkan nilai centroid ──────────────────
    function buildClusterLabels(memberData, assignments, k) {
        // Hitung rata-rata check-in per klaster
        const totals = Array(k).fill(0);
        const counts = Array(k).fill(0);
        assignments.forEach((ci, idx) => {
            totals[ci] += memberData[idx].checkins;
            counts[ci]++;
        });
        const avgs = totals.map((t, i) => (counts[i] > 0 ? t / counts[i] : 0));

        // Ranking klaster dari paling rajin (avg tertinggi) ke paling jarang
        const rankOrder = avgs
            .map((avg, ci) => ({ ci, avg }))
            .sort((a, b) => b.avg - a.avg);

        const categoryNames = ['Rajin', 'Sedang', 'Jarang', 'Sangat Jarang'];
        const labelMap = {}; // ci → { label, colorIdx }
        rankOrder.forEach(({ ci }, rank) => {
            labelMap[ci] = {
                label:     categoryNames[Math.min(rank, categoryNames.length - 1)],
                colorIdx:  rank % CLUSTER_COLORS.length,
                avgCheckin: avgs[ci],
                count:      counts[ci],
            };
        });

        return labelMap;
    }

    // ── Jalankan K-Means & render hasilnya ────────────────────────────────
    async function executeKMeans() {
        const btn = document.getElementById('runKmeans');
        if (btn) { btn.disabled = true; btn.textContent = 'Memproses...'; }

        try {
            const periodMonths = parseInt(document.getElementById('kmeansPeriod').value) || 1;
            const k = parseInt(document.getElementById('kmeansK').value) || 3;

            // Ambil data check-in semua member dari admin API
            const [usersResp, checkinsResp] = await Promise.all([
                api.getAllUsers(),
                api.getAllCheckIns({ limit: 9999 })
            ]);

            if (!usersResp.success || !checkinsResp.success) {
                showToast('Gagal mengambil data untuk analisis', 'error');
                return;
            }

            const allUsers   = usersResp.data || [];
            const allCheckIns = checkinsResp.data || [];

            // Hitung frekuensi check-in per user dalam periode
            const cutoff = new Date();
            cutoff.setMonth(cutoff.getMonth() - periodMonths);

            const checkinCount = {};
            allCheckIns.forEach(ci => {
                const t = new Date(ci.check_in_time);
                if (t >= cutoff) {
                    const uid = ci.user_id;
                    checkinCount[uid] = (checkinCount[uid] || 0) + 1;
                }
            });

            // Buat data array — satu entry per member (termasuk yang 0 check-in)
            const memberData = allUsers.map(u => ({
                id:       u.id,
                name:     u.name || u.nama || '-',
                email:    u.email || '-',
                checkins: checkinCount[u.id] || 0,
            }));

            if (memberData.length === 0) {
                showToast('Tidak ada data member', 'error');
                return;
            }

            // Jalankan K-Means
            const dataPoints  = memberData.map(m => m.checkins);
            const assignments  = runKMeans(dataPoints, k);
            const labelMap     = buildClusterLabels(memberData, assignments, k);

            // Gabungkan hasil ke memberData
            kmeansResults = memberData.map((m, idx) => ({
                ...m,
                cluster:      assignments[idx],
                clusterLabel: labelMap[assignments[idx]].label,
                colorIdx:     labelMap[assignments[idx]].colorIdx,
            }));

            renderKMeansResults(labelMap, k, periodMonths);
            showToast(`K-Means selesai: ${k} klaster dari ${memberData.length} member`, 'success');

        } catch (error) {
            console.error('K-Means error:', error);
            showToast('Gagal menjalankan K-Means: ' + error.message, 'error');
        } finally {
            if (btn) {
                btn.disabled = false;
                btn.innerHTML = `<svg viewBox="0 0 24 24" fill="none"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 14.5v-9l6 4.5-6 4.5z" fill="currentColor"/></svg> Jalankan K-Means`;
            }
        }
    }

    // ── Render: summary cards, charts, table ──────────────────────────────
    function renderKMeansResults(labelMap, k, periodMonths) {
        // Tampilkan area hasil
        document.getElementById('kmeansEmpty').style.display    = 'none';
        document.getElementById('kmeansClusters').style.display = 'block';

        // ── Summary Cards ──
        const cardsEl = document.getElementById('kmeansClusterCards');
        cardsEl.innerHTML = '';
        Object.entries(labelMap).forEach(([ci, info]) => {
            const col = CLUSTER_COLORS[info.colorIdx];
            cardsEl.innerHTML += `
                <div class="summary-box" style="border-left:4px solid ${col.text};">
                    <div class="summary-box-label">${info.label}</div>
                    <div class="summary-box-value" style="color:${col.text};">${info.count} member</div>
                    <div style="font-size:.75rem;color:var(--text-3);margin-top:4px;">
                        Rata-rata ${info.avgCheckin.toFixed(1)} check-in / ${periodMonths} bln
                    </div>
                </div>`;
        });

        // ── Bar Chart — rata-rata check-in per klaster ──
        const barCtx = document.getElementById('kmeansBarChart');
        if (kmeansBarChart) { kmeansBarChart.destroy(); kmeansBarChart = null; }
        if (barCtx) {
            const sortedEntries = Object.entries(labelMap).sort((a, b) => b[1].avgCheckin - a[1].avgCheckin);
            kmeansBarChart = new Chart(barCtx, {
                type: 'bar',
                data: {
                    labels:   sortedEntries.map(([, info]) => info.label),
                    datasets: [{
                        label: 'Rata-rata Check-in',
                        data:  sortedEntries.map(([, info]) => parseFloat(info.avgCheckin.toFixed(2))),
                        backgroundColor: sortedEntries.map(([, info]) => CLUSTER_COLORS[info.colorIdx].bg),
                        borderColor:     sortedEntries.map(([, info]) => CLUSTER_COLORS[info.colorIdx].border),
                        borderWidth: 2,
                        borderRadius: 8,
                    }]
                },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        y: { beginAtZero: true, grid: { color: 'rgba(255,255,255,0.08)' }, ticks: { color: '#cbd5e1' } },
                        x: { grid: { display: false }, ticks: { color: '#cbd5e1' } }
                    }
                }
            });
        }

        // ── Pie Chart — jumlah member per klaster ──
        const pieCtx = document.getElementById('kmeansPieChart');
        if (kmeansPieChart) { kmeansPieChart.destroy(); kmeansPieChart = null; }
        if (pieCtx) {
            const sortedEntries = Object.entries(labelMap).sort((a, b) => b[1].avgCheckin - a[1].avgCheckin);
            kmeansPieChart = new Chart(pieCtx, {
                type: 'doughnut',
                data: {
                    labels:   sortedEntries.map(([, info]) => info.label),
                    datasets: [{
                        data:            sortedEntries.map(([, info]) => info.count),
                        backgroundColor: sortedEntries.map(([, info]) => CLUSTER_COLORS[info.colorIdx].bg),
                        borderColor:     sortedEntries.map(([, info]) => CLUSTER_COLORS[info.colorIdx].border),
                        borderWidth: 2,
                    }]
                },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'bottom', labels: { color: '#cbd5e1', padding: 12 } }
                    }
                }
            });
        }

        // ── Filter buttons ──
        const filterBtns = document.getElementById('kmeansFilterBtns');
        filterBtns.innerHTML = `<button class="btn btn-secondary btn-sm kmeans-filter-btn active" data-cluster="all">Semua</button>`;
        Object.entries(labelMap)
            .sort((a, b) => b[1].avgCheckin - a[1].avgCheckin)
            .forEach(([ci, info]) => {
                const col = CLUSTER_COLORS[info.colorIdx];
                filterBtns.innerHTML += `
                    <button class="btn btn-sm kmeans-filter-btn"
                        data-cluster="${ci}"
                        style="background:${col.bg};color:#fff;border:1px solid ${col.border};">
                        ${info.label} (${info.count})
                    </button>`;
            });

        // Bind filter clicks
        document.querySelectorAll('.kmeans-filter-btn').forEach(b => {
            b.addEventListener('click', () => {
                document.querySelectorAll('.kmeans-filter-btn').forEach(x => x.classList.remove('active'));
                b.classList.add('active');
                renderKMeansTable(b.dataset.cluster === 'all' ? null : parseInt(b.dataset.cluster));
                document.getElementById('kmeansTableTitle').textContent =
                    b.dataset.cluster === 'all' ? 'Semua Member' : `Klaster: ${b.textContent.trim()}`;
            });
        });

        // Render tabel awal (semua)
        renderKMeansTable(null);
    }

    // ── Render tabel member K-Means ────────────────────────────────────────
    function renderKMeansTable(filterCluster) {
        const tbody = document.getElementById('kmeansTableBody');
        if (!tbody) return;

        const displayed = filterCluster === null
            ? [...kmeansResults]
            : kmeansResults.filter(m => m.cluster === filterCluster);

        // Sort: check-in terbanyak dulu
        displayed.sort((a, b) => b.checkins - a.checkins);

        if (displayed.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="table-empty">Tidak ada data</td></tr>';
            return;
        }

        tbody.innerHTML = displayed.map((m, i) => {
            const col = CLUSTER_COLORS[m.colorIdx];
            return `
                <tr>
                    <td>${i + 1}</td>
                    <td>${m.name}</td>
                    <td style="font-size:.8rem;color:var(--text-3);">${m.email}</td>
                    <td style="text-align:center;font-weight:700;">${m.checkins}</td>
                    <td style="text-align:center;">
                        <span style="display:inline-block;width:26px;height:26px;border-radius:50%;
                            background:${col.bg};border:2px solid ${col.border};
                            color:#fff;font-size:.7rem;font-weight:700;line-height:22px;text-align:center;">
                            ${m.cluster + 1}
                        </span>
                    </td>
                    <td>
                        <span class="badge" style="background:${col.bg};color:#fff;border:1px solid ${col.border};">
                            ${m.clusterLabel}
                        </span>
                    </td>
                </tr>`;
        }).join('');
    }

    // ── Event listeners K-Means ────────────────────────────────────────────
    function setupKMeansListeners() {
        const runBtn      = document.getElementById('runKmeans');
        const runBtnEmpty = document.getElementById('runKmeansEmpty');
        if (runBtn)      runBtn.addEventListener('click', executeKMeans);
        if (runBtnEmpty) runBtnEmpty.addEventListener('click', executeKMeans);
    }

    setupKMeansListeners();
    // ═══════════════════════════════════════════════════════════════════════════
});

