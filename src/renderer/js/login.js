/* ============================================================
   xKOR_3RR0R - LOGIN SCREEN
   Uses #login-screen div (not #login-overlay)
   POSTs to localhost:3001/auth
   Dispatches 'xkor-auth' event (matches boot.js listener)
   ============================================================ */

window.xkorAuthPending = true;

(function () {
    var screen  = document.getElementById('login-screen');
    var box     = document.getElementById('login-box');
    var userIn  = document.getElementById('login-user');
    var passIn  = document.getElementById('login-pass');
    var btn     = document.getElementById('login-btn');
    var errDiv  = document.getElementById('login-error') ||
                  document.getElementById('login-status');

    if (!screen) {
        // No login screen in HTML â€” skip auth, go straight to boot
        window.xkorAuthPending = false;
        window.dispatchEvent(new Event('xkor-auth'));
        return;
    }

    function clearErr() {
        if (errDiv) { errDiv.textContent = ''; errDiv.classList.remove('shake'); }
    }

    function showError(msg) {
        if (!errDiv) return;
        errDiv.textContent = msg;
        errDiv.classList.remove('shake');
        void errDiv.offsetWidth;
        errDiv.classList.add('shake');
        if (box) {
            box.classList.remove('shake');
            void box.offsetWidth;
            box.classList.add('shake');
        }
    }

    if (userIn) userIn.addEventListener('input', clearErr);
    if (passIn) passIn.addEventListener('input', clearErr);

    function attemptLogin() {
        var username = (userIn ? userIn.value : '').trim();
        var password = passIn ? passIn.value : '';

        if (!username) { showError('USERNAME REQUIRED'); if (userIn) userIn.focus(); return; }
        if (!password) { showError('PASSWORD REQUIRED'); if (passIn) passIn.focus(); return; }

        if (btn) { btn.disabled = true; btn.textContent = 'AUTHENTICATING...'; }
        clearErr();

        // PORT 3001 (server.js runs on 3001)
        fetch('http://localhost:3001/auth', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: username, password: password })
        })
        .then(function(r) { return r.json(); })
        .then(function(d) {
            if (d.ok) {
                screen.style.transition = 'opacity 0.6s ease';
                screen.style.opacity = '0';
                setTimeout(function() {
                    screen.style.display = 'none';
                    // dispatch 'xkor-auth' â€” matches boot.js addEventListener
                    window.xkorAuthPending = false;
                    window.dispatchEvent(new Event('xkor-auth'));
                }, 600);
            } else {
                showError('ACCESS DENIED');
                if (passIn) { passIn.value = ''; passIn.focus(); }
                if (btn) { btn.disabled = false; btn.textContent = 'AUTHENTICATE'; }
            }
        })
        .catch(function() {
            showError('BACKEND UNREACHABLE');
            setTimeout(function() {
                if (btn) { btn.disabled = false; btn.textContent = 'AUTHENTICATE'; }
            }, 2000);
        });
    }

    if (btn) btn.addEventListener('click', attemptLogin);
    if (passIn) passIn.addEventListener('keydown', function(e) { if (e.key === 'Enter') attemptLogin(); });
    if (userIn) userIn.addEventListener('keydown', function(e) { if (e.key === 'Enter' && passIn) passIn.focus(); });

    window.addEventListener('load', function() { if (userIn) userIn.focus(); });
})();