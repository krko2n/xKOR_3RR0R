let aiOpen = false;
let aiHistory = [];
let aiLoading = false;

function initAI() {
  document.addEventListener('keydown', e => {
    if (e.key === 'F5') {
      e.preventDefault();
      toggleAI();
    }
    if (e.key === 'Escape' && aiOpen) {
      toggleAI();
    }
  });

  $('#ai-input').addEventListener('keydown', e => {
    if (e.key === 'Enter') {
      const text = $('#ai-input').value.trim();
      if (text && !aiLoading) {
        $('#ai-input').value = '';
        sendAIMessage(text);
      }
    }
  });
}

function toggleAI() {
  aiOpen = !aiOpen;
  $('#ai-panel').classList.toggle('open', aiOpen);
  if (aiOpen) {
    setTimeout(() => $('#ai-input').focus(), 100);
  }
}

function addAIMessage(role, text) {
  const div = document.createElement('div');
  div.className = 'msg msg-' + role;
  div.innerHTML = `<span class="msg-label">● ${role === 'user' ? 'you' : 'ai'}</span>\n${escapeHtml(text)}`;
  $('#ai-messages').appendChild(div);
  $('#ai-messages').scrollTop = $('#ai-messages').scrollHeight;
}

function escapeHtml(text) {
  return text.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

async function sendAIMessage(text) {
  addAIMessage('user', text);
  aiLoading = true;

  try {
    const result = await xkor.invoke('ai_query', { prompt: text });
    if (result.error) {
      addAIMessage('ai', '[Error: ' + result.error + ']');
    } else {
      addAIMessage('ai', result.response || '[No response]');
    }
  } catch (err) {
    addAIMessage('ai', '[Error: ' + err + ']');
  }

  aiLoading = false;
}

// Web terminal (mode web)
let webHistory = [];
let webHistoryIndex = -1;

function initWeb() {
  $('#web-input').addEventListener('keydown', e => {
    if (e.key === 'Enter') {
      const cmd = $('#web-input').value.trim();
      $('#web-input').value = '';
      processWebCommand(cmd);
    }
  });
}

async function processWebCommand(cmd) {
  const parts = cmd.split(/\s+/);
  const action = parts[0].toLowerCase();
  const content = $('#web-content');

  if (action === 'open' && parts[1]) {
    const url = parts[1];
    $('#web-url').textContent = '\u26a1 ' + url;

    if (xkor.invoke) {
      try {
        const result = await xkor.invoke('web_fetch', { url });
        content.innerHTML = '<pre style="color:#cccccc;font-size:13px;">' + escapeHtml(result || 'No content') + '</pre>';
      } catch (err) {
        content.innerHTML = '<pre style="color:#ff3333;">Error fetching: ' + escapeHtml(err) + '</pre>';
      }
    } else {
      content.innerHTML = '<pre style="color:#0a660a;">[Web fetch not available in dev mode]</pre>';
    }
  } else if (action === 'back') {
    content.innerHTML = '<pre style="color:#0a660a;">[History navigation not implemented]</pre>';
  } else if (action === 'reload') {
    const url = $('#web-url').textContent.replace('\u26a1 ', '');
    if (url && url !== 'about:blank') {
      processWebCommand('open ' + url);
    }
  } else {
    content.innerHTML = '<pre style="color:#0a660a;">Commands: open &lt;url&gt;, back, forward, reload</pre>';
  }
}
