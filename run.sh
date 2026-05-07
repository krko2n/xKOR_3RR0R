#!/bin/bash
set -e

echo "=== Inicializace prostredi xKOR_3RR0R ==="

# 1. Vrstva prostredi: Kontrola a instalace spravce balicku 'uv'
if ! command -v uv &> /dev/null; then
    echo "[INFO] Instaluji uv manager dle doporuceni..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.cargo/env
fi

echo "[INFO] Synchronizace zavislosti (Python 3.11+ pre-req)..."
uv sync

echo "[INFO] Faze 1: Spoustim Krkn-AI Discovery..."
uv run krkn_ai discover --config settings.yaml

echo "[INFO] Faze 2: Spoustim Krkn-AI Chaos Run..."
uv run krkn_ai run --config settings.yaml