// Qlarity Side Panel — All logic for Transform, Chat, Listen tabs

(async () => {
  // ── State ──────────────────────────────────────────────────
  let selectedStyle = 'simplified';
  let selectedVoice = 'rachel';
  let selectedSpeed = 1.0;
  let pageContext = {};
  let chatHistory = [];
  let lastTransformResult = '';
  let lastOriginalText = '';

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
  const copyBtn = $('copyBtn');

  // Full-screen reader
  const expandBtn = $('expandBtn');
  const fullscreenReader = $('fullscreenReader');
  const fullscreenContent = $('fullscreenContent');
  const exitFullscreen = $('exitFullscreen');

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

  // Theme toggle
  const themeToggle = $('themeToggle');

  // ── Init ───────────────────────────────────────────────────
  buildStyleGrid();
  buildVoiceGrid();
  buildSpeedButtons();
  checkConnection();
  loadPageContext();
  loadTheme();

  // ── Markdown → HTML parser ────────────────────────────────
  function renderMarkdown(text) {
    let html = escapeHtml(text);

    // Headings (### → h3, ## → h2, # → h1)
    html = html.replace(/^### (.+)$/gm, '<h3>$1</h3>');
    html = html.replace(/^## (.+)$/gm, '<h2>$1</h2>');
    html = html.replace(/^# (.+)$/gm, '<h1>$1</h1>');

    // Horizontal rules
    html = html.replace(/^[-*_]{3,}$/gm, '<hr>');

    // Bold + italic (***text*** or ___text___)
    html = html.replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>');
    html = html.replace(/___(.+?)___/g, '<strong><em>$1</em></strong>');

    // Bold (**text** or __text__)
    html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/__(.+?)__/g, '<strong>$1</strong>');

    // Italic (*text* or _text_)
    html = html.replace(/\*(.+?)\*/g, '<em>$1</em>');
    html = html.replace(/(?<!\w)_(.+?)_(?!\w)/g, '<em>$1</em>');

    // Inline code
    html = html.replace(/`(.+?)`/g, '<code>$1</code>');

    // Blockquotes
    html = html.replace(/^&gt; (.+)$/gm, '<blockquote>$1</blockquote>');

    // Unordered lists (- or * at start of line)
    html = html.replace(/^[\-\*] (.+)$/gm, '<li>$1</li>');
    html = html.replace(/((?:<li>.*<\/li>\n?)+)/g, '<ul>$1</ul>');

    // Ordered lists (1. 2. etc.)
    html = html.replace(/^\d+\. (.+)$/gm, '<li>$1</li>');
    // Wrap consecutive <li> not already in <ul> into <ol>
    html = html.replace(/<\/ul>\s*<ul>/g, ''); // merge adjacent <ul>
    html = html.replace(/(?<!<\/ul>)((?:<li>.*<\/li>\n?)+)(?!<\/ol>)/g, (match) => {
      if (match.includes('<ul>')) return match;
      return '<ol>' + match + '</ol>';
    });

    // Paragraphs: double newlines
    html = html.replace(/\n\n+/g, '</p><p>');
    // Single newlines → <br>
    html = html.replace(/\n/g, '<br>');

    // Wrap in paragraph
    html = '<p>' + html + '</p>';

    // Clean up empty paragraphs and paragraphs wrapping block elements
    html = html.replace(/<p>\s*<\/p>/g, '');
    html = html.replace(/<p>(<h[123]>)/g, '$1');
    html = html.replace(/(<\/h[123]>)<\/p>/g, '$1');
    html = html.replace(/<p>(<ul>)/g, '$1');
    html = html.replace(/(<\/ul>)<\/p>/g, '$1');
    html = html.replace(/<p>(<ol>)/g, '$1');
    html = html.replace(/(<\/ol>)<\/p>/g, '$1');
    html = html.replace(/<p>(<blockquote>)/g, '$1');
    html = html.replace(/(<\/blockquote>)<\/p>/g, '$1');
    html = html.replace(/<p><hr><\/p>/g, '<hr>');
    html = html.replace(/<p><br>/g, '<p>');
    html = html.replace(/<br><\/p>/g, '</p>');

    return html;
  }

  // ── Full-screen reader toggle ────────────────────────────
  expandBtn.addEventListener('click', () => {
    fullscreenContent.innerHTML = renderMarkdown(lastTransformResult);
    fullscreenReader.style.display = 'flex';
  });

  exitFullscreen.addEventListener('click', () => {
    fullscreenReader.style.display = 'none';
  });

  // ── Theme ────────────────────────────────────────────────
  function loadTheme() {
    chrome.storage.sync.get('theme', (data) => {
      const theme = data.theme || '';
      applyTheme(theme);
    });
  }

  function applyTheme(theme) {
    if (theme === 'dark') {
      document.documentElement.setAttribute('data-theme', 'dark');
      themeToggle.textContent = '☀️';
      themeToggle.title = 'Switch to light mode';
    } else {
      document.documentElement.removeAttribute('data-theme');
      themeToggle.textContent = '🌙';
      themeToggle.title = 'Switch to dark mode';
    }
  }

  themeToggle.addEventListener('click', () => {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    const next = isDark ? '' : 'dark';
    applyTheme(next);
    chrome.storage.sync.set({ theme: next });
  });

  // Check OS preference on load
  if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
    chrome.storage.sync.get('theme', (data) => {
      if (!data.theme) applyTheme('dark');
    });
  }

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
  async function loadPageContext() {
    // Read from session storage (set by service worker)
    const data = await chrome.storage.session.get('pageContext');
    if (data.pageContext) {
      pageContext = data.pageContext;
      pageTitleEl.textContent = pageContext.pageTitle || pageContext.pageUrl || 'Page loaded';
      if (pageContext.selectedText) {
        transformInput.value = pageContext.selectedText;
        charCount.textContent = pageContext.selectedText.length;
      } else if (pageContext.pageText) {
        // If nothing is selected, prefill with the full extracted page text from the FAB click.
        transformInput.value = pageContext.pageText;
        charCount.textContent = pageContext.pageText.length;
      }
    } else {
      // Try to get from active tab
      try {
        const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
        if (tab?.id) {
          const response = await chrome.tabs.sendMessage(tab.id, { type: 'GET_PAGE_TEXT' });
          if (response) {
            pageContext = response;
            pageTitleEl.textContent = response.pageTitle || 'Current page';
            if (response.selectedText) {
              transformInput.value = response.selectedText;
              charCount.textContent = response.selectedText.length;
            } else if (response.pageText) {
              transformInput.value = response.pageText;
              charCount.textContent = response.pageText.length;
            }
          }
        }
      } catch {
        pageTitleEl.textContent = 'No page detected';
      }
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
      lastOriginalText = text;

      transformOutput.innerHTML = renderMarkdown(result.text);
      transformResult.style.display = 'block';

      // Also populate TTS input (plain text for speech)
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

    // Show typing indicator
    const typingEl = addChatMessage('assistant', '...');

    try {
      const result = await ApiClient.chat(text, pageContext.pageText || '', chatHistory);
      typingEl.querySelector('.sp-chat-bubble').textContent = result.reply;
      chatHistory.push({ role: 'assistant', content: result.reply });

      // Save interaction
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

      // Save interaction
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
