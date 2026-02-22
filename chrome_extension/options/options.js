// Qlarity Options Page

document.addEventListener('DOMContentLoaded', async () => {
  const urlInput = document.getElementById('apiUrl');
  const tokenInput = document.getElementById('apiToken');
  const saveBtn = document.getElementById('saveBtn');
  const statusEl = document.getElementById('status');
  const overlayAutoCheckbox = document.getElementById('overlayAuto');
  const tintSwatches = document.querySelectorAll('.tint-swatch');

  let selectedTint = 'none';

  // Load saved settings
  const config = await Auth.getConfig();
  urlInput.value = config.baseUrl;
  tokenInput.value = config.token;

  // Load overlay preferences
  chrome.storage.sync.get(['readingOverlayTint', 'readingOverlayAuto'], (data) => {
    selectedTint = data.readingOverlayTint || 'none';
    overlayAutoCheckbox.checked = !!data.readingOverlayAuto;
    highlightTint(selectedTint);
  });

  // Save connection settings
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

  // Tint swatch selection
  tintSwatches.forEach(swatch => {
    swatch.addEventListener('click', () => {
      selectedTint = swatch.dataset.tint;
      highlightTint(selectedTint);
      saveOverlayPrefs();
      applyOverlayToTabs(selectedTint);
    });
  });

  // Auto-apply checkbox
  overlayAutoCheckbox.addEventListener('change', () => {
    saveOverlayPrefs();
    if (!overlayAutoCheckbox.checked) {
      removeOverlayFromTabs();
    } else if (selectedTint && selectedTint !== 'none') {
      applyOverlayToTabs(selectedTint);
    }
  });

  function highlightTint(tint) {
    tintSwatches.forEach(s => {
      s.classList.toggle('selected', s.dataset.tint === tint);
    });
  }

  function saveOverlayPrefs() {
    chrome.storage.sync.set({
      readingOverlayTint: selectedTint,
      readingOverlayAuto: overlayAutoCheckbox.checked
    });
  }

  async function applyOverlayToTabs(tint) {
    try {
      const tabs = await chrome.tabs.query({});
      for (const tab of tabs) {
        if (tab.url && !tab.url.startsWith('chrome://')) {
          chrome.tabs.sendMessage(tab.id, { type: 'APPLY_READING_OVERLAY', tint }).catch(() => {});
        }
      }
    } catch {}
  }

  async function removeOverlayFromTabs() {
    try {
      const tabs = await chrome.tabs.query({});
      for (const tab of tabs) {
        if (tab.url && !tab.url.startsWith('chrome://')) {
          chrome.tabs.sendMessage(tab.id, { type: 'REMOVE_READING_OVERLAY' }).catch(() => {});
        }
      }
    } catch {}
  }

  function showStatus(msg, type) {
    statusEl.textContent = msg;
    statusEl.className = `status ${type}`;
    setTimeout(() => { statusEl.className = 'status'; }, 5000);
  }
});
