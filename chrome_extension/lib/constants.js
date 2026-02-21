// Qlarity Chrome Extension — Shared Constants

const QLARITY = {
  DEFAULT_API_URL: 'http://localhost:3000',

  STYLES: [
    { key: 'simplified', title: 'Simplified', icon: '✨', description: 'Shorter sentences, clearer structure' },
    { key: 'bullet_points', title: 'Bullet Points', icon: '📋', description: 'Key info as scannable bullets' },
    { key: 'plain_language', title: 'Plain Language', icon: '💬', description: 'Jargon replaced with everyday words' },
    { key: 'restructured', title: 'Restructured', icon: '🔄', description: 'Reorganized for easier reading flow' }
  ],

  VOICES: [
    { key: 'rachel', label: 'Rachel' },
    { key: 'aria', label: 'Aria' },
    { key: 'roger', label: 'Roger' },
    { key: 'sarah', label: 'Sarah' },
    { key: 'george', label: 'George' }
  ],

  SPEEDS: [
    { value: 0.7, label: 'Slow' },
    { value: 1.0, label: 'Normal' },
    { value: 1.2, label: 'Fast' }
  ],

  MAX_PAGE_TEXT: 15000
};
