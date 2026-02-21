// Qlarity Popup

document.addEventListener('DOMContentLoaded', async () => {
  const dot = document.getElementById('statusDot');
  const statusText = document.getElementById('statusText');
  const userRow = document.getElementById('userRow');
  const userName = document.getElementById('userName');

  // Check connection
  try {
    const profile = await ApiClient.getProfile();
    dot.className = 'dot connected';
    statusText.textContent = 'Connected';
    userName.textContent = profile.name;
    userRow.style.display = 'flex';
  } catch {
    dot.className = 'dot disconnected';
    statusText.textContent = 'Not connected';
  }

  // Open side panel
  document.getElementById('openPanel').addEventListener('click', async () => {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tab) {
      chrome.runtime.sendMessage({ type: 'OPEN_SIDE_PANEL', tabId: tab.id });
    }
    window.close();
  });

  // Open settings
  document.getElementById('openSettings').addEventListener('click', () => {
    chrome.runtime.openOptionsPage();
    window.close();
  });
});
