// Qlarity Service Worker — Routes messages, opens side panel, context menus

// ── Side panel open handler ─────────────────────────────────
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.type === 'OPEN_SIDE_PANEL') {
    const tabId = msg.tabId || sender.tab?.id;

    if (msg.payload) {
      // Write to session storage first, THEN notify any already-open sidepanel.
      // This guarantees the data is present before the sidepanel reads it.
      chrome.storage.session.set({ pageContext: msg.payload }).then(() => {
        chrome.runtime.sendMessage({ type: 'LOAD_PAGE_CONTEXT' }).catch(() => {
          // Sidepanel not open yet — it will read from storage on its own init.
        });
      });
    }

    // Open (or focus) the side panel for this tab
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
    chrome.storage.session.set({
      pageContext: {
        selectedText: info.selectionText || '',
        pageUrl: tab.url || '',
        pageTitle: tab.title || ''
      }
    }).then(() => {
      chrome.runtime.sendMessage({ type: 'LOAD_PAGE_CONTEXT' }).catch(() => {});
      chrome.sidePanel.open({ tabId: tab.id }).catch(console.error);
    });
  }
});

// ── Enable side panel on all tabs ───────────────────────────
chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: false }).catch(() => {});
