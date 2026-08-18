/* TOPECH — shared interactions */
document.addEventListener('DOMContentLoaded', function () {

  /* Mobile nav toggle */
  var toggle = document.querySelector('.nav-toggle');
  var nav = document.querySelector('.main-nav');
  if (toggle && nav) {
    toggle.addEventListener('click', function () {
      nav.classList.toggle('open');
    });
  }

  /* Product filter (products.html) */
  var filterBtns = document.querySelectorAll('.filter-btn');
  if (filterBtns.length) {
    var cards = document.querySelectorAll('.product-card[data-cat]');
    var applyFilter = function (cat) {
      cards.forEach(function (card) {
        card.style.display = (cat === 'all' || card.getAttribute('data-cat') === cat) ? '' : 'none';
      });
    };
    filterBtns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        filterBtns.forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
        applyFilter(btn.getAttribute('data-filter'));
      });
    });
    /* Support ?cat=xxx deep links */
    var q = new URLSearchParams(location.search).get('cat');
    if (q) {
      var target = document.querySelector('.filter-btn[data-filter="' + q + '"]');
      if (target) { target.click(); }
    }
  }

  /* FAQ accordion */
  document.querySelectorAll('.faq-q').forEach(function (q) {
    q.addEventListener('click', function () {
      var item = q.parentElement;
      var answer = item.querySelector('.faq-a');
      var isOpen = item.classList.contains('open');
      document.querySelectorAll('.faq-item.open').forEach(function (o) {
        o.classList.remove('open');
        o.querySelector('.faq-a').style.maxHeight = '0';
      });
      if (!isOpen) {
        item.classList.add('open');
        answer.style.maxHeight = answer.scrollHeight + 'px';
      }
    });
  });

  /* Detail gallery thumbnails */
  var mainImg = document.querySelector('.detail-gallery .main-img img');
  var thumbs = document.querySelectorAll('.detail-gallery .thumbs button');
  if (mainImg && thumbs.length) {
    thumbs.forEach(function (btn) {
      btn.addEventListener('click', function () {
        thumbs.forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
        var img = btn.querySelector('img');
        if (img) { mainImg.src = img.getAttribute('data-full') || img.src; }
      });
    });
  }

  /* Contact form -> FormSubmit (email to sales@topechltd.com) */
  var form = document.querySelector('#inquiry-form');
  if (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var get = function (id) { var el = document.getElementById(id); return el ? el.value.trim() : ''; };
      var status = document.getElementById('form-status');
      var btn = form.querySelector('button[type="submit"]');
      var showStatus = function (msg, ok) {
        if (!status) return;
        status.style.display = 'block';
        status.textContent = msg;
        status.style.background = ok ? '#e8f5e9' : '#fdecea';
        status.style.color = ok ? '#2e7d32' : '#c62828';
      };
      btn.disabled = true;
      btn.textContent = 'Sending...';
      var data = new FormData(form);
      data.delete('_honey');
      fetch('https://formsubmit.co/ajax/sales@topechltd.com', {
        method: 'POST',
        headers: { 'Accept': 'application/json' },
        body: data
      }).then(function (res) {
        if (!res.ok) { throw new Error('HTTP ' + res.status); }
        return res.json();
      }).then(function () {
        showStatus('✓ Thank you! Your inquiry has been sent. We will reply to your email within 24 hours.', true);
        form.reset();
        /* Facebook Pixel: Lead conversion (form inquiry) */
        if (typeof fbq === 'function') {
          fbq('track', 'Lead', { content_name: get('f-product') || 'General Inquiry' });
        }
      }).catch(function () {
        /* Fallback: open visitor's email client with prefilled message */
        var subject = encodeURIComponent('Inquiry from TOPECH website: ' + (get('f-product') || 'General'));
        var body = encodeURIComponent(
          'Name: ' + get('f-name') + '\n' +
          'Email: ' + get('f-email') + '\n' +
          'Company: ' + get('f-company') + '\n' +
          'Product: ' + get('f-product') + '\n\n' +
          'Message:\n' + get('f-message')
        );
        window.location.href = 'mailto:sales@topechltd.com?subject=' + subject + '&body=' + body;
        showStatus('Opening your email app... If nothing happens, please email us directly at sales@topechltd.com', false);
        if (typeof fbq === 'function') {
          fbq('track', 'Lead', { content_name: get('f-product') || 'General Inquiry' });
        }
      }).finally(function () {
        btn.disabled = false;
        btn.textContent = 'Submit Inquiry';
      });
    });
  }

  /* Facebook Pixel: Contact conversion (WhatsApp clicks, all pages) */
  document.addEventListener('click', function (e) {
    var link = e.target.closest ? e.target.closest('a[href*="wa.me"]') : null;
    if (link && typeof fbq === 'function') {
      fbq('track', 'Contact');
    }
  });

  /* Footer year */
  var year = document.querySelector('#year');
  if (year) { year.textContent = new Date().getFullYear(); }
});
