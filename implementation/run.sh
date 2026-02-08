#!/usr/bin/env bash
set -euo pipefail

if [ -f ".env" ]; then
  set -a
  source .env
  set +a
fi


if [ ! -d ".venv" ]; then
  echo "== Creating venv =="
  python3 -m venv .venv
fi

echo "== Activating venv =="
source .venv/bin/activate

echo "== Installing deps =="
python -m pip install --upgrade pip
pip install -r requirements.txt

echo "== Initializing DB =="
chmod +x scripts/init_db.sh
./scripts/init_db.sh

echo "== Running Flask =="
export FLASK_APP=app.py
export FLASK_ENV=development
python app/app.py
