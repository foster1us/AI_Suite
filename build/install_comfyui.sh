#!/usr/bin/env bash
set -e

BASE_DIR=/workspace
APP_DIR="${BASE_DIR}/ComfyUI"
VENV_DIR="${BASE_DIR}/venvs/comfyui"

echo "COMFY: Preparing ComfyUI in ${APP_DIR} with venv ${VENV_DIR}"

mkdir -p "${BASE_DIR}"
mkdir -p "$(dirname "${VENV_DIR}")"

# Clone or update ComfyUI repo
if [ ! -d "${APP_DIR}/.git" ]; then
  echo "COMFY: Cloning ComfyUI..."
  git clone https://github.com/comfyanonymous/ComfyUI.git "${APP_DIR}"
else
  echo "COMFY: Repo already exists, fetching updates..."
  cd "${APP_DIR}"
  git fetch --all || true
fi

cd "${APP_DIR}"

# Checkout desired version/branch/tag
if [ -n "${COMFYUI_VERSION}" ]; then
  echo "COMFY: Checking out ${COMFYUI_VERSION}"
  git checkout "${COMFYUI_VERSION}"
fi

# Create venv if needed
if [ ! -d "${VENV_DIR}" ]; then
  echo "COMFY: Creating virtualenv..."
  python3 -m venv --system-site-packages "${VENV_DIR}"
fi

# Activate venv
# shellcheck source=/dev/null
source "${VENV_DIR}/bin/activate"

# Make sure pip is reasonably up to date
pip3 install --upgrade "pip>=24.0"

# Install torch and xformers
pip3 install --no-cache-dir \
  "torch==${COMFYUI_TORCH_VERSION}" torchvision torchaudio \
  --index-url "${INDEX_URL}"

pip3 install --no-cache-dir \
  "xformers==${COMFYUI_XFORMERS_VERSION}" \
  --index-url "${INDEX_URL}"

# Core requirements
pip3 install -r requirements.txt
pip3 install accelerate
pip3 install "sageattention==1.0.6"
pip3 install --upgrade setuptools

# Custom nodes – ComfyUI-Manager
CUSTOM_NODES_DIR="${APP_DIR}/custom_nodes"
MANAGER_DIR="${CUSTOM_NODES_DIR}/ComfyUI-Manager"

mkdir -p "${CUSTOM_NODES_DIR}"

if [ ! -d "${MANAGER_DIR}/.git" ]; then
  echo "COMFY: Cloning ComfyUI-Manager..."
  git clone https://github.com/ltdrdata/ComfyUI-Manager.git "${MANAGER_DIR}"
else
  echo "COMFY: Updating ComfyUI-Manager..."
  cd "${MANAGER_DIR}"
  git fetch --all || true
  git pull --ff-only || true
fi

cd "${MANAGER_DIR}"
pip3 install -r requirements.txt || true

# Fix some incorrect modules
pip3 install "numpy==1.26.4"

# Clean cache and deactivate
pip3 cache purge || true
deactivate

echo "COMFY: Installation finished."
