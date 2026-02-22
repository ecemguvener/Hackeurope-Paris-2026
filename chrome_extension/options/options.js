// Qlarity Options Page

document.addEventListener('DOMContentLoaded', async () => {
  const urlInput = document.getElementById('apiUrl');
  const tokenInput = document.getElementById('apiToken');
  const saveBtn = document.getElementById('saveBtn');
  const statusEl = document.getElementById('status');

  // Load saved settings
  const config = await Auth.getConfig();
  urlInput.value = config.baseUrl;
  tokenInput.value = config.token;

  saveBtn.addEventListener('click', async () => {
    const url = urlInput.value.trim().replace(/\/+$/, '');
    const token = tokenInput.value.trim();

    if (!url) {
      showStatus('Please enter a backend URL.', 'error');
      return;
    }
    if (!token) {
      showStatus('Please enter an API token.', 'error');
      return;
    }

    await Auth.setBaseUrl(url);
    await Auth.setToken(token);

    // Test connection
    const connected = await ApiClient.checkConnection();
    if (connected) {
      showStatus('Saved! Connection verified.', 'success');
    } else {
      showStatus('Saved, but could not connect to the backend. Is the Rails server running?', 'error');
    }
  });

  function showStatus(msg, type) {
    statusEl.textContent = msg;
    statusEl.className = `status ${type}`;
    setTimeout(() => { statusEl.className = 'status'; }, 5000);
  }
});
