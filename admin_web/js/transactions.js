// Transactions Page Script
document.addEventListener('DOMContentLoaded', async () => {
    if (!auth.requireAuth()) return;

    let allTransactions = [];
    let filteredTransactions = [];
    let currentPage = 1;
    let totalPages = 1;

    // Initialize
    await loadTransactions();
    await loadSummary();
    setupEventListeners();

    // Load transactions
    async function loadTransactions() {
        try {
            showTableLoading(true);
            const response = await api.getAllTransactions();

            if (response.success && response.data) {
                allTransactions = response.data;
                filteredTransactions = [...allTransactions];
                renderTable();
            }
        } catch (error) {
            console.error('Error loading transactions:', error);
            showToast('Gagal memuat data transaksi', 'error');
        } finally {
            showTableLoading(false);
        }
    }

    // Load summary
    async function loadSummary() {
        try {
            const response = await api.getAllTransactions();

            if (response.success && response.data) {
                const transactions = response.data;

                const successCount = transactions.filter(t => t.status === 'success').length;
                const pendingCount = transactions.filter(t => t.status === 'pending').length;
                const failedCount = transactions.filter(t => t.status === 'failed').length;
                const totalRevenue = transactions
                    .filter(t => t.status === 'success')
                    .reduce((sum, t) => sum + (parseFloat(t.jumlah) || 0), 0);

                document.getElementById('successCount').textContent = successCount;
                document.getElementById('pendingCount').textContent = pendingCount;
                document.getElementById('failedCount').textContent = failedCount;
                document.getElementById('totalRevenue').textContent = formatCurrency(totalRevenue);
            }
        } catch (error) {
            console.error('Error loading summary:', error);
        }
    }

    // Render table
    function renderTable() {
        const tbody = document.getElementById('transactionsTableBody');
        if (!tbody) return;

        const itemsPerPage = 10;
        const startIndex = (currentPage - 1) * itemsPerPage;
        const endIndex = startIndex + itemsPerPage;
        const pageTransactions = filteredTransactions.slice(startIndex, endIndex);

        if (pageTransactions.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8" class="text-center">Tidak ada data</td></tr>';
            return;
        }

        tbody.innerHTML = pageTransactions.map(transaction => {
            const statusClass = transaction.status === 'success' ? 'badge-success' :
                transaction.status === 'pending' ? 'badge-warning' : 'badge-danger';
            const statusLabel = transaction.status === 'success' ? 'Berhasil' :
                transaction.status === 'pending' ? 'Pending' : 'Gagal';

            return `
                <tr>
                    <td>${transaction.id || '-'}</td>
                    <td>${formatDateTime(transaction.tanggal_transaksi)}</td>
                    <td>${transaction.user_name || '-'}</td>
                    <td>${transaction.package_name || '-'}</td>
                    <td>${formatCurrency(transaction.jumlah)}</td>
                    <td>${transaction.metode_pembayaran || '-'}</td>
                    <td><span class="badge ${statusClass}">${statusLabel}</span></td>
                    <td>
                        <button class="btn-icon" onclick="viewTransactionDetail('${transaction.id}')" title="Detail">
                            <svg viewBox="0 0 24 24" fill="none">
                                <path d="M12 4.5C7 4.5 2.73 7.61 1 12C2.73 16.39 7 19.5 12 19.5C17 19.5 21.27 16.39 23 12C21.27 7.61 17 4.5 12 4.5ZM12 17C9.24 17 7 14.76 7 12C7 9.24 9.24 7 12 7C14.76 7 17 9.24 17 12C17 14.76 14.76 17 12 17ZM12 9C10.34 9 9 10.34 9 12C9 13.66 10.34 15 12 15C13.66 15 15 13.66 15 12C15 10.34 13.66 9 12 9Z" fill="currentColor"/>
                            </svg>
                        </button>
                    </td>
                </tr>
            `;
        }).join('');

        updatePagination();
    }

    // Update pagination
    function updatePagination() {
        const itemsPerPage = 10;
        totalPages = Math.ceil(filteredTransactions.length / itemsPerPage);

        const pageInfo = document.getElementById('pageInfo');
        const prevBtn = document.getElementById('prevPage');
        const nextBtn = document.getElementById('nextPage');

        if (pageInfo) pageInfo.textContent = `Halaman ${currentPage} dari ${totalPages}`;
        if (prevBtn) prevBtn.disabled = currentPage === 1;
        if (nextBtn) nextBtn.disabled = currentPage === totalPages;
    }

    // Setup event listeners
    function setupEventListeners() {
        // Search
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                const query = e.target.value.toLowerCase();
                filteredTransactions = allTransactions.filter(t =>
                    (t.id?.toLowerCase().includes(query)) ||
                    (t.user_name?.toLowerCase().includes(query)) ||
                    (t.package_name?.toLowerCase().includes(query))
                );
                currentPage = 1;
                renderTable();
            });
        }

        // Status filter
        const statusFilter = document.getElementById('statusFilter');
        if (statusFilter) {
            statusFilter.addEventListener('change', applyFilters);
        }

        // Date filters
        const startDate = document.getElementById('startDate');
        const endDate = document.getElementById('endDate');

        if (startDate) startDate.addEventListener('change', applyFilters);
        if (endDate) endDate.addEventListener('change', applyFilters);

        // Pagination
        const prevBtn = document.getElementById('prevPage');
        const nextBtn = document.getElementById('nextPage');

        if (prevBtn) {
            prevBtn.addEventListener('click', () => {
                if (currentPage > 1) {
                    currentPage--;
                    renderTable();
                }
            });
        }

        if (nextBtn) {
            nextBtn.addEventListener('click', () => {
                if (currentPage < totalPages) {
                    currentPage++;
                    renderTable();
                }
            });
        }

        // Export button
        const exportBtn = document.getElementById('exportBtn');
        if (exportBtn) {
            exportBtn.addEventListener('click', exportToCSV);
        }

        // Modal close buttons
        const closeDetailBtn = document.getElementById('closeDetailBtn');
        const closeDetailModal = document.getElementById('closeDetailModal');

        if (closeDetailBtn) closeDetailBtn.addEventListener('click', closeModal);
        if (closeDetailModal) closeDetailModal.addEventListener('click', closeModal);
    }

    // Apply filters
    function applyFilters() {
        const statusFilter = document.getElementById('statusFilter').value;
        const startDate = document.getElementById('startDate').value;
        const endDate = document.getElementById('endDate').value;

        filteredTransactions = allTransactions.filter(transaction => {
            let matchStatus = true;
            let matchDate = true;

            if (statusFilter !== 'all') {
                matchStatus = transaction.status === statusFilter;
            }

            if (startDate || endDate) {
                const transDate = new Date(transaction.created_at);
                if (startDate) {
                    matchDate = matchDate && transDate >= new Date(startDate);
                }
                if (endDate) {
                    matchDate = matchDate && transDate <= new Date(endDate);
                }
            }

            return matchStatus && matchDate;
        });

        currentPage = 1;
        renderTable();
    }

    // View transaction detail
    window.viewTransactionDetail = async function (transactionId) {
        try {
            const transaction = allTransactions.find(t => t.id === transactionId);
            if (!transaction) return;

            const modal = document.getElementById('detailModal');

            document.getElementById('detailId').textContent = transaction.id || '-';
            document.getElementById('detailDate').textContent = formatDateTime(transaction.tanggal_transaksi);
            document.getElementById('detailMemberName').textContent = transaction.user_name || '-';
            document.getElementById('detailMemberEmail').textContent = transaction.user_email || '-';
            document.getElementById('detailPackage').textContent = transaction.package_name || '-';
            document.getElementById('detailAmount').textContent = formatCurrency(transaction.jumlah);
            document.getElementById('detailMethod').textContent = transaction.metode_pembayaran || '-';

            const statusClass = transaction.status === 'success' ? 'badge-success' :
                transaction.status === 'pending' ? 'badge-warning' : 'badge-danger';
            const statusLabel = transaction.status === 'success' ? 'Berhasil' :
                transaction.status === 'pending' ? 'Pending' : 'Gagal';

            const statusBadge = document.getElementById('detailStatus');
            statusBadge.textContent = statusLabel;
            statusBadge.className = `badge ${statusClass}`;

            modal.classList.add('active');
        } catch (error) {
            console.error('Error viewing transaction detail:', error);
            showToast('Gagal memuat detail transaksi', 'error');
        }
    };

    // Close modal
    function closeModal() {
        const modal = document.getElementById('detailModal');
        modal.classList.remove('active');
    }

    // Export to CSV
    function exportToCSV() {
        const headers = ['ID', 'Tanggal', 'Member', 'Paket', 'Jumlah', 'Metode', 'Status'];
        const rows = filteredTransactions.map(t => {
            const statusLabel = t.status === 'success' ? 'Berhasil' :
                t.status === 'pending' ? 'Pending' : 'Gagal';
            return [
                t.id,
                formatDateTime(t.created_at),
                t.user_name,
                t.package_name,
                t.amount,
                t.payment_method,
                statusLabel
            ];
        });

        let csv = headers.join(',') + '\n';
        csv += rows.map(row => row.join(',')).join('\n');

        const blob = new Blob([csv], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `transactions_${new Date().toISOString().split('T')[0]}.csv`;
        a.click();
    }

    // Helper functions
    function showTableLoading(show) {
        const tbody = document.getElementById('transactionsTableBody');
        if (!tbody) return;

        if (show) {
            tbody.innerHTML = '<tr class="skeleton-row"><td colspan="8"><div class="skeleton-text"></div></td></tr>';
        }
    }
});
