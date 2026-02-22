// Qlarity Content Script — FAB, text selection, page extraction, overlay

(() => {
  // Prevent double injection
  if (document.getElementById('qlarity-fab')) return;

  let selectedText = '';

  // ── FAB ──────────────────────────────────────────────────
  const fab = document.createElement('button');
  fab.id = 'qlarity-fab';
  fab.textContent = 'Q';
  fab.title = 'Open Qlarity';
  document.body.appendChild(fab);

  const tooltip = document.createElement('div');
  tooltip.id = 'qlarity-fab-tooltip';
  tooltip.textContent = 'Open Qlarity';
  document.body.appendChild(tooltip);

  // ── Text selection tracking ──────────────────────────────
  document.addEventListener('mouseup', () => {
    const sel = window.getSelection().toString().trim();
    if (sel.length > 2) {
      selectedText = sel;
      fab.classList.add('has-selection');
      tooltip.textContent = `Transform selection (${sel.length} chars)`;
      tooltip.classList.add('visible');
      setTimeout(() => tooltip.classList.remove('visible'), 2000);
    } else {
      selectedText = '';
      fab.classList.remove('has-selection');
      tooltip.textContent = 'Open Qlarity';
    }
  });

  // ── FAB click → open side panel ──────────────────────────
  fab.addEventListener('click', () => {
    const pageText = extractPageText();
    chrome.runtime.sendMessage({
      type: 'OPEN_SIDE_PANEL',
      payload: {
        selectedText,
        pageText,
        pageUrl: window.location.href,
        pageTitle: document.title
      }
    });
  });

  // ── Page text extraction ─────────────────────────────────
  function extractPageText() {
    // Try semantic elements first
    const main = document.querySelector('main') ||
                 document.querySelector('article') ||
                 document.querySelector('[role="main"]');

    const root = main || document.body;
    const clone = root.cloneNode(true);

    // Remove non-content elements
    const removeTags = ['script', 'style', 'nav', 'footer', 'header', 'aside',
                        'noscript', 'iframe', 'svg', 'form', 'button'];
    removeTags.forEach(tag => {
      clone.querySelectorAll(tag).forEach(el => el.remove());
    });

    // Remove hidden elements
    clone.querySelectorAll('[aria-hidden="true"], [hidden], .hidden').forEach(el => el.remove());

    let text = clone.textContent || '';
    // Normalize whitespace
    text = text.replace(/\s+/g, ' ').trim();
    // Truncate to limit
    return text.substring(0, QLARITY.MAX_PAGE_TEXT);
  }

  // ── Overlay rendering ────────────────────────────────────
  function showOverlay(text, style) {
    removeOverlay();

    const overlay = document.createElement('div');
    overlay.id = 'qlarity-overlay';

    const header = document.createElement('div');
    header.className = 'qlarity-overlay-header';

    const title = document.createElement('span');
    title.className = 'qlarity-overlay-title';
    title.textContent = `Qlarity — ${style || 'Transformed'}`;

    const closeBtn = document.createElement('button');
    closeBtn.className = 'qlarity-overlay-close';
    closeBtn.textContent = '×';
    closeBtn.addEventListener('click', removeOverlay);

    header.appendChild(title);
    header.appendChild(closeBtn);

    const content = document.createElement('div');
    content.className = 'qlarity-overlay-content';
    content.textContent = text;

    overlay.appendChild(header);
    overlay.appendChild(content);
    document.body.appendChild(overlay);
  }

  function removeOverlay() {
    const existing = document.getElementById('qlarity-overlay');
    if (existing) existing.remove();
  }

  // ── Reading Overlay (tinted screen filter) ───────────────
  function applyReadingOverlay(tint) {
    removeReadingOverlay();
    if (!tint || tint === 'none') return;

    const el = document.createElement('div');
    el.id = 'qlarity-reading-overlay';
    el.className = `tint-${tint}`;
    document.body.appendChild(el);
  }

  function removeReadingOverlay() {
    const existing = document.getElementById('qlarity-reading-overlay');
    if (existing) existing.remove();
  }

  // Check for saved overlay on load
  chrome.storage.sync.get(['readingOverlayTint', 'readingOverlayAuto'], (data) => {
    if (data.readingOverlayAuto && data.readingOverlayTint && data.readingOverlayTint !== 'none') {
      applyReadingOverlay(data.readingOverlayTint);
    }
  });

  // ── Message listener ─────────────────────────────────────
  chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
    switch (msg.type) {
      case 'APPLY_OVERLAY':
        showOverlay(msg.text, msg.style);
        sendResponse({ ok: true });
        break;
      case 'REMOVE_OVERLAY':
        removeOverlay();
        sendResponse({ ok: true });
        break;
      case 'APPLY_READING_OVERLAY':
        applyReadingOverlay(msg.tint);
        sendResponse({ ok: true });
        break;
      case 'REMOVE_READING_OVERLAY':
        removeReadingOverlay();
        sendResponse({ ok: true });
        break;
      case 'GET_PAGE_TEXT':
        sendResponse({
          selectedText,
          pageText: extractPageText(),
          pageUrl: window.location.href,
          pageTitle: document.title
        });
        break;
      default:
        sendResponse({ ok: false });
    }
    return true; // async response
  });
})();
