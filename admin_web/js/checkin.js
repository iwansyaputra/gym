// Check-in Page Script
document.addEventListener('DOMContentLoaded', async () => {
    if (!auth.requireAuth()) return;

    let nfcReader = null;
    let currentMember = null;       // Data member yang sedang di-preview
    let currentNfcId = null;        // NFC ID / User ID yang di-scan
    let isProcessing = false;       // Guard agar tidak bisa double-klik

    // Initialize
    await loadTodayCheckins();
    await loadCheckinHistory();
    setupEventListeners();
    initializeNFCReader();

    // ─── NFC Reader ───────────────────────────────────────────────────────────
    function initializeNFCReader() {
        if ('NDEFReader' in window) {
            setupWebNFC();
        } else {
            console.log('Web NFC not supported, using manual input only');
            updateScannerStatus('waiting', 'NFC tidak didukung – Gunakan input manual');
        }
    }

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

    // ─── SCAN HANDLER — hanya LOOKUP, belum check-in ke database ──────────────
    async function handleNFCScan(nfcId) {
        if (isProcessing) return;           // Cegah scan ganda saat masih proses
        isProcessing = true;

        updateScannerStatus('scanning', 'Memproses...');

        try {
            // Gunakan endpoint /lookup — TIDAK mencatat check-in ke DB
            const response = await api.lookupMember(nfcId);

            if (response.success && response.data) {
                currentMember = response.data.user;
                currentNfcId  = nfcId;

                if (!response.data.has_active_membership) {
                    updateScannerStatus('error', 'Membership tidak aktif');
                    showToast('Membership member ini sudah tidak aktif', 'error');
                    displayMemberInfo(currentMember, false);
                } else {
                    displayMemberInfo(currentMember, true);
                    updateScannerStatus('success', 'Member ditemukan – klik Konfirmasi');
                }
            } else {
                updateScannerStatus('error', 'Member tidak ditemukan');
                showToast('NFC ID tidak terdaftar', 'error');
            }
        } catch (error) {
            console.error('Error lookup member:', error);
            updateScannerStatus('error', 'Gagal membaca data member');
            showToast(error.message || 'Terjadi kesalahan', 'error');
        } finally {
            isProcessing = false;
        }
    }

    // ─── CONFIRM CHECK-IN — ini yang benar-benar mencatat ke database ─────────
    async function doConfirmCheckin() {
        if (!currentMember || !currentNfcId) return;
        if (isProcessing) return;
        isProcessing = true;

        const confirmBtn = document.getElementById('confirmCheckinBtn');
        if (confirmBtn) {
            confirmBtn.disabled = true;
            confirmBtn.textContent = 'Memproses...';
        }

        try {
            // Gunakan endpoint /nfc — barulah check-in dicatat ke DB
            const response = await api.checkInNFC(currentNfcId);

            if (response.success) {
                showSuccessModal();
                await loadTodayCheckins();
                await loadCheckinHistory();

                setTimeout(() => {
                    closeMemberInfo();
                    updateScannerStatus('waiting', 'Siap scan NFC berikutnya');
                }, 2000);
            } else {
                showToast(response.message || 'Gagal check-in', 'error');
            }
        } catch (error) {
            console.error('Error confirming check-in:', error);
            showToast(error.message || 'Gagal check-in', 'error');
        } finally {
            isProcessing = false;
            if (confirmBtn) {
                confirmBtn.disabled = false;
                confirmBtn.innerHTML = `<svg viewBox="0 0 24 24" fill="none"><path d="M9 16.17L4.83 12 3.41 13.41 9 19 21 7 19.59 5.59 9 16.17Z" fill="currentColor"/></svg> Konfirmasi Check-in`;
            }
        }
    }

    // ─── Scanner status ───────────────────────────────────────────────────────
    function updateScannerStatus(status, text) {
        const statusEl = document.getElementById('scannerStatus');
        if (!statusEl) return;

        const dot    = statusEl.querySelector('.status-dot');
        const textEl = statusEl.querySelector('.status-text');

        dot.classList.remove('status-waiting', 'status-scanning', 'status-success', 'status-danger');

        switch (status) {
            case 'waiting':  dot.classList.add('status-waiting');  break;
            case 'scanning': dot.classList.add('status-scanning'); break;
            case 'success':  dot.classList.add('status-success');  break;
            case 'error':    dot.classList.add('status-danger');   break;
        }

        textEl.textContent = text;
    }

    // ─── Display member card ──────────────────────────────────────────────────
    function displayMemberInfo(member, canCheckin) {
        const memberInfoCard = document.getElementById('memberInfoCard');
        if (!memberInfoCard) return;

        document.getElementById('memberInitial').textContent  = (member.name || '?').charAt(0).toUpperCase();
        document.getElementById('memberInfoName').textContent = member.name  || '-';
        document.getElementById('memberInfoId').textContent   = `ID: ${member.id}`;
        document.getElementById('memberInfoEmail').textContent = member.email || '-';
        document.getElementById('memberInfoPhone').textContent = member.phone || '-';
        document.getElementById('memberInfoPackage').textContent = member.package_name || '-';

        const status     = getMembershipStatus(member.membership_expiry);
        const statusBadge = document.getElementById('memberInfoStatus');
        statusBadge.textContent  = status.label;
        statusBadge.className    = `badge ${status.class}`;

        document.getElementById('memberInfoExpiry').textContent =
            member.membership_expiry ? formatDate(member.membership_expiry) : '-';
        document.getElementById('memberInfoLastCheckin').textContent =
            member.last_checkin ? formatDateTime(member.last_checkin) : 'Belum pernah';

        // Nonaktifkan tombol konfirmasi jika membership tidak aktif
        const confirmBtn = document.getElementById('confirmCheckinBtn');
        if (confirmBtn) {
            confirmBtn.disabled = !canCheckin;
            confirmBtn.style.opacity = canCheckin ? '1' : '0.5';
        }

        memberInfoCard.style.display = 'block';
    }

    // ─── Event listeners ──────────────────────────────────────────────────────
    function setupEventListeners() {
        // Manual check-in button (hanya lookup, bukan langsung check-in)
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

        // Confirm check-in button — inilah satu-satunya yang mencatat check-in
        const confirmBtn = document.getElementById('confirmCheckinBtn');
        if (confirmBtn) {
            confirmBtn.addEventListener('click', doConfirmCheckin);
        }

        // Close member info
        const closeBtn = document.getElementById('closeMemberInfo');
        if (closeBtn) closeBtn.addEventListener('click', closeMemberInfo);

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

    // ─── Close member info card ───────────────────────────────────────────────
    function closeMemberInfo() {
        const memberInfoCard = document.getElementById('memberInfoCard');
        if (memberInfoCard) memberInfoCard.style.display = 'none';
        currentMember = null;
        currentNfcId  = null;
        const inp = document.getElementById('manualNfcId');
        if (inp) inp.value = '';
    }

    // ─── Show success modal ───────────────────────────────────────────────────
    function showSuccessModal() {
        const modal   = document.getElementById('successModal');
        const message = document.getElementById('successMessage');

        if (currentMember) {
            message.textContent = `${currentMember.name} berhasil check-in!`;
        }

        modal.classList.add('active');
        setTimeout(() => modal.classList.remove('active'), 3000);
    }

    // ─── Load today's total check-ins ─────────────────────────────────────────
    async function loadTodayCheckins() {
        try {
            const response = await api.getDashboardStats();
            const todayTotal = document.getElementById('todayTotal');
            if (todayTotal && response) {
                todayTotal.textContent = response.todayCheckins || 0;
            }
        } catch (error) {
            console.error('Error loading today checkins:', error);
        }
    }

    // ─── Load check-in history table ─────────────────────────────────────────
    async function loadCheckinHistory() {
        try {
            const dateFilter = document.getElementById('dateFilter');
            const date = dateFilter ? dateFilter.value : new Date().toISOString().split('T')[0];

            const response = await api.getAllCheckIns({ date });
            const tbody    = document.getElementById('checkinTableBody');
            if (!tbody) return;

            if (response.success && response.data && response.data.length > 0) {
                tbody.innerHTML = response.data.map(checkin => {
                    const status = getMembershipStatus(checkin.membership_expiry);
                    return `
                        <tr>
                            <td>${formatDateTime(checkin.check_in_time)}</td>
                            <td>${checkin.user_name || '-'}</td>
                            <td>${checkin.user_id   || '-'}</td>
                            <td>${checkin.nfc_id    || '-'}</td>
                            <td><span class="badge ${status.class}">${status.label}</span></td>
                            <td><span class="badge badge-primary">${checkin.method || 'NFC'}</span></td>
                        </tr>
                    `;
                }).join('');
            } else {
                tbody.innerHTML = '<tr><td colspan="6" class="table-empty">Tidak ada data check-in</td></tr>';
            }
        } catch (error) {
            console.error('Error loading check-in history:', error);
            showToast('Gagal memuat riwayat check-in', 'error');
        }
    }
});
