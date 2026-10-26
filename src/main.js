import { store } from './storage.js';
import { filterHistory, formatTime, DEFAULT_SETTINGS } from './domain.js';
import {
  CURATED_PALETTES,
  applyRealtimePalette,
  generateRandomHarmonicPalette,
  evaluateContrast,
  triggerRealtimeAlertColor,
} from './realtime-colors.js';
import {
  renderHaikeiLayeredWaves,
  renderHaikeiBlobScene,
  renderHaikeiAmbientBackground,
} from './haikei-svg.js';
import {
  updateSlidingPillIndicator,
  renderMotionWaveform,
  renderMotionRadar,
  applyStaggerAnimation,
  showMotionAlertToast,
} from './motion-primitives.js';
import {
  renderVirtualTryOn,
  tryonState,
  tryonStore,
  init3DCanvas,
  initSplitSlider,
  executeVirtualTryOn,
  TRYON_CATALOG,
  getFullCatalog,
  CURATED_RESOURCES,
} from './virtual-tryon.js';
import { speechService, SUPPORTED_LANGUAGES } from './speech-service.js';
import './style.css';

const icons = {
  home: '⌂',
  captions: '▤',
  alerts: '◉',
  history: '◷',
  settings: '⚙',
  tryon: '✨',
  mic: '◉',
  arrow: '↗',
  wave: '〰',
  check: '✓',
};

const state = {
  page: 'home',
  settings: store.getSettings(),
  history: store.getHistory(),
  listening: false,
  paused: false,
  permission: 'unknown',
  speech: null,
  interim: '',
  demoCaption: false,
  speechError: null,
  query: '',
  filter: 'all',
  alertEnabled: false,
  onboarding: !store.hasOnboarded(),
  captionEntries: [],
  captionFont: 1,
  colorPickerOpen: false,
  customPalette: null,
  language: 'en-US',
};

const app = document.querySelector('#app');
const nav = [
  ['home', 'Home'],
  ['captions', 'Live captions'],
  ['alerts', 'Sound alerts'],
  ['history', 'History'],
  ['tryon', 'Virtual Try-On'],
];

const id = () => `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
const esc = value =>
  String(value).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const dateLabel = value =>
  new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(value));

function greeting() {
  const h = new Date().getHours();
  return h < 12 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening';
}

function todayLabel() {
  return new Intl.DateTimeFormat(undefined, {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date()).toUpperCase();
}

function record(type, text, category = '') {
  if (!state.settings.retention) return;
  const row = { id: id(), type, text, timestamp: new Date().toISOString(), category };
  state.history = store.getHistory();
  store.addRecord(row);
  state.history = store.getHistory();
}

function badge(label, tone = 'neutral') {
  return `<span class="badge ${tone}"><i></i>${label}</span>`;
}

function getActivePalette() {
  if (state.customPalette) return state.customPalette;
  const palKey = state.settings.palette || 'aurora';
  return CURATED_PALETTES[palKey] || CURATED_PALETTES.aurora;
}

/**
 * Realtime Colors Quick-Bar Component (Top Bar & Settings)
 */
function renderRealtimePaletteBar() {
  const activePal = getActivePalette();
  const isDark =
    state.settings.theme === 'dark' ||
    (state.settings.theme === 'system' && window.matchMedia?.('(prefers-color-scheme: dark)').matches);
  const themeMode = isDark ? activePal.dark : activePal.light;
  const contrastInfo = evaluateContrast(themeMode.ink, themeMode.canvas);

  const chips = Object.entries(CURATED_PALETTES)
    .map(([key, pal]) => {
      const isActive = !state.customPalette && state.settings.palette === key;
      return `
      <button class="palette-chip ${isActive ? 'active' : ''}" data-palette="${key}" title="${pal.name} · ${pal.tag}" aria-label="Switch to ${pal.name} palette">
        <span class="palette-chip-inner" style="background: linear-gradient(135deg, ${pal.primary} 50%, ${pal.accent} 50%);"></span>
      </button>`;
    })
    .join('');

  return `
  <div class="realtime-palette-bar" role="toolbar" aria-label="Realtime Colors Palette Switcher">
    <div class="palette-swatches-group">
      ${chips}
    </div>
    <span class="palette-contrast-pill" title="WCAG 2.1 Contrast Ratio of text on background">
      ${contrastInfo.rating === 'AAA' ? '★' : '✓'} ${contrastInfo.label}
    </span>
    <button class="palette-dice-btn" data-action="randomize-palette" title="Randomize Realtime Harmonic Palette (Dice)" aria-label="Generate random harmonic color palette">
      🎲
    </button>
    <button class="palette-custom-btn ${state.colorPickerOpen ? 'active' : ''}" data-action="toggle-color-tuner" title="Tune Realtime Colors" aria-label="Open custom color tuner">
      🎨
    </button>
  </div>`;
}

/**
 * Realtime Color Tuner Drawer
 */
function renderColorTunerDrawer() {
  const activePal = getActivePalette();
  return `
  <aside class="color-tuner-drawer ${state.colorPickerOpen ? 'open' : ''}" aria-label="Realtime Color Customizer">
    <div class="color-tuner-head">
      <div>
        <h4>🎨 Realtime Color Tuner</h4>
        <small style="font-size:9px;color:var(--muted)">Instant CSS variables live preview</small>
      </div>
      <button class="toast-close" data-action="toggle-color-tuner" aria-label="Close color tuner">&times;</button>
    </div>
    <div class="color-tuner-grid">
      <div class="color-tuner-row">
        <label for="pickPrimary">Primary Accent</label>
        <input type="color" id="pickPrimary" class="color-picker-input" data-color="primary" value="${activePal.primary}" />
      </div>
      <div class="color-tuner-row">
        <label for="pickSecondary">Secondary Flow</label>
        <input type="color" id="pickSecondary" class="color-picker-input" data-color="secondary" value="${activePal.secondary}" />
      </div>
      <div class="color-tuner-row">
        <label for="pickAccent">Interactive Accent</label>
        <input type="color" id="pickAccent" class="color-picker-input" data-color="accent" value="${activePal.accent}" />
      </div>
      <div class="color-tuner-row">
        <label for="pickCanvas">Canvas Background</label>
        <input type="color" id="pickCanvas" class="color-picker-input" data-color="canvas" value="${activePal.light.canvas}" />
      </div>
    </div>
    <div style="margin-top:14px;display:flex;gap:8px;">
      <button class="outline-btn" style="flex:1" data-action="randomize-palette">🎲 Randomize</button>
      <button class="primary-btn" style="flex:1;justify-content:center" data-action="reset-palette">Reset</button>
    </div>
  </aside>`;
}

function shell(content) {
  return `
  <div class="app-shell">
    ${renderHaikeiAmbientBackground()}
    <aside class="sidebar">
      <a class="brand" href="#home" data-page="home">
        <span class="brand-mark">h<span>+</span></span>
        <span>hearassist<small>ACCESSIBLE COMPANION</small></span>
      </a>
      <div class="side-label">YOUR SPACE</div>
      <nav class="nav-container">
        ${nav
          .map(
            ([key, label]) => `
          <button class="nav-item ${state.page === key ? 'active' : ''}" data-page="${key}">
            <span class="nav-icon">${icons[key]}</span>
            ${label}
            ${key === 'alerts' && state.alertEnabled ? '<span class="nav-dot"></span>' : ''}
          </button>`
          )
          .join('')}
      </nav>
      <div class="sidebar-bottom">
        <div class="privacy-mini">
          <span>✳</span>
          <div>
            <b>Your privacy matters</b>
            <small>Audio stays on your device</small>
          </div>
        </div>
        <button class="nav-item ${state.page === 'settings' ? 'active' : ''}" data-page="settings">
          <span class="nav-icon">⚙</span>Settings
        </button>
        <div class="profile">
          <div class="avatar">HA</div>
          <div>
            <b>Alex Morgan</b>
            <small>Personal account</small>
          </div>
          <span class="profile-more">···</span>
        </div>
      </div>
    </aside>

    <main class="main">
      <header class="topbar">
        <div class="mobile-brand">
          <span class="brand-mark">h<span>+</span></span> hearassist
        </div>
        <div class="crumb">
          Workspace <span>/</span>
          <b>${{ home: 'Home', captions: 'Live captions', alerts: 'Sound alerts', history: 'History', settings: 'Settings', tryon: 'Virtual Try-On Studio' }[state.page]}</b>
        </div>
        <div class="top-actions">
          ${renderRealtimePaletteBar()}
          ${badge('Private by design', 'green')}
          <button class="icon-btn" aria-label="Open settings" data-page="settings">⚙</button>
        </div>
      </header>

      <section class="content">
        ${content}
      </section>

      <footer class="footer">
        Made for clearer connections <span>·</span> Enhanced with Motion Primitives, Haikei SVGs, & Realtime Colors
      </footer>
    </main>

    <nav class="mobile-nav">
      ${nav
        .map(
          ([key, label]) => `
        <button class="${state.page === key ? 'active' : ''}" data-page="${key}">
          <span>${icons[key]}</span>${label}
        </button>`
        )
        .join('')}
    </nav>

    ${renderColorTunerDrawer()}
  </div>`;
}

function home() {
  const last = state.history.slice(0, 3);
  return `
  <div class="welcome-row">
    <div>
      <div class="eyebrow">${todayLabel()}</div>
      <h1>${greeting()}, Alex <span class="wave-hand">👋</span></h1>
      <p class="subhead">Your space for a little more understanding.</p>
    </div>
    <button class="avatar avatar-large" data-page="settings" aria-label="Open profile and settings">AM</button>
  </div>

  <section class="hero">
    <!-- Embedded generative Haikei wave backdrop -->
    ${renderHaikeiLayeredWaves({ className: 'hero-haikei-waves' })}

    <div class="hero-copy">
      <div class="hero-kicker">
        <span class="status-pulse"></span>
        YOUR COMPANION IS READY
      </div>
      <h2>Stay in the moment.<br><em>Catch every word.</em></h2>
      <p>Turn conversations into clear captions and visual alerts, right when you need them.</p>
      <button class="primary-btn" data-page="captions">
        <span>▤</span> Start listening <span class="button-arrow">↗</span>
      </button>
      <div class="hero-note">
        <span>⌁</span> Microphone access is requested only when you start
      </div>
    </div>

    <div class="hero-visual">
      <!-- Generative Haikei Organic Blob behind the card -->
      ${renderHaikeiBlobScene({ width: 320, height: 320, className: 'hero-card-blob' })}

      <div class="sound-card">
        <div class="sound-card-head">
          <span class="mini-live"><i></i> LIVE CAPTION PREVIEW</span>
          <span>•••</span>
        </div>
        <!-- Motion Primitives Equalizer Waveform -->
        ${renderMotionWaveform({ count: 28, active: true })}
        <div class="preview-text">
          “It's lovely out here.<br>We should come back soon.”<span>▍</span>
        </div>
        <div class="preview-foot">
          <span>◷ Just now</span>
          <span>On-device speech service</span>
        </div>
      </div>
    </div>
  </section>

  <div class="section-head">
    <div>
      <div class="eyebrow">YOUR TOOLS</div>
      <h2 class="section-title">A little help, right on time</h2>
    </div>
    <button class="text-btn" data-page="settings">Personalize your space <span>→</span></button>
  </div>

  <div class="tool-grid">
    <button class="tool-card" data-page="captions">
      <span class="tool-icon teal">▤</span>
      <span class="tool-content">
        <b>Live captions</b>
        <small>Follow conversations as they happen with fluid text and audio waves</small>
        <span class="tool-link">Open captions <b>↗</b></span>
      </span>
      <span class="card-arrow">↗</span>
    </button>
    <button class="tool-card" data-page="alerts">
      <span class="tool-icon purple">◉</span>
      <span class="tool-content">
        <b>Sound alerts <span class="demo-chip">DEMO</span></b>
        <small>See visual alerts for important sounds with reactive color pulses</small>
        <span class="tool-link">Explore alerts <b>↗</b></span>
      </span>
      <span class="card-arrow">↗</span>
    </button>
    <button class="tool-card" data-page="tryon">
      <span class="tool-icon" style="background:var(--accent);color:var(--ink);">✨</span>
      <span class="tool-content">
        <b>Virtual Try-On Studio</b>
        <small>Preview eyewear, helmets, sneakers, and apparel with 3D model orbit & AI simulation</small>
        <span class="tool-link">Launch Studio <b>↗</b></span>
      </span>
      <span class="card-arrow">↗</span>
    </button>
  </div>

  <div class="lower-grid">
    <section class="panel activity-panel">
      <div class="panel-head">
        <div>
          <div class="eyebrow">RECENT ACTIVITY</div>
          <h3>Your latest moments</h3>
        </div>
        <button class="text-btn" data-page="history">View history →</button>
      </div>
      ${
        last.length
          ? `<div class="activity-list">${last
              .map(
                row => `
            <div class="activity-row">
              <span class="activity-icon ${row.type}">${row.type === 'caption' ? '▤' : '◉'}</span>
              <div class="activity-copy">
                <b>${esc(row.category || (row.type === 'caption' ? 'Caption' : 'Sound alert'))}</b>
                <small>${esc(row.text)}</small>
              </div>
              <time>${formatTime(row.timestamp)}</time>
            </div>`
              )
              .join('')}</div>`
          : `<div class="activity-empty">
              <span>◷</span>
              <div>
                <b>Room for new moments</b>
                <small>Your recent captions and alerts will show up here.</small>
              </div>
              <button class="text-btn" data-page="history">See history →</button>
            </div>`
      }
    </section>

    <section class="panel mode-panel">
      <div class="eyebrow">YOUR ACCESSIBILITY MODE</div>
      <h3>Comfort, your way.</h3>
      <p>Make HearAssist feel a little more like yours with high contrast, themes, and motion controls.</p>
      <div class="mode-options">
        <span>◐ ${state.settings.theme === 'system' ? 'System theme' : state.settings.theme[0].toUpperCase() + state.settings.theme.slice(1)}</span>
        <span>Aa ${state.settings.highContrast ? 'High contrast' : 'Standard contrast'}</span>
        <span>🎨 ${getActivePalette().name}</span>
      </div>
      <button class="outline-btn" data-page="settings">Open preferences <span>→</span></button>
    </section>
  </div>

  <div class="disclaimer">
    <span>ⓘ</span>
    <span>HearAssist is a companion portfolio concept. Sound alerts are simulated examples and not a substitute for safety equipment.</span>
    <button data-page="settings">Learn about privacy →</button>
  </div>`;
}

function captions() {
  const support = speechService.isSupported();
  const status = state.listening
    ? state.paused
      ? 'Paused'
      : 'Listening (annyang Speech Engine)'
    : state.permission === 'denied'
      ? 'Microphone access blocked'
      : !support
        ? state.demoCaption
          ? 'Demo sample shown'
          : 'Microphone speech service not detected'
        : 'Ready to listen (annyang)';

  return `
  <div class="page-heading">
    <div>
      <div class="eyebrow">CAPTIONS</div>
      <h1>Live captions</h1>
      <p class="subhead">A readable view of the words around you.</p>
    </div>
    ${badge(support ? 'annyang Speech Engine · Live' : 'Demo fallback', support ? 'green' : 'amber')}
  </div>

  <div class="caption-layout">
    <section class="panel caption-main">
      <div class="caption-status">
        <div class="listening-state">
          <!-- Concentric Motion Radar Primitive -->
          ${renderMotionRadar({ active: state.listening && !state.paused, size: 28 })}
          <div>
            <b>${status}</b>
            <small>${support ? 'Continuous listening via annyang with real-time interim streaming.' : 'Speech recognition not detected in this browser. Use Voice Dictation Test or Sample below.'}</small>
          </div>
        </div>
        ${state.listening ? '<span class="elapsed">● SESSION ACTIVE</span>' : ''}
      </div>

      ${
        state.permission !== 'granted' && !state.listening
          ? `<div class="permission-prompt-card" style="margin: 10px 24px; padding: 12px 16px; background: rgba(26, 127, 114, 0.08); border: 1.5px solid var(--primary); border-radius: 12px; display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap;">
              <div style="display: flex; align-items: center; gap: 10px;">
                <span style="font-size: 20px;">🎙️</span>
                <div>
                  <b style="font-size: 13px; color: var(--ink);">Microphone Permission Required</b>
                  <div style="font-size: 11px; color: var(--muted);">Click to grant microphone access for real-time continuous speech captions.</div>
                </div>
              </div>
              <button class="primary-btn" data-action="request-mic-permission" style="font-size: 11px; padding: 6px 14px; white-space: nowrap;">
                Grant Microphone Access
              </button>
            </div>`
          : ''
      }

      ${
        state.speechError
          ? `<div class="inline-warning" style="margin: 10px 24px; padding: 10px 14px; background: rgba(239, 68, 68, 0.12); border: 1px solid rgba(239, 68, 68, 0.35); border-radius: 10px; display: flex; align-items: center; justify-content: space-between; gap: 12px; font-size: 13px;">
              <span style="color: #ef4444; font-weight: 500;">ⓘ ${esc(state.speechError)}</span>
              <div style="display:flex;gap:6px;">
                <button class="primary-btn" style="padding: 4px 10px; font-size: 11px; white-space: nowrap;" data-action="request-mic-permission">Retry Mic</button>
                <button class="outline-btn" style="padding: 4px 10px; font-size: 11px; white-space: nowrap;" data-action="simulate-speech">Test Dictation</button>
              </div>
            </div>`
          : ''
      }

      <!-- Audio-reactive Equalizer Motion Primitive -->
      <div style="padding: 10px 24px; border-bottom: 1px solid var(--line); background: var(--canvas);">
        ${renderMotionWaveform({ count: 38, active: state.listening && !state.paused })}
      </div>

      <div class="transcript" style="--caption-scale:${state.settings.textScale}">
        ${
          state.captionEntries.length
            ? state.captionEntries
                .map(
                  entry => `
              <article class="transcript-entry">
                <time>${formatTime(entry.timestamp)}</time>
                <p>${esc(entry.text)}</p>
              </article>`
                )
                .join('')
            : `<div class="transcript-empty">
                <span class="empty-mic">▤</span>
                <h3>Your words will appear here</h3>
                <p>Start a session and captions will be shown in a clear, comfortable reading view with fluid typography.</p>
              </div>`
        }
        ${
          state.interim
            ? `<article class="transcript-entry interim">
                <time>NOW</time>
                <p>${esc(state.interim)}<span> ▍</span></p>
              </article>`
            : ''
        }
      </div>

      <div class="caption-controls">
        <button class="primary-btn ${state.listening ? 'stop-btn' : ''}" data-action="toggle-listening">
          ${state.listening ? (state.paused ? '▶ Resume captions' : '■ Stop listening') : support ? '● Start listening' : state.demoCaption ? 'Show another sample' : 'Show sample caption'}
        </button>
        ${state.listening ? `<button class="outline-btn" data-action="pause-listening">${state.paused ? '▶ Resume' : 'Ⅱ Pause'}</button>` : ''}
        <button class="outline-btn" data-action="simulate-speech" title="Instant voice test with live word streaming">⚡ Test Dictation</button>
        <button class="outline-btn" data-action="clear-captions">Clear transcript</button>
        <div class="font-controls">
          <button aria-label="Decrease caption text size" data-action="font-down">A−</button>
          <span>${Math.round(state.settings.textScale * 100)}%</span>
          <button aria-label="Increase caption text size" data-action="font-up">A+</button>
        </div>
      </div>
      ${!support ? '<div class="inline-info"><span>ⓘ</span> Sample demo captions are typed examples, not microphone transcription.</div>' : ''}
    </section>

    <aside class="caption-aside">
      <section class="panel">
        <span class="aside-icon teal">✳</span>
        <h3>Made to be readable</h3>
        <p>Captions adapt to your text-size, theme, and contrast preferences. Keep the screen active while you follow along.</p>
        <div class="preference-line">
          <span>Caption size</span>
          <b>${Math.round(state.settings.textScale * 100)}%</b>
        </div>
        <button class="text-btn" data-page="settings">Adjust preferences →</button>
      </section>

      <section class="panel" style="margin-top: 14px;">
        <span class="aside-icon" style="background: rgba(14, 165, 233, 0.15); color: #0284c7;">🎙️</span>
        <h3>Speech-to-Text Engine</h3>
        <p>Configured with <b>annyang</b> voice recognition library, offering continuous dictation and interim result streaming.</p>
        <div style="margin-top: 10px;">
          <label style="font-size: 11px; font-weight: 700; color: var(--muted); display: block; margin-bottom: 4px;">VOICE RECOGNITION LANGUAGE</label>
          <select class="styled-select" data-select="language" style="width: 100%; padding: 8px 10px; border-radius: 8px; border: 1px solid var(--line); background: var(--surface); color: var(--ink); font-size: 12px; font-weight: 600;">
            ${SUPPORTED_LANGUAGES.map(l => `<option value="${l.code}" ${state.language === l.code ? 'selected' : ''}>${l.flag} ${l.name}</option>`).join('')}
          </select>
        </div>
        <button class="outline-btn full" style="margin-top: 12px; font-size: 12px;" data-action="simulate-speech">
          ⚡ Run Voice Dictation Test
        </button>
      </section>

      <section class="privacy-card" style="margin-top: 14px;">
        <span>⌂</span>
        <div>
          <b>Private by default</b>
          <p>Audio is handled directly on your local device / browser. No audio streams are recorded or stored on remote servers by HearAssist.</p>
        </div>
      </section>
    </aside>
  </div>`;
}

function alerts() {
  const enabled = Object.entries(state.settings.categories)
    .filter(([, on]) => on)
    .map(([name]) => name);
  const soundRows = state.history.filter(r => r.type === 'alert').slice(0, 4);

  return `
  <div class="page-heading">
    <div>
      <div class="eyebrow">VISUAL AWARENESS</div>
      <h1>Sound alerts</h1>
      <p class="subhead">Important sounds, made visible with realtime colors.</p>
    </div>
    ${badge('DEMO MODE', 'amber')}
  </div>

  <div class="alert-banner">
    <!-- Embedded Haikei Waves in Alert Banner -->
    ${renderHaikeiLayeredWaves({ className: 'alert-haikei-waves' })}

    <div class="alert-banner-copy">
      <div class="hero-kicker">
        <span class="demo-live"></span>
        SIMULATED SOUND EVENTS
      </div>
      <h2>See what a sound alert<br>could feel like.</h2>
      <p>Trigger a sample event below to experience real-time color pulses, motion feedback, and spring toast alerts.</p>
      <button class="primary-btn" data-action="demo-alert" ${!state.alertEnabled || !enabled.length ? 'disabled' : ''}>
        ✨ Trigger sample alert
      </button>
    </div>

    <div class="alert-toggle-wrap">
      <div class="alert-toggle-label">DEMO LISTENER</div>
      <button class="switch ${state.alertEnabled ? 'on' : ''}" role="switch" aria-checked="${state.alertEnabled}" aria-label="Enable demo sound alerts" data-action="toggle-alert">
        <span></span>
      </button>
      <small>${state.alertEnabled ? 'Enabled · demo only' : 'Disabled'}</small>
    </div>
  </div>

  <div class="alert-columns">
    <section class="panel">
      <div class="panel-head">
        <div>
          <div class="eyebrow">YOUR ALERTS</div>
          <h3>Choose what matters</h3>
        </div>
        <span class="muted-small">${enabled.length} enabled</span>
      </div>
      <p class="panel-description">Categories configure which simulated demo alerts appear. They do not activate a real audio detector.</p>
      <div class="category-list">
        ${Object.entries(state.settings.categories)
          .map(
            ([name, on]) => `
          <label class="category-row">
            <span class="category-symbol">
              ${{ Doorbell: '🔔', Alarm: '🚨', Siren: '📢', Knocking: '✊', Timer: '⏱️', Other: '✨' }[name]}
            </span>
            <span>
              <b>${name}</b>
              <small>${{ Doorbell: 'Someone at your door', Alarm: 'Alarm or alert tone', Siren: 'Emergency vehicle siren', Knocking: 'A knock at the door', Timer: 'Timer or kitchen alert', Other: 'General alert' }[name]}</small>
            </span>
            <input type="checkbox" data-category="${name}" ${on ? 'checked' : ''} aria-label="Enable ${name} alert category" />
          </label>`
          )
          .join('')}
      </div>
    </section>

    <section class="panel">
      <div class="panel-head">
        <div>
          <div class="eyebrow">RECENT DEMOS</div>
          <h3>Alert activity</h3>
        </div>
        <button class="text-btn" data-page="history">All history →</button>
      </div>
      ${
        soundRows.length
          ? `<div class="alert-history">${soundRows
              .map(
                row => `
            <div class="alert-event">
              <span class="event-icon">${{ Doorbell: '🔔', Alarm: '🚨', Siren: '📢', Knocking: '✊', Timer: '⏱️', Other: '✨' }[row.category] || '✨'}</span>
              <div>
                <b>${esc(row.category || 'Sound')}</b>
                <small>${esc(row.text)}</small>
              </div>
              <time>${formatTime(row.timestamp)}</time>
            </div>`
              )
              .join('')}</div>`
          : `<div class="alert-empty">
              <span>◉</span>
              <b>No alerts just yet</b>
              <small>Turn on the demo listener above, then trigger a sample alert.</small>
            </div>`
      }
    </section>
  </div>

  <div class="disclaimer warning">
    <span>ⓘ</span>
    <span>Demo events are manually triggered samples. HearAssist does not detect real emergency sounds and cannot replace dedicated safety equipment.</span>
  </div>`;
}

function historyPage() {
  const rows = filterHistory(state.history, state.query, state.filter);
  return `
  <div class="page-heading">
    <div>
      <div class="eyebrow">YOUR ACTIVITY</div>
      <h1>History</h1>
      <p class="subhead">A private record of your recent captions and demo alerts.</p>
    </div>
    <button class="outline-btn" data-action="clear-history" ${state.history.length ? '' : 'disabled'}>
      ⌫ Clear history
    </button>
  </div>

  <section class="panel history-panel">
    <div class="history-tools">
      <label class="search-box">
        <span>⌕</span>
        <input type="search" placeholder="Search captions and alerts" value="${esc(state.query)}" aria-label="Search history" data-search />
      </label>
      <div class="filter-tabs" role="tablist">
        <button class="${state.filter === 'all' ? 'selected' : ''}" data-filter="all">All <span>${state.history.length}</span></button>
        <button class="${state.filter === 'caption' ? 'selected' : ''}" data-filter="caption">Captions</button>
        <button class="${state.filter === 'alert' ? 'selected' : ''}" data-filter="alert">Alerts</button>
      </div>
    </div>
    ${
      rows.length
        ? `<div class="history-list">${rows
            .map(
              row => `
          <article class="history-row">
            <span class="activity-icon ${row.type}">${row.type === 'caption' ? '▤' : '◉'}</span>
            <div class="history-copy">
              <div class="history-meta">
                <span>${row.type === 'caption' ? 'CAPTION' : 'DEMO ALERT'} ${row.category ? `· ${esc(row.category.toUpperCase())}` : ''}</span>
                <time>${dateLabel(row.timestamp)}</time>
              </div>
              <p>${esc(row.text)}</p>
            </div>
          </article>`
            )
            .join('')}</div>`
        : `<div class="history-empty">
            <span>◷</span>
            <h3>${state.history.length ? 'No results found' : 'Your history starts here'}</h3>
            <p>${state.history.length ? 'Try another search or change the filter.' : 'Captions and demo alerts you save will appear here.'}</p>
            ${state.history.length ? '' : `<button class="text-btn" data-page="captions">Start a caption session →</button>`}
          </div>`
    }
  </section>

  <div class="history-note">
    <span>⌂</span> Saved locally on this device. You can clear everything whenever you like.
  </div>`;
}

function settings() {
  const s = state.settings;
  const activePal = getActivePalette();

  return `
  <div class="page-heading">
    <div>
      <div class="eyebrow">MAKE IT YOURS</div>
      <h1>Settings</h1>
      <p class="subhead">A more comfortable experience, shaped around you.</p>
    </div>
  </div>

  <div class="settings-grid">
    <div class="settings-column">
      <!-- Realtime Colors Theme Explorer -->
      <section class="panel settings-panel">
        <div class="panel-title">
          <span class="settings-icon">🎨</span>
          <div>
            <h3>Realtime Colors & Appearance</h3>
            <p>Live palette switching inspired by realtimecolors.com.</p>
          </div>
        </div>

        <div style="margin-top: 14px;">
          <div style="font-size:11px;font-weight:700;margin-bottom:8px;color:var(--ink)">Active Palette</div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:14px;">
            ${Object.entries(CURATED_PALETTES)
              .map(([key, pal]) => {
                const isSelected = !state.customPalette && s.palette === key;
                return `
              <button class="outline-btn" style="text-align:left;display:flex;align-items:center;gap:8px;padding:8px 10px;${isSelected ? 'border-color:var(--primary);background:var(--primary-soft);font-weight:800;' : ''}" data-palette="${key}">
                <span style="width:16px;height:16px;border-radius:50%;background:linear-gradient(135deg, ${pal.primary} 50%, ${pal.accent} 50%);flex:none;box-shadow:0 1px 4px rgba(0,0,0,0.15)"></span>
                <span style="font-size:10px;color:var(--ink)">${pal.name}</span>
              </button>`;
              })
              .join('')}
          </div>

          <div style="display:flex;gap:8px;align-items:center;">
            <button class="primary-btn" data-action="randomize-palette" style="flex:1;justify-content:center;">
              🎲 Randomize Harmonic Colors
            </button>
            <button class="outline-btn" data-action="toggle-color-tuner">
              🎨 Custom Tuner
            </button>
          </div>
        </div>

        <div class="setting-row" style="margin-top: 14px;">
          <div>
            <b>Theme mode</b>
            <small>Follow system or choose light or dark.</small>
          </div>
          <div class="segmented">
            ${['system', 'light', 'dark']
              .map(
                v => `
              <button data-setting="theme" data-value="${v}" class="${s.theme === v ? 'chosen' : ''}">
                ${v[0].toUpperCase() + v.slice(1)}
              </button>`
              )
              .join('')}
          </div>
        </div>

        <div class="setting-row">
          <div>
            <b>High contrast</b>
            <small>Strengthen text and surface boundaries.</small>
          </div>
          <button class="switch ${s.highContrast ? 'on' : ''}" role="switch" aria-checked="${s.highContrast}" aria-label="High contrast" data-setting="highContrast">
            <span></span>
          </button>
        </div>

        <div class="setting-row">
          <div>
            <b>Reduce animation</b>
            <small>Disables spring physics and background motion.</small>
          </div>
          <button class="switch ${s.reducedMotion ? 'on' : ''}" role="switch" aria-checked="${s.reducedMotion}" aria-label="Reduce animation" data-setting="reducedMotion">
            <span></span>
          </button>
        </div>
      </section>

      <!-- Reading Comfort -->
      <section class="panel settings-panel">
        <div class="panel-title">
          <span class="settings-icon teal">Aa</span>
          <div>
            <h3>Reading comfort</h3>
            <p>Set a font scale that's easy on your eyes.</p>
          </div>
        </div>
        <div class="font-setting">
          <div>
            <b>Caption text size</b>
            <small>Adjusts live caption typography.</small>
          </div>
          <div class="font-controls">
            <button data-action="font-down" aria-label="Decrease caption text size">A−</button>
            <span>${Math.round(s.textScale * 100)}%</span>
            <button data-action="font-up" aria-label="Increase caption text size">A+</button>
          </div>
        </div>
        <div class="sample-caption" style="--caption-scale:${s.textScale}">
          “Your captions will feel just right.”
          <small>Caption preview with live font scale</small>
        </div>
      </section>

      <!-- Sound Alerts Settings -->
      <section class="panel settings-panel">
        <div class="panel-title">
          <span class="settings-icon purple">◉</span>
          <div>
            <h3>Sound alerts</h3>
            <p>Choose which categories appear in demo alerts.</p>
          </div>
        </div>
        <div class="settings-categories">
          ${Object.entries(s.categories)
            .map(
              ([name, on]) => `
            <label class="setting-row compact">
              <div><b>${name}</b></div>
              <input type="checkbox" data-category="${name}" ${on ? 'checked' : ''} aria-label="Enable ${name} alerts" />
            </label>`
            )
            .join('')}
        </div>
        <div class="setting-row">
          <div>
            <b>Vibration feedback</b>
            <small>Use device haptics where supported.</small>
          </div>
          <button class="switch ${s.vibration ? 'on' : ''}" role="switch" aria-checked="${s.vibration}" aria-label="Vibration feedback" data-setting="vibration">
            <span></span>
          </button>
        </div>
      </section>
    </div>

    <div class="settings-column">
      <section class="panel settings-panel">
        <div class="panel-title">
          <span class="settings-icon">▤</span>
          <div>
            <h3>Privacy & history</h3>
            <p>Your data stays on your device.</p>
          </div>
        </div>
        <div class="setting-row">
          <div>
            <b>Keep local history</b>
            <small>Captions and demo events stay in this browser.</small>
          </div>
          <button class="switch ${s.retention ? 'on' : ''}" role="switch" aria-checked="${s.retention}" aria-label="Keep local history" data-setting="retention">
            <span></span>
          </button>
        </div>

        <div class="permission-box">
          <div class="permission-status">${state.permission === 'granted' ? '✓' : 'ⓘ'}</div>
          <div>
            <b>Microphone permission</b>
            <small>${state.permission === 'granted' ? 'Granted by your browser' : state.permission === 'denied' ? 'Blocked. Change this in browser site settings.' : 'Not requested yet'}</small>
          </div>
        </div>

        <p class="privacy-copy">
          Microphone access is requested only when starting live captions. Audio processing is handled by your browser service and is never stored on external servers by HearAssist.
        </p>
        <button class="outline-btn full" data-action="clear-history">Delete local history</button>
      </section>

      <section class="panel settings-panel about-panel">
        <div class="eyebrow">ABOUT HEARASSIST</div>
        <h3>Understand more.<br><em>Stay connected.</em></h3>
        <p>An accessible companion portfolio concept engineered with modern motion primitives, generative Haikei vector art, and real-time colors.</p>
        <div class="about-meta">
          <span>VERSION</span>
          <b>1.0.0 · Motion & SVG Edition</b>
        </div>
        <div class="about-meta">
          <span>REALTIME PALETTE</span>
          <b>${activePal.name}</b>
        </div>
        <div class="about-meta">
          <span>DATA STORAGE</span>
          <b>Local browser storage only</b>
        </div>
      </section>

      <button class="reset-link" data-action="reset-settings">↺ Reset all preferences to default</button>
    </div>
  </div>`;
}

function onboarding() {
  return `
  <div class="onboard-backdrop">
    <section class="onboard-card">
      <div class="brand-mark onboard-mark">h<span>+</span></div>
      <div class="eyebrow">A MORE CONNECTED MOMENT</div>
      <h1>Welcome to<br>HearAssist.</h1>
      <p>Readable speech captions, generative Haikei visual accents, and real-time adaptive colors designed for everyone.</p>

      <div class="onboard-points">
        <div>
          <span>▤</span>
          <div>
            <b>Follow the conversation</b>
            <small>Use your browser's speech recognition when available.</small>
          </div>
        </div>
        <div>
          <span>◉</span>
          <div>
            <b>Explore visual alerts</b>
            <small>Try sample events with real-time color reactivity.</small>
          </div>
        </div>
        <div>
          <span>🎨</span>
          <div>
            <b>Realtime Colors & Motion</b>
            <small>Customize themes with live harmonic color palettes.</small>
          </div>
        </div>
      </div>

      <button class="primary-btn full" data-action="finish-onboarding">
        Let's get started <span>→</span>
      </button>
      <small class="onboard-disclaimer">Sound alerts in this prototype are simulated demo events.</small>
    </section>
  </div>`;
}

function render() {
  const dark =
    state.settings.theme === 'dark' ||
    (state.settings.theme === 'system' && window.matchMedia?.('(prefers-color-scheme: dark)').matches);

  document.documentElement.dataset.theme = dark ? 'dark' : 'light';
  document.documentElement.classList.toggle('high-contrast', !!state.settings.highContrast);
  document.documentElement.classList.toggle('reduce-motion', !!state.settings.reducedMotion);

  // Apply Realtime Colors palette
  applyRealtimePalette(getActivePalette(), dark);

  const pages = { home, captions, alerts, history: historyPage, settings, tryon: renderVirtualTryOn };
  app.innerHTML = shell(pages[state.page]());
  if (state.onboarding) app.insertAdjacentHTML('beforeend', onboarding());

  postRender();
  bind();
}

/**
 * Post-render lifecycle: apply motion primitives & sliding pills
 */
function postRender() {
  // Apply sliding pill to navigation and filter tabs
  const navContainer = app.querySelector('.nav-container');
  if (navContainer) updateSlidingPillIndicator(navContainer, '.nav-item.active');

  const filterTabs = app.querySelector('.filter-tabs');
  if (filterTabs) updateSlidingPillIndicator(filterTabs, 'button.selected');

  const segmentedTheme = app.querySelector('.segmented');
  if (segmentedTheme) updateSlidingPillIndicator(segmentedTheme, 'button.chosen');

  // Apply staggered entrance animations to lists
  applyStaggerAnimation(app.querySelector('.tool-grid'), '.tool-card');
  applyStaggerAnimation(app.querySelector('.activity-list'), '.activity-row');
  applyStaggerAnimation(app.querySelector('.history-list'), '.history-row');

  // Virtual Try-On post-render handlers
  if (state.page === 'tryon') {
    if (tryonState.viewMode === '3d') {
      init3DCanvas();
    } else {
      initSplitSlider();
    }
  }
}

function setPage(page) {
  if (!['home', 'captions', 'alerts', 'history', 'settings', 'tryon'].includes(page)) return;
  state.page = page;
  render();
}

function persistSettings() {
  store.saveSettings(state.settings);
  render();
}

function startListening() {
  state.speechError = null;
  state.listening = true;
  state.paused = false;

  speechService.setLanguage(state.language || 'en-US');

  speechService.start({
    onInterim: (text) => {
      state.interim = text;
      state.permission = 'granted';
      render();
    },
    onFinal: (text) => {
      if (!text || !text.trim()) return;
      const row = { text: text.trim(), timestamp: new Date().toISOString() };
      state.captionEntries.push(row);
      record('caption', text.trim());
      state.interim = '';
      state.permission = 'granted';
      render();
    },
    onStatus: (status) => {
      if (status === 'listening') {
        state.listening = true;
        state.paused = false;
        state.permission = 'granted';
      } else if (status === 'paused') {
        state.paused = true;
      } else if (status === 'stopped') {
        state.listening = false;
        state.paused = false;
      }
      render();
    },
    onError: (err) => {
      console.warn('SpeechService error notice:', err);
      state.speechError = err.message || String(err);
      if (err.type === 'permission_denied' || err.type === 'permission_blocked') {
        state.permission = 'denied';
        state.listening = false;
      }
      render();
    },
    onLevel: (normalizedLevel, dataArray) => {
      const bars = document.querySelectorAll('.motion-wave-bar');
      if (bars && bars.length && dataArray) {
        bars.forEach((bar, idx) => {
          const val = dataArray[idx % dataArray.length] || 0;
          const h = Math.max(8, Math.min(48, (val / 255) * 40 + normalizedLevel * 20));
          bar.style.height = `${h}px`;
        });
      }
    },
  });

  render();
}

function stopListening() {
  speechService.stop();
  state.listening = false;
  state.paused = false;
  state.interim = '';
  render();
}

function bind() {
  app.querySelectorAll('[data-page]').forEach(el =>
    el.addEventListener('click', () => setPage(el.dataset.page))
  );

  // Realtime Colors Palette Quick-Switchers
  app.querySelectorAll('[data-palette]').forEach(el => {
    el.addEventListener('click', () => {
      const palKey = el.dataset.palette;
      state.settings.palette = palKey;
      state.customPalette = null;
      persistSettings();
    });
  });

  // Realtime Color Picker Sliders
  app.querySelectorAll('.color-picker-input').forEach(input => {
    input.addEventListener('input', e => {
      const colorType = e.target.dataset.color;
      const hex = e.target.value;
      const current = getActivePalette();

      if (!state.customPalette) {
        state.customPalette = JSON.parse(JSON.stringify(current));
        state.customPalette.id = 'custom-user';
        state.customPalette.name = 'Custom Tuned';
      }

      if (colorType === 'primary') {
        state.customPalette.primary = hex;
        state.customPalette.primaryHover = hex;
      } else if (colorType === 'secondary') {
        state.customPalette.secondary = hex;
      } else if (colorType === 'accent') {
        state.customPalette.accent = hex;
      } else if (colorType === 'canvas') {
        state.customPalette.light.canvas = hex;
      }

      const isDark = document.documentElement.dataset.theme === 'dark';
      applyRealtimePalette(state.customPalette, isDark);
    });
  });

  app.querySelectorAll('[data-action]').forEach(el =>
    el.addEventListener('click', () => {
      const action = el.dataset.action;

      if (action === 'toggle-listening') {
        state.listening ? stopListening() : startListening();
      }

      if (action === 'pause-listening') {
        if (state.paused) {
          state.paused = false;
          speechService.resume();
        } else {
          state.paused = true;
          speechService.pause();
        }
        render();
      }

      if (action === 'simulate-speech') {
        state.listening = true;
        state.paused = false;
        state.speechError = null;
        render();
        const testPhrases = [
          'Hello, HearAssist is listening to your voice clearly in real-time.',
          'The annyang speech engine is active and capturing continuous speech.',
          'Accessibility typography scaling and high contrast are functioning perfectly.',
          'Voice recognition is working properly and generating live captions.',
        ];
        const phrase = testPhrases[Math.floor(Math.random() * testPhrases.length)];
        speechService.simulateVoiceInput({
          text: phrase,
          onInterim: (text) => {
            state.interim = text;
            render();
          },
          onFinal: (text) => {
            state.captionEntries.push({
              text,
              timestamp: new Date().toISOString(),
              category: 'LIVE DICTATION',
            });
            record('caption', text, 'LIVE DICTATION');
            state.interim = '';
            render();
          },
        });
      }

      if (action === 'clear-captions') {
        state.captionEntries = [];
        state.demoCaption = false;
        state.interim = '';
        state.history = state.history.filter(x => x.type !== 'caption');
        store.clearHistory();
        state.history.forEach(store.addRecord.bind(store));
        render();
      }

      if (action === 'demo-sample') {
        state.demoCaption = true;
        state.speechError = null;
        const samples = [
          'Hello, can you hear me clearly?',
          'Welcome to HearAssist accessible captions.',
          'The voice recognition system is active and responsive.',
          'Everything is set up and working properly.',
        ];
        const sampleText = samples[Math.floor(Math.random() * samples.length)];
        state.captionEntries.push({
          text: sampleText,
          timestamp: new Date().toISOString(),
          category: 'DEMO SAMPLE',
        });
        record('caption', sampleText, 'DEMO SAMPLE');
        render();
      }

      if (action === 'font-up' || action === 'font-down') {
        state.settings.textScale = Math.min(
          1.7,
          Math.max(0.8, +(state.settings.textScale + (action === 'font-up' ? 0.1 : -0.1)).toFixed(1))
        );
        persistSettings();
      }

      if (action === 'toggle-alert') {
        state.alertEnabled = !state.alertEnabled;
        render();
      }

      // Demo Sound Alert with Motion Toast & Realtime Color Pulse
      if (action === 'demo-alert') {
        const categories = Object.entries(state.settings.categories)
          .filter(([, on]) => on)
          .map(([name]) => name);

        if (!state.alertEnabled || !categories.length) return;

        const category = categories[Math.floor(Math.random() * categories.length)];
        const phrases = {
          Doorbell: 'Someone may be at the door.',
          Alarm: 'A sample alarm tone was detected.',
          Siren: 'A sample emergency siren was detected.',
          Knocking: 'Someone may be knocking.',
          Timer: 'A sample timer notification.',
          Other: 'A sample sound event was triggered.',
        };

        const alertText = phrases[category] || 'A sample sound was triggered.';
        record('alert', alertText, category);

        // 1. Trigger Realtime Colors pulse
        triggerRealtimeAlertColor(category);

        // 2. Trigger Motion Primitives Spring Toast Alert
        showMotionAlertToast({
          title: `${category} Sound`,
          message: alertText,
          category,
        });

        // 3. Vibration if enabled
        if (state.settings.vibration && navigator.vibrate) {
          navigator.vibrate([100, 60, 100]);
        }

        render();
      }

      if (action === 'randomize-palette') {
        const newHarmonic = generateRandomHarmonicPalette();
        state.customPalette = newHarmonic;
        state.settings.palette = newHarmonic.id;
        persistSettings();
      }

      if (action === 'toggle-color-tuner') {
        state.colorPickerOpen = !state.colorPickerOpen;
        render();
      }

      if (action === 'reset-palette') {
        state.customPalette = null;
        state.settings.palette = 'aurora';
        persistSettings();
      }

      if (action === 'clear-history') {
        if (
          state.history.length &&
          window.confirm('Delete all locally saved captions and alerts? This cannot be undone.')
        ) {
          state.history = [];
          state.captionEntries = [];
          store.clearHistory();
          render();
        }
      }

      if (action === 'reset-settings' && window.confirm('Reset all accessibility preferences to their defaults?')) {
        state.settings = { ...DEFAULT_SETTINGS };
        state.customPalette = null;
        persistSettings();
      }

      if (action === 'finish-onboarding') {
        store.completeOnboarding();
        state.onboarding = false;
        render();
      }

      if (action === 'request-mic-permission') {
        startListening();
      }

      // --- Virtual Try-On Actions ---
      if (action === 'tryon-mode') {
        tryonState.viewMode = el.dataset.mode;
        render();
      }

      if (action === 'select-tryon-item') {
        const item = getFullCatalog().find(i => i.id === el.dataset.id);
        if (item) tryonState.selectedItem = item;
        render();
      }

      if (action === 'filter-tryon-cat') {
        tryonState.selectedCategory = el.dataset.cat;
        render();
      }

      if (action === 'select-avatar') {
        tryonState.personImage = el.dataset.img;
        tryonState.personAvatarName = el.dataset.name;
        render();
      }

      if (action === 'toggle-add-resource') {
        tryonState.resourceModalOpen = !tryonState.resourceModalOpen;
        render();
      }

      if (action === 'quick-add-curated') {
        const item = CURATED_RESOURCES.find(i => i.id === el.dataset.id);
        if (item) {
          tryonStore.saveCustomItem(item);
          tryonState.selectedItem = item;
          tryonState.resourceModalOpen = false;
          render();
        }
      }

      if (action === 'save-custom-resource') {
        const name = app.querySelector('#customItemName')?.value.trim();
        if (!name) {
          alert('Please enter a resource name');
          return;
        }
        const item = {
          id: `custom_${Date.now()}`,
          name,
          category: app.querySelector('#customItemCat')?.value || 'eyewear',
          price: parseFloat(app.querySelector('#customItemPrice')?.value) || 95,
          desc: app.querySelector('#customItemDesc')?.value.trim() || 'Custom user resource',
          image: app.querySelector('#customItemImg')?.value || '/assets/sunglasses.png',
          glb: app.querySelector('#customItemGlb')?.value || null,
          isCustom: true,
        };
        tryonStore.saveCustomItem(item);
        tryonState.selectedItem = item;
        tryonState.resourceModalOpen = false;
        render();
      }

      if (action === 'delete-custom-resource') {
        const targetId = el.dataset.id;
        tryonStore.deleteCustomItem(targetId);
        const catalog = getFullCatalog();
        if (tryonState.selectedItem.id === targetId) {
          tryonState.selectedItem = catalog[0];
        }
        render();
      }

      // Garment Cant & Fit Controls
      if (action === 'set-garment-cant') {
        tryonState.garmentCantAngle = parseFloat(el.dataset.angle);
        render();
      }

      if (action === 'reset-garment-tuning') {
        tryonState.garmentCantAngle = 0;
        tryonState.garmentOffsetY = 0;
        tryonState.garmentOffsetX = 0;
        tryonState.garmentScale = 1.0;
        render();
      }

      // 3D Angle Presets
      if (action === 'set-orbit-preset') {
        tryonState.autoRotate = false;
        if (el.dataset.yaw !== undefined) tryonState.orbitYaw = parseFloat(el.dataset.yaw);
        if (el.dataset.pitch !== undefined) tryonState.orbitPitch = parseFloat(el.dataset.pitch);
        if (el.dataset.roll !== undefined) tryonState.orbitRoll = parseFloat(el.dataset.roll);
        render();
      }

      if (action === 'run-tryon') {
        executeVirtualTryOn(
          (prog) => {
            const fill = app.querySelector('.tryon-progress-fill');
            if (fill) fill.style.width = `${prog}%`;
          },
          () => render()
        );
        render();
      }

      if (action === 'toggle-tryon-config') {
        tryonState.configOpen = !tryonState.configOpen;
        render();
      }

      if (action === 'save-tryon-config') {
        const ep = app.querySelector('#tryonEndpointInput')?.value || '';
        const tk = app.querySelector('#tryonTokenInput')?.value || '';
        tryonStore.saveEndpoint(ep);
        tryonStore.saveToken(tk);
        tryonState.apiEndpoint = ep;
        tryonState.apiToken = tk;
        tryonState.configOpen = false;
        render();
      }

      if (action === 'reset-tryon-config') {
        tryonStore.saveEndpoint('');
        tryonStore.saveToken('');
        tryonState.apiEndpoint = '';
        tryonState.apiToken = '';
        tryonState.configOpen = false;
        render();
      }

      if (action === 'download-tryon') {
        const a = document.createElement('a');
        a.href = tryonState.personImage;
        a.download = `tryon-${tryonState.selectedItem.id}.png`;
        a.click();
      }

      if (action === 'clear-tryon-history') {
        tryonStore.clearSessions();
        render();
      }

      if (action === 'toggle-orbit-autorotate') {
        tryonState.autoRotate = !tryonState.autoRotate;
        render();
      }

      if (action === 'toggle-orbit-wireframe') {
        tryonState.wireframe = !tryonState.wireframe;
        render();
      }

      if (action === 'reset-orbit-angle') {
        tryonState.orbitYaw = 0.4;
        tryonState.orbitPitch = 0.2;
        tryonState.orbitRoll = 0.0;
        tryonState.orbitZoom = 1.0;
        render();
      }
    })
  );

  // Real-time Tuning Sliders Event Listener
  app.querySelectorAll('[data-control]').forEach(input => {
    input.addEventListener('input', e => {
      const ctrl = e.target.dataset.control;
      const val = parseFloat(e.target.value);
      if (ctrl === 'garment-cant') tryonState.garmentCantAngle = val;
      if (ctrl === 'garment-offset-y') tryonState.garmentOffsetY = val;
      if (ctrl === 'garment-scale') tryonState.garmentScale = val / 100;
      if (ctrl === 'orbit-yaw') {
        tryonState.autoRotate = false;
        tryonState.orbitYaw = val / 100;
      }
      if (ctrl === 'orbit-pitch') tryonState.orbitPitch = val / 100;
      if (ctrl === 'orbit-roll') tryonState.orbitRoll = val / 100;
      if (ctrl === 'orbit-zoom') tryonState.orbitZoom = val / 100;

      // Update garment overlay directly in DOM for instantaneous feedback
      const garment = app.querySelector('.split-garment-layer');
      if (garment) {
        garment.style.transform = `translate(calc(-50% + ${tryonState.garmentOffsetX}px), ${tryonState.garmentOffsetY}px) rotate(${tryonState.garmentCantAngle}deg) scale(${tryonState.garmentScale})`;
      }
      const badge = app.querySelector('#cantAngleBadge');
      if (badge) {
        badge.textContent = `Cant: ${tryonState.garmentCantAngle >= 0 ? '+' : ''}${tryonState.garmentCantAngle}°`;
      }
      const label = e.target.parentElement?.querySelector('span');
      if (label) {
        if (ctrl === 'garment-cant') label.textContent = `${tryonState.garmentCantAngle}°`;
        if (ctrl === 'garment-offset-y') label.textContent = `${tryonState.garmentOffsetY}px`;
        if (ctrl === 'garment-scale') label.textContent = `${tryonState.garmentScale.toFixed(2)}x`;
        if (ctrl === 'orbit-yaw') label.textContent = `${Math.round((tryonState.orbitYaw * 180) / Math.PI) % 360}°`;
        if (ctrl === 'orbit-pitch') label.textContent = `${Math.round((tryonState.orbitPitch * 180) / Math.PI)}°`;
        if (ctrl === 'orbit-roll') label.textContent = `${Math.round((tryonState.orbitRoll * 180) / Math.PI)}°`;
        if (ctrl === 'orbit-zoom') label.textContent = `${tryonState.orbitZoom.toFixed(1)}x`;
      }
    });
  });

  app.querySelector('#personFileInput')?.addEventListener('change', event => {
    const file = event.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = ev => {
        tryonState.personImage = ev.target.result;
        tryonState.personAvatarName = file.name;
        render();
      };
      reader.readAsDataURL(file);
    }
  });

  app.querySelectorAll('[data-setting]').forEach(el =>
    el.addEventListener('click', () => {
      const key = el.dataset.setting;
      if (key === 'theme') {
        state.settings.theme = el.dataset.value;
      } else {
        state.settings[key] = !state.settings[key];
      }
      persistSettings();
    })
  );

  app.querySelectorAll('[data-category]').forEach(el =>
    el.addEventListener('change', () => {
      state.settings.categories[el.dataset.category] = el.checked;
      persistSettings();
    })
  );

  app.querySelectorAll('[data-filter]').forEach(el =>
    el.addEventListener('click', () => {
      state.filter = el.dataset.filter;
      render();
    })
  );

  app.querySelector('[data-search]')?.addEventListener('input', event => {
    state.query = event.target.value;
    const pos = event.target.selectionStart;
    render();
    const input = app.querySelector('[data-search]');
    input?.focus();
    input?.setSelectionRange(pos, pos);
  });

  app.querySelectorAll('[data-select="language"]').forEach(sel =>
    sel.addEventListener('change', e => {
      state.language = e.target.value;
      speechService.setLanguage(e.target.value);
      render();
    })
  );
}

// Initial Render
render();
