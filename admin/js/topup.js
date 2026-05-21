// Kelola Saldo Member — Admin Web Script
document.addEventListener('DOMContentLoaded', async () => {
    if (!auth.requireAuth()) return;

    let allWallets = [];

    // Init
    loadAdminInfo();
    setupTabs();
    setupSearch();
    setupRefreshBtn();
    await loadWallets();
    setupModal();

    // ─── Load semua wallet member ─────────────────────────────────────────────
    async function loadWallets() {
        try {
            showTableLoading(true);
            const res = await api.getAllWallets();
            if (res.success) {
                allWallets = res.data || [];
                renderSaldoTable(allWallets);
                renderStats(allWallets);
                populateMemberSelect(allWallets);
            } else {
                showToast('Gagal memuat data saldo', 'error');
            }
        } catch (err) {
            console.error('loadWallets error:', err);
            showToast('Gagal memuat data saldo: ' + err.message, 'error');
        } finally {
            showTableLoading(false);
        }
    }

    // ─── Render statistik ─────────────────────────────────────────────────────
    function renderStats(data) {
        const withBalance = data.filter(w => parseFloat(w.saldo) > 0);
        const totalSaldo = data.reduce((sum, w) => sum + (parseFloat(w.saldo) || 0), 0);
        const avg = data.length > 0 ? totalSaldo / data.length : 0;

        const el = (id) => document.getElementById(id);
        if (el('statMemberBersaldo')) el('statMemberBersaldo').textContent = withBalance.length + ' member';
        if (el('statTotalSaldo')) el('statTotalSaldo').textContent = formatCurrency(totalSaldo);
        if (el('statAvgSaldo')) el('statAvgSaldo').textContent = formatCurrency(avg);
        if (el('statTotalMember')) el('statTotalMember').textContent = data.length + ' member';
    }

    // ─── Render tabel saldo ───────────────────────────────────────────────────
    function renderSaldoTable(data) {
        const tbody = document.getElementById('saldoTableBody');
        if (!tbody) return;

        if (data.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="text-center">Tidak ada data member</td></tr>';
            return;
        }

        tbody.innerHTML = data.map(w => {
            const saldo = parseFloat(w.saldo) || 0;
            const memberStatus = getMembershipStatus(w.membership_expiry, w.membership_status || 'none');
            return `
                <tr>
                    <td>
                        <div style="font-weight:600;color:var(--text-1);">${w.user_name || '-'}</div>
                        <div style="font-size:.75rem;color:var(--text-3);">ID: ${w.user_id}</div>
                    </td>
                    <td style="font-size:.85rem;">${w.email || '-'}</td>
                    <td>
                        ${w.package_name
                            ? `<span class="badge ${memberStatus.class}">${w.package_name}</span>`
                            : '<span class="badge badge-danger">Belum Ada</span>'}
                    </td>
                    <td>
                        <span class="saldo-chip">
                            ${formatCurrency(saldo)}
                        </span>
                    </td>
                    <td>
                        <div class="action-buttons">
                            <button class="topup-btn" onclick="quickTopup(${w.user_id}, '${(w.user_name||'').replace(/'/g,"\\'")}', ${saldo})">
                                <svg viewBox="0 0 24 24" fill="none" style="width:13px;height:13px;"><path d="M19 13H13V19H11V13H5V11H11V5H13V11H19V13Z" fill="currentColor"/></svg>
                                Top Up
                            </button>
                            <button class="btn-icon" onclick="viewMemberHistory(${w.user_id}, '${(w.user_name||'').replace(/'/g,"\\'")}')" title="Riwayat Saldo" style="margin-left:4px;">
                                <svg viewBox="0 0 24 24" fill="none"><path d="M13 3C8.03 3 4 7.03 4 12H1L4.89 15.89 4.96 16.03 9 12H6C6 8.13 9.13 5 13 5C16.87 5 20 8.13 20 12C20 15.87 16.87 19 13 19C11.07 19 9.32 18.21 8.06 16.94L6.64 18.36C8.27 19.99 10.51 21 13 21C17.97 21 22 16.97 22 12C22 7.03 17.97 3 13 3ZM12 8V13L16.28 15.54 17 14.33 13.5 12.25V8H12Z" fill="currentColor"/></svg>
                            </button>
                        </div>
                    </td>
                </tr>
            `;
        }).join('');
    }

    function showTableLoading(show) {
        const tbody = document.getElementById('saldoTableBody');
        if (!tbody) return;
        if (show) {
            tbody.innerHTML = '<tr class="skeleton-row"><td colspan="5"><div class="skeleton-text"></div></td></tr>';
        }
    }

    // ─── Populate select di modal ─────────────────────────────────────────────
    function populateMemberSelect(data) {
        const sel = document.getElementById('topupUserId');
        if (!sel) return;
        sel.innerHTML = '<option value="">— pilih member —</option>' +
            data.map(w => `<option value="${w.user_id}" data-saldo="${w.saldo}">${w.user_name} — ${w.email}</option>`).join('');
    }

    // ─── Tabs ─────────────────────────────────────────────────────────────────
    function setupTabs() {
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
                document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
                btn.classList.add('active');
                const target = document.getElementById('tab-' + btn.dataset.tab);
                if (target) target.classList.add('active');
            });
        });
    }

    // ─── Search ───────────────────────────────────────────────────────────────
    function setupSearch() {
        const inp = document.getElementById('searchSaldo');
        if (!inp) return;
        inp.addEventListener('input', () => {
            const q = inp.value.toLowerCase();
            const filtered = allWallets.filter(w =>
                (w.user_name || '').toLowerCase().includes(q) ||
                (w.email || '').toLowerCase().includes(q)
            );
            renderSaldoTable(filtered);
        });
    }

    // ─── Refresh ──────────────────────────────────────────────────────────────
    function setupRefreshBtn() {
        const btn = document.getElementById('refreshBtn');
        if (btn) btn.addEventListener('click', loadWallets);
    }

    // ─── Modal Top Up ─────────────────────────────────────────────────────────
    function setupModal() {
        const modal = document.getElementById('topupModal');
        const openBtn = document.getElementById('openTopupModalBtn');
        const closeBtn = document.getElementById('closeTopupModal');
        const cancelBtn = document.getElementById('cancelTopupBtn');
        const submitBtn = document.getElementById('submitTopupBtn');
        const userSel = document.getElementById('topupUserId');

        if (openBtn) openBtn.addEventListener('click', () => openModal());
        if (closeBtn) closeBtn.addEventListener('click', closeModal);
        if (cancelBtn) cancelBtn.addEventListener('click', closeModal);

        // Tampilkan saldo saat ini ketika pilih member
        if (userSel) {
            userSel.addEventListener('change', () => {
                const opt = userSel.selectedOptions[0];
                const box = document.getElementById('currentSaldoBox');
                const val = document.getElementById('currentSaldoVal');
                if (opt && opt.value) {
                    const saldo = parseFloat(opt.dataset.saldo) || 0;
                    if (box) box.style.display = 'block';
                    if (val) val.textContent = formatCurrency(saldo);
                } else {
                    if (box) box.style.display = 'none';
                }
            });
        }

        // Preset amount buttons
        document.querySelectorAll('.preset-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.preset-btn').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');
                const inp = document.getElementById('topupJumlah');
                if (inp) inp.value = btn.dataset.amount;
            });
        });

        // Submit top up
        if (submitBtn) {
            submitBtn.addEventListener('click', async () => {
                const userId = document.getElementById('topupUserId')?.value;
                const jumlah = parseFloat(document.getElementById('topupJumlah')?.value);
                const keterangan = document.getElementById('topupKeterangan')?.value || '';

                if (!userId) { showToast('Pilih member terlebih dahulu', 'error'); return; }
                if (!jumlah || jumlah < 1000) { showToast('Jumlah minimal Rp 1.000', 'error'); return; }

                setSubmitLoading(true);
                try {
                    const res = await api.topUpWallet({ user_id: parseInt(userId), jumlah, keterangan });
                    if (res.success) {
                        showToast(res.message || 'Top up berhasil!', 'success');
                        closeModal();
                        await loadWallets();
                    } else {
                        showToast(res.message || 'Top up gagal', 'error');
                    }
                } catch (err) {
                    showToast(err.message || 'Terjadi kesalahan', 'error');
                } finally {
                    setSubmitLoading(false);
                }
            });
        }

        // Close history modal
        const closeHist = document.getElementById('closeHistoryModal');
        if (closeHist) closeHist.addEventListener('click', () => {
            document.getElementById('historyModal')?.classList.remove('active');
        });
    }

    function openModal(userId = null, saldo = null) {
        const form = document.getElementById('topupForm');
        if (form) form.reset();
        const box = document.getElementById('currentSaldoBox');
        if (box) box.style.display = 'none';
        document.querySelectorAll('.preset-btn').forEach(b => b.classList.remove('selected'));

        if (userId) {
            const sel = document.getElementById('topupUserId');
            if (sel) sel.value = userId;
            const box2 = document.getElementById('currentSaldoBox');
            const val = document.getElementById('currentSaldoVal');
            if (box2) box2.style.display = 'block';
            if (val) val.textContent = formatCurrency(saldo || 0);
        }

        document.getElementById('topupModal')?.classList.add('active');
    }

    function closeModal() {
        document.getElementById('topupModal')?.classList.remove('active');
    }

    function setSubmitLoading(loading) {
        const btn = document.getElementById('submitTopupBtn');
        if (!btn) return;
        const text = btn.querySelector('.btn-text');
        const loader = btn.querySelector('.btn-loader');
        if (text) text.style.display = loading ? 'none' : 'block';
        if (loader) loader.style.display = loading ? 'block' : 'none';
        btn.disabled = loading;
    }

    // ─── Global: quick top up dari baris tabel ────────────────────────────────
    window.quickTopup = function(userId, userName, saldo) {
        openModal(userId, saldo);
    };

    // ─── Global: lihat riwayat per member ────────────────────────────────────
    window.viewMemberHistory = async function(userId, userName) {
        const modal = document.getElementById('historyModal');
        const title = document.getElementById('historyModalTitle');
        const tbody = document.getElementById('historyModalBody');

        if (title) title.textContent = `Riwayat Saldo — ${userName}`;
        if (tbody) tbody.innerHTML = '<tr><td colspan="6" class="text-center">Memuat...</td></tr>';
        modal?.classList.add('active');

        try {
            const res = await api.getMemberWalletHistory(userId);
            if (res.success && res.data && res.data.length > 0) {
                tbody.innerHTML = res.data.map(h => {
                    const isCredit = h.jenis === 'topup' || h.jenis === 'refund';
                    const label = h.jenis === 'topup' ? '↑ Top Up' : h.jenis === 'refund' ? '↑ Refund' : '↓ Debit';
                    const cls = isCredit ? 'history-badge-topup' : 'history-badge-debit';
                    return `
                        <tr>
                            <td style="font-size:.8rem;">${formatDateTime(h.created_at)}</td>
                            <td><span class="${cls}">${label}</span></td>
                            <td>${formatCurrency(h.jumlah)}</td>
                            <td>${formatCurrency(h.saldo_awal)}</td>
                            <td>${formatCurrency(h.saldo_akhir)}</td>
                            <td style="max-width:200px;word-break:break-word;font-size:.8rem;">${h.keterangan || '-'}</td>
                        </tr>
                    `;
                }).join('');

                // Juga tampilkan di tab riwayat
                const histTab = document.getElementById('historyTableBody');
                if (histTab) histTab.innerHTML = tbody.innerHTML;
                // Switch ke tab riwayat
                document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
                document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
                const riwayatBtn = document.querySelector('[data-tab="riwayat"]');
                const riwayatPanel = document.getElementById('tab-riwayat');
                if (riwayatBtn) riwayatBtn.classList.add('active');
                if (riwayatPanel) riwayatPanel.classList.add('active');

                modal?.classList.remove('active');
            } else {
                if (tbody) tbody.innerHTML = '<tr><td colspan="6" class="text-center" style="color:var(--text-3);padding:30px;">Belum ada riwayat transaksi saldo</td></tr>';
            }
        } catch (err) {
            if (tbody) tbody.innerHTML = '<tr><td colspan="6" class="text-center" style="color:var(--danger);">Gagal memuat riwayat</td></tr>';
        }
    };

    // ─── Admin info & logout ──────────────────────────────────────────────────
    function loadAdminInfo() {
        const user = auth.getUser();
        if (!user) return;
        const name = user.nama || user.name || 'Admin';
        const initial = name.charAt(0).toUpperCase();
        ['sidebarAvatar', 'topbarAvatar'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.textContent = initial;
        });
        ['adminName', 'topbarName'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.textContent = name;
        });
        const logoutBtn = document.getElementById('logoutBtn');
        if (logoutBtn) logoutBtn.addEventListener('click', () => auth.logout());
        const menuToggle = document.getElementById('menuToggle');
        const sidebar = document.getElementById('sidebar');
        if (menuToggle && sidebar) menuToggle.addEventListener('click', () => sidebar.classList.toggle('open'));
    }
});
