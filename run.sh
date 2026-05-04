#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -d node_modules ]; then
  echo "[xKOR] node_modules not found. Running npm install first..."
  npm install
  npm run postinstall
fi

npm start