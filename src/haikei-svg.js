/**
 * Generative SVG Backgrounds powered by Haikei styling (app.haikei.app)
 * Produces organic layered waves, blob scenes, and fluid bezier contours.
 * Uses CSS variables for real-time color reactivity.
 */

/**
 * Returns an authentic Haikei Layered Waves SVG component
 * ViewBox 0 0 1440 320 with 3 smooth cubic bezier wave bands
 */
export function renderHaikeiLayeredWaves({ className = 'haikei-layered-waves', flip = false } = {}) {
  const transform = flip ? 'transform="scale(1, -1) translate(0, -320)"' : '';
  return `
  <div class="haikei-waves-wrapper ${className} ${flip ? 'flipped' : ''}" aria-hidden="true">
    <svg viewBox="0 0 1440 320" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none" class="haikei-svg">
      <defs>
        <linearGradient id="haikeiWaveGrad1" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="var(--primary)" stop-opacity="0.12" />
          <stop offset="100%" stop-color="var(--secondary)" stop-opacity="0.28" />
        </linearGradient>
        <linearGradient id="haikeiWaveGrad2" x1="0%" y1="100%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="var(--secondary)" stop-opacity="0.22" />
          <stop offset="100%" stop-color="var(--accent)" stop-opacity="0.18" />
        </linearGradient>
        <linearGradient id="haikeiWaveGrad3" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="var(--primary)" stop-opacity="0.08" />
          <stop offset="50%" stop-color="var(--secondary)" stop-opacity="0.15" />
          <stop offset="100%" stop-color="var(--primary)" stop-opacity="0.25" />
        </linearGradient>
      </defs>
      <g ${transform}>
        <!-- Layer 1: Ambient deep wave (Haikei curve 1) -->
        <path class="haikei-wave-path wave-deep" fill="url(#haikeiWaveGrad1)" d="M0,192L48,197.3C96,203,192,213,288,197.3C384,181,480,139,576,144C672,149,768,203,864,218.7C960,235,1056,213,1152,186.7C1248,160,1344,128,1392,112L1440,96L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"></path>
        <!-- Layer 2: Mid wave with contrasting frequency (Haikei curve 2) -->
        <path class="haikei-wave-path wave-mid" fill="url(#haikeiWaveGrad2)" d="M0,96L48,112C96,128,192,160,288,181.3C384,203,480,213,576,197.3C672,181,768,139,864,138.7C960,139,1056,181,1152,197.3C1248,213,1344,203,1392,197.3L1440,192L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"></path>
        <!-- Layer 3: Foreground crest (Haikei curve 3) -->
        <path class="haikei-wave-path wave-fore" fill="url(#haikeiWaveGrad3)" d="M0,256L48,229.3C96,203,192,149,288,149.3C384,149,480,203,576,218.7C672,235,768,213,864,181.3C960,149,1056,107,1152,112C1248,117,1344,171,1392,197.3L1440,224L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"></path>
      </g>
    </svg>
  </div>`;
}

/**
 * Returns a Haikei organic Blob Scene SVG
 * Used behind visual cards, hero elements, and empty states
 */
export function renderHaikeiBlobScene({ width = 360, height = 360, className = 'haikei-blob' } = {}) {
  return `
  <div class="haikei-blob-wrapper ${className}" aria-hidden="true">
    <svg viewBox="0 0 500 500" width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg" class="haikei-blob-svg">
      <defs>
        <linearGradient id="blobGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="var(--primary)" stop-opacity="0.35" />
          <stop offset="60%" stop-color="var(--secondary)" stop-opacity="0.25" />
          <stop offset="100%" stop-color="var(--accent)" stop-opacity="0.15" />
        </linearGradient>
        <filter id="blobGlow" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur stdDeviation="18" result="blur" />
          <feComposite in="SourceGraphic" in2="blur" operator="over" />
        </filter>
      </defs>
      <!-- Generative organic 7-node Haikei blob path -->
      <path fill="url(#blobGrad)" filter="url(#blobGlow)" class="motion-blob-path" d="M428.5,317.5Q402,385,342.5,422.5Q283,460,217,433.5Q151,407,102.5,357Q54,307,67.5,236Q81,165,134.5,116.5Q188,68,260,65.5Q332,63,383,113.5Q434,164,444.5,232Q455,300,428.5,317.5Z"></path>
    </svg>
  </div>`;
}

/**
 * Full ambient Haikei background canvas
 * Sits quietly behind the main workspace with layered waves & soft acoustic curves
 */
export function renderHaikeiAmbientBackground() {
  return `
  <div class="haikei-ambient-backdrop" aria-hidden="true">
    <!-- Top organic wave band -->
    ${renderHaikeiLayeredWaves({ className: 'haikei-bg-top', flip: true })}
    <!-- Floating subtle organic blob aura -->
    <div class="haikei-ambient-orb orb-primary"></div>
    <div class="haikei-ambient-orb orb-secondary"></div>
    <div class="haikei-ambient-orb orb-accent"></div>
    <!-- Bottom organic wave band -->
    ${renderHaikeiLayeredWaves({ className: 'haikei-bg-bottom', flip: false })}
  </div>`;
}
