const loginState = { step: 'username', username: '' };

function focusLogin() {
  if (loginState.step === 'username') {
    $('#login-username').focus();
  } else {
    $('#login-password').focus();
  }
}

function submitLogin() {
  const user = $('#login-username').value.trim();
  const pass = $('#login-password').value.trim();
  if (!user) { setLoginStatus('ENTER USERNAME', false); return; }
  if (!pass) { setLoginStatus('ENTER PASSWORD', false); return; }

  setLoginStatus('AUTHENTICATING...', true);
  $('#login-password').disabled = true;

  // Tauri invoke: call Rust authenticate (we'll simulate via invoke or direct check)
  if (xkor.invoke) {
    xkor.invoke('authenticate', { username: user, password: pass })
      .then(ok => {
        if (ok) {
          setLoginStatus('ACCESS GRANTED', true);
          setTimeout(() => {
            $('#login-screen').style.display = 'none';
            startBoot();
          }, 800);
        } else {
          setLoginStatus('ACCESS DENIED', false);
          $('#login-password').value = '';
          $('#login-password').disabled = false;
          $('#login-password').focus();
        }
      })
      .catch((err) => {
        // Fallback: Tauri invoke failed - deny access and show error
        setLoginStatus('ERROR: Backend unreachable — ACCESS DENIED', false);
        console.error('Tauri invoke failed:', err);
        $('#login-password').value = '';
        $('#login-password').disabled = false;
        $('#login-password').focus();
        // Log error but do NOT grant access
      });
  } else {
    // Dev fallback - same as production
    setLoginStatus('ERROR: No Tauri environment — ACCESS DENIED', false);
    console.warn('Tauri __TAURI__ not available');
    $('#login-password').value = '';
    $('#login-password').disabled = false;
    $('#login-password').focus();
  }
}

function setLoginStatus(msg, ok) {
  const el = $('#login-status');
  el.textContent = msg;
  el.className = ok ? 'success' : '';
}

function handleLoginKey(e) {
  if (e.key === 'Tab') {
    e.preventDefault();
    if (loginState.step === 'username') {
      loginState.step = 'password';
      loginState.username = $('#login-username').value.trim();
      $('#login-password').focus();
    } else {
      loginState.step = 'username';
      $('#login-username').focus();
    }
  } else if (e.key === 'Enter') {
    submitLogin();
  }
}

document.addEventListener('DOMContentLoaded', () => {
  $('#login-username').addEventListener('keydown', handleLoginKey);
  $('#login-password').addEventListener('keydown', handleLoginKey);
  focusLogin();
});
