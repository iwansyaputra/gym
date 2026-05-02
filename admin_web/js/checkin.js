// Check-in Page Script
document.addEventListener('DOMContentLoaded', async () => {
    if (!auth.requireAuth()) return;

    let nfcReader   = null;
    let nfcBridgeWS = null;         // WebSocket ke nfc-bridge (ACR122U)
    let currentMember  = null;      // Data member yang sedang di-preview
    let currentNfcId   = null;      // NFC ID / User ID yang di-scan
    let isProcessing   = false;     // Guard agar tidak bisa double-klik
    let lastScannedUid = null;      // Debounce — hindari scan ganda 1 kartu
    let scanCooldown   = 0;           // Timestamp terakhir scan (ms)

    // Initialize
    await loadTodayCheckins();
    await loadCheckinHistory();
    setupEventListeners();
    initializeNFCReader();

    // ─── NFC Reader ───────────────────────────────────────────────────────────
    function initializeNFCReader() {
        // Prioritas 1: Coba connect ke NFC Bridge (ACR122U via WebSocket)
        connectNFCBridge();
    }

    /**
     * Hubungkan ke nfc-bridge.py yang berjalan di localhost:8765
     * Bridge ini membaca kartu dari ACR122U dan mengirim NFC ID via WebSocket.
     * Jika bridge tidak aktif, fallback ke Web NFC API (mobile Chrome).
     */
    function connectNFCBridge() {
        const WS_URL = 'ws://localhost:8765';

        updateScannerStatus('waiting', 'Menghubungkan ke NFC Bridge...');

        try {
            nfcBridgeWS = new WebSocket(WS_URL);
        } catch (e) {
            console.warn('[NFC Bridge] Tidak bisa membuat WebSocket:', e);
            fallbackToWebNFC();
            return;
        }

        // ── Connected ──────────────────────────────────────────────────────
        nfcBridgeWS.onopen = () => {
            console.log('[NFC Bridge] ✅ Terhubung ke ws://localhost:8765');
            updateScannerStatus('scanning', 'ACR122U siap — Tempelkan kartu atau HP');
            showBridgeIndicator(true);
        };

        // ── Terima pesan dari bridge ───────────────────────────────────────
        nfcBridgeWS.onmessage = (event) => {
            let msg;
            try { msg = JSON.parse(event.data); }
            catch { return; }

            console.log('[NFC Bridge] Event:', msg);

            switch (msg.type) {
                case 'card_detected':
                    if (!msg.nfc_id) {
                        updateScannerStatus('error', 'UID kartu tidak terbaca');
                        return;
                    }
                    // ── Debounce: timestamp-based, set SEBELUM handle ───────
                    const now = Date.now();
                    if (lastScannedUid === msg.nfc_id && (now - scanCooldown) < 10000) {
                        console.warn(`[NFC Bridge] Duplikat scan diabaikan — cooldown ${Math.round((10000-(now-scanCooldown))/1000)}s`);
                        return;
                    }
                    // Set lock DULU sebelum memanggil handler
                    lastScannedUid = msg.nfc_id;
                    scanCooldown = now;

                    handleNFCScan(msg.nfc_id);
                    break;

                case 'card_removed':
                    // Tidak perlu action khusus
                    break;

                case 'reader_connected':
                    updateScannerStatus('scanning', `Reader: ${msg.reader || 'ACR122U'} — Siap`);
                    break;

                case 'reader_disconnected':
                    updateScannerStatus('error', 'NFC Reader dicabut!');
                    break;

                case 'status':
                    console.log('[NFC Bridge] Status:', msg.message);
                    break;

                case 'error':
                    console.error('[NFC Bridge] Error:', msg.message);
                    updateScannerStatus('error', `Error: ${msg.message}`);
                    break;
            }
        };

        // ── Error / gagal connect ──────────────────────────────────────────
        nfcBridgeWS.onerror = (e) => {
            console.warn('[NFC Bridge] Tidak bisa terhubung. Coba Web NFC / input manual.');
            showBridgeIndicator(false);
        };

        // ── Koneksi putus — coba reconnect setiap 5 detik ─────────────────
        nfcBridgeWS.onclose = () => {
            showBridgeIndicator(false);
            if (!nfcBridgeWS._manualClose) {
                updateScannerStatus('waiting', 'NFC Bridge terputus. Reconnect dalam 5 detik...');
                setTimeout(connectNFCBridge, 5000);
            }
        };
    }

    /** Tampilkan/sembunyikan indikator bridge aktif */
    function showBridgeIndicator(active) {
        let el = document.getElementById('nfcBridgeIndicator');
        if (!el) return;
        el.style.display = active ? 'flex' : 'none';
        el.querySelector('.bridge-dot').className = 'bridge-dot ' + (active ? 'dot-online' : 'dot-offline');
        el.querySelector('.bridge-label').textContent = active
            ? 'ACR122U Terhubung'
            : 'ACR122U Offline';
    }

    /** Fallback ke Web NFC API (hanya bekerja di Chrome Android) */
    function fallbackToWebNFC() {
        if ('NDEFReader' in window) {
            setupWebNFC();
        } else {
            updateScannerStatus('waiting', 'Gunakan input manual atau jalankan nfc-bridge.py');
        }
    }

    async function setupWebNFC() {
        try {
            nfcReader = new NDEFReader();
            await nfcReader.scan();
            updateScannerStatus('scanning', 'Siap scan NFC (Web NFC)');

            nfcReader.addEventListener('reading', ({ message, serialNumber }) => {
                console.log('[Web NFC] Tag detected:', serialNumber);
                handleNFCScan(serialNumber);
            });

            nfcReader.addEventListener('readingerror', () => {
                updateScannerStatus('error', 'Error membaca NFC');
            });
        } catch (error) {
            console.error('[Web NFC] Error:', error);
            updateScannerStatus('waiting', 'Gunakan input manual atau jalankan nfc-bridge.py');
        }
    }

    // ─── SCAN HANDLER — auto check-in langsung (1 tap = 1 check-in) ───────────
    async function handleNFCScan(nfcId) {
        if (isProcessing) return;           // Cegah scan ganda saat masih proses
        isProcessing = true;

        updateScannerStatus('scanning', 'Memproses...');

        try {
            // Step 1: Lookup member (verifikasi data + cek membership)
            const lookupResp = await api.lookupMember(nfcId);

            if (!lookupResp.success || !lookupResp.data) {
                updateScannerStatus('error', 'Member tidak ditemukan');
                showToast('NFC ID tidak terdaftar di database', 'error');
                return;
            }

            currentMember = lookupResp.data.user;
            currentNfcId  = nfcId;

            // Membership tidak aktif → tampilkan info tapi jangan check-in
            if (!lookupResp.data.has_active_membership) {
                updateScannerStatus('error', `${currentMember.name} — Membership tidak aktif`);
                showToast(`${currentMember.name}: Membership sudah expired`, 'error');
                displayMemberInfo(currentMember, false);
                showExpiredModal(currentMember);
                return;
            }

            // Step 2: Auto check-in langsung (tidak perlu klik konfirmasi)
            updateScannerStatus('scanning', `${currentMember.name} ditemukan — Check-in...`);
            const checkinResp = await api.checkInNFC(nfcId);

            if (checkinResp.success) {
                updateScannerStatus('success', `✅ ${currentMember.name} berhasil check-in!`);
                displayMemberInfo(currentMember, false); // tampilkan info, nonaktifkan tombol konfirmasi
                showSuccessModal();
                await loadTodayCheckins();
                await loadCheckinHistory();

                // Reset status setelah 3 detik siap untuk scan berikutnya
                setTimeout(() => {
                    closeMemberInfo();
                    updateScannerStatus('scanning', 'Siap — Tempelkan kartu berikutnya');
                }, 3000);
            } else {
                updateScannerStatus('error', checkinResp.message || 'Check-in gagal');
                showToast(checkinResp.message || 'Check-in gagal', 'error');
            }

        } catch (error) {
            console.error('Error auto check-in:', error);
            updateScannerStatus('error', 'Gagal memproses check-in');
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

    function closeSuccessModal() {
        const modal = document.getElementById('successModal');
        if (modal) modal.style.display = 'none';
        updateScannerStatus('waiting', 'Siap scan NFC berikutnya');
    }

    // ─── EXPIRED MODAL ───────────────────────────────────────────────────────
    function showExpiredModal(member) {
        const modal = document.getElementById('expiredModal');
        const msg = document.getElementById('expiredMessage');
        if (!modal || !msg) return;

        msg.innerHTML = `<strong style="color:white;">${member.name}</strong> belum memiliki paket aktif atau masa aktif sudah habis.<br><br>Silakan arahkan member untuk membeli atau memperpanjang paket.`;
        modal.style.display = 'flex';
    }

    document.getElementById('closeExpiredModal')?.addEventListener('click', () => {
        document.getElementById('expiredModal').style.display = 'none';
        updateScannerStatus('waiting', 'Siap scan NFC berikutnya');
    });

    document.getElementById('redirectPackagesBtn')?.addEventListener('click', () => {
        window.location.href = 'members.html'; // Lebih baik arahkan ke tabel member agar admin bisa atur paket member tsb
    });

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
