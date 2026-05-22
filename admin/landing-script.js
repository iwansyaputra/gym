// Initialize theme immediately
(function() {
  const savedTheme = localStorage.getItem('gymku-theme') || 'dark';
  document.documentElement.setAttribute('data-theme', savedTheme);
})();

document.addEventListener('DOMContentLoaded', () => {
  const themeToggleBtn = document.getElementById('themeToggleBtn');
  const themeToggleIcon = document.getElementById('themeToggleIcon');

  const updateToggleIcon = (theme) => {
    if (theme === 'light') {
      themeToggleIcon.innerHTML = `<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>`;
    } else {
      themeToggleIcon.innerHTML = `
        <circle cx="12" cy="12" r="5"></circle>
        <line x1="12" y1="1" x2="12" y2="3"></line>
        <line x1="12" y1="21" x2="12" y2="23"></line>
        <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line>
        <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line>
        <line x1="1" y1="12" x2="3" y2="12"></line>
        <line x1="21" y1="12" x2="23" y2="12"></line>
        <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line>
        <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>
      `;
    }
  };

  const savedTheme = localStorage.getItem('gymku-theme') || 'dark';
  if (themeToggleIcon) {
    updateToggleIcon(savedTheme);
  }

  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', () => {
      const currentTheme = document.documentElement.getAttribute('data-theme') || 'dark';
      const newTheme = currentTheme === 'dark' ? 'light' : 'dark';

      document.documentElement.setAttribute('data-theme', newTheme);
      localStorage.setItem('gymku-theme', newTheme);

      if (themeToggleIcon) {
        updateToggleIcon(newTheme);
      }
    });
  }
});

// Navbar scroll effect
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 50);
});

// Hamburger menu
const hamburger = document.getElementById('hamburger');
const navLinks = document.querySelector('.nav-links');
hamburger.addEventListener('click', () => {
  navLinks.classList.toggle('open');
});
document.querySelectorAll('.nav-links a').forEach(a => {
  a.addEventListener('click', () => navLinks.classList.remove('open'));
});

// Intersection Observer for fade-in animations
const observerOpts = { threshold: 0.1, rootMargin: '0px 0px -50px 0px' };
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.style.opacity = '1';
      entry.target.style.transform = 'translateY(0)';
      observer.unobserve(entry.target);
    }
  });
}, observerOpts);

// Animate elements on scroll
const animateEls = document.querySelectorAll(
  '.feature-card, .arch-card, .admin-page-item, .channel-item, .feat-li, .db-badge, .platform-badge'
);
animateEls.forEach((el, i) => {
  el.style.opacity = '0';
  el.style.transform = 'translateY(24px)';
  el.style.transition = `opacity 0.5s ease ${i * 0.05}s, transform 0.5s ease ${i * 0.05}s`;
  observer.observe(el);
});

// Smooth active nav highlight
const sections = document.querySelectorAll('section[id]');
const navItems = document.querySelectorAll('.nav-links a');
window.addEventListener('scroll', () => {
  let current = '';
  sections.forEach(s => {
    if (window.scrollY >= s.offsetTop - 100) current = s.getAttribute('id');
  });
  navItems.forEach(a => {
    a.style.color = a.getAttribute('href') === `#${current}` ? '#e2e8f0' : '';
  });
});

// Payment Auto-Polling Simulation
const payHeader = document.querySelector('.pay-card-header');
const payNote = document.querySelector('.pay-note');

if (payHeader && payNote) {
  const runPolling = () => {
    // At the 4th second of the 5s cycle, simulate polling
    setTimeout(() => {
      payHeader.innerHTML = '<span class="pay-status-dot" style="background: #00d4ff;"></span>Mengecek E-Smartlink...';
      payNote.innerHTML = 'Menghubungi server payment...';
    }, 4000);
    
    // Reset back at the start of the next 5s cycle
    setTimeout(() => {
      payHeader.innerHTML = '<span class="pay-status-dot"></span>Menunggu Pembayaran...';
      payNote.innerHTML = 'Auto-check tiap 5 detik';
    }, 5000);
  };
  
  // Initial run
  runPolling();
  // Loop every 5s to match CSS progressAnim
  setInterval(runPolling, 5000);
}
