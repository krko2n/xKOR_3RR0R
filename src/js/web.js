// Web panel with F7 fetch command
let webHistory = [];
let webHistoryIndex = -1;

function initWeb() {
  const webInput = $('#web-input');
  const webContent = $('#web-content');
  const webUrl = $('#web-url');
  
  if (!webInput) return;
  
  webInput.addEventListener('keydown', async (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      const cmd = webInput.value.trim();
      webInput.value = '';
      
      if (!cmd) return;
      
      // Save to history
      webHistory.push(cmd);
      webHistoryIndex = -1;
      
      // Parse command: open <url>
      if (cmd.startsWith('open ')) {
        const url = cmd.slice(5).trim();
        if (!url) return;
        
        webUrl.textContent = '⚡ ' + url;
        webContent.innerHTML = '<div style="color:#0f0;padding:12px;">Fetching...</div>';
        
        try {
          const result = await xkor.invoke('web_fetch', { url });
          if (result) {
            // Render HTML content
            webContent.innerHTML = '<pre style="color:#0f0;font-size:11px;overflow:auto;padding:8px;max-height:100%;">' + 
              escapeHtml(result.slice(0, 10000)) + 
              (result.length > 10000 ? '\n\n[... truncated ...]' : '') +
              '</pre>';
          }
        } catch (err) {
          webContent.innerHTML = '<div style="color:#ff3333;padding:12px;">Error: ' + err + '</div>';
        }
      } else if (cmd === 'clear') {
        webContent.innerHTML = '';
        webUrl.textContent = '⚡ about:blank';
      } else {
        webContent.innerHTML = '<div style="color:#ff3333;padding:12px;">Unknown command: ' + escapeHtml(cmd) + '</div>';
      }
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (webHistoryIndex < webHistory.length - 1) {
        webHistoryIndex++;
        webInput.value = webHistory[webHistory.length - 1 - webHistoryIndex];
      }
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (webHistoryIndex > 0) {
        webHistoryIndex--;
        webInput.value = webHistory[webHistory.length - 1 - webHistoryIndex];
      } else {
        webHistoryIndex = -1;
        webInput.value = '';
      }
    }
  });
}

function escapeHtml(text) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return text.replace(/[&<>"']/g, m => map[m]);
}
