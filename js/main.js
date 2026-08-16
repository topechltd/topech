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

  /* Contact form -> mailto */
  var form = document.querySelector('#inquiry-form');
  if (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var get = function (id) { var el = document.getElementById(id); return el ? el.value.trim() : ''; };
      var subject = encodeURIComponent('Inquiry from TOPECH website: ' + (get('f-product') || 'General'));
      var body = encodeURIComponent(
        'Name: ' + get('f-name') + '\n' +
        'Email: ' + get('f-email') + '\n' +
        'Company: ' + get('f-company') + '\n' +
        'Product: ' + get('f-product') + '\n\n' +
        'Message:\n' + get('f-message')
      );
      location.href = 'mailto:sales@topechltd.com?subject=' + subject + '&body=' + body;
    });
  }

  /* Footer year */
  var year = document.querySelector('#year');
  if (year) { year.textContent = new Date().getFullYear(); }
});
