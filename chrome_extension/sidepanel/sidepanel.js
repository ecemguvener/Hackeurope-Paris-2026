// Qlarity Side Panel — All logic for Transform, Chat, Listen tabs

(async () => {
  // ── State ──────────────────────────────────────────────────
  let selectedStyle = 'simplified';
  let selectedVoice = 'rachel';
  let selectedSpeed = 1.0;
  let pageContext = {};
  let chatHistory = [];
  let lastTransformResult = '';

  // ── DOM refs ───────────────────────────────────────────────
  const $ = (id) => document.getElementById(id);
  const connectionDot = $('connectionDot');
  const pageTitleEl = $('pageTitle');

  // Transform
  const styleGrid = $('styleGrid');
  const transformInput = $('transformInput');
  const charCount = $('charCount');
  const transformBtn = $('transformBtn');
  const transformResult = $('transformResult');
  const transformOutput = $('transformOutput');
  const transformLoading = $('transformLoading');
  const applyBtn = $('applyBtn');
  const copyBtn = $('copyBtn');

  // Chat
  const chatMessages = $('chatMessages');
  const chatInput = $('chatInput');
  const chatSend = $('chatSend');

  // Listen
  const voiceGrid = $('voiceGrid');
  const speedBtns = $('speedBtns');
  const ttsInput = $('ttsInput');
  const ttsBtn = $('ttsBtn');
  const ttsLoading = $('ttsLoading');
  const ttsResult = $('ttsResult');
  const ttsAudio = $('ttsAudio');

  const errorBar = $('errorBar');

  // ── Init ───────────────────────────────────────────────────
  buildStyleGrid();
  buildVoiceGrid();
  buildSpeedButtons();
  checkConnection();
  loadPageContext();

  // ── Listen for Q button re-clicks when panel is already open ──
  // Service worker sends LOAD_PAGE_CONTEXT after storage write completes.
  chrome.runtime.onMessage.addListener((msg) => {
    if (msg.type === 'LOAD_PAGE_CONTEXT') {
      loadPageContext();
    }
  });

  // ── Tabs ───────────────────────────────────────────────────
  document.querySelectorAll('.sp-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.sp-tab').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.sp-panel').forEach(p => p.classList.remove('active'));
      tab.classList.add('active');
      document.getElementById(`tab-${tab.dataset.tab}`).classList.add('active');
    });
  });

  // ── Style Grid ─────────────────────────────────────────────
  function buildStyleGrid() {
    QLARITY.STYLES.forEach(style => {
      const card = document.createElement('div');
      card.className = `sp-style-card${style.key === selectedStyle ? ' selected' : ''}`;
      card.dataset.key = style.key;
      card.innerHTML = `
        <div class="sp-style-icon">${style.icon}</div>
        <div class="sp-style-title">${style.title}</div>
        <div class="sp-style-desc">${style.description}</div>
      `;
      card.addEventListener('click', () => {
        selectedStyle = style.key;
        styleGrid.querySelectorAll('.sp-style-card').forEach(c => c.classList.remove('selected'));
        card.classList.add('selected');
      });
      styleGrid.appendChild(card);
    });
  }

  // ── Voice Grid ─────────────────────────────────────────────
  function buildVoiceGrid() {
    QLARITY.VOICES.forEach(voice => {
      const chip = document.createElement('button');
      chip.className = `sp-voice-chip${voice.key === selectedVoice ? ' selected' : ''}`;
      chip.textContent = voice.label;
      chip.addEventListener('click', () => {
        selectedVoice = voice.key;
        voiceGrid.querySelectorAll('.sp-voice-chip').forEach(c => c.classList.remove('selected'));
        chip.classList.add('selected');
      });
      voiceGrid.appendChild(chip);
    });
  }

  // ── Speed Buttons ──────────────────────────────────────────
  function buildSpeedButtons() {
    QLARITY.SPEEDS.forEach(speed => {
      const btn = document.createElement('button');
      btn.className = `sp-speed-btn${speed.value === selectedSpeed ? ' selected' : ''}`;
      btn.textContent = `${speed.label} (${speed.value}x)`;
      btn.addEventListener('click', () => {
        selectedSpeed = speed.value;
        speedBtns.querySelectorAll('.sp-speed-btn').forEach(b => b.classList.remove('selected'));
        btn.classList.add('selected');
      });
      speedBtns.appendChild(btn);
    });
  }

  // ── Char count ─────────────────────────────────────────────
  transformInput.addEventListener('input', () => {
    charCount.textContent = transformInput.value.length;
  });

  // ── Connection check ───────────────────────────────────────
  async function checkConnection() {
    connectionDot.className = 'sp-dot checking';
    connectionDot.title = 'Checking connection...';
    try {
      const connected = await ApiClient.checkConnection();
      connectionDot.className = connected ? 'sp-dot connected' : 'sp-dot disconnected';
      connectionDot.title = connected ? 'Connected to Qlarity backend' : 'Not connected — check Settings';
    } catch {
      connectionDot.className = 'sp-dot disconnected';
      connectionDot.title = 'Not connected';
    }
  }

  // ── Page context ───────────────────────────────────────────
  // Called on init AND every time the service worker fires LOAD_PAGE_CONTEXT
  // (i.e. whenever the Q button is clicked, even if the panel is already open).
  async function loadPageContext() {
    // Session storage is guaranteed written before LOAD_PAGE_CONTEXT fires,
    // but on first init we add a small retry just in case.
    let data = await chrome.storage.session.get('pageContext');
    if (!data.pageContext) {
      await new Promise(r => setTimeout(r, 150));
      data = await chrome.storage.session.get('pageContext');
    }

    if (data.pageContext) {
      pageContext = data.pageContext;
      pageTitleEl.textContent = pageContext.pageTitle || pageContext.pageUrl || 'Page loaded';

      // Prefer highlighted selection; fall back to full page text
      const fillText = pageContext.selectedText || pageContext.pageText || '';
      if (fillText) {
        transformInput.value = fillText;
        charCount.textContent = fillText.length;
      }
      return;
    }

    // Fallback: ask the content script directly (panel opened via toolbar)
    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      if (tab?.id) {
        const response = await chrome.tabs.sendMessage(tab.id, { type: 'GET_PAGE_TEXT' });
        if (response) {
          pageContext = response;
          pageTitleEl.textContent = response.pageTitle || 'Current page';
          const fillText = response.selectedText || response.pageText || '';
          if (fillText) {
            transformInput.value = fillText;
            charCount.textContent = fillText.length;
          }
        }
      }
    } catch {
      pageTitleEl.textContent = 'No page detected';
    }
  }

  // ── Transform ──────────────────────────────────────────────
  transformBtn.addEventListener('click', async () => {
    const text = transformInput.value.trim();
    if (!text) {
      showError('Please enter or select some text to transform.');
      return;
    }

    transformBtn.disabled = true;
    transformResult.style.display = 'none';
    transformLoading.style.display = 'flex';
    hideError();

    try {
      const result = await ApiClient.transform(text, selectedStyle);
      lastTransformResult = result.text;
      transformOutput.textContent = result.text;
      transformResult.style.display = 'block';

      // Also populate TTS input
      ttsInput.value = result.text;

      // Save interaction
      ApiClient.saveInteraction({
        page_url: pageContext.pageUrl || '',
        page_title: pageContext.pageTitle || '',
        action_type: 'transform',
        input_text: text.substring(0, 500),
        output_text: result.text.substring(0, 500),
        style: selectedStyle
      }).catch(() => {}); // fire and forget
    } catch (err) {
      showError(err.message);
    } finally {
      transformBtn.disabled = false;
      transformLoading.style.display = 'none';
    }
  });

  // Apply to page
  applyBtn.addEventListener('click', async () => {
    if (!lastTransformResult) return;
    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      if (tab?.id) {
        const styleName = QLARITY.STYLES.find(s => s.key === selectedStyle)?.title || selectedStyle;
        await chrome.tabs.sendMessage(tab.id, {
          type: 'APPLY_OVERLAY',
          text: lastTransformResult,
          style: styleName
        });
      }
    } catch (err) {
      showError('Could not apply to page. Try refreshing the page.');
    }
  });

  // Copy
  copyBtn.addEventListener('click', async () => {
    if (!lastTransformResult) return;
    try {
      await navigator.clipboard.writeText(lastTransformResult);
      copyBtn.textContent = 'Copied!';
      setTimeout(() => { copyBtn.textContent = 'Copy'; }, 1500);
    } catch {
      showError('Could not copy to clipboard.');
    }
  });

  // ── Chat ───────────────────────────────────────────────────
  async function sendChat() {
    const text = chatInput.value.trim();
    if (!text) return;

    chatInput.value = '';
    addChatMessage('user', text);
    chatHistory.push({ role: 'user', content: text });

    const typingEl = addChatMessage('assistant', '...');

    try {
      const result = await ApiClient.chat(text, pageContext.pageText || '', chatHistory);
      typingEl.querySelector('.sp-chat-bubble').textContent = result.reply;
      chatHistory.push({ role: 'assistant', content: result.reply });

      ApiClient.saveInteraction({
        page_url: pageContext.pageUrl || '',
        page_title: pageContext.pageTitle || '',
        action_type: 'chat',
        input_text: text.substring(0, 500),
        output_text: result.reply.substring(0, 500)
      }).catch(() => {});
    } catch (err) {
      typingEl.querySelector('.sp-chat-bubble').textContent = `Error: ${err.message}`;
    }
  }

  chatSend.addEventListener('click', sendChat);
  chatInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendChat();
    }
  });

  function addChatMessage(role, text) {
    const msg = document.createElement('div');
    msg.className = `sp-chat-msg ${role}`;
    msg.innerHTML = `<div class="sp-chat-bubble">${escapeHtml(text)}</div>`;
    chatMessages.appendChild(msg);
    chatMessages.scrollTop = chatMessages.scrollHeight;
    return msg;
  }

  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  // ── TTS (Listen) ──────────────────────────────────────────
  ttsBtn.addEventListener('click', async () => {
    const text = ttsInput.value.trim();
    if (!text) {
      showError('Please enter text to generate speech.');
      return;
    }

    ttsBtn.disabled = true;
    ttsResult.style.display = 'none';
    ttsLoading.style.display = 'flex';
    hideError();

    try {
      const config = await Auth.getConfig();
      const result = await ApiClient.tts(text, selectedVoice, selectedSpeed);
      const audioUrl = `${config.baseUrl}${result.audio_url}`;
      ttsAudio.src = audioUrl;
      ttsResult.style.display = 'block';
      ttsAudio.play().catch(() => {});

      ApiClient.saveInteraction({
        page_url: pageContext.pageUrl || '',
        page_title: pageContext.pageTitle || '',
        action_type: 'tts',
        input_text: text.substring(0, 500),
        metadata: { voice: selectedVoice, speed: selectedSpeed }
      }).catch(() => {});
    } catch (err) {
      showError(err.message);
    } finally {
      ttsBtn.disabled = false;
      ttsLoading.style.display = 'none';
    }
  });

  // ── Error handling ─────────────────────────────────────────
  function showError(msg) {
    errorBar.textContent = msg;
    errorBar.style.display = 'block';
    setTimeout(hideError, 6000);
  }

  function hideError() {
    errorBar.style.display = 'none';
  }
})();
