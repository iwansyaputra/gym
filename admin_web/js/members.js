// Members Page Script
document.addEventListener('DOMContentLoaded', async () => {
    if (!auth.requireAuth()) return;

    let currentPage = 1;
    let totalPages = 1;
    let allMembers = [];
    let filteredMembers = [];
    let allPackages = [];

    // Load initial data
    await loadMembers();
    await loadPackages();

    // Setup event listeners
    setupEventListeners();

    // Load members from API
    async function loadMembers() {
        try {
            showTableLoading(true);
            const response = await api.getAllUsers();

            if (response.success && response.data) {
                allMembers = response.data;
                filteredMembers = [...allMembers];
                renderTable();
            }
        } catch (error) {
            console.error('Error loading members:', error);
            showToast('Gagal memuat data member', 'error');
        } finally {
            showTableLoading(false);
        }
    }

    // Load membership packages
    async function loadPackages() {
        try {
            const response = await api.getMembershipPackages();
            const packageSelect = document.getElementById('memberPackage');

            if (response.success && response.data && packageSelect) {
                allPackages = response.data;
                packageSelect.innerHTML = '<option value="">Pilih paket...</option>' +
                    response.data.map(pkg => `
                        <option value="${pkg.id}">${pkg.nama} - ${formatCurrency(pkg.harga)}</option>
                    `).join('');
            }
        } catch (error) {
            console.error('Error loading packages:', error);
        }
    }

    // Render table
    function renderTable() {
        const tbody = document.getElementById('membersTableBody');
        if (!tbody) return;

        const itemsPerPage = 10;
        const startIndex = (currentPage - 1) * itemsPerPage;
        const endIndex = startIndex + itemsPerPage;
        const pageMembers = filteredMembers.slice(startIndex, endIndex);

        if (pageMembers.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8" class="text-center">Tidak ada data</td></tr>';
            return;
        }

        tbody.innerHTML = pageMembers.map(member => {
            const status = getMembershipStatus(member.membership_expiry, member.membership_status || 'none');
            return `
                <tr>
                    <td>${member.id}</td>
                    <td>${member.name || '-'}</td>
                    <td>${member.email || '-'}</td>
                    <td>${member.phone || '-'}</td>
                    <td>${member.package_name || '-'}</td>
                    <td><span class="badge ${status.class}">${status.label}</span></td>
                    <td>${status.status === 'pending' ? '-' : formatDate(member.membership_expiry)}</td>
                    <td>
                        <div class="action-buttons">
                            <button class="btn-icon btn-edit" onclick="editMember(${member.id})" title="Edit">
                                <svg viewBox="0 0 24 24" fill="none">
                                    <path d="M3 17.25V21H6.75L17.81 9.94L14.06 6.19L3 17.25ZM20.71 7.04C21.1 6.65 21.1 6.02 20.71 5.63L18.37 3.29C17.98 2.9 17.35 2.9 16.96 3.29L15.13 5.12L18.88 8.87L20.71 7.04Z" fill="currentColor"/>
                                </svg>
                            </button>
                            <button class="btn-icon btn-delete" onclick="deleteMember(${member.id}, '${member.name}')" title="Hapus">
                                <svg viewBox="0 0 24 24" fill="none">
                                    <path d="M6 19C6 20.1 6.9 21 8 21H16C17.1 21 18 20.1 18 19V7H6V19ZM19 4H15.5L14.5 3H9.5L8.5 4H5V6H19V4Z" fill="currentColor"/>
                                </svg>
                            </button>
                        </div>
                    </td>
                </tr>
            `;
        }).join('');

        updatePagination();
    }

    // Update pagination
    function updatePagination() {
        const itemsPerPage = 10;
        totalPages = Math.ceil(filteredMembers.length / itemsPerPage);
        if (totalPages === 0) totalPages = 1;

        const pageInfo = document.getElementById('pageInfo');
        const prevBtn = document.getElementById('prevPage');
        const nextBtn = document.getElementById('nextPage');
        const showingInfo = document.getElementById('showingInfo');
        const totalInfo = document.getElementById('totalInfo');

        if (pageInfo) pageInfo.textContent = `${currentPage} / ${totalPages}`;
        if (prevBtn) prevBtn.disabled = currentPage === 1;
        if (nextBtn) nextBtn.disabled = currentPage === totalPages;

        const startIndex = (currentPage - 1) * itemsPerPage + 1;
        const endIndex = Math.min(currentPage * itemsPerPage, filteredMembers.length);
        if (showingInfo) showingInfo.textContent = filteredMembers.length > 0 ? `${startIndex}–${endIndex}` : '0';
        if (totalInfo) totalInfo.textContent = filteredMembers.length;
    }

    // Setup event listeners
    function setupEventListeners() {
        // Add member button
        const addBtn = document.getElementById('addMemberBtn');
        if (addBtn) {
            addBtn.addEventListener('click', () => openModal());
        }

        // Search
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                const query = e.target.value.toLowerCase();
                filteredMembers = allMembers.filter(m =>
                    (m.name?.toLowerCase().includes(query)) ||
                    (m.email?.toLowerCase().includes(query)) ||
                    (m.phone?.includes(query))
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

        // Package filter
        const packageFilter = document.getElementById('packageFilter');
        if (packageFilter) {
            packageFilter.addEventListener('change', applyFilters);
        }

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

        // Modal close buttons
        const closeModal = document.getElementById('closeModal');
        const cancelBtn = document.getElementById('cancelBtn');

        if (closeModal) closeModal.addEventListener('click', () => closeModalForm());
        if (cancelBtn) cancelBtn.addEventListener('click', () => closeModalForm());

        // Form submit
        const memberForm = document.getElementById('memberForm');
        if (memberForm) {
            memberForm.addEventListener('submit', handleFormSubmit);
        }

        // Export button
        const exportBtn = document.getElementById('exportBtn');
        if (exportBtn) {
            exportBtn.addEventListener('click', exportToCSV);
        }
    }

    // Apply filters
    function applyFilters() {
        const statusFilter = document.getElementById('statusFilter').value;
        const packageFilter = document.getElementById('packageFilter').value;

        filteredMembers = allMembers.filter(member => {
            let matchStatus = true;
            let matchPackage = true;

            if (statusFilter !== 'all') {
                const status = getMembershipStatus(member.membership_expiry);
                matchStatus = status.status === statusFilter;
            }

            if (packageFilter !== 'all') {
                matchPackage = member.package_type === packageFilter;
            }

            return matchStatus && matchPackage;
        });

        currentPage = 1;
        renderTable();
    }

    // Open modal for add/edit
    window.openModal = function (memberId = null) {
        const modal = document.getElementById('memberModal');
        const modalTitle = document.getElementById('modalTitle');
        const form = document.getElementById('memberForm');

        if (memberId) {
            modalTitle.textContent = 'Edit Member';
            loadMemberData(memberId);
        } else {
            modalTitle.textContent = 'Tambah Member Baru';
            form.reset();
            document.getElementById('memberId').value = '';
        }

        modal.classList.add('active');
    };

    // Close modal
    function closeModalForm() {
        const modal = document.getElementById('memberModal');
        modal.classList.remove('active');
    }

    // Load member data for editing
    async function loadMemberData(memberId) {
        const member = allMembers.find(m => m.id === memberId);
        if (!member) return;

        document.getElementById('memberId').value = member.id;
        document.getElementById('memberName').value = member.name || '';
        document.getElementById('memberEmail').value = member.email || '';
        document.getElementById('memberPhone').value = member.phone || '';
        document.getElementById('memberGender').value = member.gender || '';
        document.getElementById('memberDob').value = member.date_of_birth ? member.date_of_birth.split('T')[0] : '';
        document.getElementById('memberAddress').value = member.address || '';

        let packageId = '';
        if (member.package_name) {
            const foundPackage = allPackages.find(p => p.nama === member.package_name || p.slug === member.package_name);
            if (foundPackage) {
                packageId = foundPackage.id;
            }
        }
        document.getElementById('memberPackage').value = packageId;

        // Hide password fields when editing
        document.getElementById('passwordGroup').style.display = 'none';
        document.getElementById('confirmPasswordGroup').style.display = 'none';
    }

    // Handle form submit
    async function handleFormSubmit(e) {
        e.preventDefault();

        const memberId = document.getElementById('memberId').value;
        const formData = {
            nama: document.getElementById('memberName').value,
            email: document.getElementById('memberEmail').value,
            hp: document.getElementById('memberPhone').value,
            jenis_kelamin: document.getElementById('memberGender').value,
            tanggal_lahir: document.getElementById('memberDob').value,
            alamat: document.getElementById('memberAddress').value,
            package_id: document.getElementById('memberPackage').value
        };

        if (!memberId) {
            formData.password = document.getElementById('memberPassword').value;
            formData.confirm_password = document.getElementById('memberConfirmPassword').value;
            // Penting: tambahkan flag agar di backend bisa bypass OTP jika admin yang tambah
            formData.is_admin_action = true;
        }

        try {
            setFormLoading(true);

            let response;
            if (memberId) {
                const adminUpdatePayload = {
                    name: formData.nama,
                    email: formData.email,
                    phone: formData.hp,
                    gender: formData.jenis_kelamin,
                    date_of_birth: formData.tanggal_lahir,
                    address: formData.alamat,
                    package_id: formData.package_id
                };
                response = await api.updateUser(memberId, adminUpdatePayload);
            } else {
                response = await api.register(formData);
            }

            if (response.success) {
                showToast(memberId ? 'Member berhasil diupdate' : 'Member berhasil ditambahkan', 'success');
                closeModalForm();
                await loadMembers();
            } else {
                showToast(response.message || 'Gagal menyimpan data', 'error');
            }
        } catch (error) {
            console.error('Error saving member:', error);
            showToast(error.message || 'Terjadi kesalahan', 'error');
        } finally {
            setFormLoading(false);
        }
    }

    // Edit member
    window.editMember = function (memberId) {
        openModal(memberId);
    };

    // Delete member
    window.deleteMember = function (memberId, memberName) {
        const modal = document.getElementById('deleteModal');
        const nameEl = document.getElementById('deleteMemberName');

        if (nameEl) nameEl.textContent = memberName;
        modal.classList.add('active');

        const confirmBtn = document.getElementById('confirmDeleteBtn');
        const newConfirmBtn = confirmBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);

        newConfirmBtn.addEventListener('click', async () => {
            try {
                setDeleteLoading(true);
                const response = await api.deleteUser(memberId);

                if (response.success) {
                    showToast('Member berhasil dihapus', 'success');
                    modal.classList.remove('active');
                    await loadMembers();
                } else {
                    showToast(response.message || 'Gagal menghapus member', 'error');
                }
            } catch (error) {
                console.error('Error deleting member:', error);
                showToast(error.message || 'Terjadi kesalahan', 'error');
            } finally {
                setDeleteLoading(false);
            }
        });

        const closeDeleteModal = document.getElementById('closeDeleteModal');
        const cancelDeleteBtn = document.getElementById('cancelDeleteBtn');

        if (closeDeleteModal) closeDeleteModal.addEventListener('click', () => modal.classList.remove('active'));
        if (cancelDeleteBtn) cancelDeleteBtn.addEventListener('click', () => modal.classList.remove('active'));
    };

    // Export to CSV
    function exportToCSV() {
        const headers = ['ID', 'Nama', 'Email', 'No. HP', 'Paket', 'Status', 'Expired'];
        const rows = filteredMembers.map(m => {
            const status = getMembershipStatus(m.membership_expiry);
            return [
                m.id,
                m.name,
                m.email,
                m.phone,
                m.package_name,
                status.label,
                formatDate(m.membership_expiry)
            ];
        });

        let csv = headers.join(',') + '\n';
        csv += rows.map(row => row.join(',')).join('\n');

        const blob = new Blob([csv], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `members_${new Date().toISOString().split('T')[0]}.csv`;
        a.click();
    }

    // Helper functions
    function showTableLoading(show) {
        const tbody = document.getElementById('membersTableBody');
        if (!tbody) return;

        if (show) {
            tbody.innerHTML = '<tr class="skeleton-row"><td colspan="8"><div class="skeleton-text"></div></td></tr>';
        }
    }

    function setFormLoading(loading) {
        const submitBtn = document.getElementById('submitBtn');
        const btnText = submitBtn.querySelector('.btn-text');
        const btnLoader = submitBtn.querySelector('.btn-loader');

        btnText.style.display = loading ? 'none' : 'block';
        btnLoader.style.display = loading ? 'block' : 'none';
        submitBtn.disabled = loading;
    }

    function setDeleteLoading(loading) {
        const confirmBtn = document.getElementById('confirmDeleteBtn');
        const btnText = confirmBtn.querySelector('.btn-text');
        const btnLoader = confirmBtn.querySelector('.btn-loader');

        btnText.style.display = loading ? 'none' : 'block';
        btnLoader.style.display = loading ? 'block' : 'none';
        confirmBtn.disabled = loading;
    }
});
