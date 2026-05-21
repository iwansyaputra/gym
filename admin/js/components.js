// admin_web/js/components.js

function renderSidebar() {
  const currentPage = window.location.pathname.split('/').pop() || 'dashboard.html';

  const menuItems = [
    { href: 'dashboard.html', icon: 'M3 13H11V3H3V13ZM3 21H11V15H3V21ZM13 21H21V11H13V21ZM13 3V9H21V3H13Z', text: 'Dashboard' },
    { href: 'members.html', icon: 'M16 11C17.66 11 18.99 9.66 18.99 8C18.99 6.34 17.66 5 16 5C14.34 5 13 6.34 13 8C13 9.66 14.34 11 16 11ZM8 11C9.66 11 10.99 9.66 10.99 8C10.99 6.34 9.66 5 8 5C6.34 5 5 6.34 5 8C5 9.66 6.34 11 8 11ZM8 13C5.67 13 1 14.17 1 16.5V19H15V16.5C15 14.17 10.33 13 8 13ZM16 13C15.71 13 15.38 13.02 15.03 13.05C16.19 13.89 17 15.02 17 16.5V19H23V16.5C23 14.17 18.33 13 16 13Z', text: 'Member' },
    { href: 'packages.html', icon: 'M11 2v20c-5.07-.5-9-4.79-9-10s3.93-9.5 9-10zm2 0v20c5.07-.5 9-4.79 9-10s-3.93-9.5-9-10zm-1 8.5c-1.93 0-3.5 1.57-3.5 3.5s1.57 3.5 3.5 3.5 3.5-1.57 3.5-3.5-1.57-3.5-3.5-3.5z', text: 'Kelola Harga' },
    { href: 'promos.html', icon: 'M21.41 11.58L12.41 2.58C12.05 2.22 11.55 2 11 2H4C2.9 2 2 2.9 2 4V11C2 11.55 2.22 12.05 2.59 12.42L11.59 21.42C11.95 21.78 12.45 22 13 22C13.55 22 14.05 21.78 14.41 21.41L21.41 14.41C21.78 14.05 22 13.55 22 13C22 12.45 21.77 11.94 21.41 11.58ZM5.5 7C4.67 7 4 6.33 4 5.5C4 4.67 4.67 4 5.5 4C6.33 4 7 4.67 7 5.5C7 6.33 6.33 7 5.5 7Z', text: 'Promo' },
    { href: 'checkin.html', icon: 'M9 11H7V13H9V11ZM13 11H11V13H13V11ZM17 11H15V13H17V11ZM19 4H18V2H16V4H8V2H6V4H5C3.89 4 3.01 4.9 3.01 6L3 20C3 21.1 3.89 22 5 22H19C20.1 22 21 21.1 21 20V6C21 4.9 20.1 4 19 4ZM19 20H5V9H19V20Z', text: 'Check-in NFC' },
    { href: 'topup.html', icon: 'M21 18V19C21 20.1 20.1 21 19 21H5C3.89 21 3 20.1 3 19V5C3 3.9 3.89 3 5 3H19C20.1 3 21 3.9 21 5V6H12C10.89 6 10 6.9 10 8V16C10 17.1 10.89 18 12 18H21ZM12 16H22V8H12V16ZM16 13.5C15.17 13.5 14.5 12.83 14.5 12C14.5 11.17 15.17 10.5 16 10.5C16.83 10.5 17.5 11.17 17.5 12C17.5 12.83 16.83 13.5 16 13.5Z', text: 'Topup Saldo' },
    { href: 'transactions.html', icon: 'M20 4H4C2.89 4 2 4.89 2 6V18C2 19.11 2.89 20 4 20H20C21.11 20 22 19.11 22 18V6C22 4.89 21.11 4 20 4ZM20 18H4V12H20V18ZM20 8H4V6H20V8Z', text: 'Transaksi' },
    { href: 'reports.html', icon: 'M19 3H5C3.9 3 3 3.9 3 5V19C3 20.1 3.9 21 5 21H19C20.1 21 21 20.1 21 19V5C21 3.9 20.1 3 19 3ZM9 17H7V10H9V17ZM13 17H11V7H13V17ZM17 17H15V13H17V17Z', text: 'Laporan' }
  ];

  let navItemsHtml = '';
  menuItems.forEach(item => {
    // Exact matching for href, but also handle case where pathname is empty (default to dashboard)
    const isActive = (currentPage === item.href) || (currentPage === '' && item.href === 'dashboard.html') ? 'active' : '';
    navItemsHtml += `
    <a href="${item.href}" class="nav-item ${isActive}">
      <svg class="nav-icon" viewBox="0 0 24 24" fill="none"><path d="${item.icon}" fill="currentColor"/></svg>
      ${item.text}
    </a>`;
  });

  const sidebarHtml = `
  <div class="sidebar-brand">
    <div class="brand-logo">
      <svg viewBox="0 0 24 24" fill="none"><path d="M20.57 14.86L22 13.43 20.57 12 17 15.57 8.43 7 12 3.43 10.57 2 9.14 3.43 7.71 2 5.57 4.14 4.14 2.71 2.71 4.14 4.14 5.57 2 7.71 3.43 9.14 2 10.57 3.43 12 7 8.43 15.57 17 12 20.57 13.43 22 14.86 20.57 16.29 22 18.43 19.86 19.86 21.29 21.29 19.86 19.86 18.43 22 16.29 20.57 14.86Z" fill="currentColor"/></svg>
    </div>
    <div><div class="brand-name">GymKu</div><div class="brand-tag">Admin Panel</div></div>
  </div>
  <nav class="sidebar-nav">
    <div class="nav-section-label">Menu</div>
    ${navItemsHtml}
  </nav>
  <div class="sidebar-footer">
    <div class="sidebar-user">
      <div class="sidebar-user-avatar" id="sidebarAvatar">A</div>
      <div class="sidebar-user-info">
        <div class="sidebar-user-name" id="adminName">Admin</div>
        <div class="sidebar-user-role">Administrator</div>
      </div>
    </div>
    <button class="btn-logout" id="logoutBtn">
      <svg viewBox="0 0 24 24" fill="none"><path d="M17 7L15.59 8.41 18.17 11H8V13H18.17L15.59 15.59 17 17 22 12 17 7ZM4 5H12V3H4C2.9 3 2 3.9 2 5V19C2 20.1 2.9 21 4 21H12V19H4V5Z" fill="currentColor"/></svg>Keluar
    </button>
  </div>
  `;

  // Inject into the sidebar element
  const sidebarEl = document.getElementById('sidebar');
  if (sidebarEl) {
    sidebarEl.innerHTML = sidebarHtml;
  }
}

// Execute immediately
renderSidebar();
