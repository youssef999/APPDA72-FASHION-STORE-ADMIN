#!/usr/bin/env bash
# Deploy Firestore rules + Cloud Functions using Node 22 (firebase-tools breaks on Node 26).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NODE22="$ROOT/.tools/node-v22.14.0-darwin-arm64/bin"
if [[ ! -x "$NODE22/node" ]]; then
  echo "Node 22 missing. Download it once:"
  echo "  mkdir -p \"$ROOT/.tools\" && cd \"$ROOT/.tools\""
  echo "  curl -fsSL https://nodejs.org/dist/v22.14.0/node-v22.14.0-darwin-arm64.tar.gz | tar -xz"
  exit 1
fi

export PATH="$NODE22:$PATH"
cd "$ROOT"

if [[ ! -x "$ROOT/node_modules/.bin/firebase" ]]; then
  npm install -D firebase-tools@14 --no-fund --no-audit
fi

echo "Node $(node -v) — deploying firestore:rules,functions …"
"$ROOT/node_modules/.bin/firebase" deploy --only firestore:rules,functions "$@"
