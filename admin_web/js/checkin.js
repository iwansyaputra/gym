// Check-in Page Script
document.addEventListener('DOMContentLoaded', async () => {
    if (!auth.requireAuth()) return;

    let nfcReader = null;
    let currentMember = null;

    // Initialize
    await loadTodayCheckins();
    await loadCheckinHistory();
    setupEventListeners();
    initializeNFCReader();

    // Initialize NFC Reader (Web NFC API or fallback to manual input)
    function initializeNFCReader() {
        // Check if Web NFC is supported
        if ('NDEFReader' in window) {
            setupWebNFC();
        } else {
            console.log('Web NFC not supported, using manual input only');
            updateScannerStatus('waiting', 'NFC tidak didukung - Gunakan input manual');
        }
    }

    // Setup Web NFC
    async function setupWebNFC() {
        try {
            nfcReader = new NDEFReader();
            await nfcReader.scan();

            updateScannerStatus('scanning', 'Siap scan NFC');

            nfcReader.addEventListener('reading', ({ message, serialNumber }) => {
                console.log('NFC Tag detected:', serialNumber);
                handleNFCScan(serialNumber);
            });

            nfcReader.addEventListener('readingerror', () => {
                updateScannerStatus('error', 'Error membaca NFC');
            });
        } catch (error) {
            console.error('Error setting up NFC:', error);
            updateScannerStatus('waiting', 'Gunakan input manual');
        }
    }

    // Handle NFC scan
    async function handleNFCScan(nfcId) {
        updateScannerStatus('scanning', 'Memproses...');

        try {
            const response = await api.checkInNFC(nfcId);

            if (response.success && response.data) {
                currentMember = response.data.user;
                displayMemberInfo(currentMember);
                updateScannerStatus('success', 'Member ditemukan');
            } else {
                updateScannerStatus('error', 'Member tidak ditemukan');
                showToast('NFC ID tidak terdaftar', 'error');
            }
        } catch (error) {
            console.error('Error checking in:', error);
            updateScannerStatus('error', 'Gagal check-in');
            showToast(error.message || 'Terjadi kesalahan', 'error');
        }
    }

    // Update scanner status
    function updateScannerStatus(status, text) {
        const statusEl = document.getElementById('scannerStatus');
        if (!statusEl) return;

        const dot = statusEl.querySelector('.status-dot');
        const textEl = statusEl.querySelector('.status-text');

        // Remove all status classes
        dot.classList.remove('status-waiting', 'status-scanning', 'status-success', 'status-error');

        // Add new status class
        switch (status) {
            case 'waiting':
                dot.classList.add('status-waiting');
                break;
            case 'scanning':
                dot.classList.add('status-scanning');
                break;
            case 'success':
                dot.classList.add('status-success');
                break;
            case 'error':
                dot.classList.add('status-danger');
                break;
        }

        textEl.textContent = text;
    }

    // Display member info
    function displayMemberInfo(member) {
        const memberInfoCard = document.getElementById('memberInfoCard');
        if (!memberInfoCard) return;

        document.getElementById('memberInfoName').textContent = member.name || '-';
        document.getElementById('memberInfoId').textContent = `ID: ${member.id}`;
        document.getElementById('memberInfoEmail').textContent = member.email || '-';
        document.getElementById('memberInfoPhone').textContent = member.phone || '-';
        document.getElementById('memberInfoPackage').textContent = member.package_name || '-';

        const status = getMembershipStatus(member.membership_expiry);
        const statusBadge = document.getElementById('memberInfoStatus');
        statusBadge.textContent = status.label;
        statusBadge.className = `badge ${status.class}`;

        document.getElementById('memberInfoExpiry').textContent = formatDate(member.membership_expiry);
        document.getElementById('memberInfoLastCheckin').textContent =
            member.last_checkin ? formatDateTime(member.last_checkin) : 'Belum pernah';

        memberInfoCard.style.display = 'block';
    }

    // Setup event listeners
    function setupEventListeners() {
        // Manual check-in button
        const manualBtn = document.getElementById('manualCheckinBtn');
        if (manualBtn) {
            manualBtn.addEventListener('click', async () => {
                const nfcId = document.getElementById('manualNfcId').value.trim();
                if (!nfcId) {
                    showToast('Masukkan NFC ID atau User ID', 'error');
                    return;
                }
                await handleNFCScan(nfcId);
            });
        }

        // Confirm check-in button
        const confirmBtn = document.getElementById('confirmCheckinBtn');
        if (confirmBtn) {
            confirmBtn.addEventListener('click', async () => {
                if (!currentMember) return;

                try {
                    const response = await api.checkInNFC(currentMember.nfc_id || currentMember.id);

                    if (response.success) {
                        showSuccessModal();
                        await loadTodayCheckins();
                        await loadCheckinHistory();

                        // Reset
                        setTimeout(() => {
                            closeMemberInfo();
                            updateScannerStatus('waiting', 'Siap scan NFC berikutnya');
                        }, 2000);
                    }
                } catch (error) {
                    console.error('Error confirming check-in:', error);
                    showToast(error.message || 'Gagal check-in', 'error');
                }
            });
        }

        // Close member info
        const closeBtn = document.getElementById('closeMemberInfo');
        if (closeBtn) {
            closeBtn.addEventListener('click', closeMemberInfo);
        }

        // Date filter
        const dateFilter = document.getElementById('dateFilter');
        if (dateFilter) {
            dateFilter.value = new Date().toISOString().split('T')[0];
            dateFilter.addEventListener('change', loadCheckinHistory);
        }

        // Refresh button
        const refreshBtn = document.getElementById('refreshBtn');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', async () => {
                await loadTodayCheckins();
                await loadCheckinHistory();
                showToast('Data diperbarui', 'success');
            });
        }

        // Success modal close
        const closeSuccessBtn = document.getElementById('closeSuccessModal');
        if (closeSuccessBtn) {
            closeSuccessBtn.addEventListener('click', () => {
                document.getElementById('successModal').classList.remove('active');
            });
        }
    }

    // Close member info card
    function closeMemberInfo() {
        const memberInfoCard = document.getElementById('memberInfoCard');
        if (memberInfoCard) {
            memberInfoCard.style.display = 'none';
        }
        currentMember = null;
        document.getElementById('manualNfcId').value = '';
    }

    // Show success modal
    function showSuccessModal() {
        const modal = document.getElementById('successModal');
        const message = document.getElementById('successMessage');

        if (currentMember) {
            message.textContent = `${currentMember.name} berhasil check-in!`;
        }

        modal.classList.add('active');

        setTimeout(() => {
            modal.classList.remove('active');
        }, 3000);
    }

    // Load today's check-in count
    async function loadTodayCheckins() {
        try {
            const response = await api.getCheckInStats({ period: 'today' });
            const todayTotal = document.getElementById('todayTotal');

            if (todayTotal && response.success) {
                todayTotal.textContent = response.data?.today || 0;
            }
        } catch (error) {
            console.error('Error loading today checkins:', error);
        }
    }

    // Load check-in history
    async function loadCheckinHistory() {
        try {
            const dateFilter = document.getElementById('dateFilter');
            const date = dateFilter ? dateFilter.value : new Date().toISOString().split('T')[0];

            const response = await api.getCheckInHistory({ date });
            const tbody = document.getElementById('checkinTableBody');

            if (!tbody) return;

            if (response.success && response.data && response.data.length > 0) {
                tbody.innerHTML = response.data.map(checkin => {
                    const status = getMembershipStatus(checkin.membership_expiry);
                    return `
                        <tr>
                            <td>${formatDateTime(checkin.check_in_time)}</td>
                            <td>${checkin.user_name || '-'}</td>
                            <td>${checkin.user_id || '-'}</td>
                            <td>${checkin.nfc_id || '-'}</td>
                            <td><span class="badge ${status.class}">${status.label}</span></td>
                            <td><span class="badge badge-primary">${checkin.method || 'NFC'}</span></td>
                        </tr>
                    `;
                }).join('');
            } else {
                tbody.innerHTML = '<tr><td colspan="6" class="text-center">Tidak ada data check-in</td></tr>';
            }
        } catch (error) {
            console.error('Error loading check-in history:', error);
            showToast('Gagal memuat riwayat check-in', 'error');
        }
    }
});
