// Promo Management Script
document.addEventListener('DOMContentLoaded', async () => {
    if (!auth.requireAuth()) return;

    let promos = [];
    let deleteTargetId = null;
    let isEditMode = false;

    await loadPromos();
    setupModals();

    // ─── Load promos from admin endpoint ────────────────────────────────────────
    async function loadPromos() {
        try {
            showTableLoading(true);
            const response = await api.request('/promos/admin/all', { method: 'GET' });

            if (response.success && response.data) {
                promos = response.data;
                renderTable();
                renderActivePromoInfo();
            } else {
                showToast('Gagal memuat data promo', 'error');
            }
        } catch (error) {
            console.error('loadPromos error:', error);
            showToast('Terjadi kesalahan saat memuat promo', 'error');
        } finally {
            showTableLoading(false);
        }
    }

    // ─── Render table ────────────────────────────────────────────────────────────
    function renderTable() {
        const tbody = document.getElementById('promosTableBody');
        if (!tbody) return;

        if (promos.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="table-empty">Belum ada promo. Klik "Tambah Promo" untuk mulai.</td></tr>';
            return;
        }

        tbody.innerHTML = promos.map(p => {
            const isValid = p.is_valid;
            const isActive = p.is_active;
            const statusClass = isActive && isValid ? 'badge-success' : isActive ? 'badge-warning' : 'badge-muted';
            const statusText = isActive && isValid ? 'Aktif' : isActive ? 'Belum Mulai / Kadaluarsa' : 'Nonaktif';

            return `<tr>
                <td>
                    <div style="font-weight:600;color:var(--text-1);">${escHtml(p.judul)}</div>
                    <div style="font-size:.8rem;color:var(--text-3);margin-top:2px;">${escHtml(p.deskripsi || '—')}</div>
                </td>
                <td>
                    ${p.diskon_persen > 0
                        ? `<span class="badge badge-primary no-dot" style="font-size:.85rem;padding:4px 12px;">🏷 ${p.diskon_persen}%</span>`
                        : `<span style="color:var(--text-3);font-size:.85rem;">Tanpa diskon</span>`}
                </td>
                <td style="font-size:.85rem;color:var(--text-2);">
                    ${formatDate(p.tanggal_mulai)} s/d ${formatDate(p.tanggal_berakhir)}
                    ${isActive && isValid ? `<div style="font-size:.75rem;color:var(--success);margin-top:2px;">⏳ ${p.days_remaining} hari lagi</div>` : ''}
                </td>
                <td><span class="badge ${statusClass}">${statusText}</span></td>
                <td>
                    <div style="display:flex;gap:8px;">
                        <button class="btn btn-secondary btn-sm" onclick="editPromo(${p.id})">
                            <svg viewBox="0 0 24 24" fill="none" style="width:14px;height:14px;"><path d="M3 17.25V21H6.75L17.81 9.94L14.06 6.19L3 17.25ZM20.71 7.04C21.1 6.65 21.1 6.02 20.71 5.63L18.37 3.29C17.98 2.9 17.35 2.9 16.96 3.29L15.13 5.12L18.88 8.87L20.71 7.04Z" fill="currentColor"/></svg>
                            Edit
                        </button>
                        <button class="btn btn-danger btn-sm" onclick="deletePromo(${p.id}, '${escHtml(p.judul)}')">
                            <svg viewBox="0 0 24 24" fill="none" style="width:14px;height:14px;"><path d="M6 19C6 20.1 6.9 21 8 21H16C17.1 21 18 20.1 18 19V7H6V19ZM19 4H15.5L14.5 3H9.5L8.5 4H5V6H19V4Z" fill="currentColor"/></svg>
                            Hapus
                        </button>
                    </div>
                </td>
            </tr>`;
        }).join('');
    }

    // ─── Show active promo info banner ───────────────────────────────────────────
    function renderActivePromoInfo() {
        const active = promos.find(p => p.is_active && p.is_valid && p.diskon_persen > 0);
        const banner = document.getElementById('activePromoInfo');
        const text = document.getElementById('activePromoText');
        if (!banner || !text) return;

        if (active) {
            text.textContent = `${active.judul} — Diskon ${active.diskon_persen}%`;
            banner.style.display = 'block';
        } else {
            banner.style.display = 'none';
        }
    }

    // ─── Setup modals ────────────────────────────────────────────────────────────
    function setupModals() {
        // Add/Edit modal
        document.getElementById('openAddPromoBtn')?.addEventListener('click', openAddModal);
        document.getElementById('closePromoModal')?.addEventListener('click', closePromoModal);
        document.getElementById('cancelPromoBtn')?.addEventListener('click', closePromoModal);
        document.getElementById('savePromoBtn')?.addEventListener('click', handleSavePromo);

        // Delete modal
        document.getElementById('closeDeleteModal')?.addEventListener('click', closeDeleteModal);
        document.getElementById('cancelDeleteBtn')?.addEventListener('click', closeDeleteModal);
        document.getElementById('confirmDeleteBtn')?.addEventListener('click', handleDeletePromo);

        // Click outside to close
        document.getElementById('promoModal')?.addEventListener('click', e => {
            if (e.target === e.currentTarget) closePromoModal();
        });
        document.getElementById('deletePromoModal')?.addEventListener('click', e => {
            if (e.target === e.currentTarget) closeDeleteModal();
        });
    }

    function openAddModal() {
        isEditMode = false;
        document.getElementById('promoModalTitle').textContent = 'Tambah Promo Baru';
        document.getElementById('promoForm').reset();
        document.getElementById('promoId').value = '';
        // Set default dates
        const today = new Date().toISOString().split('T')[0];
        const nextMonth = new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0];
        document.getElementById('promoTanggalMulai').value = today;
        document.getElementById('promoTanggalBerakhir').value = nextMonth;
        document.getElementById('promoModal').classList.add('active');
    }

    function closePromoModal() {
        document.getElementById('promoModal').classList.remove('active');
    }

    function closeDeleteModal() {
        document.getElementById('deletePromoModal').classList.remove('active');
        deleteTargetId = null;
    }

    // ─── Open edit modal ─────────────────────────────────────────────────────────
    window.editPromo = function(id) {
        const promo = promos.find(p => p.id === id);
        if (!promo) return;

        isEditMode = true;
        document.getElementById('promoModalTitle').textContent = 'Edit Promo';
        document.getElementById('promoId').value = promo.id;
        document.getElementById('promoJudul').value = promo.judul || '';
        document.getElementById('promoDeskripsi').value = promo.deskripsi || '';
        document.getElementById('promoDiskon').value = promo.diskon_persen || 0;
        document.getElementById('promoTanggalMulai').value = (promo.tanggal_mulai || '').split('T')[0];
        document.getElementById('promoTanggalBerakhir').value = (promo.tanggal_berakhir || '').split('T')[0];
        document.getElementById('promoIsActive').value = promo.is_active ? '1' : '0';
        document.getElementById('promoModal').classList.add('active');
    };

    // ─── Open delete confirm ─────────────────────────────────────────────────────
    window.deletePromo = function(id, nama) {
        deleteTargetId = id;
        document.getElementById('deletePromoName').textContent = nama;
        document.getElementById('deletePromoModal').classList.add('active');
    };

    // ─── Save promo (create or update) ──────────────────────────────────────────
    async function handleSavePromo() {
        const judul = document.getElementById('promoJudul').value.trim();
        const deskripsi = document.getElementById('promoDeskripsi').value.trim();
        const diskon = parseInt(document.getElementById('promoDiskon').value, 10) || 0;
        const tanggalMulai = document.getElementById('promoTanggalMulai').value;
        const tanggalBerakhir = document.getElementById('promoTanggalBerakhir').value;
        const isActive = document.getElementById('promoIsActive').value === '1';

        if (!judul) { showToast('Judul promo wajib diisi', 'error'); return; }
        if (!tanggalMulai || !tanggalBerakhir) { showToast('Periode promo wajib diisi', 'error'); return; }
        if (new Date(tanggalBerakhir) < new Date(tanggalMulai)) {
            showToast('Tanggal berakhir harus setelah tanggal mulai', 'error');
            return;
        }

        const payload = { judul, deskripsi, diskon_persen: diskon, tanggal_mulai: tanggalMulai, tanggal_berakhir: tanggalBerakhir, is_active: isActive };

        try {
            setSaveLoading(true);
            let response;

            if (isEditMode) {
                const id = document.getElementById('promoId').value;
                response = await api.request(`/promos/admin/${id}`, { method: 'PUT', body: payload });
            } else {
                response = await api.request('/promos/admin', { method: 'POST', body: payload });
            }

            if (response.success) {
                showToast(response.message || 'Promo berhasil disimpan!', 'success');
                closePromoModal();
                await loadPromos();
            } else {
                showToast(response.message || 'Gagal menyimpan promo', 'error');
            }
        } catch (error) {
            showToast('Gagal menyimpan: ' + error.message, 'error');
        } finally {
            setSaveLoading(false);
        }
    }

    // ─── Delete promo ────────────────────────────────────────────────────────────
    async function handleDeletePromo() {
        if (!deleteTargetId) return;

        try {
            setDeleteLoading(true);
            const response = await api.request(`/promos/admin/${deleteTargetId}`, { method: 'DELETE' });

            if (response.success) {
                showToast('Promo berhasil dihapus', 'success');
                closeDeleteModal();
                await loadPromos();
            } else {
                showToast(response.message || 'Gagal menghapus promo', 'error');
            }
        } catch (error) {
            showToast('Gagal menghapus: ' + error.message, 'error');
        } finally {
            setDeleteLoading(false);
        }
    }

    // ─── Helpers ────────────────────────────────────────────────────────────────
    function showTableLoading(show) {
        const tbody = document.getElementById('promosTableBody');
        if (show) tbody.innerHTML = '<tr class="skeleton-row"><td colspan="5"><div class="skeleton-text"></div></td></tr>';
    }

    function setSaveLoading(loading) {
        const btn = document.getElementById('savePromoBtn');
        if (!btn) return;
        btn.querySelector('.btn-text').style.display = loading ? 'none' : 'block';
        btn.querySelector('.btn-loader').style.display = loading ? 'block' : 'none';
        btn.disabled = loading;
    }

    function setDeleteLoading(loading) {
        const btn = document.getElementById('confirmDeleteBtn');
        if (!btn) return;
        btn.querySelector('.btn-text').style.display = loading ? 'none' : 'block';
        btn.querySelector('.btn-loader').style.display = loading ? 'block' : 'none';
        btn.disabled = loading;
    }

    function formatDate(dateStr) {
        if (!dateStr) return '—';
        const d = new Date(dateStr);
        return d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });
    }

    function escHtml(str) {
        return String(str || '').replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
    }
});
