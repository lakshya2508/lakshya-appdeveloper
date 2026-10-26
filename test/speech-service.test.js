import { describe, it, expect, vi } from 'vitest';
import { speechService, SUPPORTED_LANGUAGES } from '../src/speech-service.js';

describe('SpeechService Module', () => {
  it('exposes supported language definitions with codes and flags', () => {
    expect(SUPPORTED_LANGUAGES.length).toBeGreaterThan(3);
    const us = SUPPORTED_LANGUAGES.find(l => l.code === 'en-US');
    expect(us).toBeDefined();
    expect(us.name).toContain('English');
    const india = SUPPORTED_LANGUAGES.find(l => l.code === 'en-IN');
    expect(india).toBeDefined();
  });

  it('updates and retrieves speech recognition language', () => {
    speechService.setLanguage('en-IN');
    expect(speechService.getLanguage()).toBe('en-IN');
    speechService.setLanguage('en-US');
    expect(speechService.getLanguage()).toBe('en-US');
  });

  it('reports support state safely without browser crashes', () => {
    const supported = speechService.isSupported();
    expect(typeof supported).toBe('boolean');
  });

  it('simulates word-by-word streaming voice dictation with interim and final callbacks', async () => {
    const text = 'HearAssist delivers accessible speech captions';
    const interimResults = [];
    let finalText = '';

    await new Promise((resolve) => {
      speechService.simulateVoiceInput({
        text,
        onInterim: (interim) => {
          interimResults.push(interim);
        },
        onFinal: (final) => {
          finalText = final;
        },
        onDone: resolve,
      });
    });

    expect(interimResults.length).toBeGreaterThan(0);
    expect(finalText).toBe(text);
  });
});
