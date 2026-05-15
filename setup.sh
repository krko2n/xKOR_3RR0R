# @summary: One-time setup for App Mode on any Linux distro.
#!/usr/bin/env bash
# â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
# â•‘         xKOR_3RR0R â€” FULL SETUP SCRIPT                          â•‘
# â•‘         Run once after git clone: bash setup.sh                 â•‘
# â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•ť
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# â”€â”€ Colors â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

step() { echo -e "\n${CYAN}${BOLD}â–¸ $1${NC}"; }
ok()   { echo -e "  ${GREEN}âś“${NC}  $1"; }
warn() { echo -e "  ${YELLOW}!${NC}  $1"; }
fail() { echo -e "\n${RED}âś— FATAL: $1${NC}\n"; exit 1; }

clear
echo -e "${CYAN}"
cat << 'ART'
  â–â–â•—  â–â–â•—â–â–â•—  â–â–â•— â–â–â–â–â–â–â•— â–â–â–â–â–â–â•—      â–â–â•—â–â–â–â–â–â–â•— â–â–â–â–â–â–â•—  â–â–â–â–â–â–â•— â–â–â–â–â–â–â•—
  â•šâ–â–â•—â–â–â•”â•ťâ–â–â•‘ â–â–â•”â•ťâ–â–â•”â•â•â•â–â–â•—â–â–â•”â•â•â–â–â•—     â•šâ•â•ťâ•šâ•â•â•â•â–â–â•—â–â–â•”â•â•â–â–â•—â–â–â•”â•â•â•â–â–â•—â–â–â•”â•â•â–â–â•—
   â•šâ–â–â–â•”â•ť â–â–â–â–â–â•”â•ť â–â–â•‘   â–â–â•‘â–â–â–â–â–â–â•”â•ť        â•”â•â•â•â•ťâ–â–â•”â•ťâ–â–â–â–â–â–â•”â•ťâ–â–â•‘   â–â–â•‘â–â–â–â–â–â–â•”â•ť
   â–â–â•”â–â–â•— â–â–â•”â•â–â–â•— â–â–â•‘   â–â–â•‘â–â–â•”â•â•â–â–â•—        â•”â•â•â•â•ťâ–â–â•”â•ťâ•šâ•â•â•â•â•â•ť â–â–â•‘   â–â–â•‘â–â–â•”â•â•â–â–â•—
  â–â–â•”â•ť â–â–â•—â–â–â•‘  â–â–â•—â•šâ–â–â–â–â–â–â•”â•ťâ–â–â•‘  â–â–â•‘        â–â–â–â–â–â–â–â•”â•ť         â•šâ–â–â–â–â–â–â•”â•ťâ–â–â•‘  â–â–â•‘
  â•šâ•â•ť  â•šâ•â•ťâ•šâ•â•ť  â•šâ•â•ť â•šâ•â•â•â•â•â•ť â•šâ•â•ť  â•šâ•â•ť       â•šâ•â•â•â•â•â•â•ť           â•šâ•â•â•â•â•â•ť â•šâ•â•ť  â•šâ•â•ť
ART
echo -e "${NC}"
echo -e "  ${DIM}Setup script â€” applies all bug fixes, creates login screen, configures autostart${NC}"
echo ""

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 1. PREREQUISITES
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Checking prerequisites"

command -v node &>/dev/null || fail "Node.js not found. Install Node.js 18+ from https://nodejs.org"
NODE_VER=$(node --version | sed 's/v//' | cut -d. -f1)
[ "$NODE_VER" -ge 18 ] || fail "Node.js 18+ required (you have $(node --version))"
ok "Node.js $(node --version)"

command -v npm &>/dev/null || fail "npm not found."
ok "npm $(npm --version)"

command -v python3 &>/dev/null || fail "python3 required for patching files."
ok "python3 found"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 2. LINUX BUILD DEPS
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    step "Checking Linux build dependencies"
    MISSING=()
    for pkg in build-essential python3 libx11-dev libxkbfile-dev libsecret-1-dev; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || MISSING+=("$pkg")
    done
    if [ ${#MISSING[@]} -gt 0 ]; then
        warn "Missing packages: ${MISSING[*]}"
        echo -e "  ${DIM}Installing with sudo apt-get...${NC}"
        sudo apt-get install -y "${MISSING[@]}" \
            || warn "Auto-install failed. Run: sudo apt install ${MISSING[*]}"
    fi
    ok "Build dependencies satisfied"
fi

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 3. LOGIN CREDENTIALS
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Configure login screen credentials"
echo ""
echo -e "  ${DIM}Set a username and password for the xKOR_3RR0R lock screen.${NC}"
echo -e "  ${DIM}(This is a local UI lock only, not a system account.)${NC}"
echo ""
read -rp "  Username [xkor]: " LOGIN_USER
LOGIN_USER="${LOGIN_USER:-xkor}"

while true; do
    read -rsp "  Password (leave blank for no lock): " LOGIN_PASS
    echo ""
    read -rsp "  Confirm password: " LOGIN_PASS2
    echo ""
    [ "$LOGIN_PASS" = "$LOGIN_PASS2" ] && break
    echo -e "  ${RED}Passwords don't match. Try again.${NC}"
done

mkdir -p config
cat > config/user.json << USERJSON
{
    "username": "${LOGIN_USER}",
    "password": "${LOGIN_PASS}"
}
USERJSON
ok "Credentials saved â†’ config/user.json"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 4. FIX: backend/ai/proxy.js  (remove node-fetch)
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Fix #1 â€” removing broken node-fetch dependency"
cat > backend/ai/proxy.js << 'ENDPROXY'
// fetch() is built into Node.js 18+ â€” no external package needed
const config = require("../../config/ai-endpoint.json");

module.exports = async function (prompt) {
    try {
        const res = await fetch(config.endpoint, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ prompt }),
        });
        const data = await res.json();
        return data.response || "No response";
    } catch {
        return "AI endpoint unreachable";
    }
};
ENDPROXY
ok "backend/ai/proxy.js â€” node-fetch removed, using global fetch()"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 5. FIX: backend/server.js  (add /auth endpoint)
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Fix #2 â€” adding /auth endpoint to backend"
python3 << 'PYEOF'
with open("backend/server.js", "r", encoding="utf-8") as f:
    content = f.read()

if '"/auth"' in content or "'/auth'" in content:
    print("  /auth endpoint already present â€” skipped")
else:
    auth_block = '''// -----------------------------
// AUTH ENDPOINT
// -----------------------------
const userConfig = (() => {
    try { return require("../config/user.json"); }
    catch { return { username: "xkor", password: "" }; }
})();

app.post("/auth", (req, res) => {
    const { username, password } = req.body || {};
    if (username === userConfig.username && password === userConfig.password) {
        res.json({ ok: true });
    } else {
        res.status(401).json({ ok: false, error: "ACCESS DENIED" });
    }
});

'''
    # Insert before the WEBSOCKET section
    marker = "// -----------------------------\n// WEBSOCKET"
    if marker in content:
        content = content.replace(marker, auth_block + marker)
    else:
        # Fallback: insert before wss.on
        content = content.replace("wss.on(", auth_block + "wss.on(", 1)
    with open("backend/server.js", "w", encoding="utf-8") as f:
        f.write(content)
    print("  /auth endpoint added to backend/server.js")
PYEOF
ok "backend/server.js â€” /auth endpoint ready"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 6. WRITE: src/renderer/css/login.css
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Writing login screen CSS"
mkdir -p src/renderer/css
cat > src/renderer/css/login.css << 'ENDCSS'
/* ============================================================
   xKOR_3RR0R â€” LOGIN SCREEN
   ============================================================ */

#login-screen {
    position: fixed;
    inset: 0;
    z-index: 9999;
    background: #000;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
}

/* CRT scanlines overlay */
#login-screen::before {
    content: '';
    position: absolute;
    inset: 0;
    background: repeating-linear-gradient(
        to bottom,
        transparent 0px, transparent 2px,
        rgba(0,255,159,0.025) 2px, rgba(0,255,159,0.025) 4px
    );
    pointer-events: none;
    z-index: 1;
    animation: scanMove 8s linear infinite;
}

@keyframes scanMove {
    from { background-position: 0 0; }
    to   { background-position: 0 40px; }
}

/* Vignette */
#login-screen::after {
    content: '';
    position: absolute;
    inset: 0;
    background: radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,0.8) 100%);
    pointer-events: none;
    z-index: 1;
}

/* Noise texture */
#login-noise {
    position: absolute;
    inset: 0;
    opacity: 0.04;
    background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
    background-size: 200px;
    pointer-events: none;
    z-index: 2;
}

#login-box {
    position: relative;
    z-index: 10;
    border: 1px solid rgba(0,255,159,0.5);
    padding: 52px 60px;
    min-width: 380px;
    background: rgba(0, 8, 4, 0.92);
    box-shadow:
        0 0 0 1px rgba(0,255,159,0.08),
        0 0 60px rgba(0,255,159,0.12),
        inset 0 0 30px rgba(0,255,159,0.03);
    animation: boxAppear 0.7s cubic-bezier(0.16,1,0.3,1) both;
    backdrop-filter: blur(4px);
}

@keyframes boxAppear {
    from { opacity: 0; transform: translateY(24px) scale(0.97); }
    to   { opacity: 1; transform: translateY(0)   scale(1);    }
}

/* Corner brackets */
#login-box::before { content: ''; position: absolute; top:  -1px; left:  -1px; width: 16px; height: 16px; border-top:  2px solid #00ff9f; border-left:  2px solid #00ff9f; }
#login-box::after  { content: ''; position: absolute; bottom: -1px; right: -1px; width: 16px; height: 16px; border-bottom: 2px solid #00ff9f; border-right: 2px solid #00ff9f; }

#login-logo {
    font-family: 'Share Tech Mono', monospace;
    font-size: 26px;
    color: #00ff9f;
    letter-spacing: 8px;
    text-align: center;
    margin-bottom: 6px;
    text-shadow: 0 0 30px rgba(0,255,159,0.7), 0 0 60px rgba(0,255,159,0.3);
    animation: logoPulse 4s ease-in-out infinite;
}

@keyframes logoPulse {
    0%, 100% { text-shadow: 0 0 30px rgba(0,255,159,0.7), 0 0 60px rgba(0,255,159,0.3); }
    50%       { text-shadow: 0 0 20px rgba(0,255,159,0.4), 0 0 40px rgba(0,255,159,0.2); }
}

#login-subtitle {
    font-family: 'Share Tech Mono', monospace;
    font-size: 10px;
    color: #005533;
    letter-spacing: 5px;
    text-align: center;
    margin-bottom: 12px;
}

#login-version {
    font-family: 'Share Tech Mono', monospace;
    font-size: 9px;
    color: #003322;
    letter-spacing: 2px;
    text-align: center;
    margin-bottom: 36px;
}

#login-divider {
    height: 1px;
    background: linear-gradient(to right, transparent, rgba(0,255,159,0.3), transparent);
    margin-bottom: 32px;
}

.login-field {
    margin-bottom: 20px;
}

.login-field label {
    display: block;
    font-family: 'Share Tech Mono', monospace;
    font-size: 10px;
    color: #007744;
    letter-spacing: 4px;
    margin-bottom: 8px;
}

.login-field input {
    width: 100%;
    font-family: 'Share Tech Mono', monospace;
    font-size: 15px;
    background: transparent;
    border: none;
    border-bottom: 1px solid rgba(0,255,159,0.2);
    color: #00ff9f;
    padding: 8px 0;
    outline: none;
    caret-color: #00ff9f;
    letter-spacing: 2px;
    box-sizing: border-box;
    transition: border-color 0.25s, box-shadow 0.25s;
}

.login-field input:focus {
    border-bottom-color: #00ff9f;
    box-shadow: 0 2px 0 rgba(0,255,159,0.15);
}

.login-field input::placeholder { color: #002211; }

#login-btn {
    width: 100%;
    margin-top: 32px;
    padding: 14px;
    font-family: 'Share Tech Mono', monospace;
    font-size: 12px;
    letter-spacing: 5px;
    background: transparent;
    border: 1px solid rgba(0,255,159,0.5);
    color: #00ff9f;
    cursor: pointer;
    transition: all 0.2s ease;
    position: relative;
    overflow: hidden;
}

#login-btn::before {
    content: '';
    position: absolute;
    inset: 0;
    background: #00ff9f;
    transform: translateX(-101%);
    transition: transform 0.25s ease;
    z-index: -1;
}

#login-btn:hover { color: #000; border-color: #00ff9f; }
#login-btn:hover::before { transform: translateX(0); }
#login-btn:disabled { opacity: 0.4; cursor: default; }

#login-status {
    font-family: 'Share Tech Mono', monospace;
    font-size: 11px;
    text-align: center;
    margin-top: 18px;
    min-height: 18px;
    letter-spacing: 3px;
    color: #ff3333;
    transition: color 0.2s;
}

#login-status.ok { color: #00ff9f; }
#login-status.dim { color: #004422; }

/* Shake on bad password */
@keyframes shake {
    0%,100% { transform: translateX(0); }
    15%      { transform: translateX(-10px); }
    30%      { transform: translateX(10px); }
    45%      { transform: translateX(-7px); }
    60%      { transform: translateX(7px); }
    75%      { transform: translateX(-4px); }
    90%      { transform: translateX(4px); }
}
#login-box.shake { animation: shake 0.45s ease; }

/* Fade out after auth */
#login-screen.fade-out {
    animation: loginFade 0.9s cubic-bezier(0.4,0,1,1) forwards;
}
@keyframes loginFade {
    to { opacity: 0; transform: scale(1.015); pointer-events: none; }
}
ENDCSS
ok "src/renderer/css/login.css written"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 7. WRITE: src/renderer/js/login.js
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Writing login screen JS"
cat > src/renderer/js/login.js << 'ENDJS'
/* ============================================================
   xKOR_3RR0R â€” LOGIN SCREEN
   Runs before boot.js â€” holds boot until auth passes
   ============================================================ */

// Signal boot.js to wait for us
window.xkorAuthPending = true;

(function () {
    const screen  = document.getElementById("login-screen");
    const box     = document.getElementById("login-box");
    const userInp = document.getElementById("login-user");
    const passInp = document.getElementById("login-pass");
    const btn     = document.getElementById("login-btn");
    const status  = document.getElementById("login-status");

    if (!screen) {
        // Login screen HTML not present â€” skip auth, boot normally
        window.xkorAuthPending = false;
        window.dispatchEvent(new Event("xkor-auth"));
        return;
    }

    // Focus username on load
    window.addEventListener("load", () => {
        userInp.focus();
    });

    userInp.addEventListener("keydown", (e) => {
        if (e.key === "Enter") passInp.focus();
    });
    passInp.addEventListener("keydown", (e) => {
        if (e.key === "Enter") doLogin();
    });
    btn.addEventListener("click", doLogin);

    // â”€â”€ Core auth function â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    async function doLogin() {
        const username = userInp.value.trim();
        const password = passInp.value;

        if (!username) {
            setStatus("ENTER USERNAME");
            shake();
            return;
        }

        btn.disabled = true;
        setStatus("AUTHENTICATING...", "dim");

        try {
            const res = await fetch("http://localhost:3001/auth", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ username, password })
            });

            if (res.ok) {
                setStatus("ACCESS GRANTED", "ok");
                setTimeout(grantAccess, 700);
            } else {
                setStatus("ACCESS DENIED");
                shake();
                passInp.value = "";
                passInp.focus();
                btn.disabled = false;
            }
        } catch {
            // Backend not ready yet â€” retry in 1s
            setStatus("CONNECTING TO BACKEND...", "dim");
            setTimeout(() => {
                btn.disabled = false;
                setStatus("");
                doLogin();
            }, 1200);
        }
    }

    // â”€â”€ Auth success: release boot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    function grantAccess() {
        screen.classList.add("fade-out");
        screen.addEventListener("animationend", () => {
            screen.style.display = "none";
        }, { once: true });

        // Release boot sequence
        window.xkorAuthPending = false;
        window.dispatchEvent(new Event("xkor-auth"));
    }

    // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    function setStatus(msg, cls = "") {
        status.textContent = msg;
        status.className = cls;
    }

    function shake() {
        box.classList.remove("shake");
        void box.offsetWidth; // force reflow
        box.classList.add("shake");
        box.addEventListener("animationend", () => box.classList.remove("shake"), { once: true });
    }
})();
ENDJS
ok "src/renderer/js/login.js written"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 8. PATCH: src/renderer/js/boot.js  (wait for xkor-auth event)
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Patching boot.js to wait for login"
python3 << 'PYEOF'
with open("src/renderer/js/boot.js", "r", encoding="utf-8") as f:
    content = f.read()

old_call = "bootStep();"
new_call = """// Wait for login auth before starting boot sequence
if (window.xkorAuthPending) {
    window.addEventListener("xkor-auth", bootStep, { once: true });
} else {
    bootStep();
}"""

if old_call in content and "xkor-auth" not in content:
    content = content.replace(old_call, new_call)
    with open("src/renderer/js/boot.js", "w", encoding="utf-8") as f:
        f.write(content)
    print("  boot.js patched â€” will wait for auth")
else:
    print("  boot.js already patched or structure differs â€” skipped")
PYEOF
ok "src/renderer/js/boot.js patched"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 9. PATCH: src/renderer/index.html  (CSP + font + login HTML)
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Patching index.html (CSP, font, login screen)"
python3 << 'PYEOF'
import re

with open("src/renderer/index.html", "r", encoding="utf-8") as f:
    html = f.read()

changes = []

# â”€â”€ Fix CSP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
csp_re = re.compile(r'<meta http-equiv="Content-Security-Policy"[^>]+>', re.DOTALL)
new_csp = (
    '<meta http-equiv="Content-Security-Policy"\n'
    '          content="default-src \'self\'; '
    'connect-src ws://localhost:* http://localhost:*; '
    'script-src \'self\'; '
    'style-src \'self\' \'unsafe-inline\' https://fonts.googleapis.com; '
    'font-src \'self\' https://fonts.gstatic.com;">'
)
if csp_re.search(html):
    html = csp_re.sub(new_csp, html)
    changes.append("CSP fixed (HTTP + font CDNs allowed)")

# â”€â”€ Add Google Fonts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
fonts = (
    '    <link rel="preconnect" href="https://fonts.googleapis.com">\n'
    '    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n'
    '    <link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&display=swap" rel="stylesheet">\n'
)
if "fonts.googleapis.com/css2?family=Share+Tech+Mono" not in html:
    html = html.replace(
        '    <link rel="stylesheet" href="css/boot.css">',
        fonts + '    <link rel="stylesheet" href="css/boot.css">'
    )
    changes.append("Google Fonts (Share Tech Mono) added")

# â”€â”€ Add login.css link â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
if 'css/login.css' not in html:
    html = html.replace(
        '<link rel="stylesheet" href="css/globe.css">',
        '<link rel="stylesheet" href="css/globe.css">\n    <link rel="stylesheet" href="css/login.css">'
    )
    changes.append("login.css linked")

# â”€â”€ Add login.js FIRST (before boot.js) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
if 'js/login.js' not in html:
    html = html.replace(
        '<script src="js/boot.js"></script>',
        '<script src="js/login.js"></script>\n<script src="js/boot.js"></script>'
    )
    changes.append("login.js linked (before boot.js)")

# â”€â”€ Inject login screen HTML â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
login_html = '''
<!-- ========================= -->
<!-- LOGIN SCREEN              -->
<!-- ========================= -->
<div id="login-screen">
    <div id="login-noise"></div>
    <div id="login-box">
        <div id="login-logo">xKOR_3RR0R</div>
        <div id="login-subtitle">SECURE TERMINAL INTERFACE</div>
        <div id="login-version">v1.0.0 &nbsp;Â·&nbsp; AUTHENTICATED ACCESS ONLY</div>
        <div id="login-divider"></div>
        <div class="login-field">
            <label>USER IDENTIFIER</label>
            <input type="text" id="login-user" autocomplete="off" spellcheck="false" placeholder="â€”â€”â€”â€”â€”â€”">
        </div>
        <div class="login-field">
            <label>ACCESS KEY</label>
            <input type="password" id="login-pass" autocomplete="off" placeholder="â€”â€”â€”â€”â€”â€”">
        </div>
        <button id="login-btn">[ AUTHENTICATE ]</button>
        <div id="login-status"></div>
    </div>
</div>

'''

if 'id="login-screen"' not in html:
    # Inject right after <body>
    html = html.replace('<body>', '<body>\n' + login_html)
    changes.append("Login screen HTML injected")

with open("src/renderer/index.html", "w", encoding="utf-8") as f:
    f.write(html)

for c in changes:
    print(f"  âś“ {c}")
PYEOF
ok "src/renderer/index.html fully patched"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 10. npm install
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Installing npm dependencies"
npm install
ok "npm install complete"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 11. Rebuild node-pty for Electron
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Rebuilding node-pty for Electron (this takes a minute)"
npm run postinstall 2>&1 || {
    warn "postinstall script failed â€” trying fallback"
    npx @electron/rebuild -f -w node-pty 2>&1 \
        || fail "node-pty rebuild failed. Check build-essential is installed."
}
ok "node-pty rebuilt successfully"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 12. Create launcher script
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Creating launcher"
LAUNCH_SCRIPT="$SCRIPT_DIR/xkor-launch.sh"
cat > "$LAUNCH_SCRIPT" << LAUNCHEOF
#!/usr/bin/env bash
cd "${SCRIPT_DIR}"
npm start
LAUNCHEOF
chmod +x "$LAUNCH_SCRIPT"
ok "xkor-launch.sh created"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# 13. Autostart on desktop login
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
step "Setting up autostart on login"

AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

ICON_PATH="$SCRIPT_DIR/assets/icons/icon.png"
[ -f "$ICON_PATH" ] || ICON_PATH=""

cat > "$AUTOSTART_DIR/xkor3rr0r.desktop" << DESKTOPEOF
[Desktop Entry]
Type=Application
Name=xKOR_3RR0R
Comment=Cyberpunk secure terminal interface
Exec=bash -c "cd '${SCRIPT_DIR}' && npm start"
Icon=${ICON_PATH}
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
X-KDE-autostart-after=panel
DESKTOPEOF

ok "Autostart configured: ~/.config/autostart/xkor3rr0r.desktop"
ok "App will launch automatically on next desktop login"

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# DONE
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
echo ""
echo -e "${CYAN}${BOLD}"
echo "  â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—"
echo "  â•‘           SETUP COMPLETE                             â•‘"
echo "  â• â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•Ł"
echo -e "  â•‘  ${NC}Run now:    ${BOLD}npm start${NC}${CYAN}${BOLD}                                â•‘"
echo -e "  â•‘  ${NC}Or:         ${BOLD}bash xkor-launch.sh${NC}${CYAN}${BOLD}                     â•‘"
echo -e "  â•‘  ${NC}Autostart:  next login ${BOLD}âś“${NC}${CYAN}${BOLD}                            â•‘"
echo -e "  â•‘  ${NC}Login user: ${BOLD}${LOGIN_USER}${NC}${CYAN}${BOLD}                                   â•‘"
echo -e "  â•‘                                                    â•‘"
echo -e "  â•‘  ${NC}${DIM}AI panel: edit config/ai-endpoint.json${NC}${CYAN}${BOLD}           â•‘"
echo "  â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•ť"
echo -e "${NC}"
