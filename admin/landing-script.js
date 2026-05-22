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
