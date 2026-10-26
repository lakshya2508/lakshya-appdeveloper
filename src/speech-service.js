import annyang from 'annyang';

export const SUPPORTED_LANGUAGES = [
  { code: 'en-US', name: 'English (US)', flag: '🇺🇸' },
  { code: 'en-IN', name: 'English (India)', flag: '🇮🇳' },
  { code: 'en-GB', name: 'English (UK)', flag: '🇬🇧' },
  { code: 'hi-IN', name: 'Hindi (India)', flag: '🇮🇳' },
  { code: 'es-ES', name: 'Spanish (ES)', flag: '🇪🇸' },
  { code: 'fr-FR', name: 'French (FR)', flag: '🇫🇷' },
];

class SpeechService {
  constructor() {
    this.isListening = false;
    this.isPaused = false;
    this.currentLanguage = 'en-US';
    this.rawRecognizer = null;
    this.micStream = null;
    this.audioContext = null;
    this.analyser = null;
    this.animFrameId = null;
    this.onInterimCallback = null;
    this.onFinalCallback = null;
    this.onStatusCallback = null;
    this.onErrorCallback = null;
    this.onLevelCallback = null;
    this._restartTimer = null;
    this._simulationTimer = null;
  }

  isSupported() {
    return Boolean(
      (annyang && annyang.isSpeechRecognitionSupported && annyang.isSpeechRecognitionSupported()) ||
      typeof window !== 'undefined' && (window.SpeechRecognition || window.webkitSpeechRecognition)
    );
  }

  setLanguage(lang) {
    this.currentLanguage = lang;
    if (annyang && typeof annyang.setLanguage === 'function') {
      try {
        annyang.setLanguage(lang);
      } catch (e) {
        console.warn('SpeechService setLanguage note:', e);
      }
    }
    if (this.rawRecognizer) {
      try {
        this.rawRecognizer.lang = lang;
      } catch (_) {}
    }
  }

  getLanguage() {
    return this.currentLanguage;
  }

  async start({ onInterim, onFinal, onStatus, onError, onLevel }) {
    this.onInterimCallback = onInterim;
    this.onFinalCallback = onFinal;
    this.onStatusCallback = onStatus;
    this.onErrorCallback = onError;
    this.onLevelCallback = onLevel;
    this.isListening = true;
    this.isPaused = false;

    // Start Audio Level Meter (Voice Activity Detection / Volume Indicator)
    this._startAudioMeter();

    // Initialize annyang and speech recognition engine
    const SpeechRecognitionClass =
      typeof window !== 'undefined'
        ? window.SpeechRecognition || window.webkitSpeechRecognition
        : null;

    if (!SpeechRecognitionClass && (!annyang || !annyang.isSpeechRecognitionSupported())) {
      this.onErrorCallback?.({
        type: 'unsupported',
        message: 'Speech recognition is not natively supported in this browser. You can use the Voice Simulation or Demo sample to test live captions.',
      });
      this.onStatusCallback?.('unsupported');
      return;
    }

    try {
      if (annyang) {
        annyang.removeCallback(); // Clear old callbacks
        annyang.setLanguage(this.currentLanguage);

        // Access raw recognizer to enable live interimResults
        this.rawRecognizer = annyang.getSpeechRecognizer();
        if (this.rawRecognizer) {
          this.rawRecognizer.continuous = true;
          this.rawRecognizer.interimResults = true;
          this.rawRecognizer.maxAlternatives = 3;
          this.rawRecognizer.lang = this.currentLanguage;

          // Wire interim and final results directly from SpeechRecognition
          this.rawRecognizer.onresult = (event) => {
            if (this.isPaused) return;
            let interimTranscript = '';
            for (let i = event.resultIndex; i < event.results.length; ++i) {
              const res = event.results[i];
              const transcript = res[0].transcript;
              if (res.isFinal) {
                this.onFinalCallback?.(transcript.trim());
                interimTranscript = '';
              } else {
                interimTranscript += transcript;
              }
            }
            if (interimTranscript) {
              this.onInterimCallback?.(interimTranscript);
            }
          };
        }

        // Hook annyang callbacks
        annyang.addCallback('start', () => {
          this.isListening = true;
          this.onStatusCallback?.('listening');
        });

        annyang.addCallback('soundstart', () => {
          this.onStatusCallback?.('sound_detected');
        });

        annyang.addCallback('result', (phrases) => {
          if (phrases && phrases.length && !this.rawRecognizer?.onresult) {
            this.onFinalCallback?.(phrases[0]);
          }
        });

        annyang.addCallback('errorNetwork', (err) => {
          console.warn('SpeechRecognition network timeout/block:', err);
          this.onErrorCallback?.({
            type: 'network',
            message: 'Speech service network timeout. The browser speech server is unavailable or blocked by browser privacy settings. You can still speak or use simulated dictation.',
          });
        });

        annyang.addCallback('errorPermissionBlocked', (err) => {
          this.isListening = false;
          this.onErrorCallback?.({
            type: 'permission_blocked',
            message: 'Microphone access is blocked in this browser. Please allow microphone permission in the browser address bar.',
          });
          this.onStatusCallback?.('blocked');
        });

        annyang.addCallback('errorPermissionDenied', (err) => {
          this.isListening = false;
          this.onErrorCallback?.({
            type: 'permission_denied',
            message: 'Microphone permission was denied. Please click the lock/camera icon in your address bar to enable it.',
          });
          this.onStatusCallback?.('denied');
        });

        annyang.addCallback('end', () => {
          if (this.isListening && !this.isPaused) {
            clearTimeout(this._restartTimer);
            this._restartTimer = setTimeout(() => {
              if (this.isListening && !this.isPaused) {
                try {
                  annyang.start({ autoRestart: true, continuous: true });
                } catch (_) {}
              }
            }, 300);
          } else {
            this.onStatusCallback?.('stopped');
          }
        });

        // Start listening via annyang
        annyang.start({ autoRestart: true, continuous: true });
        this.onStatusCallback?.('listening');
      } else {
        // Fallback to direct SpeechRecognition instance
        this._startNativeRecognition(SpeechRecognitionClass);
      }
    } catch (err) {
      console.warn('Failed to start annyang, falling back to direct recognizer:', err);
      if (SpeechRecognitionClass) {
        this._startNativeRecognition(SpeechRecognitionClass);
      } else {
        this.onErrorCallback?.({
          type: 'start_failed',
          message: `Could not start speech recognition: ${err.message || err}`,
        });
      }
    }
  }

  _startNativeRecognition(SpeechRecognitionClass) {
    try {
      this.rawRecognizer = new SpeechRecognitionClass();
      this.rawRecognizer.continuous = true;
      this.rawRecognizer.interimResults = true;
      this.rawRecognizer.maxAlternatives = 2;
      this.rawRecognizer.lang = this.currentLanguage;

      this.rawRecognizer.onstart = () => {
        this.isListening = true;
        this.onStatusCallback?.('listening');
      };

      this.rawRecognizer.onresult = (event) => {
        if (this.isPaused) return;
        let interim = '';
        for (let i = event.resultIndex; i < event.results.length; i++) {
          const res = event.results[i];
          if (res.isFinal) {
            this.onFinalCallback?.(res[0].transcript.trim());
          } else {
            interim += res[0].transcript;
          }
        }
        if (interim) {
          this.onInterimCallback?.(interim);
        }
      };

      this.rawRecognizer.onerror = (e) => {
        if (e.error === 'no-speech') return; // Silence is normal
        this.onErrorCallback?.({
          type: e.error,
          message: `Speech recognition status: ${e.error}`,
        });
      };

      this.rawRecognizer.onend = () => {
        if (this.isListening && !this.isPaused) {
          clearTimeout(this._restartTimer);
          this._restartTimer = setTimeout(() => {
            if (this.isListening && !this.isPaused) {
              try {
                this.rawRecognizer.start();
              } catch (_) {}
            }
          }, 300);
        }
      };

      this.rawRecognizer.start();
    } catch (err) {
      this.onErrorCallback?.({
        type: 'native_failed',
        message: `Native speech error: ${err.message || err}`,
      });
    }
  }

  async _startAudioMeter() {
    if (typeof navigator === 'undefined' || !navigator.mediaDevices?.getUserMedia) return;
    try {
      this.micStream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;

      this.audioContext = new AudioCtx();
      if (this.audioContext.state === 'suspended') {
        await this.audioContext.resume();
      }

      const source = this.audioContext.createMediaStreamSource(this.micStream);
      this.analyser = this.audioContext.createAnalyser();
      this.analyser.fftSize = 64;
      source.connect(this.analyser);

      const dataArray = new Uint8Array(this.analyser.frequencyBinCount);
      const updateMeter = () => {
        if (!this.isListening || this.isPaused || !this.analyser) return;
        this.analyser.getByteFrequencyData(dataArray);

        let sum = 0;
        for (let i = 0; i < dataArray.length; i++) {
          sum += dataArray[i];
        }
        const avg = sum / dataArray.length;
        const normalized = Math.min(1.0, avg / 70.0);
        this.onLevelCallback?.(normalized, dataArray);

        this.animFrameId = requestAnimationFrame(updateMeter);
      };

      cancelAnimationFrame(this.animFrameId);
      this.animFrameId = requestAnimationFrame(updateMeter);
    } catch (e) {
      console.warn('Audio meter access note (non-critical):', e.message);
    }
  }

  pause() {
    this.isPaused = true;
    if (annyang && typeof annyang.pause === 'function') {
      try {
        annyang.pause();
      } catch (_) {}
    }
    this.onStatusCallback?.('paused');
  }

  resume() {
    this.isPaused = false;
    if (annyang && typeof annyang.resume === 'function') {
      try {
        annyang.resume();
      } catch (_) {}
    }
    this.onStatusCallback?.('listening');
  }

  stop() {
    this.isListening = false;
    this.isPaused = false;
    clearTimeout(this._restartTimer);
    clearTimeout(this._simulationTimer);
    cancelAnimationFrame(this.animFrameId);

    if (annyang && typeof annyang.abort === 'function') {
      try {
        annyang.abort();
      } catch (_) {}
    }

    if (this.rawRecognizer) {
      try {
        this.rawRecognizer.stop();
        this.rawRecognizer.abort?.();
      } catch (_) {}
      this.rawRecognizer = null;
    }

    if (this.micStream) {
      this.micStream.getTracks().forEach((track) => track.stop());
      this.micStream = null;
    }

    if (this.audioContext && this.audioContext.state !== 'closed') {
      this.audioContext.close().catch(() => {});
      this.audioContext = null;
    }

    this.analyser = null;
    this.onStatusCallback?.('stopped');
  }

  /**
   * Simulates word-by-word streaming speech dictation for instant testing
   * when microphone or cloud speech recognition is unavailable.
   */
  simulateVoiceInput({ text, onInterim, onFinal, onDone }) {
    clearTimeout(this._simulationTimer);
    const words = text.split(' ');
    let current = '';
    let index = 0;

    const step = () => {
      if (index < words.length) {
        current += (current ? ' ' : '') + words[index];
        index++;
        onInterim?.(current);
        this._simulationTimer = setTimeout(step, 180 + Math.random() * 120);
      } else {
        onFinal?.(current);
        onDone?.();
      }
    };

    step();
  }
}

export const speechService = new SpeechService();
