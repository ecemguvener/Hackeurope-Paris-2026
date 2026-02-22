// Qlarity Chrome Extension — Shared fetch wrapper for all Rails API calls

const ApiClient = {
  async _fetch(endpoint, options = {}) {
    const config = await Auth.getConfig();
    if (!config.token) {
      throw new Error('API token not configured. Go to Settings to add your token.');
    }

    const url = `${config.baseUrl}/api/v1${endpoint}`;
    const response = await fetch(url, {
      method: options.method || 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${config.token}`,
        ...options.headers
      },
      body: options.body ? JSON.stringify(options.body) : undefined
    });

    if (!response.ok) {
      const err = await response.json().catch(() => ({ error: `HTTP ${response.status}` }));
      throw new Error(err.error || `Request failed (${response.status})`);
    }

    return response.json();
  },

  async transform(text, style = 'simplified') {
    return this._fetch('/transform', {
      body: { text, style }
    });
  },

  async tts(text, voice = 'rachel', speed = 1.0) {
    return this._fetch('/tts', {
      body: { text, voice, speed }
    });
  },

  async summarize(text) {
    return this._fetch('/summarize', {
      body: { text }
    });
  },

  async chat(message, pageContent = '', history = []) {
    return this._fetch('/chat', {
      body: { message, page_content: pageContent, history }
    });
  },

  async getProfile() {
    return this._fetch('/profile', { method: 'GET' });
  },

  async updateProfile(data) {
    return this._fetch('/profile', {
      method: 'PATCH',
      body: data
    });
  },

  async saveInteraction(data) {
    return this._fetch('/interactions', {
      body: data
    });
  },

  async checkConnection() {
    try {
      await this.getProfile();
      return true;
    } catch {
      return false;
    }
  }
};
