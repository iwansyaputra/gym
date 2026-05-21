// Packages Management Script
document.addEventListener('DOMContentLoaded', async () => {
    if (!auth.requireAuth()) return;

    let packages = [];

    await loadPackages();
    setupEventListeners();
    setupAddPackageModal();

    // ─── Load packages ────────────────────────────────────────────────────────
    async function loadPackages() {
        try {
            showTableLoading(true);
            const response = await api.getMembershipPackages();
            if (response.success && response.data) {
                packages = response.data;
                renderTable();
            } else {
                showToast('Gagal memuat data paket', 'error');
            }
        } catch (error) {
            console.error('Error loading packages:', error);
            showToast('Terjadi kesalahan saat memuat paket', 'error');
        } finally {
            showTableLoading(false);
        }
    }

    // ─── Render table ─────────────────────────────────────────────────────────
    function renderTable() {
        const tbody = document.getElementById('packagesTableBody');
        if (!tbody) return;

        if (packages.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="text-center">Tidak ada data paket ditemukan</td></tr>';
            return;
        }

        tbody.innerHTML = packages.map(pkg => `
            <tr>
                <td><span class="badge badge-primary">${pkg.id || pkg.slug || '-'}</span></td>
                <td style="font-weight:600;">${pkg.nama || pkg.title || '-'}</td>
                <td>${pkg.durasi !== undefined ? pkg.durasi : (pkg.duration || '-')} Hari</td>
                <td style="color:#4ade80;font-weight:bold;">${formatCurrency(pkg.harga || pkg.price || 0)}</td>
                <td>
                    <button class="btn btn-secondary btn-sm" onclick="editPackage('${pkg.id}')">
                        <svg viewBox="0 0 24 24" fill="none"><path d="M3 17.25V21H6.75L17.81 9.94L14.06 6.19L3 17.25ZM20.71 7.04C21.1 6.65 21.1 6.02 20.71 5.63L18.37 3.29C17.98 2.9 17.35 2.9 16.96 3.29L15.13 5.12L18.88 8.87L20.71 7.04Z" fill="currentColor"/></svg>
                        Edit
                    </button>
                </td>
            </tr>
        `).join('');
    }

    // ─── Setup Edit Modal ─────────────────────────────────────────────────────
    function setupEventListeners() {
        const closeModal = document.getElementById('closePackageModal');
        const cancelBtn = document.getElementById('cancelPackageBtn');
        const packageForm = document.getElementById('packageForm');

        if (closeModal) closeModal.addEventListener('click', closeEditModal);
        if (cancelBtn) cancelBtn.addEventListener('click', closeEditModal);
        if (packageForm) packageForm.addEventListener('submit', handleFormSubmit);
    }

    window.editPackage = function (id) {
        const pkg = packages.find(p => p.id == id);
        if (!pkg) return;

        document.getElementById('editPackageId').value = pkg.id;
        document.getElementById('editPackageName').value = pkg.nama || pkg.title || '';
        document.getElementById('editPackagePrice').value = pkg.harga || pkg.price || 0;
        document.getElementById('editPackageDuration').value = pkg.durasi !== undefined ? pkg.durasi : (parseInt((pkg.duration || '30').replace(/\D/g, '')) || 30);
        document.getElementById('editPackageDesc').value = pkg.deskripsi || '';
        document.getElementById('editPackageFeatures').value = Array.isArray(pkg.fitur)
            ? pkg.fitur.join('\n')
            : (Array.isArray(pkg.features) ? pkg.features.join('\n') : '');

        document.getElementById('editPackageModal').classList.add('active');
    };

    function closeEditModal() {
        document.getElementById('editPackageModal').classList.remove('active');
        document.getElementById('packageForm').reset();
    }

    async function handleFormSubmit(e) {
        e.preventDefault();

        const id = document.getElementById('editPackageId').value;
        const name = document.getElementById('editPackageName').value.trim();
        const price = parseInt(document.getElementById('editPackagePrice').value, 10);
        const duration = parseInt(document.getElementById('editPackageDuration').value, 10);
        const desc = document.getElementById('editPackageDesc').value.trim();
        const features = document.getElementById('editPackageFeatures').value
            .split('\n').map(f => f.trim()).filter(f => f.length > 0);

        if (!name || isNaN(price) || price < 0 || isNaN(duration) || duration < 0) {
            showToast('Mohon lengkapi semua kolom dengan benar', 'error');
            return;
        }

        try {
            setFormLoading(true);
            const response = await api.updateMembershipPackage(id, {
                nama: name, harga: price, durasi: duration, deskripsi: desc, fitur: features
            });

            if (response.success || response.statusCode === 200) {
                showToast('Paket berhasil diperbarui!', 'success');
                closeEditModal();
                await loadPackages();
            } else {
                showToast(response.message || 'Gagal menyimpan perubahan', 'error');
            }
        } catch (error) {
            showToast('Gagal menyimpan: ' + error.message, 'error');
        } finally {
            setFormLoading(false);
        }
    }

    // ─── Setup Tambah Paket Baru Modal ────────────────────────────────────────
    function setupAddPackageModal() {
        const openBtn  = document.getElementById('openAddPackageBtn');
        const closeBtn = document.getElementById('closeAddPackageModal');
        const cancelBtn = document.getElementById('cancelAddPackageBtn');
        const saveBtn  = document.getElementById('saveAddPackageBtn');

        if (openBtn)  openBtn.addEventListener('click', openAddModal);
        if (closeBtn) closeBtn.addEventListener('click', closeAddModal);
        if (cancelBtn) cancelBtn.addEventListener('click', closeAddModal);
        if (saveBtn)  saveBtn.addEventListener('click', handleAddPackageSubmit);
    }

    function openAddModal() {
        document.getElementById('addPackageForm').reset();
        document.getElementById('addPackageModal').classList.add('active');
    }

    function closeAddModal() {
        document.getElementById('addPackageModal').classList.remove('active');
        document.getElementById('addPackageForm').reset();
    }

    async function handleAddPackageSubmit() {
        const name     = document.getElementById('addPackageName').value.trim();
        const slug     = document.getElementById('addPackageSlug').value.trim().toLowerCase().replace(/\s+/g, '');
        const price    = parseInt(document.getElementById('addPackagePrice').value, 10);
        const duration = parseInt(document.getElementById('addPackageDuration').value, 10);
        const desc     = document.getElementById('addPackageDesc').value.trim();
        const features = document.getElementById('addPackageFeatures').value
            .split('\n').map(f => f.trim()).filter(f => f.length > 0);

        if (!name)                          { showToast('Nama paket wajib diisi', 'error'); return; }
        if (!slug)                          { showToast('Slug wajib diisi', 'error'); return; }
        if (isNaN(price) || price < 1000)   { showToast('Harga minimal Rp 1.000', 'error'); return; }
        if (isNaN(duration) || duration < 0){ showToast('Durasi minimal 0 hari (untuk paket harian)', 'error'); return; }

        if (packages.some(p => (p.slug || p.id) === slug)) {
            showToast(`Slug "${slug}" sudah digunakan paket lain`, 'error');
            return;
        }

        try {
            setAddLoading(true);
            const response = await api.addMembershipPackage({
                slug, nama: name, harga: price, durasi: duration, deskripsi: desc, fitur: features
            });

            if (response.success) {
                showToast('Paket baru berhasil ditambahkan!', 'success');
                closeAddModal();
                await loadPackages();
            } else {
                showToast(response.message || 'Gagal menambahkan paket', 'error');
            }
        } catch (error) {
            showToast('Gagal menambahkan: ' + error.message, 'error');
        } finally {
            setAddLoading(false);
        }
    }

    // ─── UI Helpers ───────────────────────────────────────────────────────────
    function showTableLoading(show) {
        const tbody = document.getElementById('packagesTableBody');
        if (!tbody) return;
        if (show) tbody.innerHTML = '<tr class="skeleton-row"><td colspan="5"><div class="skeleton-text"></div></td></tr>';
    }

    function setFormLoading(loading) {
        const btn = document.getElementById('savePackageBtn');
        if (!btn) return;
        btn.querySelector('.btn-text').style.display = loading ? 'none' : 'block';
        btn.querySelector('.btn-loader').style.display = loading ? 'block' : 'none';
        btn.disabled = loading;
    }

    function setAddLoading(loading) {
        const btn = document.getElementById('saveAddPackageBtn');
        if (!btn) return;
        btn.querySelector('.btn-text').style.display = loading ? 'none' : 'block';
        btn.querySelector('.btn-loader').style.display = loading ? 'block' : 'none';
        btn.disabled = loading;
    }
});
