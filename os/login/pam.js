'use strict';
// PAM authentication via pamtester (system binary).
// Replaces authenticate-pam which cannot compile on Node.js 22+.
// Requires: sudo pacman -S pamtester (added to install.sh)

const { spawn } = require('child_process');

exports.authenticate = (username, password) => {
    return new Promise((resolve) => {
        // pamtester <service> <user> authenticate
        // We pipe the password via stdin
        const proc = spawn('pamtester', ['login', username, 'authenticate'], {
            stdio: ['pipe', 'pipe', 'pipe']
        });

        let stderr = '';
        proc.stderr.on('data', (d) => { stderr += d.toString(); });

        proc.on('close', (code) => {
            if (code !== 0) {
                console.error('[PAM] Auth failed:', stderr.trim());
            }
            resolve(code === 0);
        });

        proc.on('error', (err) => {
            console.error('[PAM] pamtester not found:', err.message);
            console.error('[PAM] Install with: sudo pacman -S pamtester');
            resolve(false);
        });

        // Write password to stdin and close it
        proc.stdin.write(password + '\n');
        proc.stdin.end();
    });
};