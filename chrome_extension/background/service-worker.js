// Qlarity Service Worker — Routes messages, opens side panel, context menus

// ── Side panel open handler ─────────────────────────────────
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.type === 'OPEN_SIDE_PANEL') {
    const tabId = msg.tabId || sender.tab?.id;

    // Store page context for the side panel to read
    if (msg.payload) {
      chrome.storage.session.set({ pageContext: msg.payload });
    }

    // Open side panel
    if (tabId) {
      chrome.sidePanel.open({ tabId }).catch(console.error);
    }

    sendResponse({ ok: true });
  }
  return true;
});

// ── Context menu ────────────────────────────────────────────
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'qlarity-transform',
    title: 'Transform with Qlarity',
    contexts: ['selection']
  });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'qlarity-transform' && tab?.id) {
    // Store selected text as page context
    chrome.storage.session.set({
      pageContext: {
        selectedText: info.selectionText || '',
        pageUrl: tab.url || '',
        pageTitle: tab.title || ''
      }
    });
    // Open side panel
    chrome.sidePanel.open({ tabId: tab.id }).catch(console.error);
  }
});

// ── Enable side panel on all tabs ───────────────────────────
chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: false }).catch(() => {});
