/* LXR-MOONSHINE — the still card | © 2026 iBoss21 / LXRCore */
(function () {
  const $ = (id) => document.getElementById(id);
  const card = $('card');
  let L = {}, left = 0, total = 0, timer = null, minutes = {};
  const t = (k, vars) => { let s = L[k] || k.split('.').pop().replace(/_/g, ' '); if (vars) for (const v in vars) s = s.replace('%{' + v + '}', vars[v]); return s; };
  function applyLocale() { document.querySelectorAll('[data-l]').forEach(el => { const k = 'ui.' + el.dataset.l; if (L[k]) el.textContent = L[k]; }); }
  function tick() {
    const pct = total > 0 ? Math.round((1 - left / total) * 100) : 0;
    $('meter').style.width = pct + '%';
    if (left <= 0) { $('state').textContent = t('ui.ready'); return; }
    const m = Math.floor(left / 60), s = Math.floor(left % 60);
    $('state').textContent = t('ui.left', { time: `${m}:${String(s).padStart(2, '0')}` });
    left -= 1;
  }
  window.addEventListener('message', e => {
    const m = e.data || {};
    if (m.brand && m.brand.theme) document.documentElement.dataset.theme = m.brand.theme;
    if (m.locale) { L = m.locale; applyLocale(); }
    if (m.lang) document.body.classList.toggle('lang-ka', m.lang === 'ka');
    if (m.recipes) minutes = Object.fromEntries(m.recipes.map(r => [r.id, r.minutes]));
    if (m.action === 'show') {
      const p = m.payload || {};
      $('owner').textContent = p.mine ? '' : t('ui.not_yours');
      clearInterval(timer);
      if (!p.recipe) { $('recipe').textContent = t('ui.idle'); $('meter').style.width = '0%'; $('state').textContent = t('ui.load_hint'); }
      else { $('recipe').textContent = t('recipe.' + p.recipe); left = Number(p.left) || 0; total = (minutes[p.recipe] || 0) * 60 || Math.max(left, 1); tick(); timer = setInterval(tick, 1000); }
      card.classList.remove('lxr-hidden');
    }
    if (m.action === 'hide') { card.classList.add('lxr-hidden'); clearInterval(timer); }
  });
  if (window.__LXR_MOCK__) window.postMessage(window.__LXR_MOCK__, '*');
})();
