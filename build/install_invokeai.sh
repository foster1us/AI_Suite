#!/usr/bin/env bash
set -e

# Base paths (all under /workspace so they persist between pods)
BASE_DIR=/workspace
APP_DIR="$BASE_DIR/InvokeAI"
VENV_DIR="$BASE_DIR/venvs/invokeai"

echo "INVOKE: Preparing InvokeAI in $APP_DIR with venv $VENV_DIR"

# Create dirs if needed
mkdir -p "$APP_DIR"
mkdir -p "$(dirname "$VENV_DIR")"

cd "$APP_DIR"

# Create venv only if it doesn't already exist
if [ ! -d "$VENV_DIR" ]; then
  echo "INVOKE: Creating virtualenv..."
  python3 -m venv --system-site-packages "$VENV_DIR"
fi

# Activate venv
# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"

# Upgrade pip inside this venv to avoid old resolver bugs
pip3 install --upgrade "pip>=24.0"

# Install/upgrade InvokeAI
# INVOKEAI_VERSION should already be set in your env; if not, you can hard-pin it here
echo "INVOKE: Installing InvokeAI version ${INVOKEAI_VERSION:-latest from constraint}"
pip3 install "InvokeAI[xformers]==${INVOKEAI_VERSION}" --use-pep517

# Clean pip cache
pip3 cache purge || true

deactivate

echo "INVOKE: Installation finished."
