// Qlarity Chrome Extension — Token Storage via chrome.storage.sync

const Auth = {
  async getToken() {
    const data = await chrome.storage.sync.get('apiToken');
    return data.apiToken || '';
  },

  async setToken(token) {
    await chrome.storage.sync.set({ apiToken: token });
  },

  async getBaseUrl() {
    const data = await chrome.storage.sync.get('apiUrl');
    return data.apiUrl || QLARITY.DEFAULT_API_URL;
  },

  async setBaseUrl(url) {
    await chrome.storage.sync.set({ apiUrl: url });
  },

  async getConfig() {
    const data = await chrome.storage.sync.get(['apiToken', 'apiUrl']);
    return {
      token: data.apiToken || '',
      baseUrl: data.apiUrl || QLARITY.DEFAULT_API_URL
    };
  }
};
