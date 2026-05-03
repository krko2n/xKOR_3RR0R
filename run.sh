#!/bin/bash

echo "========================================"
echo "   xKOR_3RR0R — Runtime Launcher"
echo "========================================"

# --- START BACKEND ---
echo "[*] Starting backend server..."
node backend/server.js &

BACKEND_PID=$!
echo "[*] Backend PID: $BACKEND_PID"

# --- WAIT FOR BACKEND ---
echo "[*] Waiting for backend to initialize..."
sleep 1

# --- START ELECTRON ---
echo "[*] Launching Electron frontend..."
electron .

# --- CLEANUP ---
echo "[*] Shutting down backend..."
kill $BACKEND_PID 2>/dev/null
