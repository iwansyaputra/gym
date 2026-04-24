// Packages Management Script
document.addEventListener('DOMContentLoaded', async () => {
    if (!auth.requireAuth()) return;

    let packages = [];

    // Load initial data
    await loadPackages();
    setupEventListeners();

    // Load packages from API
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

    // Render table
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
                <td style="font-weight: 600;">${pkg.nama || pkg.title || '-'}</td>
                <td>${pkg.durasi || pkg.duration || '-'} Hari</td>
                <td style="color: #4ade80; font-weight: bold;">${formatCurrency(pkg.harga || pkg.price || 0)}</td>
                    <button class="btn btn-secondary btn-sm" onclick="editPackage('${pkg.id}')">
                        <svg viewBox="0 0 24 24" fill="none"><path d="M3 17.25V21H6.75L17.81 9.94L14.06 6.19L3 17.25ZM20.71 7.04C21.1 6.65 21.1 6.02 20.71 5.63L18.37 3.29C17.98 2.9 17.35 2.9 16.96 3.29L15.13 5.12L18.88 8.87L20.71 7.04Z" fill="currentColor"/></svg>
                        Edit Paket
                    </button>
                </td>
            </tr>
        `).join('');
    }

    // Setup event listeners
    function setupEventListeners() {
        const closeModal = document.getElementById('closePackageModal');
        const cancelBtn = document.getElementById('cancelPackageBtn');
        const packageForm = document.getElementById('packageForm');

        if (closeModal) closeModal.addEventListener('click', () => closeEditModal());
        if (cancelBtn) cancelBtn.addEventListener('click', () => closeEditModal());

        if (packageForm) {
            packageForm.addEventListener('submit', handleFormSubmit);
        }
    }

    // Open Edit Modal
    window.editPackage = function (id) {
        const pkg = packages.find(p => p.id == id);
        if (!pkg) return;

        document.getElementById('editPackageId').value = pkg.id;
        document.getElementById('editPackageName').value = pkg.nama || pkg.title || '';
        document.getElementById('editPackagePrice').value = pkg.harga || pkg.price || 0;
        document.getElementById('editPackageDuration').value = pkg.durasi || parseInt((pkg.duration || '30').replace(/\D/g, '')) || 30;
        document.getElementById('editPackageDesc').value = pkg.deskripsi || '';
        document.getElementById('editPackageFeatures').value = Array.isArray(pkg.fitur) ? pkg.fitur.join('\n') : (Array.isArray(pkg.features) ? pkg.features.join('\n') : '');

        document.getElementById('editPackageModal').classList.add('active');
    };

    // Close Edit Modal
    function closeEditModal() {
        document.getElementById('editPackageModal').classList.remove('active');
        document.getElementById('packageForm').reset();
    }

    // Handle Form Submission
    async function handleFormSubmit(e) {
        e.preventDefault();

        const id = document.getElementById('editPackageId').value;
        const name = document.getElementById('editPackageName').value;
        const price = parseInt(document.getElementById('editPackagePrice').value, 10);
        const duration = parseInt(document.getElementById('editPackageDuration').value, 10);
        const desc = document.getElementById('editPackageDesc').value;
        const featuresText = document.getElementById('editPackageFeatures').value;

        if (isNaN(price) || price < 0 || isNaN(duration) || duration < 1 || !name) {
            showToast('Mohon lengkapi semua kolom dengan benar', 'error');
            return;
        }

        const features = featuresText.split('\n').map(f => f.trim()).filter(f => f.length > 0);

        try {
            setFormLoading(true);

            const payload = { 
                nama: name, 
                harga: price, 
                durasi: duration,
                deskripsi: desc,
                fitur: features
            };

            const response = await api.updateMembershipPackage(id, payload);

            if (response.success || response.statusCode === 200) {
                showToast('Harga paket berhasil diperbarui!', 'success');
                closeEditModal();
                await loadPackages(); // Reload data
            } else {
                showToast(response.message || 'Gagal menyimpan perubahan harga', 'error');
            }
        } catch (error) {
            console.error('Error updating package:', error);
            showToast('Fitur ini memerlukan API endpoint PUT /membership/packages di backend untuk berjalan.', 'error');
        } finally {
            setFormLoading(false);
        }
    }

    // UI Helpers
    function showTableLoading(show) {
        const tbody = document.getElementById('packagesTableBody');
        if (!tbody) return;
        if (show) tbody.innerHTML = '<tr class="skeleton-row"><td colspan="5"><div class="skeleton-text"></div></td></tr>';
    }

    function setFormLoading(loading) {
        const btn = document.getElementById('savePackageBtn');
        const text = btn.querySelector('.btn-text');
        const loader = btn.querySelector('.btn-loader');

        text.style.display = loading ? 'none' : 'block';
        loader.style.display = loading ? 'block' : 'none';
        btn.disabled = loading;
    }
});
