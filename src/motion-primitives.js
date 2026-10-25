/**
 * Motion Primitives Library
 * Composable, physics-based animation primitives for tactile, responsive interfaces.
 * Includes sliding spring pill tabs, audio-reactive waveform equalizers,
 * concentric radar ripples, staggered cascade entrances, and spring toasts.
 */

/**
 * Initializes or updates a sliding pill indicator behind active buttons/tabs
 * Uses spring transition physics: transform & width glide smoothly.
 */
export function updateSlidingPillIndicator(container, activeSelector = '.active') {
  if (!container) return;
  const activeEl = container.querySelector(activeSelector);
  let indicator = container.querySelector('.motion-sliding-pill');

  if (!indicator) {
    indicator = document.createElement('span');
    indicator.className = 'motion-sliding-pill';
    indicator.setAttribute('aria-hidden', 'true');
    container.style.position = 'relative';
    container.appendChild(indicator);
  }

  if (!activeEl) {
    indicator.style.opacity = '0';
    return;
  }

  const containerRect = container.getBoundingClientRect();
  const activeRect = activeEl.getBoundingClientRect();

  const left = activeRect.left - containerRect.left;
  const top = activeRect.top - containerRect.top;
  const width = activeRect.width;
  const height = activeRect.height;

  indicator.style.opacity = '1';
  indicator.style.transform = `translate3d(${left}px, ${top}px, 0)`;
  indicator.style.width = `${width}px`;
  indicator.style.height = `${height}px`;
}

/**
 * Generates an accessible, animated motion waveform equalizer
 * Each bar has its own calculated spring frequency and reactive height.
 */
export function renderMotionWaveform({ count = 32, active = false, liveClass = '' } = {}) {
  const bars = Array.from({ length: count }, (_, i) => {
    // Generate harmonious natural distribution
    const baseH = 12 + ((i * 17 + 7) % 36);
    const delay = ((i % 8) * 0.12).toFixed(2);
    const speed = (0.9 + (i % 5) * 0.18).toFixed(2);
    return `<i class="motion-wave-bar ${active ? 'listening' : ''}" style="--bar-h:${baseH}px;--delay:${delay}s;--speed:${speed}s"></i>`;
  }).join('');

  return `
  <div class="motion-waveform-primitive ${active ? 'is-active' : ''} ${liveClass}" role="presentation">
    ${bars}
  </div>`;
}

/**
 * Concentric animated radar rings primitive for listening state or alerts
 */
export function renderMotionRadar({ active = true, tone = 'primary', size = 120 } = {}) {
  return `
  <div class="motion-radar-primitive ${active ? 'pulsing' : ''} tone-${tone}" style="--radar-size:${size}px;" aria-hidden="true">
    <span class="motion-radar-ring ring-1"></span>
    <span class="motion-radar-ring ring-2"></span>
    <span class="motion-radar-ring ring-3"></span>
    <span class="motion-radar-core"></span>
  </div>`;
}

/**
 * Automatically applies staggered entrance indices to container children
 */
export function applyStaggerAnimation(container, selector = ':scope > *') {
  if (!container) return;
  const items = container.querySelectorAll(selector);
  items.forEach((item, index) => {
    item.classList.add('motion-stagger-item');
    item.style.setProperty('--stagger-index', index);
  });
}

/**
 * Floating spring alert toast notification primitive
 */
let activeToastTimer = null;
export function showMotionAlertToast({ title, message, category = 'Other' }) {
  let toast = document.querySelector('.motion-alert-toast');
  if (!toast) {
    toast = document.createElement('aside');
    toast.className = 'motion-alert-toast';
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'assertive');
    document.body.appendChild(toast);
  }

  const icons = {
    Doorbell: '🔔',
    Alarm: '🚨',
    Siren: '📢',
    Knocking: '✊',
    Timer: '⏱️',
    Other: '✨',
  };

  toast.innerHTML = `
    <div class="toast-visual">
      <span class="toast-icon category-${category.toLowerCase()}">${icons[category] || '✨'}</span>
      <span class="toast-pulse-ring"></span>
    </div>
    <div class="toast-body">
      <div class="toast-kicker">DEMO SOUND DETECTED · <b>${category.toUpperCase()}</b></div>
      <h4 class="toast-title">${title}</h4>
      <p class="toast-msg">${message}</p>
    </div>
    <button class="toast-close" aria-label="Dismiss alert">&times;</button>
  `;

  toast.querySelector('.toast-close')?.addEventListener('click', () => {
    toast.classList.remove('visible');
  });

  // Trigger spring entrance
  requestAnimationFrame(() => {
    toast.classList.add('visible');
  });

  if (activeToastTimer) clearTimeout(activeToastTimer);
  activeToastTimer = setTimeout(() => {
    toast.classList.remove('visible');
  }, 4800);
}
